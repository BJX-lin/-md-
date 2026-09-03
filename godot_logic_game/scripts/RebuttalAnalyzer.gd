class_name RebuttalAnalyzer
extends RefCounted

# ============================================================
#  玩家反击分析器（V2.1）
#  当玩家回应 AI 的攻击时，评估这次反击的“质量”（五级）。
#  0=无效 1=弱反击 2=部分有效 3=有效 4=致命反击
#  输出：{ quality, rebuttal_type, target, level }
#  高质量反击会让 AI 攻击强度下降、玩家逻辑分增加。
# ============================================================

# 五级判定基准（用于给玩家/测试展示）
const LEVELS := [
	{ "level": 0, "label": "无效", "desc": "你才是错的。" },
	{ "level": 1, "label": "弱反击", "desc": "我不同意。" },
	{ "level": 2, "label": "部分有效", "desc": "也许还有其他情况。" },
	{ "level": 3, "label": "有效", "desc": "你的结论依赖这个前提，但你没证明它成立。" },
	{ "level": 4, "label": "致命反击", "desc": "你的攻击针对我的表达方式，而非实际论证，因此即使成立也无法推出我错。" },
]

# 输出五级反击的文案（供 UI 求助/教学展示）
func describe_levels() -> String:
	var out := ""
	for l in LEVELS:
		out += "%d＝%s：%s\n" % [l["level"], l["label"], l["desc"]]
	return out

# 评估玩家反击质量（0~4）
func analyze(player_input: String, ai_attack: Dictionary) -> Dictionary:
	var text := player_input.strip_edges()
	var level := 0
	var rtype := "未回应"
	var target := str(ai_attack.get("target", ""))

	# 4 致命：明确指出“攻击的是表达方式/论证形式，而非结论”，或给出具体区分概念
	if _has_meta_level(text):
		level = 4
		rtype = "区分概念/攻击论证形式"
	# 3 有效：指出“你依赖的前提未证明 / 结论不成立”，即反驳掉前提或推出关系
	elif _has_counter_premise(text):
		level = 3
		rtype = "攻击前提/推出关系"
	# 2 部分有效：承认可能存在其它情况 / 反例
	elif _has_qualifier(text):
		level = 2
		rtype = "引入例外/限定"
	# 1 弱：表达不同意但未给理由
	elif _has_disagreement(text):
		level = 1
		rtype = "单纯反对"
	# 0 无效：对 AI 的攻击点（target）没有针对性回应
	return {
		"quality": float(level),
		"rebuttal_type": rtype,
		"target": target,
		"level": level,
	}

func _has_meta_level(t: String) -> bool:
	return t.contains("论证形式") or t.contains("表达方式") or t.contains("不是我的") \
		or t.contains("偷换") or t.contains("针对的不是") or t.contains("区分") \
		or t.contains("概念") or t.contains("并不是") or t.contains("而非")

func _has_counter_premise(t: String) -> bool:
	return t.contains("前提") or t.contains("未证明") or t.contains("不能推出") \
		or t.contains("不代表") or t.contains("不等于") or t.contains("没有证据") \
		or t.contains("无法证明") or t.contains("还不够") or t.contains("不成立")

func _has_qualifier(t: String) -> bool:
	return t.contains("可能") or t.contains("不一定") or t.contains("也有") \
		or t.contains("反例") or t.contains("例外") or t.contains("其他情况") \
		or t.contains("有时候") or t.contains("通常情况下")

func _has_disagreement(t: String) -> bool:
	return t.contains("不同意") or t.contains("不对") or t.contains("错了") \
		or t.contains("不是这样") or t.contains("你错了")
