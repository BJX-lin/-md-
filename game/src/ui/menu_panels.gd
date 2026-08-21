extends RefCounted
class_name MenuPanels
# Save/Load

const TOUCH_MIN := 48

static func _shell(title: String) -> Array:

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.043, 0.051, 0.067, 0.90)
	root.add_child(shade)

	var wall := UITex.make_layer("menu_bg", 0.32)
	if wall != null:
		root.add_child(wall)

	var inset := SafeArea.get_safe_insets()
	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 60 + inset.x
	frame.offset_right = -60 - inset.z
	frame.offset_top = 40 + inset.y
	frame.offset_bottom = -40 - inset.w

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.129, 0.153, 0.204, 0.98)
	sb.border_color = Color(0.169, 0.2, 0.271, 0.6)
	sb.set_border_width_all(1)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	frame.add_theme_stylebox_override("panel", sb)
	root.add_child(frame)

	var grain := UITex.make_layer("panel_frame", 0.30)
	if grain != null:
		grain.set_anchors_preset(Control.PRESET_FULL_RECT)
		grain.offset_left = frame.offset_left
		grain.offset_right = frame.offset_right
		grain.offset_top = frame.offset_top
		grain.offset_bottom = frame.offset_bottom
		root.add_child(grain)
		root.move_child(grain, frame.get_index())

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	frame.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var t := Label.new()
	t.text = title
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	head.add_child(t)
	var close := Button.new()
	close.text = "关闭"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(120, TOUCH_MIN)
	close.pressed.connect(func():
		AudioDirector.play_sfx("sfx_click", 0.6)
		root.queue_free()
	)
	head.add_child(close)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.169, 0.2, 0.271, 0.5)
	v.add_child(sep)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	v.add_child(content)
	return [root, content]

static func _scroll(parent: Control) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	sc.follow_focus = false
	sc.scroll_deadzone = 12
	parent.add_child(sc)
	var vsb := sc.get_v_scroll_bar()
	if vsb:
		vsb.custom_minimum_size.x = 18
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	sc.add_child(v)
	return v

static func history_panel() -> Control:
	var pair := _shell("回想")
	var root: Control = pair[0]
	var content: Control = pair[1]

	var hist: Array = GameState.history
	var start := maxi(0, hist.size() - 300)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.scroll_deadzone = 12
	content.add_child(sc)
	var vsb := sc.get_v_scroll_bar()
	if vsb:
		vsb.custom_minimum_size.x = 18

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	sc.add_child(v)

	for i in range(start, hist.size()):
		var h: Dictionary = hist[i]
		var who := String(h.get("who", ""))
		var rt := RichTextLabel.new()
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.scroll_active = false
		rt.selection_enabled = false

		rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rt.add_theme_font_size_override("normal_font_size", 25)
		rt.add_theme_constant_override("line_separation", 6)
		if who == "__choice__":
			rt.text = "[color=#c98b46]▶ 你的选择：%s[/color]" % String(h.get("text", ""))
		elif who == "":
			rt.text = "[color=#a9a69f]%s[/color]" % String(h.get("text", ""))
		else:
			var nm := String(Cfg.CHARACTERS.get(who, {}).get("name", who))
			var col: Color = Cfg.CHARACTERS.get(who, {}).get("color", Color.WHITE)
			rt.text = "[color=#%s]%s[/color]　%s" % [col.to_html(false), nm, String(h.get("text", ""))]
		v.add_child(rt)

	if hist.is_empty():
		var e := Label.new()
		e.text = "（还没有内容）"
		e.add_theme_color_override("font_color", Color(0.545, 0.576, 0.639))
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(e)

	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 16)
	content.add_child(bar)

	var b_top := Button.new()
	b_top.text = "▲ 最早"
	b_top.focus_mode = Control.FOCUS_NONE
	b_top.add_theme_font_size_override("font_size", 22)
	b_top.pressed.connect(func():
		AudioDirector.play_sfx("sfx_click", 0.5)
		sc.scroll_vertical = 0
	)
	bar.add_child(b_top)

	var b_bottom := Button.new()
	b_bottom.text = "▼ 最新"
	b_bottom.focus_mode = Control.FOCUS_NONE
	b_bottom.add_theme_font_size_override("font_size", 22)
	b_bottom.pressed.connect(func():
		AudioDirector.play_sfx("sfx_click", 0.5)
		sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)
	)
	bar.add_child(b_bottom)

	root.ready.connect(func():
		await root.get_tree().process_frame
		var bar_v := sc.get_v_scroll_bar()
		if bar_v:
			sc.scroll_vertical = int(bar_v.max_value)
	, CONNECT_ONE_SHOT)
	return root

