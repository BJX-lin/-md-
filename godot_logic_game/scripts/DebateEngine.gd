class_name DebateEngine
extends RefCounted

# ============================================================
# 离线辩论引擎（规则式，非真实 AI，纯本地、零联网）
# ------------------------------------------------------------
# 流程：
#   1) 侦测用户输入命中的逻辑谬误 -> 命中则给出【识别-拆解-反问-归谬】
#   2) 未命中但像在讲理（含证据类词）-> 夸 + 给玩家分
#   3) 是疑问 -> 苏格拉底式追问
#   4) 兜底 -> 通用拆解 / 归谬
# 同时管理：辩题、回合、双方计分、结算判定。
# 返回给 UI 的字典：
#   { text, tone, tag, hit, ai_gain, user_gain, end_round }
# ============================================================

var difficulty := 0          # 0温和 1毒舌 2归谬狂魔
var current_topic := ""      # 当前辩题
var max_rounds := 12         # 达到后建议结算

# --- V2.1 模块（离线规则增强）---
var _analyzer := ArgumentAnalyzer.new()
var _fallacy := FallacyDetector.new()
var _combat := AICombatDecision.new()
var _score := ScoreSystem.new()
var _state := DebateStateMachine.new()
var _settle := SettlementSystem.new()
var _export := ExportManager.new()

# --- LLM 可插拔（默认关闭，纯规则）---
# 规则引擎负责“想什么”，此层负责“怎么说”。未接入/不可用即回退纯规则。
var _gen := ResponseGenerator.new()

# 注入一个 LLM 提供者（LocalLLM / 其它）。传 null 或不可用时走纯规则。
func set_llm(provider: LLMProvider) -> void:
	_gen.set_llm(provider)

func has_llm() -> bool:
	return _gen.has_llm()

# 把规则模板文本交给可选 LLM 润色；LLM 不可用时原样返回
# 最后统一做一次流畅度修饰（补齐标点、合并重复、避免句尾截断）
func _naturalize(base_text: String, scene: String, intent: String) -> String:
	return _polish(_gen.naturalize(base_text, intent, current_topic, scene))

# --- 统计 ---
var _ai_score := 0           # 抓到玩家谬误的次数
var _user_score := 0         # 玩家讲理/用到证据的次数
var _user_hits := 0          # 玩家掉谬误数（= 有点相近，但分开记）
var _round := 0

const GOOD_MOVE_WORDS := [
	"反例", "证据", "例如", "比如", "鉴于", "我认为", "因为", "所以", "如果",
	"假设", "验证", "数据", "来源", "恰恰", "然而", "但", "相较于", "对比",
]

func reset() -> void:
	_ai_score = 0
	_user_score = 0
	_user_hits = 0
	_round = 0
	current_topic = ""
	_score.reset()
	_state.reset()
	_combat.set_difficulty(difficulty)

func set_difficulty(d: int) -> void:
	difficulty = clampi(d, 0, 2)
	_combat.set_difficulty(difficulty)

func integrity() -> Dictionary:
	return _score.integrity_report()

func current_stage_label() -> String:
	return _state.current_stage_label()

func player_integrity() -> int:
	return _score.player_integrity

func ai_integrity() -> int:
	return _score.ai_integrity

func ai_score() -> int:
	return _ai_score

func user_score() -> int:
	return _user_score

func user_hits() -> int:
	return _user_hits

func round_count() -> int:
	return _round

func should_end() -> bool:
	return _round >= max_rounds

# 抽一个新辩题并返回开场语
func setup_topic() -> String:
	var t := KnowledgeBase.pick_dict(KnowledgeBase.TOPICS)
	current_topic = str(t.get("topic", ""))
	var ask := str(t.get("ask", "你怎么看？"))
	var out := "本期辩题：「%s」。%s" % [current_topic, ask]
	# 若该辩题在真实议题库里，附上“立场锚点”作提示
	var debate = _debate_for(current_topic)
	if not debate.is_empty():
		out += "\n（提示：本议题的核心冲突是——%s ）" % str(debate.get("clash", ""))
	# 若是经典辩论赛辩题，附上出处与核心技战法
	var c = _case_for(current_topic)
	if not c.is_empty():
		out += "\n（典出：%s ）" % str(c.get("source", ""))
		out += "\n（经典技战法：%s ）" % str(c.get("move", ""))
	return out

func _debate_for(topic: String) -> Dictionary:
	var key := _clean(topic)
	for k in KnowledgeBase.DEBATES.keys():
		if _clean(str(k)) == key:
			return KnowledgeBase.DEBATES[k]
	return {}

