class_name ArgumentAnalyzer
extends RefCounted

# ============================================================
#  论证解析器（V2.1 阶段 1）
#  只负责把玩家文字“转成结构化 argument”，不做推理、不说话。
#  输出 schema 为固定字段（供 FallacyDetector / AICombatDecision / RebuttalAnalyzer 使用）。
#  逻辑：关键词 + 子句切分 + 推论连接词判向，全部用 String / RegEx / Array 实现。
# ============================================================

func analyze(text: String) -> Dictionary:
	var kwe := KeywordExtractor.new()
	var kw := kwe.extract(text)

	var r := {
		"text": text,
		"claim": "",
		"premises": [],
		"evidence": [],
		"examples": [],
		"questions": [],
		"conditions": [],
		"conclusions": [],
		"connectors": [],
		"quantifiers": [],
		"emotion_signals": [],
		"authority_signals": [],
		"causal_signals": [],
		"comparison_signals": [],
		"certainty": 0.0,
	}

	# 字段照抄关键词分类（空数组也保留，schema 恒定）
	r["connectors"] = _merge(_merge(kw["causal"], kw["action"]), kw["contrast"])
	r["quantifiers"] = kw["absolute"].duplicate()
	r["quantifiers"] = _merge(r["quantifiers"], kw["quantifier"])
	r["emotion_signals"] = kw["emotion"]
	r["authority_signals"] = kw["authority"]
	r["causal_signals"] = kw["causal"]
	r["comparison_signals"] = kw["compare"]

	# 拆子句
	var clauses := _split_clauses(text)

	# 识别结论句（含“所以/因此/因而/由此可见/证明/说明/得出/足以说明/意味着/表明”）
	var conclusion_words := _merge(
		kw["action"], ["所以", "因此", "因而", "由此可见", "总之"]
	)

	var premises0: Array = []
	var conclusions0: Array = []
	for clause in clauses:
		var c := str(clause)
		var is_conclusion := _hit(c, conclusion_words)
		var is_premise := _hit(c, kw["causal"]) or _hit(c, ["因为", "由于", "鉴于"])
		if is_conclusion:
			conclusions0.append(c.strip_edges())
		elif is_premise:
			premises0.append(c.strip_edges())
		else:
			# 无信号：若整体只有一个主句，则视为 claim 候选
			premises0.append(c.strip_edges())

	r["premises"] = premises0
	r["conclusions"] = conclusions0

	# claim：优先取含“应该/必须/我认为/是/不是/一定”的主句，否则取第一个非空结论，否则取整体
	r["claim"] = _pick_claim(text, clauses, kw["opinion"], conclusions0, premises0)

	# evidence：关键词里命中证据类的词（含其出现的子句）
	for w in kw["evidence"]:
		var ew := str(w)
		if not r["evidence"].has(ew):
			r["evidence"].append(ew)
	# examples
	for w in kw["examples"]:
		var ew := str(w)
		if not r["examples"].has(ew):
			r["examples"].append(ew)
	# questions
	if kw["question"]:
		var qbody := text.strip_edges()
		if qbody != "":
			r["questions"].append(qbody)
	# conditions（“如果/假如/在某些情况下/当…时”）
	r["conditions"] = _find_conditions(text)

	# certainty：0.5 基准；绝对化 +，概率/条件 -，clamp 到 [0,1]
	var cert := 0.5
	if kw["absolute"].size() > 0:
		cert += 0.25
	if kw["quantifier"].size() > 0:
		cert -= 0.2
	if r["conditions"].size() > 0:
		cert -= 0.1
	r["certainty"] = clampf(cert, 0.0, 1.0)
	return r

# ---------- 工具 ----------
func _hit(text: String, words: Array) -> bool:
	for w in words:
		var s := str(w)
		if not s.is_empty() and text.contains(s):
			return true
	return false

func _merge(a: Array, b: Array) -> Array:
	var out := a.duplicate()
	for x in b:
		if not out.has(x):
			out.append(x)
	return out

func _split_clauses(text: String) -> Array:
	var parts: Array = []
	var buf := ""
	for ch in text:
		if ch in "，。；！？,;.!？":
			var t := buf.strip_edges()
			if t != "":
				parts.append(t)
			buf = ""
		else:
			buf += ch
	var t := buf.strip_edges()
	if t != "":
		parts.append(t)
	return parts

func _pick_claim(text: String, clauses: Array, opinion: Array, conclusions: Array, premises: Array) -> String:
	# 优先结论句
	for c in conclusions:
		return str(c)
	# 再找含观点的子句
	for clause in clauses:
		var cl := str(clause)
		if _hit(cl, opinion):
			return cl
	# 否则第一个前提，或整体
	if premises.size() > 0:
		return str(premises[0])
	return text.strip_edges()

func _find_conditions(text: String) -> Array:
	var out: Array = []
	var cond_words := ["如果", "假如", "要是", "若", "在某些情况下", "的情况下"]
	for w in cond_words:
		var s := str(w)
		if text.contains(s):
			if not out.has(s):
				out.append(s)
	# “当…时 / 当…的时候” 才作条件，避免“应当/当然/相当”误报
	if text.contains("当") and (text.contains("时") or text.contains("的时候")):
		if not out.has("当...时"):
			out.append("当...时")
	return out