# Clues
static func clue_panel() -> Control:
	var pair := _shell("线索簿　（%d / %d）" % [GameState.clues.size(), GameState.CLUES.size()])
	var root: Control = pair[0]
	var v := _scroll(pair[1])
	# Clues
	for cid in GameState.CLUES:
		var info: Dictionary = GameState.CLUES[cid]
		var got := GameState.clues.has(cid)
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.169, 0.2, 0.271, 0.9) if got else Color(0.129, 0.153, 0.204, 0.7)
		sb.border_color = Color(0.29, 0.55, 1.0, 0.6) if got else Color(0.29, 0.314, 0.376, 0.5)
		sb.set_border_width_all(1)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		p.add_theme_stylebox_override("panel", sb)
		v.add_child(p)
		var vv := VBoxContainer.new()
		p.add_child(vv)
		var t := Label.new()
		t.text = ("【第%d章】%s" % [int(info.get("ch", 1)), String(info.get("name", cid))]) if got else "【？】未获得的线索"
		t.add_theme_font_size_override("font_size", 26)
		t.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0) if got else Color(0.545, 0.576, 0.639))
		vv.add_child(t)
		var d := Label.new()
		d.text = String(info.get("text", "")) if got else "——"
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 23)
		d.add_theme_color_override("font_color", Color(0.91, 0.918, 0.929) if got else Color(0.545, 0.576, 0.639))
		vv.add_child(d)

	# Items
	var t2 := Label.new()
	t2.text = "—— 随身物品 ——"
	t2.add_theme_font_size_override("font_size", 27)
	t2.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	v.add_child(t2)
	if GameState.inventory.is_empty():
		var e := Label.new()
		e.text = "（空）"
		e.add_theme_color_override("font_color", Color(0.545, 0.576, 0.639))
		v.add_child(e)
	for iid in GameState.inventory:
		var info2: Dictionary = GameState.ITEMS.get(iid, {})
		var l := Label.new()
		l.text = "◆ %s —— %s" % [String(info2.get("name", iid)), String(info2.get("desc", ""))]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", Color(0.91, 0.918, 0.929))
		v.add_child(l)
	return root

# State
static func status_panel() -> Control:
	var pair := _shell("状态")
	var root: Control = pair[0]
	var v := _scroll(pair[1])

	var head := Label.new()
	head.text = "第 %s 章　游玩时长 %d 分钟　周目 %d" % [
		("终" if GameState.current_chapter >= 5 else str(GameState.current_chapter)),
		int(GameState.play_seconds / 60.0),
		int(GameState.persistent.get("cycles", 0)) + 1,
	]
	head.add_theme_font_size_override("font_size", 25)
	head.add_theme_color_override("font_color", Color(0.91, 0.918, 0.929))
	v.add_child(head)

	for key in ["truth", "sanity", "memory_echo", "shenhe_focus"]:
		v.add_child(_bar_row(key))
	var sep := Label.new()
	sep.text = "—— 关系 ——"
	sep.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	v.add_child(sep)
	for key in ["trust_zhouxu", "trust_liangye", "trust_xuqing", "trust_oldqin"]:
		v.add_child(_bar_row(key))
	var sep2 := Label.new()
	sep2.text = "—— 倾向 ——"
	sep2.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	v.add_child(sep2)
	for key in ["route_obedience", "route_investigate", "route_empathy", "route_hostility", "taboo_count"]:
		v.add_child(_bar_row(key))

	# Truth
	var tips := Label.new()
	var truth := GameState.get_num("truth")
	var msg := "你还什么都不确定。"
	for pair2 in Cfg.TH_TRUTH:
		if truth >= int(pair2[0]):
			msg = String(pair2[1])
	tips.text = "认知：" + msg
	tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips.add_theme_font_size_override("font_size", 24)
	tips.add_theme_color_override("font_color", Color(0.55, 0.7, 0.9))
	v.add_child(tips)

	var san := GameState.get_num("sanity")
	var smsg := "叙述稳定，可信。"
	for pair3 in Cfg.TH_SANITY:
		if san <= int(pair3[0]):
			smsg = String(pair3[1])
	var stip := Label.new()
	stip.text = "精神：" + smsg
	stip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stip.add_theme_font_size_override("font_size", 24)
	stip.add_theme_color_override("font_color", Color(1.0, 0.706, 0.329))
	v.add_child(stip)

	# State
	var sep3 := Label.new()
	sep3.text = "—— 相关的人 ——"
	sep3.add_theme_color_override("font_color", Color(0.29, 0.55, 1.0))
	v.add_child(sep3)
	for row in [
		["梁野", _liangye_desc()], ["周叙", _zhouxu_desc()],
		["许清", _xuqing_desc()], ["沈禾", _shenhe_desc()], ["老秦", _oldqin_desc()],
	]:
		var l := Label.new()
		l.text = "%s：%s" % [String(row[0]), String(row[1])]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 24)
		v.add_child(l)

	if not GameState.deaths.is_empty():
		var dl := Label.new()
		dl.text = "已失去：" + ", ".join(GameState.deaths)
		dl.add_theme_color_override("font_color", Color(1.0, 0.478, 0.612))
		dl.add_theme_font_size_override("font_size", 24)
		v.add_child(dl)
	return root

