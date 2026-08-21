extends Control
# Sprite

signal finished(ending_id: String)
signal quit_to_title()

const BGLayerS := preload("res://src/art/bg_layer.gd")
const ActorSpriteS := preload("res://src/art/actor_sprite.gd")
const LoadingOverlayS := preload("res://src/ui/loading_overlay.gd")
const StatusGaugeS := preload("res://src/ui/status_gauge.gd")
const EffectsLayerS := preload("res://src/art/effects_layer.gd")
const SanityFXS := preload("res://src/art/sanity_fx.gd")
const GoreOverlayS := preload("res://src/art/gore_overlay.gd")
const OW := preload("res://src/ui/overlay_widgets.gd")
const MP := preload("res://src/ui/menu_panels.gd")
const PadlockPanelS := preload("res://src/ui/padlock_panel.gd")

const TOUCH_MIN := 48

# Sanity
# Sanity

const SANITY_GHOST_AT := 20.0

var world: Control
var bg: BGLayer
var actor_root: Control
var actors := {}                # who -> {"node":ActorSprite,"pos":String}
var fx: EffectsLayer
var sanity_fx: SanityFX
var gore: GoreOverlay
var time_label: Label
var fps_label: Label
var ui_root: Control

var name_label: Label
var text_label: RichTextLabel
var text_ghost: RichTextLabel  # Sanity
var box: PanelContainer
var _box_text_holder: VBoxContainer
var _fps_acc := 0.0
var _box_texture: TextureRect
var _name_plate: PanelContainer  # Name
var _name_row: HBoxContainer  # Name
var choice_box: VBoxContainer
var continue_hint: Label
var top_bar: HBoxContainer
var status_strip: HBoxContainer
var sanity_bar: ProgressBar

var _typing := false
var _full_text := ""
var _shown := 0
var _type_acc := 0.0
var _cur_who := ""
var _auto := false
var _skip := false
var _fast_skipping := false
var _auto_timer := 0.0
var _blocked := false  # FX
var _pending_wait := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_connect_engine()
	set_process(true)
	set_process_unhandled_input(true)

func begin(node_id: String) -> void:
	StoryEngine.start(node_id)

# Save/Load
# Save/Load
# Background
func restore_scene() -> void:
	if is_instance_valid(bg):
		bg.set_scene(GameState.scene_bg, GameState.scene_variant)
		bg.blood_amount = 0.8 if GameState.scene_variant == "blood" else 0.0
		bg.wet = 1.0 if GameState.scene_variant == "rain" else 0.0
	for k in actors.keys():
		actors[k]["node"].queue_free()
	actors.clear()
	for a in GameState.scene_actors:
		var d: Dictionary = a
		_on_actor("show", String(d.get("who", "")),
			String(d.get("emo", "normal")), String(d.get("pos", "center")))

# UI
func _build() -> void:
	world = Control.new()
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world)

	bg = BGLayerS.new()
	world.add_child(bg)

	actor_root = Control.new()
	actor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	actor_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(actor_root)
	# Sprite
	resized.connect(_layout_actors)

	fx = EffectsLayerS.new()
	fx.shake_offset.connect(func(o):
		var extra := sanity_fx.shudder_offset() if is_instance_valid(sanity_fx) else Vector2.ZERO
		world.position = o + extra
	)
	add_child(fx)

	sanity_fx = SanityFXS.new()
	add_child(sanity_fx)

	gore = GoreOverlayS.new()
	add_child(gore)

	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(ui_root)

	# Text

	# Time

	# State

	var click := Control.new()
	click.set_anchors_preset(Control.PRESET_FULL_RECT)
	click.mouse_filter = Control.MOUSE_FILTER_STOP
	click.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_on_screen_tap()
				click.accept_event()
		elif e is InputEventScreenTouch:
			var st := e as InputEventScreenTouch
			if st.pressed:
				_on_screen_tap()
				click.accept_event()
	)
	ui_root.add_child(click)

	_build_top_bar()
	_build_text_box()
	_build_choice_area()

