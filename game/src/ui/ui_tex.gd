extends RefCounted
class_name UITex
# UI
# UI

# UI
# State

const ROOT := "res://assets/ui"

# UI
# Cache
static var _cache := {}

static func get_tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var path := "%s/%s.png" % [ROOT, name]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is Texture2D:
			tex = r
	_cache[name] = tex
	return tex

static func has(name: String) -> bool:
	return get_tex(name) != null

# Background

static func make_layer(name: String, alpha := 1.0,
		stretch := TextureRect.STRETCH_SCALE) -> TextureRect:
	var tex := get_tex(name)
	if tex == null:
		return null
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = stretch
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = Color(1, 1, 1, alpha)
	return tr

static func add_under(parent: Control, name: String, alpha := 1.0) -> TextureRect:
	var layer := make_layer(name, alpha)
	if layer == null:
		return null
	parent.add_child(layer)
	parent.move_child(layer, 0)
	return layer

static func style_box(name: String, tint := Color(1, 1, 1, 1),
		margin := 8) -> StyleBoxTexture:
	var tex := get_tex(name)
	if tex == null:
		return null
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.modulate_color = tint
	s.set_texture_margin_all(margin)
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return s