static func _bar_row(key: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = Cfg.NUM_LABEL.get(key, key)
	l.custom_minimum_size.x = 160
	l.add_theme_font_size_override("font_size", 24)
	h.add_child(l)
	var r: Array = Cfg.NUM_RANGE.get(key, [0, 10])
	var pb := ProgressBar.new()
	pb.min_value = float(r[0])
	pb.max_value = float(Cfg.BAR_MAX.get(key, r[1]))
	pb.value = float(GameState.get_num(key))
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(360, 20)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bgsb := StyleBoxFlat.new()
	bgsb.bg_color = Color(0.129, 0.153, 0.204)
	bgsb.set_corner_radius_all(3)
	var fgsb := StyleBoxFlat.new()
	fgsb.bg_color = Color(0.29, 0.55, 1.0)
	if key == "sanity":
		fgsb.bg_color = Color(0.29, 0.85, 0.57)
	elif key == "truth":
		fgsb.bg_color = Color(0.29, 0.55, 1.0)
	elif key.begins_with("trust"):
		fgsb.bg_color = Color(1.0, 0.706, 0.329)
	fgsb.set_corner_radius_all(3)
	pb.add_theme_stylebox_override("background", bgsb)
	pb.add_theme_stylebox_override("fill", fgsb)
	h.add_child(pb)
	var val := Label.new()
	val.text = str(GameState.get_num(key))
	val.custom_minimum_size.x = 60
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 24)
	h.add_child(val)
	return h

static func _liangye_desc() -> String:
	match GameState.get_state("liangye_final_state_ch3"):
		"anchor_alive": return "还在。他说过不会先走。"
		"rescued_half": return "拉回来了，但他说话有时是过去时。"
		"abandoned": return "你放开了手。"
		"missing": return "没有回来。名字后面写着“已听见”。"
	match GameState.get_state("liangye_state"):
		"missing_marked": return "被点到过名，一整天都在发抖。"
		"half_assimilated": return "回来了。影子却没跟上。"
		"fear_alive": return "怕得要命，但还在你旁边。"
		"ally_shaken": return "肯跟你一起查了。"
		_: return "还算正常。"

static func _zhouxu_desc() -> String:
	match GameState.get_state("zhouxu_final_state_ch3"):
		"confessor_protector": return "他坦白了一部分，并且决定站在你这边。"
		"coercer": return "他只想尽快结束，包括用你结束。"
	match GameState.get_state("zhouxu_state"):
		"guarding": return "他在护着你，也在瞒着你。"
		"hiding": return "他躲着你的问题。"
		"coercing": return "他开始逼你做决定。"
		_: return "班长。做事很稳。"

static func _xuqing_desc() -> String:
	match GameState.get_state("xuqing_state"):
		"revealed": return "已经确认：她五年前就不在名册上了。"
		"destabilized": return "被你说破了——她只是站得太久的人。"
		"observer": return "她不再拦你，只是看着。"
		"suspected": return "她走路没有声音，也从不穿鞋。"
		_: return "班主任。语文老师。"