func _build_top_bar() -> void:
	var inset := SafeArea.get_safe_insets()
	var wrap := PanelContainer.new()
	wrap.set_anchors_preset(Control.PRESET_TOP_WIDE)
	wrap.offset_left = inset.x
	wrap.offset_right = -inset.z
	wrap.offset_top = 0

	wrap.offset_bottom = 68 + inset.y
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.086, 0.102, 0.133, 0.88)   # VNShell BG 88%
	sb.border_color = Color(0.169, 0.2, 0.271, 0.6)
	sb.border_width_bottom = 1
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	wrap.add_theme_stylebox_override("panel", sb)
	ui_root.add_child(wrap)

	var bar_tex := UITex.make_layer("topbar", 0.5)
	if bar_tex != null:
		bar_tex.set_anchors_preset(Control.PRESET_TOP_WIDE)
		bar_tex.offset_top = 0
		bar_tex.offset_bottom = 68
		ui_root.add_child(bar_tex)
		ui_root.move_child(bar_tex, wrap.get_index())

	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 6)
	wrap.add_child(top_bar)

	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 19)
	time_label.add_theme_color_override("font_color", Color(0.91, 0.918, 0.929))
	time_label.custom_minimum_size.x = 190
	top_bar.add_child(time_label)

	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 18)
	fps_label.add_theme_color_override("font_color", Color(0.55, 0.75, 0.60))
	fps_label.custom_minimum_size.x = 74
	fps_label.visible = bool(SaveSystem.settings.get("show_fps", false))
	top_bar.add_child(fps_label)
	_refresh_time()
	GameState.time_changed.connect(_on_time_changed)

	var vsep := ColorRect.new()
	vsep.custom_minimum_size = Vector2(1, 22)
	vsep.color = Color(0.169, 0.2, 0.271, 0.5)
	top_bar.add_child(vsep)

	status_strip = HBoxContainer.new()
	status_strip.add_theme_constant_override("separation", 14)
	status_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(status_strip)
	_refresh_status()
	GameState.var_changed.connect(_on_var_changed)

	for spec in [
		["自动", "_toggle_auto"], ["快进", "_toggle_skip"], ["跳选", "_start_skip_to_choice"],
		["回想", "_open_history"], ["线索", "_open_clues"], ["状态", "_open_status"],
		["成就", "_open_achievements"],
		["存档", "_open_saves"], ["≡", "_open_menu"],
	]:
		var b := Button.new()
		b.text = String(spec[0])
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 21)

		b.custom_minimum_size = Vector2(64, TOUCH_MIN)
		var s2 := StyleBoxFlat.new()
		s2.bg_color = Color(0.129, 0.153, 0.204, 0.92)
		s2.border_color = Color(0.169, 0.2, 0.271, 0.5)
		s2.set_border_width_all(1)
		s2.set_corner_radius_all(3)
		s2.content_margin_left = 14
		s2.content_margin_right = 14
		s2.content_margin_top = 8
		s2.content_margin_bottom = 8
		b.add_theme_stylebox_override("normal", s2)
		b.pressed.connect(Callable(self, String(spec[1])))
		top_bar.add_child(b)
		if spec[0] == "自动":
			b.set_meta("role", "auto")
		if spec[0] == "快进":
			b.set_meta("role", "skip")

func _on_time_changed(_day: int, _minute: int) -> void:
	_refresh_time()

func _on_var_changed(_key: String, _old: int, _new: int) -> void:
	_refresh_status()

func _refresh_time() -> void:
	if time_label == null:
		return
	time_label.text = GameState.time_display()

	var h := GameState.story_minute / 60
	if h >= 22 or h < 5:
		time_label.add_theme_color_override("font_color", Color(0.55, 0.7, 0.9))
	elif h < 8:
		time_label.add_theme_color_override("font_color", Color(0.7, 0.76, 0.85))
	else:
		time_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.62))

