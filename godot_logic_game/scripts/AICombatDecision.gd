class_name AICombatDecision
extends RefCounted

# ============================================================
#  AI 攻击决策（V2.1）
#  输入 ArgumentAnalyzer 的结构化结果 + FallacyDetector 候选，
#  生成最多 3 个攻击候选（每个含 type/target/attack_score/text_hint），
#  再用加权公式打分，选最高分作为本轮攻击。
#  无谬误时也有攻击点：证据不足/定义不清/因果缺失/方案未知/成本/反例/范围过大。
# ============================================================

const ATK_CLAIM := "ATTACK_CLAIM"
const ATK_PREMISE := "ATTACK_PREMISE"
const ATK_EVIDENCE := "ATTACK_EVIDENCE"
const ATK_CAUSALITY := "ATTACK_CAUSALITY"
const ATK_DEFINITION := "ATTACK_DEFINITION"
const ATK_SCOPE := "ATTACK_SCOPE"
const ATK_EXCEPTION := "ATTACK_EXCEPTION"
const ATK_COUNTEREXAMPLE := "ATTACK_COUNTEREXAMPLE"
const ATK_CONTRADICTION := "ATTACK_CONTRADICTION"
const ATK_REDUCTIO := "ATTACK_REDUCTIO"
const ATK_RELEVANCE := "ATTACK_RELEVANCE"

# 三档难度权重（真正改变行为）：{attack, concession, reductio, question, error}
const DIFFICULTY := [
	{ "attack": 0.5, "concession": 0.7, "reductio": 0.2, "question": 0.5, "error": 0.15 }, # 温和
	{ "attack": 0.8, "concession": 0.35, "reductio": 0.55, "question": 0.75, "error": 0.08 }, # 毒舌
	{ "attack": 1.0, "concession": 0.15, "reductio": 0.9, "question": 0.9, "error": 0.05 }, # 归谬狂魔
]

var _difficulty := 0
func set_difficulty(d: int) -> void:
	_difficulty = clampi(d, 0, 2)

# 主入口：返回 { picked: Dictionary, candidates: Array }
func decide(argument: Dictionary) -> Dictionary:
	var candidates := _generate_candidates(argument)
	var picked: Dictionary = {}
	var best := -1.0
	for c in candidates:
		if c["attack_score"] > best:
			best = c["attack_score"]
			picked = c
	return { "picked": picked, "candidates": candidates }

func _generate_candidates(argument: Dictionary) -> Array:
	var out: Array = []
	var text := str(argument.get("text", ""))
	var claim := str(argument.get("claim", ""))
	var evidence: Array = argument.get("evidence", [])
	var premises: Array = argument.get("premises", [])
	var quantity := maxi(1, premises.size())
	var fallacies: Array = argument.get("_fallacies", [])

	# 用谬误候选喂高价值攻击
	for f in fallacies:
		if out.size() >= 3:
			break
		var conf := float(f.get("confidence", 0.0))
		var atk := "ATTACK_" + _type_from_fallacy(str(f.get("name", "")))
		var score := 0.3 + conf * 0.6
		out.append(_mk(atk, str(f.get("name", "")), score, str(f.get("probe", ""))))

	# 始终补充几个基于结构的攻击点（保证无谬误也有话说）
	var extras := [
		_mk(ATK_EVIDENCE, "证据", _score_by_weight(0.2, evidence.is_empty(), quantity, text), "你给的是断言，还是可核验的证据？"),
		_mk(ATK_DEFINITION, "定义", _score_by_weight(0.2, claim.length() > 0 and not claim.contains("是"), quantity, text), "先把“%s”的含义界定清楚，否则没法谈。" % _head(claim)),
		_mk(ATK_CAUSALITY, "因果", _score_by_weight(0.2, (argument.get("causal_signals", []) as Array).size() == 0, quantity, text), "A 和 B 之间一定有因果吗？还是只是相关？"),
		_mk(ATK_SCOPE, "范围", _score_by_weight(0.25, _has_scope(argument), quantity, text), "这个结论适用到所有情况吗？有没有边界/例外？"),
		_mk(ATK_COUNTEREXAMPLE, "反例", _score_by_weight(0.2, _has_absolute_word(text), quantity, text), "给我一个反例就够了——你能举一个不成立的情形吗？"),
	]
	for e in extras:
		if out.size() >= 3:
			break
		if e["attack_score"] > 0.0:
			out.append(e)

	# 按评分降序
	out.sort_custom(func(a, b): return a["attack_score"] > b["attack_score"])
	return out

func _mk(atk_type: String, target: String, score: float, hint: String) -> Dictionary:
	return { "type": atk_type, "target": target, "attack_score": score, "text_hint": hint }

# 加权评分：漏洞明显度(含 fallback 用 score_weight)、相关度、证据缺口、反击难度、策略
func _score_by_weight(score_weight: float, gap: bool, quantity: int, text: String) -> float:
	var attr := float(randf()) * 0.3 + score_weight       # 漏洞明显度（0.3 权）
	# 相关度：文本越长、前提越多，通常越值得攻击
	var relevance := clampf(float(text.length()) / 30.0 + float(quantity) * 0.08, 0.0, 1.0)
	var evidence_gap := 0.0
	if gap:
		evidence_gap = 0.2
	var counter_hardness := 0.15                            # 反击难度
	var strategy := float(_difficulty) * 0.05               # 当前回合策略
	return clampf(attr * 0.3 + relevance * 0.25 + evidence_gap * 0.2 + counter_hardness * 0.15 + strategy * 0.1, 0.0, 1.0)

func _has_scope(argument: Dictionary) -> bool:
	var text := str(argument.get("text", ""))
	return _has_absolute_word(text) or not (argument.get("quantifiers", []) as Array).is_empty()

func _has_absolute_word(text: String) -> bool:
	for w in KeywordDatabase.ABSOLUTE:
		if text.contains(str(w)):
			return true
	return false

func _type_from_fallacy(name: String) -> String:
	var m := {
		"大众": "RELEVANCE", "权威": "RELEVANCE", "人身": "RELEVANCE",
		"滑坡": "CAUSALITY", "假两难": "SCOPE", "以偏概全": "SCOPE",
		"稻草人": "CLAIM", "循环": "PREMISE", "类比": "COUNTEREXAMPLE",
	}
	for k in m.keys():
		if name.contains(str(k)):
			return str(m[k])
	return "CLAIM"

func _head(s: String) -> String:
	if s.length() > 12:
		return s.substr(0, 12) + "…"
	return s