static func _shenhe_desc() -> String:
	match GameState.get_state("shenhe_state"):
		"seated_core": return "她坐在播音椅上，等你念完。"
		"half_present": return "她已经能被看见一部分了。"
		"calling": return "她在叫名字。有时候叫的是你的。"
		_: return "只是一个只剩半个字的名字。"

static func _oldqin_desc() -> String:
	if GameState.get_flag("flag_oldqin_survived"):
		return "你把他从火里拖出来了。他说这是五年来头一回活着走出那间屋子。"
	match GameState.get_state("oldqin_state"):
		"burned": return "值班室烧了。他没出来。"
		"missing": return "钥匙板上少了一把钥匙，人也少了一个。"
		_: return "守夜的老保安。抽很凶的烟。"

# Save/Load
static func save_panel(allow_save: bool) -> Control:
	var pair := _shell("存档 / 读档")
	var root: Control = pair[0]
	var v := _scroll(pair[1])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)

	for i in SaveSystem.SLOT_COUNT:
		var d := SaveSystem.read_slot(i)
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.10, 0.11, 0.95)
		sb.border_color = Color(0.45, 0.40, 0.35, 0.7)
		sb.set_border_width_all(1)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		p.add_theme_stylebox_override("panel", sb)
		p.custom_minimum_size = Vector2(430, 0)
		grid.add_child(p)
		var vv := VBoxContainer.new()
		p.add_child(vv)
		var meta: Dictionary = d.get("_meta", {})
		var head := Label.new()
		head.text = "槽 %d" % (i + 1)
		head.add_theme_color_override("font_color", Color(0.86, 0.72, 0.48))
		head.add_theme_font_size_override("font_size", 24)
		vv.add_child(head)
		var info := Label.new()
		if d.is_empty():
			info.text = "—— 空 ——"
			info.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		else:
			info.text = "第%s章　真相%d　理智%d\n%s\n%s" % [
				str(meta.get("chapter", 1)), int(meta.get("truth", 0)), int(meta.get("sanity", 0)),
				String(meta.get("preview", "")), String(meta.get("time", "")),
			]
		info.add_theme_font_size_override("font_size", 21)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vv.add_child(info)
		var hb := HBoxContainer.new()
		vv.add_child(hb)
		if allow_save:
			var bs := Button.new()
			bs.text = "保存"
			bs.focus_mode = Control.FOCUS_NONE
			bs.add_theme_font_size_override("font_size", 21)
			bs.custom_minimum_size = Vector2(110, TOUCH_MIN)
			bs.pressed.connect(func():
				SaveSystem.save_slot(i)
				AudioDirector.play_sfx("sfx_write", 0.8)
				root.queue_free()
			)
			hb.add_child(bs)
		var bl := Button.new()
		bl.text = "读取"
		bl.disabled = d.is_empty()
		bl.focus_mode = Control.FOCUS_NONE
		bl.add_theme_font_size_override("font_size", 21)
		bl.custom_minimum_size = Vector2(110, TOUCH_MIN)
		bl.pressed.connect(func():
			var cb = root.get_meta("on_load", null)
			if cb is Callable:
				cb.call(i)
			root.queue_free()
		)
		hb.add_child(bl)
	return root

