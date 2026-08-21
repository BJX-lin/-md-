extends Control
class_name SplashScreen
# Splash
# Engine

# Title

## 开屏（v1.4.6 双图标合并版）：
##   段0 双图标汇合：塞博仓鼠(AI) 从左、Godot 从右向中间移动 → 合并闪光后只保留
##      Godot 图标 → 放大 0.5s 后复原 → 跑马灯字幕带扫过 → 进入下一段
##   段1 作品标示（标题/副标题/内容提示/版本）
## 进入方式：点击 / 触摸 / 任意键 = 前进一段（每段最短停留 0.35s 防误触连跳）；
##           Esc = 一键跳过。底部有动态提示文字。

signal finished

const STAGE_DUR := [4.8, 3.0]
const STAGE_MIN_HOLD := 0.35
const FADE := 0.45

## 合并动画时间轴（秒）
const T_SLIDE := 1.1      # 双图标向中间移动
const T_MERGE := 0.45     # 仓鼠淡出/合并闪光
const T_PULSE := 0.5      # Godot 图标放大
const T_PULSE_BACK := 0.3 # 放大后复原
const T_MARQUEE := 1.3    # 跑马灯扫过

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

	_stages = [_build_merge_stage(), _build_game_stage()]
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
	if i == 0:
		_play_merge_sequence(root)

## 段0：双图标对进 → 合并 → 仅留 Godot → 放大 0.5s 复原 → 跑马灯
func _build_merge_stage() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 合并闪光（初始全透明）
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_CENTER)
	flash.color = Color(0.55, 0.72, 1.0, 0.0)
	flash.custom_minimum_size = Vector2(360, 360)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.name = "Flash"
	c.add_child(flash)

	# 仓鼠（AI）图标：居中锚点，起点在屏幕左外
	var ham := TextureRect.new()
	ham.texture = UITex.get_tex("agent_hamster")
	ham.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ham.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ham.custom_minimum_size = Vector2(150, 150)
	ham.set_anchors_preset(Control.PRESET_CENTER)
	ham.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ham.grow_vertical = Control.GROW_DIRECTION_BOTH
	ham.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ham.pivot_offset = Vector2(75, 75)
	ham.name = "Hamster"
	c.add_child(ham)
	if ham.texture == null:
		var fb := _draw_hamster_fallback()
		fb.name = "HamsterFallback"
		fb.custom_minimum_size = Vector2(150, 150)
		fb.set_anchors_preset(Control.PRESET_CENTER)
		c.add_child(fb)

	# Godot 图标：居中锚点，起点在屏幕右外
	var god := TextureRect.new()
	god.texture = UITex.get_tex("godot_mark")
	god.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	god.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	god.custom_minimum_size = Vector2(128, 128)
	god.set_anchors_preset(Control.PRESET_CENTER)
	god.grow_horizontal = Control.GROW_DIRECTION_BOTH
	god.grow_vertical = Control.GROW_DIRECTION_BOTH
	god.mouse_filter = Control.MOUSE_FILTER_IGNORE
	god.pivot_offset = Vector2(64, 64)
	god.name = "Godot"
	c.add_child(god)
	if god.texture == null:
		var fb2 := _draw_godot_fallback()
		fb2.name = "GodotFallback"
		fb2.custom_minimum_size = Vector2(140, 140)
		fb2.set_anchors_preset(Control.PRESET_CENTER)
		c.add_child(fb2)

	# 引擎致意字幕（合并后淡入）
	var credit := Label.new()
	credit.text = "该游戏使用 Godot 4.7.2 制作"
	credit.name = "Credit"
	credit.set_anchors_preset(Control.PRESET_CENTER)
	credit.offset_top = 110
	credit.offset_bottom = 150
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 21)
	credit.add_theme_color_override("font_color", Color(0.62, 0.70, 0.82))
	credit.modulate.a = 0.0
	credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(credit)

	# 跑马灯字幕带（初始在屏幕右外）
	var band := PanelContainer.new()
	band.name = "Marquee"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.14, 0.22, 0.92)
	sb.border_color = Color(0.29, 0.55, 1.0, 0.55)
	sb.set_border_width_all(1)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	band.add_theme_stylebox_override("panel", sb)
	var ml := Label.new()
	ml.text = "《第十三节课》 THE 13TH PERIOD　★　塞博仓鼠 × AI 制作　★　该游戏使用 Godot 4.7.2 制作　★　建议佩戴耳机游玩"
	ml.add_theme_font_size_override("font_size", 22)
	ml.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98))
	band.add_child(ml)
	band.set_anchors_preset(Control.PRESET_CENTER)
	band.offset_top = 170
	band.offset_bottom = 224
	band.modulate.a = 0.0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.size = Vector2(0, 0)
	c.add_child(band)
	return c