func _refresh_status() -> void:
	# Stats
	# Stats
	if status_strip.get_child_count() != Cfg.NUM_VISIBLE.size():
		for c in status_strip.get_children():
			c.queue_free()
		for key in Cfg.NUM_VISIBLE:
			var g: StatusGauge = StatusGaugeS.new()
			g.key = String(key)
			g.label_text = String(Cfg.NUM_LABEL.get(key, key))
			status_strip.add_child(g)
	var i := 0
	for key in Cfg.NUM_VISIBLE:
		var node := status_strip.get_child(i) as StatusGauge
		i += 1
		if node == null:
			continue
		var rng: Array = Cfg.NUM_RANGE.get(key, [0, 100])
		node.set_value(GameState.get_num(key), int(rng[1]))
	_apply_state_theme()

# UI
# Text
# Name
# Truth
func _apply_state_theme() -> void:
	var san := float(GameState.get_num("sanity"))
	var san_max: float = float((Cfg.NUM_RANGE.get("sanity", [0, 100]) as Array)[1])
	var sev := clampf((san_max * 0.8 - san) / (san_max * 0.8), 0.0, 1.0)

	if is_instance_valid(box):
		var sb := box.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:

			sb.border_color = Color(0.48, 0.44, 0.40, 0.55).lerp(
				Color(0.72, 0.24, 0.22, 0.85), sev)
			sb.set_border_width_all(1 + int(round(sev * 1.5)))
	if is_instance_valid(text_label):
		# Sanity
		text_label.modulate = Color(1, 1, 1).lerp(Color(0.86, 0.82, 0.82), sev * 0.8)

	var focus := float(GameState.get_num("shenhe_focus"))
	var focus_max: float = float((Cfg.NUM_RANGE.get("shenhe_focus", [0, 60]) as Array)[1])
	var fr := clampf(focus / focus_max, 0.0, 1.0)
	if is_instance_valid(name_label):
		name_label.add_theme_color_override("font_color",
			Color(0.84, 0.78, 0.62).lerp(Color(0.92, 0.42, 0.38), fr * 0.75))

# Sprite
# Sanity

func _apply_box_texture() -> void:
	_box_texture = UITex.make_layer("dialogue_panel", 1.0)
	if _box_texture == null:
		return
	_box_texture.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box_texture.offset_left = box.offset_left
	_box_texture.offset_right = box.offset_right
	_box_texture.offset_top = box.offset_top
	_box_texture.offset_bottom = box.offset_bottom
	ui_root.add_child(_box_texture)
	ui_root.move_child(_box_texture, box.get_index())

	var sb := box.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		sb.bg_color = Color(0.129, 0.153, 0.204, 0.55)

func _build_text_box() -> void:
	var inset := SafeArea.get_safe_insets()
	box = PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 24 + inset.x
	box.offset_right = -24 - inset.z
	box.offset_top = -252
	box.offset_bottom = -20 - inset.w
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.086, 0.102, 0.133, 0.985)  # VNShell BG
	sb.border_color = Color(0.169, 0.2, 0.271, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 18
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 12
	box.add_theme_stylebox_override("panel", sb)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(box)

	# Sanity

	_apply_box_texture()

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	box.add_child(v)
	_box_text_holder = v

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", _dialogue_font_size() - 3)
	name_label.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	# Name

	var plate_sb := UITex.style_box("name_plate", Color(1, 1, 1, 0.9), 10)
	if plate_sb != null:
		plate_sb.content_margin_left = 16
		plate_sb.content_margin_right = 20
		plate_sb.content_margin_top = 2
		plate_sb.content_margin_bottom = 3
		_name_plate = PanelContainer.new()
		_name_plate.add_theme_stylebox_override("panel", plate_sb)
		_name_plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_name_plate.add_child(name_label)
		var plate_row := HBoxContainer.new()
		plate_row.add_child(_name_plate)
		v.add_child(plate_row)
		_name_row = plate_row
	else:
		v.add_child(name_label)

	# Sanity
	# Text
	var text_stack := Control.new()
	text_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(text_stack)

	text_ghost = RichTextLabel.new()
	text_ghost.bbcode_enabled = true
	text_ghost.fit_content = false
	text_ghost.scroll_active = false
	text_ghost.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_ghost.add_theme_font_size_override("normal_font_size", _dialogue_font_size())
	text_ghost.add_theme_constant_override("line_separation", 10)
	text_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_ghost.visible = false
	text_stack.add_child(text_ghost)

	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = false
	text_label.scroll_active = false
	text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_label.add_theme_font_size_override("normal_font_size", _dialogue_font_size())
	text_label.add_theme_constant_override("line_separation", 10)
	text_stack.add_child(text_label)

	continue_hint = Label.new()
	continue_hint.text = "▼"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.add_theme_font_size_override("font_size", 20)
	continue_hint.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0, 0.8))
	v.add_child(continue_hint)

