extends Control
# Text

signal back_to_title()

const MenuPanelsS := preload("res://src/ui/menu_panels.gd")

var ending_id := "ending_empty_seat"

const ENDING_INFO := {
	"ending_true_release": {
		"title": "《点名停止》",
		"tag": "TRUE END",
		"color": Color(0.72, 0.84, 0.80),
		"text": "名单上的“沈禾”被念全了。\n那一声“到”，是她自己答的。\n\n广播灯灭下去的时候，走廊里第一次真正安静。\n第二天的晨会上，没有人再说“人数不对”。\n你在新的座位表上找到自己的名字——写得很浅，但是完整的。",
	},
	"ending_bittersweet_exchange": {
		"title": "《留堂》",
		"tag": "BITTERSWEET END",
		"color": Color(0.78, 0.72, 0.58),
		"text": "有人必须留下来，晚自习才能下课。\n你坐进那把还带着体温的椅子，把麦克风拉近。\n\n“沈禾。”\n门外传来一声很轻的“到”。\n\n那之后，这所学校再也没有失踪过学生。\n只是每晚十点零七分，广播里都会有个男生的声音，\n很耐心地，把每一个名字念完。",
	},
	"ending_manager": {
		"title": "《管理员》",
		"tag": "COLD END",
		"color": Color(0.62, 0.66, 0.74),
		"text": "规则不需要被打破，只需要有人继续执行。\n你把名单摊平，抽出笔，在“待定”那一栏画了一道很直的线。\n\n许清站在门口看了你很久，然后转身走了。\n她终于可以不用再描那些字了。\n\n第二年，新的转学生填表时，桌上压着一张揉皱的违纪记录表。\n你在他抬头之前，先按住了那张纸：\n“那张别碰。”",
	},
	"ending_destroyer": {
		"title": "《焚校》",
		"tag": "DESTRUCTION END",
		"color": Color(0.86, 0.44, 0.24),
		"text": "你把名单塞进调音台的散热口，按下了打火机。\n火先舔上了那些名字，纸卷起来，像一排排低头的人。\n\n广播在燃烧中还在念，念到一半，声音终于断了。\n\n消防车来的时候，旧楼只剩半边。\n没有人在废墟里找到尸体，也没有人再听见点名。\n只是从那以后，凡是烧过的地方，都长不出草。",
	},
	"ending_empty_seat": {
		"title": "《到》",
		"tag": "BAD END",
		"color": Color(0.70, 0.26, 0.24),
		"text": "你张开嘴，答了一声“到”。\n\n很奇怪，说完之后你就轻松了——\n就像终于把一件背了很久的东西放下。\n\n名单上的“林昼”被划掉，改成了一个更浅的字。\n最后一排靠窗的位置空出来了。\n\n新来的转学生会在那里坐下。\n然后在某个晚自习的夜里，听见广播念一个只有姓的名字。",
	},
	"ending_extra_sunny": {
		"title": "《天晴》",
		"tag": "EXTRA · 后日谈",
		"color": Color(0.85, 0.80, 0.60),
		"text": "雨停了。账开始记了。四十一就是四十一。\n\n那支笔放回了有人记得的地方——\n从那天起，它再没有被翻动过，\n但每天早上，它旁边的那一小片桌角，都是干净的。\n\n晚上没有课了。一节都没有。\n\n第十三节课，下课了。",
	},
}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var info: Dictionary = ENDING_INFO.get(ending_id, ENDING_INFO["ending_empty_seat"])
	var bgc := ColorRect.new()
	bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bgc.color = Color(0.02, 0.02, 0.025)
	add_child(bgc)

	# Endings
	# Endings
	var vg := UITex.make_layer("ending_vignette", 0.55)
	if vg != null:
		var tint: Color = info["color"]
		vg.modulate = Color(
			lerpf(1.0, tint.r, 0.35),
			lerpf(1.0, tint.g, 0.35),
			lerpf(1.0, tint.b, 0.35),
			0.55)
		add_child(vg)

	AudioDirector.stop_amb()
	AudioDirector.play_bgm("bgm_ending_true" if ending_id in ["ending_true_release", "ending_extra_sunny"] else "bgm_ending_bad")

	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.offset_left = 80
	sc.offset_right = -80
	sc.offset_top = 50
	sc.offset_bottom = -50
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 18)
	sc.add_child(v)

	var tag := Label.new()
	tag.text = String(info["tag"])
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(0.545, 0.576, 0.639))
	v.add_child(tag)

	var t := Label.new()
	t.text = String(info["title"])
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 64)
	t.add_theme_color_override("font_color", info["color"])
	v.add_child(t)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 29)
	body.add_theme_constant_override("line_separation", 14)
	body.text = "[center][color=#d6d3cc]" + String(info["text"]).replace("\n", "\n") + "[/color][/center]"
	v.add_child(body)

	v.add_child(_sep())

	var stat := Label.new()
	stat.text = "本周目：真相 %d / 理智 %d / 回响 %d / 关注 %d　　线索 %d/%d　　用时 %d 分钟" % [
		GameState.get_num("truth"), GameState.get_num("sanity"),
		GameState.get_num("memory_echo"), GameState.get_num("shenhe_focus"),
		GameState.clues.size(), GameState.CLUES.size(), int(GameState.play_seconds / 60.0),
	]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat.add_theme_font_size_override("font_size", 24)
	stat.add_theme_color_override("font_color", Color(0.72, 0.76, 0.80))
	v.add_child(stat)

	var fate := RichTextLabel.new()
	fate.bbcode_enabled = true
	fate.fit_content = true
	fate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fate.add_theme_font_size_override("normal_font_size", 25)
	fate.text = "[center][color=#b8b4ac]" + _fates() + "[/color][/center]"
	v.add_child(fate)

	v.add_child(_sep())

	var recap := RichTextLabel.new()
	recap.bbcode_enabled = true
	recap.fit_content = true
	recap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recap.add_theme_font_size_override("normal_font_size", 23)
	recap.text = "[color=#8d8a84]" + _recap() + "[/color]"
	v.add_child(recap)

	var hint := Label.new()
	hint.text = _next_hint()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(1.0, 0.706, 0.329))
	v.add_child(hint)

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	var b1 := Button.new()
	b1.text = "结局与记录"
	b1.focus_mode = Control.FOCUS_NONE
	b1.pressed.connect(func(): add_child(MenuPanelsS.gallery_panel()))
	h.add_child(b1)
	var b2 := Button.new()
	b2.text = "返回标题"
	b2.focus_mode = Control.FOCUS_NONE
	b2.pressed.connect(func(): back_to_title.emit())
	h.add_child(b2)

	modulate.a = 0.0
	if is_inside_tree():
		create_tween().tween_property(self, "modulate:a", 1.0, 1.6)
	else:
		modulate.a = 1.0

