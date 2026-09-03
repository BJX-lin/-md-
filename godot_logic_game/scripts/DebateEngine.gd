class_name DebateEngine
extends RefCounted

# ============================================================
# 离线辩论引擎（规则式，非真实 AI，纯本地、零联网）
# ------------------------------------------------------------
# 流程：接收玩家一句话 →
#   1) 侦测是否命中某种逻辑谬误（用 KnowledgeBase 的谬误库）
#   2) 命中 → 给出【识别-拆解-追问】的三连击
#   3) 未命中 → 根据难度/是否疑问/是否含证据，出对应的进攻弹药
# 返回一个字典给 UI：
#   { text, tag, hit, praise, ai_gain, user_gain }
# ============================================================

# --- 难度：越高越“毒舌”/越爱归谬。可在 UI 调整。---
var difficulty := 0

# --- 统计 ---
var _ai_score := 0
var _user_score := 0
var _round := 0

# 用户输入里出现“像在讲理”的词，就给用户加分
const GOOD_MOVE_WORDS := ["反例", "证据", "例如", "比如", "其实", "我认为", "因为", "所以", "如果", "假设", "验证", "数据", "来源", "恰恰"]

func reset() -> void:
	_ai_score = 0
	_user_score = 0
	_round = 0

func ai_score() -> int:
	return _ai_score

func user_score() -> int:
	return _user_score

func round_count() -> int:
	return _round

# --- 主入口：根据玩家输入返回一条“AI 的回应” ---
func respond(user_input: String) -> Dictionary:
	_round += 1
	var text := user_input.strip_edges()
	if text.is_empty():
		return _make("（你还没说话呢——先抛个观点，我才能杠你。）", "", "说明", false, false)

	# 1) 先侦测谬误（最高优先级）
	var f := _detect_fallacy(text)
	if not f.is_empty():
		_ai_score += 1
		return _make_fallacy_response(f)

	# 2) 用户说了“像在讲理”的内容 → 给用户加分并夸
	var user_good := _has_good_move(text)
	if user_good:
		_user_score += 1
		var praise := KnowledgeBase.pick(KnowledgeBase.PRAISE)
		return _make(_attack_or_socratic(text) + "\n\n" + praise, "", "有道理？", false, true)

	# 3) 是疑问 → 用苏格拉底式追问回应
	if _is_question(text):
		return _make(_socratic(text), "", "追问", false, false)

	# 4) 兜底：通用攻击
	return _make(_attack_or_socratic(text), "", "拆解", false, false)

# ------------------------------------------------------------
#  构造一条回应
# ------------------------------------------------------------
func _make(reply: String, tag: String, tone: String, ai_gain: bool, user_gain: bool) -> Dictionary:
	return {
		"text": reply,
		"tag": tag,
		"tone": tone,
		"hit": not tag.is_empty(),
		"praise": user_gain,
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

func _attack_or_socratic(text: String) -> String:
	# 难度越高，越可能上归谬术
	if difficulty >= 2 and randf() < 0.4:
		return _reductio(text)
	var tpl := KnowledgeBase.pick(KnowledgeBase.ATTACKS)
	return tpl

func _reductio(text: String) -> String:
	var kw := _pick_keyword(text)
	var tpl := KnowledgeBase.pick(KnowledgeBase.REDUCTIO)
	return tpl.replace("{kw}", kw)

# 从一个句子里取一个像“关键词”的词放进模板，避免追问太空洞
func _pick_keyword(text: String) -> String:
	# 挑一个长度 ≥ 2 的有意义片段：直接用整句里的一段或抽取一个已知词。
	# 简单起见：如果句子很短就拿整句；否则随机截一个关键短语。
	var trimmed := text.strip_edges()
	if trimmed.length() <= 8:
		return trimmed
	# 尝试抽取“内容词”：列出常见实词，若含则用第一个
	var nouns := ["你", "我", "大家", "这个", "那个", "人", "事", "问题", "政策", "钱", "国家", "社会", "环境", "公平", "自由", "效率", "安全", "科学", "技术"]
	for n in nouns:
		if trimmed.contains(n):
			return n
	# 兜底：取句子前几个字
	return trimmed.substr(0, 6)
