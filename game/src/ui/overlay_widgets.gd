extends RefCounted
class_name OverlayWidgets
# Chapters

static func _when_in_tree(n: Node, cb: Callable) -> void:

	if n.is_inside_tree():
		cb.call()
	else:
		n.tree_entered.connect(cb, CONNECT_ONE_SHOT)

static func _full(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

static func chapter_card(num: int, title: String) -> Control:
	var root := ColorRect.new()
	_full(root)
	root.color = Color(0.086, 0.102, 0.133, 1.0)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	root.add_child(v)

	var idx := Label.new()
	idx.text = "第 %s 章" % ("终" if num >= 5 else str(num))
	idx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	idx.add_theme_font_size_override("font_size", 30)
	idx.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	v.add_child(idx)

	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 62)
	t.add_theme_color_override("font_color", Color(0.91, 0.918, 0.929))
	v.add_child(t)

	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(320, 1)
	line.color = Color(0.169, 0.2, 0.271, 0.6)
	v.add_child(line)

	AudioDirector.play_sfx("sfx_bell", 0.5)
	root.modulate.a = 0.0
	_when_in_tree(root, func():
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 1.0, 0.9)
		tw.tween_interval(2.0)
		tw.tween_property(root, "modulate:a", 0.0, 1.0)
		tw.tween_callback(root.queue_free)
	)
	return root

static func title_card(text: String) -> Control:
	var root := Control.new()
	_full(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	_full(shade)
	shade.color = Color(0, 0, 0, 0.72)
	root.add_child(shade)

	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 900
	l.add_theme_font_size_override("font_size", 46)
	l.add_theme_color_override("font_color", Color(0.91, 0.918, 0.929))
	root.add_child(l)

	root.modulate.a = 0.0
	_when_in_tree(root, func():
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 1.0, 0.6)
		tw.tween_interval(1.9)
		tw.tween_property(root, "modulate:a", 0.0, 0.7)
		tw.tween_callback(root.queue_free)
	)
	return root

static func note_card(text: String) -> Control:

	var root := Control.new()
	_full(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	_full(shade)
	shade.color = Color(0, 0, 0, 0.78)
	root.add_child(shade)

	var paper := PanelContainer.new()
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	paper.grow_vertical = Control.GROW_DIRECTION_BOTH
	paper.custom_minimum_size = Vector2(820, 0)

	var note_sb := UITex.style_box("note_paper", Color(1, 1, 1, 1), 24)
	if note_sb != null:
		note_sb.content_margin_left = 42
		note_sb.content_margin_right = 42
		note_sb.content_margin_top = 34
		note_sb.content_margin_bottom = 34
		paper.add_theme_stylebox_override("panel", note_sb)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.129, 0.153, 0.204)
		sb.border_color = Color(0.29, 0.55, 1.0)
		sb.set_border_width_all(1)
		sb.content_margin_left = 42
		sb.content_margin_right = 42
		sb.content_margin_top = 34
		sb.content_margin_bottom = 34
		sb.shadow_color = Color(0, 0, 0, 0.7)
		sb.shadow_size = 20
		paper.add_theme_stylebox_override("panel", sb)
	root.add_child(paper)

	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(736, 0)
	rt.text = "[color=#20201c]" + text.replace("\\n", "\n") + "[/color]"
	rt.add_theme_font_size_override("normal_font_size", 30)
	rt.add_theme_constant_override("line_separation", 12)
	paper.add_child(rt)

	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	var e := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, e)
	btn.pressed.connect(func():
		AudioDirector.play_sfx("sfx_page", 0.8)
		root.queue_free()
	)
	root.add_child(btn)

	AudioDirector.play_sfx("sfx_page", 1.0)
	root.modulate.a = 0.0
	_when_in_tree(root, func():
		root.create_tween().tween_property(root, "modulate:a", 1.0, 0.35)
	)
	return root

