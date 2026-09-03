extends Control

# ============================================================
# 主界面：搭建 UI + 把用户输入送给离线辩论引擎
# ------------------------------------------------------------
# 纯代码构建 UI，不依赖 .tscn 里的复杂节点，方便手机端运行。
# 技能要点：
#   - LineEdit 在手机上自动唤起虚拟键盘
#   - RichTextLabel scroll_following 自动滚到最底
# ============================================================

var engine := DebateEngine.new()

# UI 节点
var _log: RichTextLabel
var _input: LineEdit
var _ai_vis: ProgressBar
var _user_vis: ProgressBar
var _status: Label

func _ready() -> void:
	_build_ui()
	# 0 号播放器是"杠精AI"
	engine.reset()
	_app_say("我是「杠精老师 · 逻辑裁判」。你输入任何观点/论证，我用逻辑漏洞来杠你。" )
	_app_say("示范：试试输入一句「大家都这么做，所以肯定是对的」。" )
	_refresh_hud()

# ------------------------------------------------------------
#  UI 构建
# ------------------------------------------------------------
func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.11, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.offset_left = 12
	root.offset_right = -12
	root.offset_top = 16
	root.offset_bottom = -12
	add_child(root)

	# 标题
	var title := Label.new()
	title.text = "逻辑辩论 · 文字博弈"
	title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.98))
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)

	# 计分板
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 10)
	root.add_child(score_row)

	var ai_box := VBoxContainer.new()
	var ai_lbl := Label.new()
	ai_lbl.text = "杠精 AI"
	ai_lbl.add_theme_color_override("font_color", Color(0.95, 0.6, 0.5))
	ai_box.add_child(ai_lbl)
	_ai_vis = ProgressBar.new()
	_ai_vis.max_value = 100.0
	_ai_vis.value = 0
	_ai_vis.custom_minimum_size = Vector2(0, 14)
	ai_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_box.add_child(_ai_vis)
	score_row.add_child(ai_box)

	var user_box := VBoxContainer.new()
	var user_lbl := Label.new()
	user_lbl.text = "玩家"
	user_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 0.7))
	user_box.add_child(user_lbl)
	_user_vis = ProgressBar.new()
	_user_vis.max_value = 100.0
	_user_vis.value = 0
	_user_vis.custom_minimum_size = Vector2(0, 14)
	user_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	user_box.add_child(_user_vis)
	score_row.add_child(user_box)

	_status = Label.new()
	_status.text = "回合：0"
	_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	score_row.add_child(_status)

	# 对话记录区
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.fit_content = true
	_log.custom_minimum_size = Vector2(0, 300)
	scroll.add_child(_log)

	# 输入区
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	root.add_child(input_row)

	_input = LineEdit.new()
	_input.placeholder_text = "输入你的观点，回车或点发送…"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.minimum_size = Vector2(0, 48)
	_input.clear_button_enabled = true
	_input.text_submitted.connect(_on_submit)
	input_row.add_child(_input)

	var btn := Button.new()
	btn.text = "发送"
	btn.custom_minimum_size = Vector2(90, 48)
	btn.pressed.connect(_on_send)
	input_row.add_child(btn)

	# 难度调节
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 8)
	root.add_child(diff_row)

	var d_lbl := Label.new()
	d_lbl.text = "难度："
	diff_row.add_child(d_lbl)
	var d_var := OptionButton.new()
	d_var.add_item("温和", 0)
	d_var.add_item("毒舌", 1)
	d_var.add_item("归谬狂魔", 2)
	d_var.selected = 0
	d_var.item_selected.connect(_on_difficulty_selected)
	diff_row.add_child(d_var)

	diff_row.add_child(_make_sep())

	var reset := Button.new()
	reset.text = "重开"
	reset.pressed.connect(_on_reset)
	diff_row.add_child(reset)

# 简单分隔占位
func _make_sep() -> Control:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(10, 0)
	return sp

# ------------------------------------------------------------
#  事件
# ------------------------------------------------------------
func _on_difficulty_selected(idx: int) -> void:
	engine.difficulty = idx
	var names := ["温和", "毒舌", "归谬狂魔"]
	_app_say("（难度切换为：%s）" % names[idx])

func _on_send() -> void:
	_submit(_input.text)

func _on_submit(text: String) -> void:
	_submit(text)

func _submit(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty():
		return
	_input.clear()
	# 玩家的话上屏（右对齐样式，简单用颜色区分）
	_app_say_player("[b]你：[/b] %s" % t)
	# 交给引擎
	var r: Dictionary = engine.respond(t)
	_show_engine_response(r)
	_refresh_hud()

func _on_reset() -> void:
	engine.reset()
	_log.clear()
	_app_say("已重置。再来一轮吧——抛个观点给我。" )
	_refresh_hud()

# ------------------------------------------------------------
#  显示
# ------------------------------------------------------------
func _app_say(msg: String) -> void:
	_log.append_text("[color=#9fb0d0][i]%s[/i][/color]\n" % msg)

func _app_say_player(msg: String) -> void:
	_log.append_text("%s\n" % msg)

func _show_engine_response(r: Dictionary) -> void:
	var tone: String = r.get("tone", "")
	var hit: bool = r.get("hit", false)
	var text: String = r.get("text", "")
	var tag: String = r.get("tag", "")

	if hit:
		_log.append_text("[color=#ff9a7a][b]【%s】[/b] %s[/color]\n" % [tone, tag])
	_log.append_text("[color=#f2f2fa]%s[/color]\n" % text)

func _refresh_hud() -> void:
	_status.text = "回合：%d" % engine.round_count()
	# 分数映射到进度条（分数越高越强）
	_ai_vis.value = clampf(engine.ai_score() * 10.0, 0, 100)
	_user_vis.value = clampf(engine.user_score() * 10.0, 0, 100)