static func system_panel() -> Control:
	var pair := _shell("设置")
	var root: Control = pair[0]
	var v := _scroll(pair[1])

	v.add_child(_option_row("文本速度", ["很慢", "慢", "正常", "极快"], int(SaveSystem.settings.get("text_speed", 2)), func(i):
		SaveSystem.set_setting("text_speed", i)))
	v.add_child(_option_row("血腥表现", ["关闭", "温和", "完整"], int(SaveSystem.settings.get("gore", 2)), func(i):
		SaveSystem.set_setting("gore", i)))
	v.add_child(_toggle_row("画面震动（默认关）", bool(SaveSystem.settings.get("screen_shake", false)), func(b):
		SaveSystem.set_setting("screen_shake", b)))
	v.add_child(_toggle_row("强闪光效果", bool(SaveSystem.settings.get("flash", true)), func(b):
		SaveSystem.set_setting("flash", b)))
	v.add_child(_toggle_row("触觉震动（手机惊吓反馈）", bool(SaveSystem.settings.get("haptics", true)), func(b):
		SaveSystem.set_setting("haptics", b)))
	v.add_child(_option_row("文字大小", ["小", "中", "大"], int(SaveSystem.settings.get("text_size", 1)), func(i):
		SaveSystem.set_setting("text_size", i)))
	v.add_child(_slider_row("总音量", float(SaveSystem.settings.get("vol_master", 1.0)), func(x):
		SaveSystem.set_setting("vol_master", x)))
	v.add_child(_slider_row("音乐/环境", float(SaveSystem.settings.get("vol_bgm", 0.7)), func(x):
		SaveSystem.set_setting("vol_bgm", x)))
	v.add_child(_slider_row("音效", float(SaveSystem.settings.get("vol_sfx", 0.85)), func(x):
		SaveSystem.set_setting("vol_sfx", x)))
	v.add_child(_toggle_row("显示帧率", bool(SaveSystem.settings.get("show_fps", false)), func(b):
		SaveSystem.set_setting("show_fps", b)))
	v.add_child(_slider_row("自动播放停顿", float(SaveSystem.settings.get("auto_speed", 1.6)), func(x):
		SaveSystem.set_setting("auto_speed", clampf(x * 3.0, 0.3, 3.0)), float(SaveSystem.settings.get("auto_speed", 1.6)) / 3.0))

	var warn := Label.new()
	warn.text = "提示：本作含惊吓演出、血腥描写与压抑题材。可在上方随时降低表现强度。"
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn.add_theme_font_size_override("font_size", 22)
	warn.add_theme_color_override("font_color", Color(0.75, 0.58, 0.42))
	v.add_child(warn)

	# Title

	# Save/Load
	var sep2 := ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 1)
	sep2.color = Color(0.4, 0.38, 0.34, 0.4)
	v.add_child(sep2)

	var applied := Label.new()
	applied.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	applied.add_theme_font_size_override("font_size", 21)
	applied.add_theme_color_override("font_color", Color(0.58, 0.78, 0.62))
	applied.modulate.a = 0.0

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)

	var apply := Button.new()
	apply.text = "应用"
	apply.focus_mode = Control.FOCUS_NONE
	apply.custom_minimum_size = Vector2(150, TOUCH_MIN + 6)
	apply.pressed.connect(func():
		SaveSystem.save_settings()
		AudioDirector.play_sfx("sfx_click", 0.8)
		_notify_settings_saved(root)
		applied.text = "设置已保存"
		applied.modulate.a = 1.0
		if applied.is_inside_tree():
			applied.create_tween().tween_property(applied, "modulate:a", 0.0, 2.0) \
				.set_delay(1.2)
	)
	row.add_child(apply)

	var cont := Button.new()
	cont.text = "继续游戏"
	cont.focus_mode = Control.FOCUS_NONE
	cont.custom_minimum_size = Vector2(180, TOUCH_MIN + 6)
	cont.pressed.connect(func():
		SaveSystem.save_settings()
		AudioDirector.play_sfx("sfx_click", 0.8)
		_notify_settings_saved(root)
		root.queue_free()
	)
	row.add_child(cont)
	v.add_child(applied)

	var quit := Button.new()
	quit.text = "保存并返回标题"
	quit.focus_mode = Control.FOCUS_NONE
	quit.custom_minimum_size.y = TOUCH_MIN
	quit.pressed.connect(func():
		var cb = root.get_meta("on_quit", null)
		root.queue_free()
		if cb is Callable:
			cb.call()
	)
	v.add_child(quit)
	return root

## 设置保存后通知宿主（游戏界面据此即时应用文字大小等）
static func _notify_settings_saved(root: Control) -> void:
	var cb = root.get_meta("on_settings_saved", null)
	if cb is Callable:
		cb.call()


static func _option_row(title: String, options: Array, current: int, cb: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(220, TOUCH_MIN)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var group_buttons: Array[Button] = []
	for i in options.size():
		var b := Button.new()
		b.text = String(options[i])
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(96, TOUCH_MIN)
		b.modulate = Color(1.0, 0.72, 0.6) if i == current else Color.WHITE
		group_buttons.append(b)
		b.pressed.connect(func():
			cb.call(i)
			for k in group_buttons.size():
				group_buttons[k].modulate = Color(1.0, 0.72, 0.6) if k == i else Color.WHITE
			AudioDirector.play_sfx("sfx_click", 0.5)
		)
		h.add_child(b)
	return h

static func _toggle_row(title: String, value: bool, cb: Callable) -> Control:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(220, TOUCH_MIN)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var c := CheckButton.new()
	c.button_pressed = value
	c.focus_mode = Control.FOCUS_NONE
	c.custom_minimum_size.y = TOUCH_MIN
	c.toggled.connect(func(b): cb.call(b))
	h.add_child(c)
	return h

static func _slider_row(title: String, value: float, cb: Callable, display := -1.0) -> Control:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(220, TOUCH_MIN)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value if display < 0.0 else display
	s.custom_minimum_size = Vector2(360, TOUCH_MIN)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(x): cb.call(x))
	h.add_child(s)
	return h

