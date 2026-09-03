class_name ResponseGenerator
extends RefCounted

# ============================================================
#  回应生成器（V2.1 / LLM 可插拔）
#  原则：规则引擎负责“想什么”，本层负责“怎么说”。
#  默认用规则模板（base_text）直接输出，行为与纯离线版完全一致；
#  若配置了可用的 LocalLLM，则让 LLM 把 base_text 改写得更自然，
#  但只作为“润色”，不改要点，失败时静默回退到 base_text。
# ============================================================

var llm: LLMProvider = null

func set_llm(provider: LLMProvider) -> void:
	llm = provider

func has_llm() -> bool:
	return llm != null and llm.is_available()

# 把结构化的 AI 回应转成最终文本
#  params:
#   - base_text: 规则引擎已装配好的文字（必填）
#   - intent:    意图提示，如 "命中谬误:诉诸大众 / 毒舌" 或 "安抚"（用于给 LLM 的 instruction）
#   - topic:     当前辩题（可选，供 LLM 保持主题）
#   - scene:     emoji 场景（hit/good/ask/generic/reductio/open/calm）
func naturalize(base_text: String, intent: String, topic: String, scene: String) -> String:
	if base_text.strip_edges().is_empty():
		return base_text
	if not has_llm():
		return base_text
	var prompt := _build_prompt(base_text, intent, topic, scene)
	var max_t := llm.default_max_tokens()
	var rewritten := llm.generate(prompt, max_t)
	if rewritten.strip_edges().is_empty():
		return base_text
	return rewritten.strip_edges()

func _build_prompt(base_text: String, intent: String, topic: String, scene: String) -> String:
	var p := "你是「杠精老师」· 逻辑辩论离线助手。用中文把下面这句话改写成更自然、更口语化的反驳，保持逻辑要点与讽刺/教学语气，不要添加原本没有的事实，不要超过 120 字。\n"
	if topic != "":
		p += "当前辩题：%s\n" % topic
	if intent != "":
		p += "意图：%s\n" % intent
	if scene != "":
		p += "氛围场景：%s\n" % scene
	p += "待改写原文：\n%s\n\n请直接输出改写后的回复：" % base_text
	return p