func _build_choice_area() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -70
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(center)
	choice_box = VBoxContainer.new()
	# Choices
	choice_box.add_theme_constant_override("separation", 16)
	choice_box.custom_minimum_size.x = 720
	center.add_child(choice_box)

# Engine
func _connect_engine() -> void:
	StoryEngine.line_ready.connect(_on_line)
	StoryEngine.choices_ready.connect(_on_choices)
	StoryEngine.scene_requested.connect(_on_scene)
	StoryEngine.actor_requested.connect(_on_actor)
	StoryEngine.effect_requested.connect(_on_effect)
	StoryEngine.overlay_requested.connect(_on_overlay)
	StoryEngine.chapter_started.connect(_on_chapter)
	StoryEngine.story_finished.connect(_on_story_done)
	# Achievements（v1.4.0）：解锁时右上角 Toast 提示
	# 稳定性（v1.4.1）：必须用命名方法连接——lambda 连接不会随节点销毁自动断开，
	# 旧界面的 lambda 被触发时会访问已释放实例，在 Android 上直接闪退。
	Ach.unlocked.connect(_on_achievement_unlocked)

func _on_story_done(e: String) -> void:
	finished.emit(e)

func _on_achievement_unlocked(id: String) -> void:
	var toast := OW.toast("成就达成　%s" % Ach.name_of(id))
	ui_root.add_child(toast)
	AudioDirector.play_sfx("sfx_unlock", 0.5)

func _on_scene(kind: String, value: String, extra: String) -> void:
	if kind == "bg":
		bg.set_scene(value, extra)
		bg.blood_amount = 0.0
		if extra == "blood":
			bg.blood_amount = 0.8
		bg.wet = 1.0 if extra == "rain" else 0.0

func _on_actor(kind: String, who: String, emo: String, pos: String) -> void:
	match kind:
		"show":
			var a: ActorSprite
			if actors.has(who):
				a = actors[who]["node"]
			else:
				a = ActorSpriteS.new()
				a.who = who
				actor_root.add_child(a)
				actors[who] = {"node": a, "pos": pos}
			a.setup(who, emo if emo != "" else "normal")
			actors[who]["pos"] = pos

			a.glitch = 0.0
			a.wounded = 0.0
			if who == "shenhe":
				a.glitch = 0.35
			if who == "liangye" and GameState.get_state("liangye_state") == "half_assimilated":
				a.glitch = 0.5
				a.wounded = 0.35
			if who == "liangye" and GameState.get_flag("flag_liangye_bleeding"):
				a.wounded = 0.8
			if who == "oldqin" and GameState.get_state("oldqin_state") == "burned":
				a.wounded = 1.0
			_layout_actors()
		"hide":
			if actors.has(who):
				actors[who]["node"].queue_free()
				actors.erase(who)
				_layout_actors()
		"clear":
			for k in actors.keys():
				actors[k]["node"].queue_free()
			actors.clear()

func _layout_actors() -> void:
	var keys := actors.keys()
	var slots := {"left": 0.22, "center": 0.5, "right": 0.78, "farleft": 0.10, "farright": 0.90}
	var i := 0
	for k in keys:
		var d: Dictionary = actors[k]
		var a: ActorSprite = d["node"]
		var pos := String(d["pos"])
		var fx_ratio: float = float(slots.get(pos, 0.5))
		if not slots.has(pos):
			fx_ratio = 0.5 + (i - (keys.size() - 1) * 0.5) * 0.26

		# Text
		var box_top: float = size.y - 272.0
		if is_instance_valid(box) and box.size.y > 1.0:
			box_top = box.position.y
		var top_bar_h := 56.0
		var ratio: float = ActorSpriteS.UPPER_RATIO
		var waist_y: float = box_top + 40.0

		var visible_h: float = waist_y - top_bar_h
		var scale := visible_h / (768.0 * ratio)
		# Sprite
		var max_w: float = size.x * (0.52 if keys.size() > 1 else 0.68)
		if 768.0 * scale > max_w:
			scale = max_w / 768.0
		var w := 768.0 * scale
		var h := 768.0 * ratio * scale
		a.size = Vector2(w, h)

		var top_y: float = waist_y - h

		var x: float = clampf(size.x * fx_ratio - w * 0.5, -w * 0.08,
			maxf(0.0, size.x - w * 0.92))
		a.position = Vector2(x, top_y)
		i += 1