static func gallery_panel() -> Control:
	var pair := _shell("结局与记录")
	var root: Control = pair[0]
	var v := _scroll(pair[1])
	const ENDINGS := [
		["ending_true_release", "真结局《点名停止》", "让沈禾离席，让晚自习真正下课。"],
		["ending_bittersweet_exchange", "遗憾结局《留堂》", "有人得留下来，那就你留。"],
		["ending_manager", "管理者结局《管理员》", "规则不需要被打破，只需要换个人执行。"],
		["ending_destroyer", "毁灭结局《焚校》", "把名单、广播和这栋楼一起烧掉。"],
		["ending_empty_seat", "空席结局《到》", "你答了一声。之后就没人再答了。"],
	]
	var got: Dictionary = GameState.persistent.get("endings", {})
	for e in ENDINGS:
		var id := String(e[0])
		var unlocked := got.has(id)
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.09, 0.10, 0.95) if unlocked else Color(0.07, 0.07, 0.08, 0.8)
		sb.border_color = Color(0.62, 0.32, 0.26, 0.8) if unlocked else Color(0.25, 0.25, 0.25, 0.6)
		sb.set_border_width_all(1)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		p.add_theme_stylebox_override("panel", sb)
		v.add_child(p)
		var vv := VBoxContainer.new()
		p.add_child(vv)
		var t := Label.new()
		t.text = String(e[1]) if unlocked else "？？？"
		t.add_theme_font_size_override("font_size", 27)
		t.add_theme_color_override("font_color", Color(0.90, 0.74, 0.52) if unlocked else Color(0.40, 0.40, 0.40))
		vv.add_child(t)
		var d := Label.new()
		d.text = (String(e[2]) + "　（达成 %d 次）" % int(got.get(id, 0))) if unlocked else "尚未抵达。"
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 23)
		d.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72) if unlocked else Color(0.34, 0.34, 0.34))
		vv.add_child(d)
	var st := Label.new()
	st.text = "已循环 %d 次　线索图鉴 %d / %d　最高真相 %d" % [
		int(GameState.persistent.get("cycles", 0)),
		(GameState.persistent.get("clues_seen", []) as Array).size(),
		GameState.CLUES.size(),
		int(GameState.persistent.get("best_truth", 0)),
	]
	st.add_theme_font_size_override("font_size", 24)
	st.add_theme_color_override("font_color", Color(0.70, 0.78, 0.84))
	v.add_child(st)
	return root

## 成就面板（v1.4.0）：按 ACHIEVEMENTS 表顺序列出，hidden 成就在解锁前只显示 ？？？
static func achievement_panel() -> Control:
	var pair := _shell("成就")
	var root: Control = pair[0]
	var v := _scroll(pair[1])

	var head := Label.new()
	head.text = "已解锁 %d / %d" % [Ach.unlocked_count(), Ach.total_count()]
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", Color(0.90, 0.74, 0.52))
	v.add_child(head)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = Ach.total_count()
	bar.value = Ach.unlocked_count()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.show_percentage = false
	v.add_child(bar)

	for id in Ach.ACHIEVEMENTS:
		var sid := String(id)
		var got := Ach.is_unlocked(sid)
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.11, 0.08, 0.95) if got else Color(0.07, 0.07, 0.08, 0.8)
		sb.border_color = Color(0.72, 0.58, 0.32, 0.85) if got else Color(0.25, 0.25, 0.25, 0.6)
		sb.set_border_width_all(1)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		p.add_theme_stylebox_override("panel", sb)
		v.add_child(p)
		var vv := VBoxContainer.new()
		p.add_child(vv)
		var t := Label.new()
		t.text = Ach.name_of(sid) if got else "？？？"
		t.add_theme_font_size_override("font_size", 25)
		t.add_theme_color_override("font_color", Color(0.92, 0.80, 0.52) if got else Color(0.42, 0.42, 0.42))
		vv.add_child(t)
		var d := Label.new()
		d.text = Ach.desc_of(sid) if got or not Ach.is_hidden(sid) else "隐藏成就——自己走到那一步就会知道。"
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 21)
		d.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72) if got or not Ach.is_hidden(sid) else Color(0.36, 0.36, 0.36))
		vv.add_child(d)
	return root