func _case_for(topic: String) -> Dictionary:
	var key := _clean(topic)
	for k in KnowledgeBase.DEBATE_CASES.keys():
		if _clean(str(k)) == key:
			return KnowledgeBase.DEBATE_CASES[k]
	return {}

func _clean(s: String) -> String:
	var t := s.replace("\u201c", "").replace("\u201d", "")
	t = t.replace("「", "").replace("」", "")
	return t.strip_edges()

# ------------------------------------------------------------
#  主入口
# ------------------------------------------------------------
func respond(user_input: String) -> Dictionary:
	_round += 1
	var text := user_input.strip_edges()
	if text.is_empty():
		_round -= 1
		return _make("（还没说话呢——抛个观点，我才能杠你。）", "说明", "", false, false)

	# 0) 最高优先：情绪化输入（人身攻击/脏话/极短语/发泄词）-> 安抚+教学，不硬杠
	var emo := _detect_emotion(text)
	if not emo.is_empty():
		_user_hits += 1
		_score.apply_player_fallacy(0.6)
		var r := _make(str(emo.get("reply", "")), str(emo.get("tone", "安抚")), "", false, false)
		r["text"] = _decorate(_naturalize(r["text"], "calm", "情绪安抚"), "calm")
		return r

	# 结构解析 + 谬误检测（新 V2.1 模块）
	var argument := _analyzer.analyze(text)
	var fallac_cands := _fallacy.detect(argument)
	argument["_fallacies"] = fallac_cands
	var top_fallacy: Dictionary = fallac_cands[0] if not fallac_cands.is_empty() else {}

	if not top_fallacy.is_empty():
		# 命中谬误：用结构化谬误回应 + 计血
		var severity := float(top_fallacy.get("confidence", 0.5))
		_ai_score += 1
		_user_hits += 1
		_score.apply_player_fallacy(severity)
		var r := _make_fallacy_response(top_fallacy)
		r["text"] = _decorate(_naturalize(r["text"], "hit", str(r.get("tone", ""))), "hit")
		# 命中后偶尔给出“标准答案/让步”，避免无限杠
		if randf() < 0.4:
			var conc := KnowledgeBase.pick(KnowledgeBase.CONCESSIONS)
			if not conc.is_empty():
				r["text"] += "\n\n" + conc
		return r

	# 2) 用户用到“讲理/证据”类词 -> 加玩家分并夸
	if _has_good_move(text):
		_user_score += 1
		_score.apply_player_good_move()
		var praise := KnowledgeBase.pick(KnowledgeBase.PRAISE)
		var r := _make(_attack_or_socratic(text) + "\n\n" + praise, "有道理？", "", false, true)
		r["text"] = _decorate(_naturalize(r["text"], "good", "夸奖讲理"), "good")
		return r

	# 4) 是疑问 -> 苏格拉底追问
	if _is_question(text):
		var r := _make(_socratic(text), "追问", "", false, false)
		r["text"] = _decorate(_naturalize(r["text"], "ask", "追问"), "ask")
		return r

	# 5) 兜底：AI 决策（无谬误也有攻击点）+ 事实弹药
	var decision := _combat.decide(argument)
	var picked: Dictionary = decision.get("picked", {})
	var attack_text := str(picked.get("text_hint", KnowledgeBase.pick(KnowledgeBase.ATTACKS)))
	var ammo := _fact_ammo()
	var reply := attack_text
	if not ammo.is_empty():
		reply += "\n\n" + ammo
	var r := _make(reply, "拆解", "", false, false)
	var scene := "reductio" if (difficulty >= 2 and reply.contains("照你这么说")) else "generic"
	r["text"] = _decorate(_naturalize(r["text"], scene, "拆解"), scene)
	return r

# 求助 / 见招拆招：给玩家一条原则 + 一条通用反制技巧
func hint() -> String:
	var rb := RebuttalAnalyzer.new()
	var p := KnowledgeBase.pick(KnowledgeBase.PRINCIPLES)
	var h := KnowledgeBase.pick(KnowledgeBase.HINTS)
	return "📖 提示：\n" + p + "\n\n" + h + "\n\n【反击等级】\n" + rb.describe_levels()

# ------------------------------------------------------------
#  结算判定（V2.1：完整度/得分/反击/让步 + 双输）
# ------------------------------------------------------------
func settle() -> Dictionary:
	var ai_hits := 0
	return _settle.settle(_score, _score.player_integrity, _score.ai_integrity,
		_score.player_hits, ai_hits)

