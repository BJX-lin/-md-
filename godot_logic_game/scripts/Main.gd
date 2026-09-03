extends Control

# ============================================================
# 主界面：聊天气泡式界面
# ------------------------------------------------------------
# - 玩家气泡靠右（绿色），AI 气泡靠左（深灰）
# - 顶部：标题 + 双方计分条 + 回合数
# - 底部：输入框 + 发送；附加栏：换辩题 / 结算 / 导出 / 重开
# - 结算面板：显示回合、命中、讲理、胜负判定
# - 导出：把整段对话存到 user:// 下，可在手机上被访问
# ============================================================

const MAX_LOG := 400

var engine := DebateEngine.new()

# UI 节点
var _chat: VBoxContainer        # 存放消息气泡
var _scroll: ScrollContainer
var _input: LineEdit
var _ai_bar: ProgressBar
var _user_bar: ProgressBar
var _round_lbl: Label
var _topic_lbl: Label
var _settle: Control            # 结算面板
var _settle_body: RichTextLabel

# 存档文本（导出用）
var _transcript := ""

func _ready() -> void:
	_build_ui()
	engine.reset()
	engine.max_rounds = 12
	_refresh_hud()
	# 开场
	_ai_say("我是「杠精老师 · 逻辑裁判」。你输入任何观点，我用逻辑漏洞来杠你。 🎬")
	var topic_msg := engine.setup_topic()
	_ai_say(topic_msg)
	_set_topic_label(engine.current_topic)
	_ai_say("示范：输入「大家都这么做，所以肯定是对的」。")

# ------------------------------------------------------------
#  UI 构建
# ------------------------------------------------------------
func _build_ui() -> void:
	# 深色背景
	var bg := ColorRect.new()
	bg.color = Color(0.075, 0.085, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	root.offset_left = 10; root.offset_right = -10
	root.offset_top = 16; root.offset_bottom = -10
	add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_topic_bar())
	root.add_child(_build_chat())
	root.add_child(_build_input())
	root.add_child(_build_toolbar())

	# 结算面板（覆盖层，默认隐藏）
	_settle = _build_settle_panel()
	add_child(_settle)

func _build_header() -> Control:
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "逻辑辩论 · 文字博弈"
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)

	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 10)
	top.add_child(score_row)

	score_row.add_child(_make_bar("杠精 AI", Color(0.95, 0.62, 0.48), true))
	score_row.add_child(_make_bar("玩家", Color(0.5, 0.85, 0.7), false))

	_round_lbl = Label.new()
	_round_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.8))
	_round_lbl.add_theme_font_size_override("font_size", 14)
	top.add_child(_round_lbl)
	return top

func _make_bar(label_text: String, color: Color, is_ai: bool) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 13)
	box.add_child(lbl)
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = 0
	bar.custom_minimum_size = Vector2(0, 14)
	box.add_child(bar)
	if is_ai:
		_ai_bar = bar
	else:
		_user_bar = bar
	return box

func _build_topic_bar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var btn := Button.new()
	btn.text = "换辩题"
	btn.custom_minimum_size = Vector2(84, 30)
	btn.pressed.connect(_on_next_topic)
	row.add_child(btn)
	_topic_lbl = Label.new()
	_topic_lbl.text = ""
	_topic_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_topic_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_topic_lbl.add_theme_color_override("font_color", Color(0.95, 0.8, 0.5))
	row.add_child(_topic_lbl)
	return row

func _build_chat() -> Control:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat = VBoxContainer.new()
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat.add_theme_constant_override("separation", 10)
	_scroll.add_child(_chat)
	return _scroll

func _build_input() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_input = LineEdit.new()
	_input.placeholder_text = "输入你的观点，回车或点发送…"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size = Vector2(0, 44)
	_input.clear_button_enabled = true
	_input.text_submitted.connect(_on_submit)
	row.add_child(_input)
	var send := Button.new()
	send.text = "发送"
	send.custom_minimum_size = Vector2(84, 44)
	send.pressed.connect(_on_send)
	row.add_child(send)
	return row

func _build_toolbar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_tool("难度", Callable(self, "_on_cycle_difficulty")))
	row.add_child(_make_tool("结算", Callable(self, "_on_settle")))
	row.add_child(_make_tool("导出", Callable(self, "_on_export")))
	row.add_child(_make_tool("重开", Callable(self, "_on_reset")))
	return row

func _on_cycle_difficulty() -> void:
	var opts := ["温和", "毒舌", "归谬狂魔"]
	engine.difficulty = (engine.difficulty + 1) % 3
	_app_toast("难度 → %s" % opts[engine.difficulty])

func _make_tool(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 36)
	b.pressed.connect(cb)
	return b

func _build_settle_panel() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.19)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	var title := Label.new()
	title.text = "本轮结算"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	title.add_theme_font_size_override("font_size", 22)
	inner.add_child(title)

	_settle_body = RichTextLabel.new()
	_settle_body.bbcode_enabled = true
	_settle_body.fit_content = true
	_settle_body.custom_minimum_size = Vector2(240, 0)
	inner.add_child(_settle_body)

	var close := Button.new()
	close.text = "继续 / 关闭"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(_on_close_settle)
	inner.add_child(close)

	return overlay

# ------------------------------------------------------------
#  消息气泡
# ------------------------------------------------------------
func _ai_say(msg: String) -> void:
	_add_bubble(msg, true)

func _say_player(msg: String) -> void:
	_add_bubble(msg, false)