static func feedback_panel() -> Control:
	var pair := _shell("BUG 反馈 / 玩家交流")
	var root: Control = pair[0]
	var v := _scroll(pair[1])

	var qq := Cfg.qq_group()
	var qr_ok := Cfg.qq_qr_valid()
	var tampered := qq == "" or Cfg.qq_group_url() == "" or not qr_ok

	if tampered:

		var warn_box := PanelContainer.new()
		var wsb := StyleBoxFlat.new()
		wsb.bg_color = Color(0.20, 0.06, 0.05, 0.95)
		wsb.border_color = Color(0.80, 0.30, 0.26, 0.9)
		wsb.set_border_width_all(2)
		wsb.content_margin_left = 24
		wsb.content_margin_right = 24
		wsb.content_margin_top = 18
		wsb.content_margin_bottom = 18
		warn_box.add_theme_stylebox_override("panel", wsb)
		v.add_child(warn_box)
		var wl := Label.new()
		wl.text = "⚠ 联系方式校验未通过\n\n本页的群号或二维码与原版签名不符，\n可能已被第三方篡改。请不要按此处信息加群。\n\n请到官方发布页重新下载游戏。"
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wl.add_theme_font_size_override("font_size", 24)
		wl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.76))
		warn_box.add_child(wl)
		return root

	var intro := Label.new()
	intro.text = "遇到卡关、闪退、错字、剧情前后矛盾、\n或者时间线对不上——都欢迎反馈。"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 25)
	intro.add_theme_color_override("font_color", Color(0.80, 0.79, 0.75))
	v.add_child(intro)

	var card := PanelContainer.new()
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.10, 0.10, 0.12, 0.95)
	csb.border_color = Color(0.52, 0.46, 0.38, 0.7)
	csb.set_border_width_all(1)
	csb.set_corner_radius_all(4)
	csb.content_margin_left = 26
	csb.content_margin_right = 26
	csb.content_margin_top = 20
	csb.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", csb)
	v.add_child(card)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	card.add_child(cv)

	var lab := Label.new()
	lab.text = "QQ 交流群"
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 23)
	lab.add_theme_color_override("font_color", Color(0.66, 0.64, 0.60))
	cv.add_child(lab)

	var num := Label.new()
	num.text = qq
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 52)
	num.add_theme_color_override("font_color", Color(0.90, 0.84, 0.66))
	cv.add_child(num)

	var copy_row := HBoxContainer.new()
	copy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	copy_row.add_theme_constant_override("separation", 14)
	cv.add_child(copy_row)

	var tip := Label.new()
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 21)
	tip.add_theme_color_override("font_color", Color(0.58, 0.72, 0.60))
	tip.modulate.a = 0.0

	var copy_btn := Button.new()
	copy_btn.text = "复制群号"
	copy_btn.focus_mode = Control.FOCUS_NONE
	copy_btn.custom_minimum_size = Vector2(190, 0)
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(qq)
		AudioDirector.play_sfx("sfx_click", 0.8)
		tip.text = "已复制到剪贴板"
		tip.modulate.a = 1.0
		if tip.is_inside_tree():
			tip.create_tween().tween_property(tip, "modulate:a", 0.0, 2.4) \
				.set_delay(1.2)
	)
	copy_row.add_child(copy_btn)
	cv.add_child(tip)

	var qr := UITex.get_tex("qq_qr")
	if qr != null:
		var qrow := HBoxContainer.new()
		qrow.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(qrow)
		var pic := TextureRect.new()
		pic.texture = qr
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(300, 300)
		qrow.add_child(pic)

		var qtip := Label.new()
		qtip.text = "用手机 QQ 扫码，或长按识别"
		qtip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qtip.add_theme_font_size_override("font_size", 22)
		qtip.add_theme_color_override("font_color", Color(0.62, 0.61, 0.58))
		v.add_child(qtip)
	else:
		var qmiss := Label.new()
		qmiss.text = "（二维码图片缺失，请直接搜索上面的群号加群）"
		qmiss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qmiss.add_theme_font_size_override("font_size", 21)
		qmiss.add_theme_color_override("font_color", Color(0.60, 0.58, 0.55))
		v.add_child(qmiss)

	var env := PanelContainer.new()
	var esb := StyleBoxFlat.new()
	esb.bg_color = Color(0.07, 0.07, 0.085, 0.9)
	esb.border_color = Color(0.40, 0.38, 0.34, 0.5)
	esb.set_border_width_all(1)
	esb.content_margin_left = 22
	esb.content_margin_right = 22
	esb.content_margin_top = 16
	esb.content_margin_bottom = 16
	env.add_theme_stylebox_override("panel", esb)
	v.add_child(env)

	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 8)
	env.add_child(ev)

	var eh := Label.new()
	eh.text = "反馈时请附上以下信息"
	eh.add_theme_font_size_override("font_size", 23)
	eh.add_theme_color_override("font_color", Color(0.78, 0.76, 0.70))
	ev.add_child(eh)

	var info := _env_string()
	var ib := Label.new()
	ib.text = info
	ib.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ib.add_theme_font_size_override("font_size", 21)
	ib.add_theme_color_override("font_color", Color(0.64, 0.68, 0.74))
	ev.add_child(ib)

	var etip := Label.new()
	etip.add_theme_font_size_override("font_size", 20)
	etip.add_theme_color_override("font_color", Color(0.58, 0.72, 0.60))
	etip.modulate.a = 0.0

	var ebtn := Button.new()
	ebtn.text = "复制环境信息"
	ebtn.focus_mode = Control.FOCUS_NONE
	ebtn.pressed.connect(func():
		DisplayServer.clipboard_set(info)
		AudioDirector.play_sfx("sfx_click", 0.8)
		etip.text = "已复制"
		etip.modulate.a = 1.0
		if etip.is_inside_tree():
			etip.create_tween().tween_property(etip, "modulate:a", 0.0, 2.4) \
				.set_delay(1.2)
	)
	ev.add_child(ebtn)
	ev.add_child(etip)

	return root

