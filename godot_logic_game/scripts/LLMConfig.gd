class_name LLMConfig
extends RefCounted

# ============================================================
#  LLM 配置（本地 llama.cpp / GGUF）
#  纯离线：模型文件放在手机应用私有目录，不联网、不接云端 API。
#  目标运行环境：Godot 4.7.2（Android 插件 + GABE）或桌面。
#  这些值只被 LocalLLM / LLMAdapter 读取；改这里即改模型行为，不改引擎。
# ============================================================

# 是否尝试启用本地 LLM。false = 完全走纯规则引擎（默认，最稳）。
var enabled := false

# GGUF 模型路径（Android 应用私有目录，如 user:// 或 res:// 预置，需插件能读）
var model_path := "user://model.gguf"

# 上下文长度（llama.cpp 文档明确提醒：过大会让内存暴涨，手机先小）
var context_size := 512

# 单次生成最大 token（手机先短回答）
var max_tokens := 80

# 温度（0=确定性，越高越随机；规则型回复建议偏低）
var temperature := 0.7

# 历史轮数（用于给 LLM 提供最近几轮上下文，0=只看当前）
var history_turns := 2

# ---- 安卓插件接口名称（与 Android 插件 LLMProvider.kt 注册的单例名一致）----
var plugin_singleton := "LlamaCpp"

# 探测到的插件是否已加载模型
var model_loaded := false

func is_enabled() -> bool:
	return enabled

func describe() -> String:
	return "LLMConfig(enabled=%s path=%s ctx=%d max=%d temp=%.2f turns=%d)" % [
		enabled, model_path, context_size, max_tokens, temperature, history_turns
	]
