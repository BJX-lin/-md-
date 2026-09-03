class_name FallacyDetector
extends RefCounted

# ============================================================
#  谬误检测器（V2.1）
#  由 ArgumentAnalyzer 的结构化输出 + 关键词置信度规则，
#  推断最可能的逻辑谬误。输出多条候选（带 confidence），
#  供 AICombatDecision 选择攻击点。
#  纯离线：只用 RegEx / 关键词 / 字符串，不联网。
# ============================================================

# 主入口：给出结构化 argument，返回命中候选（按置信度降序）
# 每条候选 = { name, en, confidence, explain, probe, reductio, counter }
func detect(argument: Dictionary) -> Array:
	var text := str(argument.get("text", ""))
	var scored: Array = []
	for f in KnowledgeBase.FALLACIES:
		var conf := _score_fallacy(f, text, argument)
		if conf > 0.0:
			var cand: Dictionary = f.duplicate(true)
			cand["confidence"] = conf
			scored.append(cand)
	# 按置信度降序
	scored.sort_custom(func(a, b): return a["confidence"] > b["confidence"])
	return scored

# 对单条谬误计算置信度：基础命中 + 结构信号加成/削弱
func _score_fallacy(f: Dictionary, text: String, argument: Dictionary) -> float:
	var signals: Array = f.get("signals", [])
	var regexes: Array = f.get("regex", [])
	var base := 0.0
	for s in signals:
		var sig := str(s)
		if not sig.is_empty() and text.contains(sig):
			base = 0.6
			break
	if base == 0.0:
		for p in regexes:
			var re := RegEx.create_from_string(str(p))
			if re != null and re.is_valid() and re.search(text) != null:
				base = 0.6
				break
	if base == 0.0:
		return 0.0

	var name := str(f.get("name", ""))
	var certainty := float(argument.get("certainty", 0.5))
	var quantifiers: Array = argument.get("quantifiers", [])

	# 绝对化 / 以偏概全 / 滑坡：出现绝对化词则增强
	if _contains_any(name, ["以偏概全", "绝对化", "滑坡", "假两难", "诉诸大众"]) :
		var has_abs := str(argument.get("text", "")).length() > 0 and _has_absolute(text)
		if has_abs:
			base += 0.15
	# 概率/限定词：削弱“以偏概全/过度概括”
	if _contains_any(name, ["以偏概全", "绝对化", "草率概括"]) and _has_quantifier(quantifiers):
		base -= 0.15
	# 诉诸权威：需“权威+因果/绝对化”显著组合
	if name.contains("权威"):
		var has_authority := not (argument.get("authority_signals", []) as Array).is_empty()
		var has_causal := not (argument.get("causal_signals", []) as Array).is_empty()
		if not (has_authority and has_causal):
			base -= 0.2
	# 复杂问句：命中且含疑问 → 增强
	if name.contains("复杂问句") and not (argument.get("questions", []) as Array).is_empty():
		base += 0.1
	# 圆滑：too certain but no evidence → 轻微增强“断言”
	if certainty > 0.7 and (argument.get("evidence", []) as Array).is_empty():
		base += 0.05
	return clampf(base, 0.0, 1.0)

func _contains_any(name: String, keys: Array) -> bool:
	for k in keys:
		if name.contains(str(k)):
			return true
	return false

func _has_absolute(text: String) -> bool:
	for w in KeywordDatabase.ABSOLUTE:
		if text.contains(str(w)):
			return true
	return false

func _has_quantifier(quantifiers: Array) -> bool:
	for q in quantifiers:
		var s := str(q)
		if s in KeywordDatabase.QUANTIFIER:
			return true
	return false