# 动态提前结束：核心论证崩溃
func should_early_end() -> bool:
	return _state.is_final() or _settle.should_early_end(_score.player_integrity, _score.ai_integrity)

# ------------------------------------------------------------
#  构造回应
# ------------------------------------------------------------
func _make(reply: String, tone: String, tag: String, ai_gain: bool, user_gain: bool) -> Dictionary:
	return {
		"text": reply,
		"tone": tone,
		"tag": tag,
		"hit": not tag.is_empty(),
		"ai_gain": ai_gain,
		"user_gain": user_gain,
	}

# 给回应文本附加一个 emoji（放在句尾，概率触发以免太吵）
func _decorate(text: String, scene: String) -> String:
	if randf() < 0.5:
		return text
	var e := KnowledgeBase.emoji(scene)
	if e.is_empty():
		return text
	return text + "  " + e

# 语言流畅度修饰：补齐句末标点、合并多余标点、避免句尾截断（不断句/无错字）
func _polish(text: String) -> String:
	var t := text.strip_edges()
	if t.is_empty():
		return t
	# 合并重复的标点，如 “。。。” -> “。”， “？？？” -> “？”
	t = _collapse_punct(t)
	# 若结尾没有句子标点，补一个句号（保留引号/括号收尾的情况）
	var last := t.substr(t.length() - 1, 1)
	var enders := ["。", "！", "？", "…", "”", "」", "』", "）", ")", "！", "?", ".", "!"]
	if not enders.has(last):
		t += "。"
	return t

func _collapse_punct(text: String) -> String:
	# 把连续相同标点压缩为一个
	var out := ""
	var prev := ""
	for ch in text:
		if ch == prev and (ch in "。？！，、；：！？."):
			continue
		out += ch
		prev = ch
	return out

func _make_fallacy_response(f: Dictionary) -> Dictionary:
	var reply := ""
	for line in KnowledgeBase.FALLACY_RESPONSE_TEMPLATE:
		var l := str(line)
		l = l.replace("{name}", str(f["name"]))
		l = l.replace("{explain}", str(f["explain"]))
		l = l.replace("{probe}", str(f["probe"]))
		l = l.replace("{reductio}", str(f["reductio"]))
		reply += l + "\n"
	return _make(reply.strip_edges(), "命中谬误：" + str(f["name"]), "秒杀", true, false)

# ------------------------------------------------------------
#  情绪识别（人身攻击/脏话/极短语/发泄词）
# ------------------------------------------------------------
func _detect_emotion(text: String) -> Dictionary:
	var t := text.strip_edges()
	# 人身攻击 / 脏话
	for w in KnowledgeBase.INSULT_WORDS:
		if t.contains(w):
			return _emo("insult", t)
	# 极短（≤2 字）——多半是情绪或没想好，不硬杠
	if t.length() <= 2:
		return _emo("short", t)
	# 情绪化 / 挑衅 / 嘲讽短语
	for w in KnowledgeBase.RHETORIC_WORDS:
		if t.contains(w):
			return _emo("rhetoric", t)
	return {}

func _emo(kind: String, raw: String) -> Dictionary:
	var pool: Array = []
	match kind:
		"insult":
			pool = KnowledgeBase.EMOTION_INSULT
		"short":
			pool = KnowledgeBase.EMOTION_SHORT
		_:
			pool = KnowledgeBase.EMOTION_RHETORIC
	var tpl := KnowledgeBase.pick(pool)
	return {
		"reply": tpl.replace("{}", raw),
		"tone": "情绪安抚",
		"key": kind,
	}

# ------------------------------------------------------------
#  谬误侦测
# ------------------------------------------------------------
func _detect_fallacy(text: String) -> Dictionary:
	for f in KnowledgeBase.FALLACIES:
		if _signals_hit(text, f):
			return f
	return {}

func _signals_hit(text: String, f: Dictionary) -> bool:
	var signals: Array = f.get("signals", [])
	for s in signals:
		var sig := str(s)
		if not sig.is_empty() and text.contains(sig):
			return true
	var regexes: Array = f.get("regex", [])
	for p in regexes:
		if _regex_hit(text, str(p)):
			return true
	return false

func _regex_hit(text: String, pattern: String) -> bool:
	var re := RegEx.create_from_string(pattern)
	if re == null or not re.is_valid():
		return false
	return re.search(text) != null