func _add_bubble(text: String, is_ai: bool) -> void:
	if _chat.get_child_count() > MAX_LOG:
		_chat.remove_child(_chat.get_child(0))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	# 头像占位（窄条）
	var av := Label.new()
	av.text = "AI" if is_ai else "我"
	av.add_theme_font_size_override("font_size", 12)
	av.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	av.custom_minimum_size = Vector2(28, 0)
	av.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# 气泡
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	if is_ai:
		sb.bg_color = Color(0.17, 0.19, 0.25)
	else:
		sb.bg_color = Color(0.16, 0.42, 0.34)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	panel.add_child(body)
	var who := Label.new()
	who.text = "杠精 AI" if is_ai else "你"
	who.add_theme_font_size_override("font_size", 11)
	who.add_theme_color_override("font_color", Color(0.7, 0.7, 0.78))
	body.add_child(who)
	var msg := RichTextLabel.new()
	msg.bbcode_enabled = true
	msg.text = text
	msg.fit_content = true
	msg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# 约束气泡最大宽度，让长文本自动换行，不溢出屏幕
	var view_w := _scroll.size.x if _scroll != null else 720.0
	var max_w := maxf(220.0, view_w * 0.78)
	msg.custom_minimum_size = Vector2(180, 0)
	msg.custom_maximum_size = Vector2(max_w, 0)
	body.add_child(msg)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if is_ai:
		row.add_child(av)
		row.add_child(panel)
		row.add_child(spacer)
	else:
		row.add_child(spacer)
		row.add_child(panel)
		row.add_child(av)
	_chat.add_child(row)

	# 记入导出文本（去除 bbcode 标记）
	_transcript += ("[%s] %s：%s\n" % [_now(), ("杠精AI" if is_ai else "你"), _strip_bbcode(text)])

	# 自动滚动到底（用超过上限的值，让其钳制到最大）
	_scroll.set_deferred("scroll_vertical", 2147483647)

func _now() -> String:
	return Time.get_time_string_from_system().substr(0, 8)

func _strip_bbcode(s: String) -> String:
	var out := s
	out = out.replace("[b]", "").replace("[/b]", "")
	out = out.replace("[i]", "").replace("[/i]", "")
	# 去掉 [color=xxxx]...[/color]
	var re := RegEx.create_from_string("\\[/?color[^\\]]*\\]")
	if re != null and re.is_valid():
		out = re.sub(out, "", true)
	return out

# ------------------------------------------------------------
#  事件
# ------------------------------------------------------------
func _on_send() -> void:
	_submit(_input.text)
func _on_submit(text: String) -> void:
	_submit(text)

func _submit(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty():
		return
	_input.clear()
	_say_player(t)
	var r: Dictionary = engine.respond(t)
	_ai_say(str(r.get("text", "")))
	if r.get("hit", false):
		_app_toast("命中：" + str(r.get("tone", "")))
	_refresh_hud()
	if engine.should_end():
		_on_settle()

func _on_next_topic() -> void:
	var msg := engine.setup_topic()
	_ai_say(msg + "  " + KnowledgeBase.emoji("open"))
	_set_topic_label(engine.current_topic)
	_refresh_hud()

func _on_reset() -> void:
	engine.reset()
	engine.max_rounds = 12
	_chat.clear()
	_transcript = ""
	_refresh_hud()
	_ai_say("已重开。抛个观点——先来个新辩题。 🔄")
	var topic_msg := engine.setup_topic()
	_ai_say(topic_msg + "  " + KnowledgeBase.emoji("open"))
	_set_topic_label(engine.current_topic)

func _on_close_settle() -> void:
	_settle.visible = false

func _on_settle() -> void:
	var s: Dictionary = engine.settle()
	var verdict := str(s.get("verdict", ""))
	var verdict_text := str(s.get("text", ""))
	var icon := "⚖️"
	if verdict == "ai":
		icon = "🤖"
	elif verdict == "user":
		icon = "🏆"
	_settle_body.text = (
		"[color=#ffd98a][b]🏁 本轮结算[/b][/color]\n\n" +
		"[color=#a6b3d4]共进行回合[/color]  %d\n" % engine.round_count() +
		"[color=#a6b3d4]杠精 AI 抓到（命中谬误）[/color]  %d\n" % engine.ai_score() +
		"[color=#a6b3d4]你讲理得分（证据/结构）[/color]  %d\n" % engine.user_score() +
		"\n[color=#ff9a7a][b]%s 判定[/b][/color]  %s" % [icon, verdict_text]
	)
	_settle.visible = true

func _on_export() -> void:
	var path := "user://辩论记录_%s.md" % str(int(Time.get_unix_time_from_system()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_app_toast("导出失败：" + str(FileAccess.get_open_error()))
		return
	f.store_string("# 逻辑辩论记录\n\n" + _transcript)
	f.close()
	_app_toast("已导出到：" + path)

func _refresh_hud() -> void:
	_round_lbl.text = "回合 %d / %d" % [engine.round_count(), engine.max_rounds]
	_ai_bar.value = clampf(engine.ai_score() * 10.0, 0, 100)
	_user_bar.value = clampf(engine.user_score() * 10.0, 0, 100)

func _set_topic_label(t: String) -> void:
	_topic_lbl.text = "辩题：「%s」" % t

func _app_toast(msg: String) -> void:
	_ai_say("[b]▸ %s[/b]" % msg)
