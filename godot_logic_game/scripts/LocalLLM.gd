class_name LocalLLM
extends LLMProvider

# ============================================================
#  本地 LLM（llama.cpp via Android 插件）
#  通过 Godot 的 Engine.get_singleton 调用 Android 插件。
#  插件名默认 "LlamaCpp"（见 LLMConfig.plugin_singleton，与 LLMProvider.kt 一致）。
#  ✔ 插件/模型存在 → 走本地推理
#  ✔ 不存在/未加载 → is_available()=false，引擎自动回退纯规则，不崩溃
# ============================================================

var config := LLMConfig.new()
var _plugin: Variant = null

func _init() -> void:
	_refresh_plugin()

func provider_name() -> String:
	return "LocalLLM(llama.cpp)"

func default_max_tokens() -> int:
	return config.max_tokens

# 探测插件单例是否存在
func _refresh_plugin() -> void:
	_plugin = null
	if Engine.has_singleton(config.plugin_singleton):
		_plugin = Engine.get_singleton(config.plugin_singleton)
		if _plugin == null:
			_plugin = null

func has_plugin() -> bool:
	return _plugin != null

func load_model() -> bool:
	_refresh_plugin()
	if _plugin == null:
		config.model_loaded = false
		return false
	# 调用插件 load_model(path, ctx)。不同插件签名可能不同；失败静默返回 false。
	var ok: bool = _call_plugin("load_model", [config.model_path, config.context_size]) as bool
	config.model_loaded = ok
	return ok

func unload_model() -> void:
	if _plugin != null:
		_call_plugin("unload_model", [])
	config.model_loaded = false

func is_available() -> bool:
	if not config.is_enabled():
		return false
	_refresh_plugin()
	if _plugin == null:
		return false
	# 若要求已加载模型，则需 model_loaded 或插件自报 loaded
	return config.model_loaded or (_call_plugin("is_loaded", []) as bool)

func generate(prompt: String, max_tokens: int) -> String:
	_refresh_plugin()
	if _plugin == null:
		return ""
	var n := max_tokens if max_tokens > 0 else config.max_tokens
	var out: String = _call_plugin("generate", [prompt, n]) as String
	if out == null:
		return ""
	return out

func cancel() -> void:
	if _plugin != null:
		_call_plugin("cancel", [])

# 通过反射调用插件方法；任何异常都返回 null，避免崩溃
func _call_plugin(method: String, args: Array) -> Variant:
	if _plugin == null:
		return null
	if not _plugin.has_method(method):
		return null
	# 插件单例是 Variant，callv() 返回类型也是 Variant；显式定型，避免 Godot 无法推断
	var ok: Variant = _plugin.callv(method, args)
	return ok