## 时间轴驱动（等布局稳定后启动）
func _play_merge_sequence(root: Control) -> void:
	var ham: Control = root.get_node_or_null("Hamster")
	if ham == null:
		ham = root.get_node_or_null("HamsterFallback")
	var god: Control = root.get_node_or_null("Godot")
	if god == null:
		god = root.get_node_or_null("GodotFallback")
	var flash: ColorRect = root.get_node("Flash")
	var credit: Label = root.get_node("Credit")
	var band: PanelContainer = root.get_node("Marquee")
	if ham == null or god == null:
		return

	_play_merge_sequence_deferred.call_deferred(ham, god, flash, credit, band)

func _play_merge_sequence_deferred(ham: Control, god: Control, flash: ColorRect, credit: Label, band: PanelContainer) -> void:
	var vw := size.x
	var travel := vw * 0.5 + 160.0
	# 起始：左右屏幕外
	ham.position.x = size.x * 0.5 - travel - ham.size.x * 0.5
	god.position.x = size.x * 0.5 + travel - god.size.x * 0.5
	ham.modulate.a = 1.0
	god.modulate.a = 1.0

	var tw := create_tween()
	tw.set_parallel(true)
	# 1) 双图标向中间移动
	tw.tween_property(ham, "position:x",
		size.x * 0.5 - ham.size.x * 0.5, T_SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(god, "position:x",
		size.x * 0.5 - god.size.x * 0.5, T_SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# 2) 合并：闪光 + 仓鼠淡出（仅保留 Godot）
	tw.tween_property(flash, "color:a", 0.85, 0.12).set_delay(T_SLIDE)
	tw.tween_property(flash, "color:a", 0.0, 0.35).set_delay(T_SLIDE + 0.12)
	tw.tween_property(ham, "modulate:a", 0.0, T_MERGE).set_delay(T_SLIDE)
	tw.tween_property(ham, "scale", Vector2(1.25, 1.25), T_MERGE).set_delay(T_SLIDE)
	# 3) Godot 放大 0.5s 后复原
	tw.tween_property(god, "scale", Vector2(1.35, 1.35), T_PULSE).set_delay(T_SLIDE + T_MERGE) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(god, "scale", Vector2.ONE, T_PULSE_BACK).set_delay(T_SLIDE + T_MERGE + T_PULSE)
	# 4) 字幕淡入
	tw.tween_property(credit, "modulate:a", 1.0, 0.4).set_delay(T_SLIDE + T_MERGE + 0.1)
	# 5) 跑马灯：从右向左扫过屏幕
	tw.tween_property(band, "modulate:a", 1.0, 0.2).set_delay(T_SLIDE + T_MERGE + T_PULSE + T_PULSE_BACK)
	var band_w := maxf(900.0, band.size.x + 80.0)
	tw.tween_property(band, "position:x", -band_w, T_MARQUEE) \
		.set_delay(T_SLIDE + T_MERGE + T_PULSE + T_PULSE_BACK + 0.15) \
		.set_trans(Tween.TRANS_LINEAR)
	tw.tween_property(band, "modulate:a", 0.0, 0.25) \
		.set_delay(T_SLIDE + T_MERGE + T_PULSE + T_PULSE_BACK + T_MARQUEE)
	tw.set_parallel(false)

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
		c.draw_circle(Vector2(cx - r * 0.62, cy - r * 0.92), r * 0.30, fur)
		c.draw_circle(Vector2(cx + r * 0.62, cy - r * 0.92), r * 0.30, fur)
		c.draw_circle(Vector2(cx - r * 0.62, cy - r * 0.92), r * 0.14, glow)
		c.draw_circle(Vector2(cx + r * 0.62, cy - r * 0.92), r * 0.14, glow)
		c.draw_circle(Vector2(cx, cy), r, fur)
		c.draw_circle(Vector2(cx - r * 0.38, cy - r * 0.08), r * 0.16, glow)
		c.draw_circle(Vector2(cx + r * 0.38, cy - r * 0.08), r * 0.16, glow)
		c.draw_line(Vector2(cx - r * 0.8, cy + r * 0.35), Vector2(cx + r * 0.8, cy + r * 0.35), glow * Color(1, 1, 1, 0.5), 2.0)
		c.draw_circle(Vector2(cx - r * 0.72, cy + r * 0.22), r * 0.10, Color(0.36, 0.72, 0.52))
		c.draw_circle(Vector2(cx + r * 0.72, cy + r * 0.22), r * 0.10, Color(0.36, 0.72, 0.52))
	)
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

	var made := Label.new()
	made.text = "塞博仓鼠 🐹 × AI 制作　·　该游戏使用 Godot 4.7.2 制作"
	made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	made.add_theme_font_size_override("font_size", 17)
	made.add_theme_color_override("font_color", Color(0.58, 0.66, 0.80))
	v.add_child(made)

	var ver := Label.new()
	ver.text = "v" + Cfg.VERSION
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 14)
	ver.add_theme_color_override("font_color", Color(0.38, 0.38, 0.40, 0.8))
	v.add_child(ver)
	return c