func _sep() -> Control:
	var c := ColorRect.new()
	c.custom_minimum_size = Vector2(0, 1)
	c.color = Color(0.4, 0.38, 0.34, 0.4)
	return c

func _fates() -> String:
	var out: Array[String] = []
	out.append("梁野：" + MenuPanelsS._liangye_desc())
	out.append("周叙：" + MenuPanelsS._zhouxu_desc())
	out.append("许清：" + MenuPanelsS._xuqing_desc())
	out.append("老秦：" + MenuPanelsS._oldqin_desc())
	if not GameState.deaths.is_empty():
		out.append("[color=#b8443a]这一次失去的：" + "，".join(GameState.deaths) + "[/color]")
	return "\n".join(out)

func _recap() -> String:
	var rows := [
		["clue_record_table", "违纪记录表 —— 上一轮循环留下的看守记录"],
		["clue_page109", "第109页 —— 第109次重排"],
		["clue_dont_answer", "“别替我答到” —— 终章解局的核心"],
		["clue_shenhe_name", "沈禾的全名 —— 被念全，才算离席"],
		["clue_xuqing_dead", "许清 —— 只是站得太久、还在描线的人"],
		["clue_night_rewrite", "夜间改写 —— 名单真正生效的时刻"],
		["clue_self_repeat", "重复的你 —— 你也不是第一个林昼"],
	]
	var out: Array[String] = ["【伏笔回收】"]
	for r in rows:
		var got := GameState.clues.has(String(r[0]))
		out.append(("✔ " if got else "✘ ") + String(r[1]))
	return "\n".join(out)

func _next_hint() -> String:
	match ending_id:
		"ending_true_release":
			return "你把她的名字念全了。——试试别的路：如果这一次你先选择接管，或者先点着那张名单呢？"
		"ending_extra_sunny":
			return "后日谈完结。——成就：%d / %d。剩下的那几枚，都在没有天晴的夜里。" % [
				Ach.unlocked_count(), Ach.total_count()]
		"ending_bittersweet_exchange":
			return "线索：真结局需要“写回名字 + 夜间核对名单 + 完整真相 + 梁野还在”。"
		"ending_manager":
			return "线索：救人线分数（救梁野、补沈禾名字、先点沈禾）足够高时，会出现另一条路。"
		"ending_destroyer":
			return "线索：火能烧掉名单，但烧不掉“少一个人”这件事本身。"
		_:
			return "线索：不要替任何人答“到”。先把她的名字弄全。"
