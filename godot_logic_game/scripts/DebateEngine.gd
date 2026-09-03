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
	return out

func _debate_for(topic: String) -> Dictionary:
	var key := topic.replace("\u201c", "").replace("\u201d", "")
	for k in KnowledgeBase.DEBATES.keys():
		if str(k).replace("\u201c", "").replace("\u201d", "") == key:
			return KnowledgeBase.DEBATES[k]
	return {}

# ------------------------------------------------------------
#  主入口
# ------------------------------------------------------------
func respond(user_input: String) -> Dictionary:
	_round += 1
	var text := user_input.strip_edges()
	if text.is_empty():
		_round -= 1
		return _make("（还没说话呢——抛个观点，我才能杠你。）", "说明", "", false, false)

	# 1) 最高优先：侦测谬误
	var f := _detect_fallacy(text)
	if not f.is_empty():
		_ai_score += 1
		_user_hits += 1
		return _make_fallacy_response(f)

	# 2) 用户用到“讲理/证据”类词 -> 加玩家分并夸
	if _has_good_move(text):
		_user_score += 1
		var praise := KnowledgeBase.pick(KnowledgeBase.PRAISE)
		return _make(_attack_or_socratic(text) + "\n\n" + praise, "有道理？", "", false, true)

	# 4) 是疑问 -> 苏格拉底追问
	if _is_question(text):
		return _make(_socratic(text), "追问", "", false, false)

	# 5) 兜底：通用攻击（若当前是真议题，带上一句“事实弹药”显专业）
	var ammo := _fact_ammo()
	return _make(_attack_or_socratic(text) + ("\n\n" + ammo if not ammo.is_empty() else ""), "拆解", "", false, false)

# ------------------------------------------------------------
#  结算判定
# ------------------------------------------------------------
func settle() -> Dictionary:
	# 返回 { verdict: "ai"/"user"/"draw", text }
	var verdict := "draw"
	if _user_hits > _user_score + 2:
		verdict = "ai"
	elif _user_score > _user_hits + 2:
		verdict = "user"
	var text := ""
	if verdict == "ai":
		text = KnowledgeBase.pick(KnowledgeBase.VERDICT_AI_WIN)
	elif verdict == "user":
		text = KnowledgeBase.pick(KnowledgeBase.VERDICT_USER_WIN)
	else:
		text = KnowledgeBase.pick(KnowledgeBase.VERDICT_DRAW)
	return { "verdict": verdict, "text": text }

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

# 从当前议题库取一句“事实弹药”（约 30% 概率，避免太过重复）
func _fact_ammo() -> String:
	var debate := _debate_for(current_topic)
	if debate.is_empty():
		return ""
	var facts: Array = debate.get("facts", [])
	if facts.is_empty():
		return ""
	# 用个简单“伪随机”不依赖额外状态，避免每条都带
	if randf() < 0.4:
		return ""
	return "补充一点事实：「%s」" % str(KnowledgeBase.pick(facts))

func _attack_or_socratic(text: String) -> String:
	if difficulty >= 2 and randf() < 0.45:
		return _reductio(text)
	return KnowledgeBase.pick(KnowledgeBase.ATTACKS)

func _reductio(text: String) -> String:
	var kw := _pick_keyword(text)
	var tpl := KnowledgeBase.pick(KnowledgeBase.REDUCTIO)
	return tpl.replace("{kw}", kw)

func _pick_keyword(text: String) -> String:
	var trimmed := text.strip_edges()
	if trimmed.length() <= 8:
		return trimmed
	var nouns := [
		"你", "我", "大家", "这个", "那个", "人", "事", "问题", "政策", "钱", "国家",
		"社会", "环境", "公平", "自由", "效率", "安全", "科学", "技术", "自然", "发展",
	]
	for n in nouns:
		if trimmed.contains(n):
			return n
	return trimmed.substr(0, 6)