func _on_effect(name: String, power: float) -> void:
	# Haptics（手机震动反馈：惊吓演出 + 密码错误）
	if name in ["sting", "bigshake", "bloodburst"] \
			and bool(SaveSystem.settings.get("haptics", true)) \
			and OS.get_name() in ["Android", "iOS"]:
		var ms := 320 if name == "sting" else (200 if name == "bigshake" else 150)
		Input.vibrate_handheld(clampi(int(ms * power), 50, 600))
	# UI
	match name:
		"handprint", "bloodhand":
			gore.add_mark("handprint", power)
			AudioDirector.play_sfx("sfx_flesh", 0.5)
			return
		"bloodsmear":
			gore.add_mark("smear", power)
			return
		"blooddrip":
			gore.add_mark("drip", power)
			AudioDirector.play_sfx("sfx_water", 0.4)
			return
		"bloodedge":
			gore.add_mark("edge", power)
			return
		"bloodcrack":
			gore.add_mark("crack", power)
			AudioDirector.play_sfx("sfx_glass", 0.5)
			return
		"cleanblood":
			gore.clear_marks()
			return
	fx.play(name, power)
	if name == "flicker":
		bg.flicker = 1.0
		create_tween().tween_property(bg, "flicker", 0.0, 1.2)
	elif name == "blood" or name == "bloodburst":
		bg.blood_amount = minf(1.0, bg.blood_amount + 0.35 * power)

func _on_chapter(num: int, title: String) -> void:
	_blocked = true
	var ov := OW.chapter_card(num, title)
	add_child(ov)
	ov.tree_exited.connect(_unblock)

func _on_overlay(kind: String, payload: Dictionary) -> void:
	match kind:
		"title":
			_blocked = true
			var ov := OW.title_card(String(payload.get("text", "")))
			add_child(ov)
			ov.tree_exited.connect(_unblock)
		"note":
			_blocked = true
			var ov2 := OW.note_card(String(payload.get("text", "")))
			add_child(ov2)
			ov2.tree_exited.connect(_unblock)
		"roster":
			_blocked = true
			var ov3 := OW.roster_card()
			add_child(ov3)
			ov3.tree_exited.connect(_unblock)
		"padlock":
			_blocked = true
			var pl := PadlockPanelS.new()
			pl.setup(String(payload.get("code", "")), String(payload.get("hint", "")))
			add_child(pl)
			pl.solved.connect(func():
				_blocked = false
				StoryEngine.padlock_done(true)
			)
			pl.failed.connect(func():
				_blocked = false
				StoryEngine.padlock_done(false)
			)
		"item":
			var t := OW.toast("获得道具：" + GameState.item_name(String(payload.get("id", ""))))
			add_child(t)
			AudioDirector.play_sfx("sfx_page", 0.7)
		"clue":
			var cid := String(payload.get("id", ""))
			var cname := String(GameState.CLUES.get(cid, {}).get("name", cid))
			var t2 := OW.toast("线索：" + cname)
			add_child(t2)
			AudioDirector.play_sfx("sfx_write", 0.8)
		"wait":
			_blocked = true
			_pending_wait = float(payload.get("time", 1.0))

func _unblock() -> void:
	_blocked = false
	StoryEngine.advance()

# Name
func _speaker_display_name(who: String) -> String:
	if who in ["me", "linzhou", "linday"]:
		return GameState.player_name
	return String(Cfg.CHARACTERS.get(who, {}).get("name", who))

