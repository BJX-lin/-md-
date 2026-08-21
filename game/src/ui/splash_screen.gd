extends Control
class_name SplashScreen
# Splash
# Engine

# Title

signal finished

const STAGE_DUR := [2.4, 2.8]
const FADE := 0.45

var _t := 0.0
var _stage := 0
var _done := false

var _stage_root: Control
var _stage0: Control
var _stage1: Control

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0.0
	offset_bottom = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(true)
	set_process_unhandled_input(true)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.012, 0.014, 0.02)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Background
	# Engine
	var scene_tex := UITex.get_tex("splash_bg")
	if scene_tex != null:
		var scene := TextureRect.new()
		scene.texture = scene_tex
		scene.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		scene.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		scene.set_anchors_preset(Control.PRESET_FULL_RECT)
		scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scene.modulate = Color(0.62, 0.66, 0.72)
		add_child(scene)
		# Perf
		scene.scale = Vector2(1.08, 1.08)
		scene.pivot_offset = scene.size * 0.5
		scene.resized.connect(func(): scene.pivot_offset = scene.size * 0.5)
		var tw_bg := create_tween()
		tw_bg.tween_property(scene, "scale", Vector2.ONE, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_stage_root = Control.new()
	_stage_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_root)

	_stage0 = _build_godot_stage()
	_stage1 = _build_game_stage()
	_stage_root.add_child(_stage0)
	_stage_root.add_child(_stage1)
	_show_stage(0)

	var skip := Label.new()
	skip.text = "点击跳过"
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -140
	skip.offset_top = -34
	skip.offset_right = -24
	skip.add_theme_font_size_override("font_size", 15)
	skip.add_theme_color_override("font_color", Color(0.42, 0.42, 0.46, 0.75))
	skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skip)

	gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_skip()
	)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		_skip()
	elif e is InputEventScreenTouch and e.pressed:
		_skip()

func _skip() -> void:
	if _done:
		return
	_finish()

func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var limit: float = float(STAGE_DUR[_stage]) if _stage < STAGE_DUR.size() else 0.0
	if _t >= limit:
		_t = 0.0
		_stage += 1
		if _stage >= STAGE_DUR.size():
			_finish()
			return
		_show_stage(_stage)

func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		finished.emit()
		queue_free()
	)

func _show_stage(i: int) -> void:
	_stage0.visible = i == 0
	_stage1.visible = i == 1
	var root: Control = _stage0 if i == 0 else _stage1
	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, FADE)

# Engine
func _build_godot_stage() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 22)
	center.add_child(v)

	var icon := TextureRect.new()
	icon.texture = UITex.get_tex("godot_mark")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(128, 128)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)

	var wordmark := TextureRect.new()
	wordmark.texture = UITex.get_tex("godot_logo")
	wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wordmark.custom_minimum_size = Vector2(0, 52)
	wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(wordmark)

	# Draw
	if icon.texture == null:
		var fb := _draw_godot_fallback()
		fb.custom_minimum_size = Vector2(140, 140)
		v.add_child(fb)
	if wordmark.texture == null:
		var cap := Label.new()
		cap.text = "MADE WITH GODOT ENGINE"
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 26)
		cap.add_theme_color_override("font_color", Color(0.80, 0.84, 0.88))
		v.add_child(cap)

	var site := Label.new()
	site.text = "godotengine.org"
	site.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	site.add_theme_font_size_override("font_size", 16)
	site.add_theme_color_override("font_color", Color(0.45, 0.50, 0.56, 0.9))
	v.add_child(site)
	return c

func _draw_godot_fallback() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var s := c.size
		var r := minf(s.x, s.y) * 0.36
		var head := Vector2(s.x * 0.5, s.y * 0.48)
		var body := Color(0.30, 0.47, 0.62)
		var eye := Color(0.92, 0.95, 0.98)
		var pts := PackedVector2Array([
			head + Vector2(-r, -r * 0.55), head + Vector2(r, -r * 0.55),
			head + Vector2(r * 1.05, r * 0.5), head + Vector2(0, r * 0.95),
			head + Vector2(-r * 1.05, r * 0.5),
		])
		c.draw_colored_polygon(pts, body)
		c.draw_circle(head + Vector2(-r * 0.42, -r * 0.05), r * 0.24, eye)
		c.draw_circle(head + Vector2(r * 0.42, -r * 0.05), r * 0.24, eye)
		c.draw_circle(head + Vector2(-r * 0.42, -r * 0.05), r * 0.11, Color(0.12, 0.16, 0.2))
		c.draw_circle(head + Vector2(r * 0.42, -r * 0.05), r * 0.11, Color(0.12, 0.16, 0.2))
		c.draw_rect(Rect2(head.x - r * 0.5, head.y + r * 0.42, r, r * 0.13), Color(0.16, 0.26, 0.34), true)
	)
	return c

func _build_game_stage() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)

	var title := Label.new()
	title.text = Cfg.GAME_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.90, 0.88, 0.82))
	title.add_theme_color_override("font_shadow_color", Color(0.5, 0.05, 0.04, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	v.add_child(title)

	var sub := Label.new()
	sub.text = Cfg.GAME_SUBTITLE
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.55, 0.53, 0.50))
	v.add_child(sub)

	var warn := Label.new()
	warn.text = "本作含惊悚与少量血腥描写 · 建议在光线充足的环境下游玩"
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_font_size_override("font_size", 17)
	warn.add_theme_color_override("font_color", Color(0.62, 0.58, 0.54, 0.95))
	v.add_child(warn)

	var ver := Label.new()
	ver.text = "v" + Cfg.VERSION
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 14)
	ver.add_theme_color_override("font_color", Color(0.38, 0.38, 0.40, 0.8))
	v.add_child(ver)
	return c
