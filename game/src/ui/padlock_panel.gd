extends Control
class_name PadlockPanel
# Password lock
# Password lock

signal solved()
signal failed()

var _code := ""
var _display: Label
var _input := ""

const KEY_ROWS := [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["⌫", "0", "确认"]]

func setup(code: String, hint: String) -> void:
	_code = code
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.043, 0.051, 0.067, 0.88)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = "电子密码锁"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	v.add_child(title)

	if hint != "":
		var h := Label.new()
		h.text = hint
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_theme_font_size_override("font_size", 21)
		h.add_theme_color_override("font_color", Color(0.545, 0.576, 0.639))
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(h)

	var win := PanelContainer.new()
	win.custom_minimum_size = Vector2(300, 72)
	var win_sb := StyleBoxFlat.new()
	win_sb.bg_color = Color(0.03, 0.04, 0.06)
	win_sb.border_color = Color(0.29, 0.55, 1.0, 0.9)
	win_sb.set_border_width_all(2)
	win_sb.set_corner_radius_all(6)
	win.add_theme_stylebox_override("panel", win_sb)
	_display = Label.new()
	_display.text = "· · · ·"
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_display.add_theme_font_size_override("font_size", 40)
	_display.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	win.add_child(_display)
	v.add_child(win)

	# Theme
	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	v.add_child(grid)
	var key_norm := UITex.style_box("keypad_button", Color(1, 1, 1, 0.95), 10)
	var key_hover: StyleBox = null
	var key_press: StyleBox = null
	if key_norm != null:
		key_hover = UITex.style_box("keypad_button", Color(1.35, 1.1, 0.95, 1.0), 10)
		key_press = UITex.style_box("keypad_button", Color(1.6, 0.7, 0.5, 1.0), 10)
	for row in KEY_ROWS:
		var hrow := HBoxContainer.new()
		hrow.alignment = BoxContainer.ALIGNMENT_CENTER
		hrow.add_theme_constant_override("separation", 10)
		grid.add_child(hrow)
		for k in row:
			var b := Button.new()
			b.text = k
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(120, 64)
			b.add_theme_font_size_override("font_size", 28)
			if key_norm != null:
				b.add_theme_stylebox_override("normal", key_norm)
				b.add_theme_stylebox_override("hover", key_hover)
				b.add_theme_stylebox_override("pressed", key_press)
				b.add_theme_stylebox_override("disabled", key_norm)
			b.pressed.connect(_on_key.bind(String(k)))
			hrow.add_child(b)

	var cancel := Button.new()
	cancel.text = "放弃"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size = Vector2(160, 48)
	cancel.add_theme_font_size_override("font_size", 22)
	cancel.pressed.connect(func():
		AudioDirector.play_sfx("sfx_click", 0.8)
		failed.emit()
		queue_free()
	)
	v.add_child(cancel)

func _on_key(k: String) -> void:
	AudioDirector.play_sfx("sfx_click", 0.8)
	match k:
		"⌫":
			if _input.length() > 0:
				_input = _input.substr(0, _input.length() - 1)
			_refresh()
		"确认":
			_submit()
		_:
			if _input.length() < 4:
				_input += k
				_refresh()

func _refresh() -> void:
	var s := ""
	for i in 4:
		s += (_input[i] if i < _input.length() else "·") + " "
	_display.text = s.rstrip(" ")

func _submit() -> void:
	if _input == _code:
		_display.add_theme_color_override("font_color", Color(0.29, 0.85, 0.57))
		_display.text = _input[0] + " " + _input[1] + " " + _input[2] + " " + _input[3]
		solved.emit()
		queue_free()
	else:
		# Story + haptics
		if bool(SaveSystem.settings.get("haptics", true)) and OS.get_name() in ["Android", "iOS"]:
			Input.vibrate_handheld(80)
		_display.add_theme_color_override("font_color", Color(1.0, 0.478, 0.612))
		var base := _display.position
		var tw := create_tween()
		tw.tween_property(_display, "position:x", base.x + 9.0, 0.04)
		tw.tween_property(_display, "position:x", base.x - 8.0, 0.06)
		tw.tween_property(_display, "position:x", base.x + 5.0, 0.05)
		tw.tween_property(_display, "position:x", base.x, 0.05)
		tw.tween_callback(func():
			_input = ""
			_display.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
			_refresh()
			failed.emit()
			queue_free()
		)