# Text
func _on_line(line: Dictionary) -> void:
	_clear_choices()
	_cur_who = String(line.get("who", ""))
	var style := String(line.get("style", "line"))
	var raw := String(line.get("text", ""))

	if _cur_who == "":
		name_label.visible = false
		if is_instance_valid(_name_row):
			_name_row.visible = false
	else:
		name_label.visible = true
		if is_instance_valid(_name_row):
			_name_row.visible = true
		name_label.text = _speaker_display_name(_cur_who)
		name_label.add_theme_color_override("font_color", Cfg.CHARACTERS.get(_cur_who, {}).get("color", Color.WHITE))

	for k in actors:
		actors[k]["node"].active = (k == _cur_who)

	var prefix := ""
	var suffix := ""
	match style:
		"narration":
			prefix = "[color=#b9b6ae]"
			suffix = "[/color]"
		"note":
			prefix = "[color=#c9a24a][i]"
			suffix = "[/i][/color]"
		_:
			prefix = "[color=#e6e3dc]"
			suffix = "[/color]"
	_full_text = prefix + raw + suffix
	text_label.text = _full_text
	text_label.visible_characters = 0
	# Text
	if is_instance_valid(text_ghost):
		text_ghost.text = _full_text
		text_ghost.visible_characters = 0
	_shown = 0
	_typing = true
	_type_acc = 0.0
	continue_hint.visible = false
	if _cur_who != "":
		AudioDirector.play_sfx("sfx_click", 0.10)

# Text
# Text
# UI

# Sanity
# Sanity

# Story

func _update_text_ghost(_delta: float) -> void:
	if not is_instance_valid(text_ghost):
		return
	var san := float(GameState.get_num("sanity"))
	if san >= SANITY_GHOST_AT:
		if text_ghost.visible:
			text_ghost.visible = false
		return

	var g := clampf((SANITY_GHOST_AT - san) / SANITY_GHOST_AT, 0.0, 1.0)
	text_ghost.visible = true
	text_ghost.visible_characters = text_label.visible_characters

	var amp := 1.5 + g * 7.0
	var jitter := 0.0
	if g > 0.5 and bool(SaveSystem.settings.get("screen_shake", true)):
		jitter = (g - 0.5) * 4.0
	var t := Time.get_ticks_msec() / 1000.0
	var gx := -amp + sin(t * 2.3) * jitter
	var gy := amp * 0.45 + cos(t * 3.1) * jitter * 0.6
	text_ghost.position = Vector2(gx, gy)
	# Sanity
	text_ghost.modulate = Color(0.95, 0.42, 0.40, 0.16 + g * 0.30)

func _process(delta: float) -> void:
	_update_text_ghost(delta)
	if is_instance_valid(fps_label):
		var want := bool(SaveSystem.settings.get("show_fps", false))
		if fps_label.visible != want:
			fps_label.visible = want
		if want:
			# Text
			_fps_acc += delta
			if _fps_acc >= 0.25:
				_fps_acc = 0.0
				fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	if _pending_wait > 0.0:
		_pending_wait -= delta
		if _pending_wait <= 0.0:
			_pending_wait = 0.0
			_unblock()
		return
	if _typing:
		var spd := SaveSystem.text_delay()
		if _skip:
			spd = 0.001
		_type_acc += delta
		while _type_acc >= spd and _typing:
			_type_acc -= spd
			_shown += 1
			text_label.visible_characters = _shown
			if _shown % 3 == 0 and _cur_who != "" and not _skip:
				AudioDirector.play_blip(_cur_who)
			if _shown >= text_label.get_total_character_count():
				_typing = false
				text_label.visible_characters = -1
				continue_hint.visible = true
				_auto_timer = 0.0
	elif (_auto or _skip) and not _blocked and choice_box.get_child_count() == 0:
		_auto_timer += delta
		var need := 0.05 if _skip else float(SaveSystem.settings.get("auto_speed", 1.6))
		if _auto_timer >= need:
			_auto_timer = 0.0
			_advance()
	# Breathe
	if continue_hint.visible:
		continue_hint.modulate.a = 0.4 + 0.6 * absf(sin(Time.get_ticks_msec() / 500.0))
	_layout_actors_if_needed()