# ------------------------------------------------------------
#  兜底弹药
# ------------------------------------------------------------
func _has_good_move(text: String) -> bool:
	for w in GOOD_MOVE_WORDS:
		if text.contains(w):
			return true
	return false

func _is_question(text: String) -> bool:
	return text.contains("?") or text.contains("？") or text.contains("吗")

func _socratic(text: String) -> String:
	var kw := _pick_keyword(text)
	var tpl := KnowledgeBase.pick(KnowledgeBase.SOCRATIC)
	return tpl.replace("{kw}", kw)

# 从当前议题库/经典案例库取一句“事实弹药或经典反驳”（约 30% 概率，避免太过重复）
func _fact_ammo() -> String:
	if randf() < 0.4:
		return ""
	# 经典辩论赛实例：给一句“对方立场里最能用的一句”
	var c := _case_for(current_topic)
	if not c.is_empty():
		var sides: Dictionary = c.get("sides", {})
		# 挑一个与你当前话题相关、但属于“对方”立场的要点来逼你自圆其说
		var all_points: Array = []
		for k in sides.keys():
			var pts: Array = sides.get(k, [])
			for p in pts:
				all_points.append(str(p))
		if not all_points.is_empty():
			return "经典视角：「%s」——你如何回应这一面？" % str(KnowledgeBase.pick(all_points))
	# 否则用真实议题的事实弹药
	var debate := _debate_for(current_topic)
	if debate.is_empty():
		return ""
	var facts: Array = debate.get("facts", [])
	if facts.is_empty():
		return ""
	return "补充一点事实：「%s」" % str(KnowledgeBase.pick(facts))

func _attack_or_socratic(text: String) -> String:
	if difficulty >= 2 and randf() < 0.45:
		return _reductio(text)
	# 经典辩手句式（约 20% 概率），让接招更像资历辩手
	if randf() < 0.2:
		var kw := _pick_keyword(text)
		var tpl := KnowledgeBase.pick(KnowledgeBase.DEBATE_MOVES)
		return tpl.replace("{kw}", kw)
	return KnowledgeBase.pick(KnowledgeBase.ATTACKS)

func _reductio(text: String) -> String:
	var kw := _pick_keyword(text)
	var tpl := KnowledgeBase.pick(KnowledgeBase.REDUCTIO)
	return tpl.replace("{kw}", kw)

func _pick_keyword(text: String) -> String:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return "这事"
	if trimmed.length() <= 8:
		return trimmed
	# 优先取一个干净的“内容词”作为引用对象，避免把句子随意切断（不断句）
	var kw := _extract_clean_keyword(trimmed)
	if kw != "":
		return kw
	# 兜底：取第一个完整子句（到标点为界），太长再截断并加省略号保持连贯
	var seg := _first_clause(trimmed)
	if seg.length() <= 8:
		return seg
	return seg.substr(0, 6) + "…"

# 从输入里挑一个相对有意义的“内容词”（跳过连接词/虚词，避免“因为”“但是”被抓）
func _extract_clean_keyword(text: String) -> String:
	var nouns := [
		"你", "我", "大家", "这个", "那个", "人", "事", "问题", "政策", "钱", "国家",
		"社会", "环境", "公平", "自由", "效率", "安全", "科学", "技术", "自然", "发展",
		"法律", "秩序", "利益", "权利", "义务", "道德", "情感", "需求", "情绪", "事实",
		"教育", "医疗", "经济", "市场", "政府", "企业", "学校", "家庭", "文化",
	]
	for n in nouns:
		if text.contains(n):
			return n
	# 否则取一个“词性像内容”的子串：避开开头连接词，截到下一标点或长度上限
	var seg := _first_clause(text)
	if seg.is_empty():
		return ""
	# 去掉句首的过渡连接词
	var lead := [
		"那", "其实", "但是", "可是", "然而", "不过", "所以", "因此", "就是说",
		"反正", "问题在于", "关键", "所以呢", "那我说",
	]
	for l in lead:
		if seg.begins_with(l):
			seg = seg.substr(l.length()).strip_edges()
			break
	if seg.length() >= 2 and seg.length() <= 8:
		return seg
	if seg.length() > 8:
		return seg.substr(0, 6)
	return ""

# 取第一个完整子句：以常用标点为界，返回其去首尾空白后的内容
func _first_clause(text: String) -> String:
	var i := 0
	var chars := ["，", "。", "；", "！", "？", ",", ".", ";", "!", "?", " "]
	while i < text.length():
		if chars.has(text.substr(i, 1)):
			break
		i += 1
	return text.substr(0, i).strip_edges()
