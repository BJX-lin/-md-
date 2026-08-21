extends Control
# UI

signal start_new()
signal continue_game()
signal load_slot(i: int)
signal start_extra()

const BGLayerS := preload("res://src/art/bg_layer.gd")
const MenuPanelsS := preload("res://src/ui/menu_panels.gd")
const NameEntryS := preload("res://src/ui/name_entry.gd")

var _t := 0.0
var subtitle_label: Label
var emblem: TextureRect

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg: BGLayer = BGLayerS.new()
	bg.set_scene("schoolyard", "dusk")
	add_child(bg)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.01, 0.02, 0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# Title

	emblem = UITex.make_layer("title_emblem", 0.32,
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	if emblem != null:
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(emblem)
		_layout_emblem()
		resized.connect(_layout_emblem)

	# Title

	# Title

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 12
	add_child(scroll)

	var page := MarginContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("margin_left", 56)
	page.add_theme_constant_override("margin_right", 56)
	page.add_theme_constant_override("margin_top", 40)
	page.add_theme_constant_override("margin_bottom", 64)
	scroll.add_child(page)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 48)
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(cols)

	# Title
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.add_theme_constant_override("separation", 8)
	cols.add_child(left)

	var title := Label.new()
	title.text = Cfg.GAME_TITLE
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color(0.91, 0.918, 0.929))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	left.add_child(title)

	# Title
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(140, 2)
	rule.color = Color(0.29, 0.55, 1.0, 0.85)
	left.add_child(rule)

	subtitle_label = Label.new()
	subtitle_label.text = Cfg.GAME_SUBTITLE
	subtitle_label.add_theme_font_size_override("font_size", 21)
	subtitle_label.add_theme_color_override("font_color", Color(0.545, 0.576, 0.639))
	left.add_child(subtitle_label)

	var cycles := int(GameState.persistent.get("cycles", 0))
	if cycles > 0:
		var cy := Label.new()
		cy.text = "这是第 %d 次重排。" % (109 + cycles)
		cy.add_theme_font_size_override("font_size", 22)
		cy.add_theme_color_override("font_color", Color(1.0, 0.478, 0.612))
		left.add_child(cy)

	var right := VBoxContainer.new()
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", 10)
	cols.add_child(right)

	var has_save := SaveSystem.has_any_save()
	_add_btn(right, "继续（自动存档）", func(): continue_game.emit(), not has_save)
	_add_btn(right, "开始新游戏", func(): _confirm_new())
	# 番外《天晴》：达成真结局后解锁（v1.4.0）
	var endings: Dictionary = GameState.persistent.get("endings", {})
	if endings.has("ending_true_release"):
		_add_btn(right, "番外　《天晴》", func(): start_extra.emit())
	_add_btn(right, "读取存档", func():
		var p := MenuPanelsS.save_panel(false)
		p.set_meta("on_load", func(i): load_slot.emit(i))
		add_child(p))
	_add_btn(right, "结局与记录", func(): add_child(MenuPanelsS.gallery_panel()))
	_add_btn(right, "设置", func():
		var p := MenuPanelsS.system_panel()
		p.set_meta("on_quit", func(): pass)
		add_child(p))
	_add_btn(right, "BUG 反馈 / 交流群", func(): add_child(MenuPanelsS.feedback_panel()))
	if OS.get_name() != "Web":
		_add_btn(right, "退出", func(): get_tree().quit())

	var ver := Label.new()
	ver.text = "v%s　Godot 4.7.2 stable　含惊吓与血腥描写，建议佩戴耳机" % Cfg.VERSION
	ver.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ver.offset_top = -40
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 18)
	ver.add_theme_color_override("font_color", Color(0.545, 0.576, 0.639, 0.8))
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

	AudioDirector.play_bgm("bgm_title")
	AudioDirector.play_amb("amb_rain")
	set_process(true)

func _add_btn(v: VBoxContainer, text: String, cb: Callable, disabled := false) -> void:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.focus_mode = Control.FOCUS_NONE
	# Title
	b.custom_minimum_size = Vector2(420, 58)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func():
		AudioDirector.play_sfx("sfx_click", 0.8)
		cb.call()
	)
	v.add_child(b)

func _confirm_new() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.85)
	root.add_child(shade)
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	var l := Label.new()
	l.text = "内容提示\n本作包含：校园怪谈恐怖、突发惊吓演出、\n血腥与伤害描写、自杀/事故相关情节、压抑主题。\n可在设置中调整血腥程度、闪光与震动。\n\n开始新游戏？"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	v.add_child(l)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	var yes := Button.new()
	yes.text = "开始"
	yes.focus_mode = Control.FOCUS_NONE
	yes.custom_minimum_size = Vector2(160, 52)
	yes.pressed.connect(func():
		root.queue_free()
		_open_name_entry())
	h.add_child(yes)
	var no := Button.new()
	no.text = "返回"
	no.focus_mode = Control.FOCUS_NONE
	no.custom_minimum_size = Vector2(160, 52)
	no.pressed.connect(func(): root.queue_free())
	h.add_child(no)
	add_child(root)

func _layout_emblem() -> void:
	if emblem == null:
		return
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return
	var menu_cx := w - 56.0 - 210.0
	var disp_w := 768.0 * h / 1024.0

	disp_w = minf(disp_w, w - 112.0)
	var half := disp_w * 0.5
	emblem.anchor_left = clampf((menu_cx - half) / w, 0.0, 1.0)
	emblem.anchor_right = clampf((menu_cx + half) / w, 0.0, 1.0)
	emblem.anchor_top = 0.0
	emblem.anchor_bottom = 1.0
	emblem.offset_left = 0
	emblem.offset_right = 0
	emblem.offset_top = 0
	emblem.offset_bottom = 0

func _process(delta: float) -> void:
	_t += delta
	if subtitle_label:
		subtitle_label.modulate.a = 0.55 + 0.35 * sin(_t * 0.9)

# Name
# Name
func _open_name_entry() -> void:
	var ne := NameEntryS.new()
	ne.confirmed.connect(func(player_name: String):
		GameState.player_name = player_name
		start_new.emit()
	)
	add_child(ne)