var _last_size := Vector2.ZERO
func _layout_actors_if_needed() -> void:
	if size != _last_size:
		_last_size = size
		_layout_actors()

# Choices
func _on_choices(list: Array) -> void:
	_clear_choices()
	continue_hint.visible = false
	AudioDirector.play_sfx("sfx_chair", 0.35)
	var idx := 0
	for c in list:
		var ch: Dictionary = c
		var b := Button.new()
		var txt := String(ch["text"])
		if not bool(ch.get("enabled", true)):
			txt += "  〔%s〕" % String(ch.get("hint", "条件未满足"))
		b.text = txt
		b.disabled = not bool(ch.get("enabled", true))
		b.focus_mode = Control.FOCUS_NONE
		# Text
		b.custom_minimum_size = Vector2(720, TOUCH_MIN + 8)
		b.add_theme_font_size_override("font_size", 27)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.clip_text = false
		b.pressed.connect(func():
			AudioDirector.play_sfx("sfx_click", 0.8)
			_confirm_choice(b, ch)
		)
		choice_box.add_child(b)
		b.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.05 * idx)
		tw.tween_property(b, "modulate:a", 1.0, 0.22)
		idx += 1

func _confirm_choice(btn: Button, ch: Dictionary) -> void:
	_blocked = true
	for c in choice_box.get_children():
		var other := c as Button
		if other == null:
			continue
		other.disabled = true
		if other != btn:
			var tw_o := create_tween()
			tw_o.tween_property(other, "modulate:a", 0.18, 0.16)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.129, 0.153, 0.204, 0.95)
	sb.border_color = Color(0.29, 0.55, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_color_override("font_disabled_color", Color(0.91, 0.918, 0.929))
	btn.pivot_offset = btn.size * 0.5
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.035, 1.035), 0.12)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.10)

	_flash_choice_effects(ch)

	var major := _is_major_choice(ch)
	await get_tree().create_timer(0.42 if major else 0.26).timeout
	_clear_choices()
	_blocked = false

	if major:
		_run_transition(func(): StoryEngine.pick_choice(ch))
	else:
		StoryEngine.pick_choice(ch)

# Text
func _flash_choice_effects(ch: Dictionary) -> void:
	var msgs: Array[String] = []
	for e in ch.get("effects", []):
		var ef: Dictionary = e
		var cmd := String(ef.get("cmd", ""))
		var args: Array = ef.get("args", [])
		if cmd == "set" and args.size() >= 2:
			var key := String(args[0])
			if not Cfg.NUM_VISIBLE.has(key):
				continue
			var label := String(Cfg.NUM_LABEL.get(key, key))
			msgs.append("%s %s" % [label, String(args[1])])
		elif cmd == "clue":
			msgs.append("获得线索")
		elif cmd == "item":
			msgs.append("获得道具")
	if msgs.is_empty():
		return
	var lbl := Label.new()
	lbl.text = "　".join(msgs)
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.62, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	lbl.position = Vector2(size.x * 0.5 - 200, size.y - 300)
	lbl.custom_minimum_size.x = 400
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 34.0, 0.9)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.chain().tween_callback(lbl.queue_free)

# Endings
func _is_major_choice(ch: Dictionary) -> bool:
	var weight := 0
	for e in ch.get("effects", []):
		var ef: Dictionary = e
		var cmd := String(ef.get("cmd", ""))
		if cmd == "flag" or cmd == "item":
			weight += 3
		elif cmd == "clue":
			weight += 2
		elif cmd == "set":
			var args: Array = ef.get("args", [])
			if args.size() >= 2:
				var v := String(args[1]).lstrip("+-=")
				if v.is_valid_int() and int(v) >= 3:
					weight += 2
	return weight >= 4

func _run_transition(next: Callable) -> void:
	var ov := LoadingOverlayS.new()
	add_child(ov)
	var keep: Array[String] = []
	if is_instance_valid(bg):
		var cur := bg.current_texture_path()
		if cur != "":
			keep.append(cur)
	ov.begin(GameState.current_chapter, keep)
	ov.finished.connect(func():
		if next.is_valid():
			next.call()
	)

