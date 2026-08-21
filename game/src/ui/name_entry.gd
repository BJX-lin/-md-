extends Control
class_name NameEntry
# UI
# Name
# Save/Load

signal confirmed(player_name: String)
signal cancelled()

const MAX_LEN := 6

# Name
const NAME_POOL: Array[String] = ["林昼", "许言", "陈渡", "沈默", "江晚", "陆离"]

var _edit: LineEdit

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	# UI
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.01, 0.015, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			AudioDirector.play_sfx("sfx_click", 0.8)
			cancelled.emit()
			queue_free()
	)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = "为你的角色命名"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	v.add_child(title)

	var tip := Label.new()
	tip.text = "名字会出现在对话、名册与存档中。\n最多 %d 个字，可以留空使用默认名。\n（主角：高二（3）班转学生）" % MAX_LEN
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 20)
	tip.add_theme_color_override("font_color", Color(0.66, 0.65, 0.61))
	v.add_child(tip)

	var edit_row := HBoxContainer.new()
	edit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	edit_row.add_theme_constant_override("separation", 12)
	v.add_child(edit_row)

	_edit = LineEdit.new()
	_edit.placeholder_text = GameState.player_name
	_edit.max_length = MAX_LEN
	_edit.custom_minimum_size = Vector2(300, 64)
	_edit.add_theme_font_size_override("font_size", 30)
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.text_submitted.connect(func(_t): _confirm())
	edit_row.add_child(_edit)

	var dice := Button.new()
	dice.text = "随机"
	dice.focus_mode = Control.FOCUS_NONE
	dice.custom_minimum_size = Vector2(110, 64)
	dice.pressed.connect(func():
		_edit.text = NAME_POOL[randi() % NAME_POOL.size()]
		_edit.grab_focus()
		AudioDirector.play_sfx("sfx_click", 0.8)
	)
	edit_row.add_child(dice)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 20)
	v.add_child(btns)

	var ok := Button.new()
	ok.text = "确认开始"
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(180, 56)
	ok.add_theme_font_size_override("font_size", 26)
	ok.pressed.connect(_confirm)
	btns.add_child(ok)

	var cancel := Button.new()
	cancel.text = "返回"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size = Vector2(140, 56)
	cancel.add_theme_font_size_override("font_size", 26)
	cancel.pressed.connect(func():
		AudioDirector.play_sfx("sfx_click", 0.8)
		cancelled.emit()
		queue_free()
	)
	btns.add_child(cancel)

	_edit.grab_focus()

func _confirm() -> void:
	var n := _edit.text.strip_edges()
	if n.is_empty():
		n = GameState.player_name
	AudioDirector.play_sfx("sfx_pickup", 0.8)
	confirmed.emit(n)
	queue_free()
