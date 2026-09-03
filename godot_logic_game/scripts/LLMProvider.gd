class_name LLMProvider
extends RefCounted

# ============================================================
#  LLM 提供者（抽象基类）
#  DebateEngine 只面向本接口，不直接碰 llama.cpp /
#  Android 插件。这样换模型、换后端都不改辩论系统。
#  子类必须实现：
#    - name()
#    - is_available() -> bool
#    - generate(prompt, max_tokens) -> String   （失败返回 "")
#    - cancel()
# ============================================================

func provider_name() -> String:
	return "Abstract"

# 该后端当前是否可用（插件存在且模型已加载）
func is_available() -> bool:
	return false

# 生成文本；出错或不可用返回 ""
func generate(_prompt: String, _max_tokens: int) -> String:
	return ""

func cancel() -> void:
	pass

# 默认单次生成 token 上限；子类可按配置覆写
func default_max_tokens() -> int:
	return 80

# 便捷：给一个结构提示 + 上下文，返回自然语言；失败返回 fallback
func generate_naturalized(prompt: String, max_tokens: int, fallback: String) -> String:
	if not is_available():
		return fallback
	var out := generate(prompt, max_tokens)
	if out.strip_edges().is_empty():
		return fallback
	return out.strip_edges()