static func roster_card() -> Control:
	# State
	var lines: Array[String] = []
	lines.append("高二（三）班  补录名单")
	lines.append("————————————————")
	lines.append("周叙　　%s" % _zhouxu_tag())
	lines.append("梁野　　%s" % _liangye_tag())
	lines.append("许清　　（记录）")
	lines.append("沈禾　　%s" % ("（被写回）" if GameState.get_flag("flag_name_written_back") else "（删除未完成）"))
	lines.append("林昼　　%s" % _player_tag())
	if GameState.get_flag("flag_saw_self_repeat"):
		lines.append("林昼　　（第%d次）" % (109 + int(GameState.persistent.get("cycles", 0))))
	lines.append("————————————————")
	lines.append("未到齐者，晚自习不下课。")

	var root := Control.new()
	_full(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	_full(shade)
	shade.color = Color(0, 0, 0, 0.85)
	root.add_child(shade)

	var paper := PanelContainer.new()
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	paper.grow_vertical = Control.GROW_DIRECTION_BOTH

	var roster_sb := UITex.style_box("note_paper", Color(0.94, 0.93, 0.90, 1), 24)
	if roster_sb != null:
		roster_sb.content_margin_left = 60
		roster_sb.content_margin_right = 60
		roster_sb.content_margin_top = 40
		roster_sb.content_margin_bottom = 40
		paper.add_theme_stylebox_override("panel", roster_sb)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.169, 0.2, 0.271)
		sb.border_color = Color(0.29, 0.55, 1.0)
		sb.set_border_width_all(2)
		sb.content_margin_left = 60
		sb.content_margin_right = 60
		sb.content_margin_top = 40
		sb.content_margin_bottom = 40
		paper.add_theme_stylebox_override("panel", sb)
	root.add_child(paper)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	paper.add_child(v)
	for i in lines.size():
		var l := Label.new()
		l.text = String(lines[i])
		l.add_theme_font_size_override("font_size", 30 if i == 0 else 27)
		var col := Color(0.13, 0.12, 0.11)
		if String(lines[i]).contains("删除未完成"):
			col = Color(0.55, 0.10, 0.09)
		elif String(lines[i]).contains("待定") or String(lines[i]).contains("可补"):
			col = Color(0.42, 0.26, 0.10)
		l.add_theme_color_override("font_color", col)
		v.add_child(l)
		l.modulate.a = 0.0
		var delay := 0.12 * i
		_when_in_tree(l, func():
			var tw := l.create_tween()
			tw.tween_interval(delay)
			tw.tween_property(l, "modulate:a", 1.0, 0.25)
			tw.tween_callback(func(): AudioDirector.play_sfx("sfx_write", 0.4))
		)

	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	var e := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, e)
	btn.pressed.connect(func(): root.queue_free())
	root.add_child(btn)
	AudioDirector.play_sfx("sfx_page", 1.0)
	return root

static func _zhouxu_tag() -> String:
	match GameState.get_state("zhouxu_end_state"):
		"enter_with_player": return "（在册 / 同行）"
		"pressure_player": return "（在册 / 门外）"
		_: return "（在册）"

static func _liangye_tag() -> String:
	match GameState.get_state("liangye_end_state"):
		"present_anchor": return "（在册 / 锚）"
		"present_fragile_truth": return "（在册 / 已听见）"
		"absent_echo": return "（缺失 / 已听见）"
		_:
			if GameState.get_state("liangye_state") == "missing_marked":
				return "（待定 / 缺失）"
			return "（旁听）"

static func _player_tag() -> String:
	var t := "（待定"
	if GameState.get_flag("flag_true_linday_status_known"):
		t += " / 可补"
	if GameState.get_num("shenhe_focus") >= 10:
		t += " / 替补候选"
	return t + "）"

static func toast(text: String) -> Control:
	var root := Control.new()
	_full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.offset_top = 76
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.11, 0.95)
	sb.border_color = Color(0.70, 0.52, 0.32, 0.8)
	sb.set_border_width_all(1)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	root.add_child(p)

	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68))
	p.add_child(l)

	root.modulate.a = 0.0
	_when_in_tree(root, func():
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 1.0, 0.25)
		tw.tween_interval(2.0)
		tw.tween_property(root, "modulate:a", 0.0, 0.5)
		tw.tween_callback(root.queue_free)
	)
	return root
