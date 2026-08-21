extends Control
class_name SplashScreen
# Splash
# Engine

# Title

## 开屏（v1.4.5 三段式）：
##   段0 Godot 引擎致意（"该游戏使用 Godot 4.7.2 制作"）
##   段1 制作信息（塞博仓鼠 × AI 制作 + AI 仓鼠图标）
##   段2 作品标示（标题/副标题/内容提示/版本）
## 进入方式：点击 / 触摸 / 任意键 = 前进一段（每段最短停留 0.35s 防误触连跳）；
##           Esc / 手柄B = 一键跳过全部。底部有动态提示文字。

signal finished

const STAGE_DUR := [2.6, 3.0, 2.8]
const STAGE_MIN_HOLD := 0.35
const FADE := 0.45

var _t := 0.0
var _stage := 0
var _done := false

var _stage_root: Control
var _stages: Array[Control] = []
var _hint: Label

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

	_stages = [_build_godot_stage(), _build_credits_stage(), _build_game_stage()]
	for st in _stages:
		_stage_root.add_child(st)
	_show_stage(0)

	_hint = Label.new()
	_hint.text = "点击进入下一段 · Esc 跳过"
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -34
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(0.42, 0.42, 0.46, 0.75))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_advance()
	)

func _unhandled_input(e: InputEvent) -> void:
	if _done:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			_skip_all()
		else:
			_advance()
	elif e is InputEventScreenTouch and e.pressed:
		_advance()

## 进入方式（v1.4.5）：普通点击/按键逐段前进；Esc 直接跳到结尾
func _advance() -> void:
	if _done:
		return
	if _t < STAGE_MIN_HOLD:
		return  # 防止连点瞬间跳完整段
	_t = 0.0
	_stage += 1
	if _stage >= _stages.size():
		_finish()
	else:
		_show_stage(_stage)

func _skip_all() -> void:
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
		if _stage >= _stages.size():
			_finish()
			return
		_show_stage(_stage)

func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	_hint.text = ""
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		finished.emit()
		queue_free()
	)

func _show_stage(i: int) -> void:
	for k in _stages.size():
		_stages[k].visible = k == i
	var root: Control = _stages[i]
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

	var credit := Label.new()
	credit.text = "该游戏使用 Godot 4.7.2 制作"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 20)
	credit.add_theme_color_override("font_color", Color(0.62, 0.70, 0.82))
	v.add_child(credit)

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

## 制作信息段（v1.4.5）：塞博仓鼠 × AI 制作；AI 图标缺失时回落为代码绘制的小仓鼠
func _build_credits_stage() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	center.add_child(v)

	var icon := TextureRect.new()
	icon.texture = UITex.get_tex("agent_hamster")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(150, 150)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	if icon.texture != null:
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(icon, "modulate:a", 0.86, 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(icon, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	else:
		var fb := _draw_hamster_fallback()
		fb.custom_minimum_size = Vector2(150, 150)
		v.add_child(fb)

	var made := Label.new()
	made.text = "塞博仓鼠 🐹 × AI 制作"
	made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	made.add_theme_font_size_override("font_size", 34)
	made.add_theme_color_override("font_color", Color(0.72, 0.84, 1.0))
	made.add_theme_color_override("font_shadow_color", Color(0.10, 0.20, 0.40, 0.6))
	made.add_theme_constant_override("shadow_offset_y", 2)
	v.add_child(made)

	var sub := Label.new()
	sub.text = "CYBER HAMSTER × AI"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.45, 0.52, 0.62))
	v.add_child(sub)
	return c

## AI 仓鼠图标的代码回落绘制（无贴图时也能成立）
func _draw_hamster_fallback() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var s := c.size
		var cx := s.x * 0.5
		var cy := s.y * 0.55
		var r := minf(s.x, s.y) * 0.30
		var fur := Color(0.16, 0.20, 0.30)
		var glow := Color(0.29, 0.55, 1.0)
		# 耳朵
		c.draw_circle(Vector2(cx - r * 0.62, cy - r * 0.92), r * 0.30, fur)
		c.draw_circle(Vector2(cx + r * 0.62, cy - r * 0.92), r * 0.30, fur)
		c.draw_circle(Vector2(cx - r * 0.62, cy - r * 0.92), r * 0.14, glow)
		c.draw_circle(Vector2(cx + r * 0.62, cy - r * 0.92), r * 0.14, glow)
		# 脸
		c.draw_circle(Vector2(cx, cy), r, fur)
		# 发光眼
		c.draw_circle(Vector2(cx - r * 0.38, cy - r * 0.08), r * 0.16, glow)
		c.draw_circle(Vector2(cx + r * 0.38, cy - r * 0.08), r * 0.16, glow)
		# 电路纹
		c.draw_line(Vector2(cx - r * 0.8, cy + r * 0.35), Vector2(cx + r * 0.8, cy + r * 0.35), glow * Color(1, 1, 1, 0.5), 2.0)
		# 腮帮籽
		c.draw_circle(Vector2(cx - r * 0.72, cy + r * 0.22), r * 0.10, Color(0.36, 0.72, 0.52))
		c.draw_circle(Vector2(cx + r * 0.72, cy + r * 0.22), r * 0.10, Color(0.36, 0.72, 0.52))
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