func _clear_choices() -> void:
	for c in choice_box.get_children():
		c.queue_free()

func _on_screen_tap() -> void:
	if _fast_skipping:
		return
	if choice_box.get_child_count() > 0:
		return
	_advance()

func _advance() -> void:
	if _blocked:
		return
	if _typing:
		_typing = false
		text_label.visible_characters = -1
		continue_hint.visible = true
		return
	_auto_timer = 0.0
	StoryEngine.advance()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_SPACE, KEY_ENTER:
				_on_screen_tap()
			KEY_ESCAPE:
				_open_menu()
			KEY_A:
				_toggle_auto()
			KEY_S:
				_toggle_skip()
			KEY_H:
				_open_history()
			KEY_TAB:
				_open_clues()

func _toggle_auto() -> void:
	_auto = not _auto
	_skip = false
	_mark_toggle()

func _toggle_skip() -> void:
	_skip = not _skip
	_auto = false
	_mark_toggle()


# 快进到下一选项：引擎 fast_mode 逐帧推进，遇选项/密码锁/结局自动停止
func _start_skip_to_choice() -> void:
	if _fast_skipping or StoryEngine.waiting_choice or not StoryEngine.running:
		return
	_fast_skipping = true
	_skip = false
	_auto = false
	_mark_toggle()
	text_label.text = ""
	text_ghost.text = ""
	name_label.visible = false
	continue_hint.visible = false
	StoryEngine.fast_mode = true
	_fast_step()


func _fast_step() -> void:
	if not _fast_skipping or not is_inside_tree():
		return
	if _blocked:
		call_deferred("_fast_step")
		return
	if StoryEngine.fast_mode and StoryEngine.running:
		StoryEngine.advance()
		call_deferred("_fast_step")
		return
	_finish_fast_skip()


func _finish_fast_skip() -> void:
	if not _fast_skipping:
		return
	_fast_skipping = false
	StoryEngine.fast_mode = false
	# 若快进停在无选项的节点尾部，给玩家明确反馈
	if not StoryEngine.waiting_choice and StoryEngine.running:
		var t := OW.toast("已到可继续阅读的位置")
		add_child(t)


func _dialogue_font_size() -> int:
	return [26, 29, 33][clampi(int(SaveSystem.settings.get("text_size", 1)), 0, 2)]


func _apply_text_size() -> void:
	var sz := _dialogue_font_size()
	text_label.add_theme_font_size_override("normal_font_size", sz)
	text_ghost.add_theme_font_size_override("normal_font_size", sz)
	name_label.add_theme_font_size_override("font_size", sz - 3)

func _mark_toggle() -> void:
	for b in top_bar.get_children():
		if b is Button and b.has_meta("role"):
			var r := String(b.get_meta("role"))
			var on := (_auto and r == "auto") or (_skip and r == "skip")
			b.modulate = Color(0.6, 0.75, 1.0) if on else Color.WHITE

func _open_history() -> void:
	_push_panel(MP.history_panel())

func _open_clues() -> void:
	_push_panel(MP.clue_panel())

func _open_status() -> void:
	_push_panel(MP.status_panel())

func _open_achievements() -> void:
	_push_panel(MP.achievement_panel())

func _open_saves() -> void:
	var p := MP.save_panel(true)
	p.set_meta("on_load", func(idx: int):
		var d := SaveSystem.read_slot(idx)
		if d.is_empty():
			return
		GameState.from_dict(d)
		_refresh_status()
		var n := String(d.get("node", "prologue"))
		StoryEngine.start(n if StoryEngine.has_story_node(n) else "prologue")
		restore_scene()
	)
	_push_panel(p)

func _open_menu() -> void:
	var p := MP.system_panel()
	p.set_meta("on_quit", func():
		SaveSystem.autosave()
		quit_to_title.emit()
	)
	p.set_meta("on_settings_saved", func():
		_apply_text_size()
	)
	_push_panel(p)

func _push_panel(p: Control) -> void:
	_blocked = true
	add_child(p)
	p.tree_exited.connect(func(): _blocked = false)