# Chapters

# Perf
# Endings
static func _env_string() -> String:
	var node_id := String(GameState.current_node)
	if node_id == "":
		node_id = "-"
	var vp := DisplayServer.window_get_size()
	var lines := PackedStringArray()
	lines.append("——《%s》反馈信息——" % Cfg.GAME_TITLE)
	lines.append("版本 v%s　引擎 Godot %s" % [Cfg.VERSION, Engine.get_version_info().get("string", "?")])
	lines.append("系统 %s %s　机型 %s" % [
		OS.get_name(), OS.get_version(), OS.get_model_name()])
	lines.append("渲染 %s　窗口 %dx%d　帧率 %d" % [
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")),
		vp.x, vp.y, Engine.get_frames_per_second()])
	lines.append("语言 %s　内存 %.0fMB" % [
		OS.get_locale(), OS.get_static_memory_usage() / 1048576.0])
	lines.append("—— 进度 ——")
	lines.append("章节 第%d章　节点 %s" % [GameState.current_chapter, node_id])
	lines.append("剧情时间 第%d天 %s　周目 %d" % [
		GameState.story_day, GameState.time_hhmm(),
		int(GameState.persistent.get("cycles", 0)) + 1])
	lines.append("真相 %d　理智 %d　救人线 %d　沈禾关注 %d" % [
		GameState.get_num("truth"), GameState.get_num("sanity"),
		GameState.get_num("save_route_score"), GameState.get_num("shenhe_focus")])
	lines.append("真相层级 %s　线索 %d/%d　道具 %d" % [
		GameState.get_state("truth_state"),
		GameState.clues.size(), GameState.CLUES.size(),
		GameState.inventory.size()])
	if not GameState.deaths.is_empty():
		lines.append("死亡/失踪 %s" % ", ".join(GameState.deaths))
	lines.append("—— 设置 ——")
	lines.append("血腥 %d　震动 %s　闪光 %s　文字速度 %d" % [
		int(SaveSystem.settings.get("gore", 2)),
		"开" if bool(SaveSystem.settings.get("screen_shake", false)) else "关",
		"开" if bool(SaveSystem.settings.get("flash", true)) else "关",
		int(SaveSystem.settings.get("text_speed", 2))])
	return "\n".join(lines)
