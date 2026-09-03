class_name KeywordExtractor
extends RefCounted

# ============================================================
#  关键词提取器（V2.1 阶段 1）
#  只负责把玩家文字里的“关键词信号”分类出来，不做推理、不说话。
#  数据源：data/KeywordDatabase.gd（12 类 + 动作关键词）。
#  输出字段供 ArgumentAnalyzer / FallacyDetector 使用。
# ============================================================

# 逐类扫描文本，返回 { 类别: [命中词...], question: bool }
func extract(text: String) -> Dictionary:
	var r := {
		"causal":      [],   # 因果
		"opinion":     [],   # 观点/结论
		"evidence":    [],   # 证据/数据
		"examples":    [],   # 举例
		"contrast":    [],   # 转折
		"compare":     [],   # 比较
		"absolute":    [],   # 绝对化
		"quantifier":  [],   # 概率/限定
		"emotion":     [],   # 情绪
		"authority":   [],   # 权威
		"action":      [],   # 动作/推论
		"question": false,   # 是否疑问
	}
	_collect(text, KeywordDatabase.CAUSAL, r["causal"])
	_collect(text, KeywordDatabase.OPINION, r["opinion"])
	_collect(text, KeywordDatabase.EVIDENCE, r["evidence"])
	_collect(text, KeywordDatabase.EXAMPLES, r["examples"])
	_collect(text, KeywordDatabase.CONTRAST, r["contrast"])
	_collect(text, KeywordDatabase.COMPARE, r["compare"])
	_collect(text, KeywordDatabase.ABSOLUTE, r["absolute"])
	_collect(text, KeywordDatabase.QUANTIFIER, r["quantifier"])
	_collect(text, KeywordDatabase.EMOTION_KW, r["emotion"])
	_collect(text, KeywordDatabase.AUTHORITY, r["authority"])
	_collect(text, KeywordDatabase.ACTION, r["action"])
	r["question"] = _is_question(text)
	return r

# 把命中的关键词去重后填入目标数组
func _collect(text: String, pool: Array, into: Array) -> void:
	for w in pool:
		var kw := str(w)
		if not kw.is_empty() and text.contains(kw):
			if not into.has(kw):
				into.append(kw)

func _is_question(text: String) -> bool:
	for w in KeywordDatabase.QUESTION:
		if text.contains(str(w)):
			return true
	return text.contains("?") or text.contains("？")
