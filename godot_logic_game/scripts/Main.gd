extends Control

# ============================================================
# 主界面：Telegram 小飞机风格聊天气泡界面
# ------------------------------------------------------------
# - 顶部导航栏：返回箭头 + AI 圆形头像 + 名称/在线状态 + 更多（⋯）
# - 聊天区：浅色底图纹理；AI 气泡靠左（深灰蓝），玩家气泡靠右（绿）
#   圆形头像紧贴气泡；气泡右下角带时间戳
# - 底部：圆角输入框 + 蓝色纸飞机发送按钮；附加栏：换辩题 / 结算 / 导出 / 重开
# - 结算面板：显示回合、命中、讲理、胜负判定
# - 导出：把整段对话存到 user:// 下，可在手机上被访问
# ============================================================

const MAX_LOG := 400
const SEND_COOLDOWN_MS := 700   # 发送冷却，防连点/刷屏
const REPEAT_WINDOW_MS := 3000  # 同一句在窗口内重复则拦截

const IMG_SEND := "res://assets/send_plane.png"
const IMG_BACK := "res://assets/icon_back.png"
const IMG_LOGO := "res://assets/logo_tg.png"
const IMG_CHAT_BG := "res://assets/chat_bg.png"
const IMG_GAME := "res://assets/icon_game.png"

# 可选头像（4 个 AI / 5 个玩家），点击头像弹出面板挑选
const AV_AI := ["res://assets/avatar_ai_1.png", "res://assets/avatar_ai_2.png",
	"res://assets/avatar_ai_3.png", "res://assets/avatar_ai_4.png"]
const AV_USER := ["res://assets/avatar_user_1.png", "res://assets/avatar_user_2.png",
	"res://assets/avatar_user_3.png", "res://assets/avatar_user_4.png",
	"res://assets/avatar_user_5.png"]

# TG 配色
const COL_HEADER := Color(0.09, 0.13, 0.17)      # 顶部深海军蓝 #17212b
const COL_CHAT_BG := Color(0.07, 0.10, 0.15)     # 聊天底 #0e1621
const COL_AI_BUBBLE := Color(0.11, 0.15, 0.22)   # AI 深灰蓝 #1c2638
const COL_USER_BUBBLE := Color(0.22, 0.52, 0.36) # 玩家绿 #3a855c
const COL_ACCENT := Color(0.16, 0.67, 0.93)      # TG 蓝 #2AABEE
const COL_TEXT := Color(0.93, 0.94, 0.97)

var engine := DebateEngine.new()

# 防刷屏状态
var _last_send_ms := 0
var _last_text := ""
var _last_text_ms := 0

# 图片资源
var _tex_send: Texture2D
var _tex_back: Texture2D
var _tex_chat_bg: Texture2D
var _tex_game: Texture2D
var _ai_avatar_tex: Texture2D      # 当前 AI 头像（顶部/气泡用）
var _user_avatar_tex: Texture2D    # 当前玩家头像（气泡用）
var _ai_avatar_idx := 0
var _user_avatar_idx := 0

# UI 节点
var _chat: VBoxContainer        # 存放消息气泡
var _scroll: ScrollContainer
var _input: LineEdit
var _ai_bar: ProgressBar
var _user_bar: ProgressBar
var _round_lbl: Label
var _topic_lbl: Button
var _topic_detail := ""      # 辩题完整详情（含提示），展开时显示
var _topic_expanded := false  # 辩题是否展开
var _settle: Control            # 结算面板
var _settle_body: RichTextLabel
var _header_avatar: Button        # 顶栏 AI 头像，可点开换头像
var _avatar_panel: Control       # 头像选择弹层

# 存档文本（导出用）
var _transcript := ""

func _ready() -> void:
	_load_textures()
	_build_ui()
	engine.reset()
	engine.max_rounds = 12
	_refresh_hud()
	# 开场
	_ai_say("我是「杠精老师 · 逻辑裁判」。你抛观点，我用逻辑漏洞杠你；但你要是拿得出可核验的证据，我也认账让步。 🎬")
	var topic_msg := engine.setup_topic()
	_ai_say(topic_msg)
	_topic_detail = topic_msg
	_set_topic_label(engine.current_topic)
	_ai_say("示范：输入「大家都这么做，所以肯定是对的」。卡住就点「求助」，我教你反杀。")

func _load_textures() -> void:
	_tex_send = load(IMG_SEND) as Texture2D
	_tex_back = load(IMG_BACK) as Texture2D
	_tex_chat_bg = load(IMG_CHAT_BG) as Texture2D
	_tex_game = load(IMG_GAME) as Texture2D
	_ai_avatar_tex = load(AV_AI[_ai_avatar_idx]) as Texture2D
	_user_avatar_tex = load(AV_USER[_user_avatar_idx]) as Texture2D

# ------------------------------------------------------------
#  UI 构建
# ------------------------------------------------------------
func _build_ui() -> void:
	# 深色背景
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	root.offset_left = 0; root.offset_right = 0
	root.offset_top = 0; root.offset_bottom = 0
	add_child(root)

	root.add_child(_build_header())

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.offset_left = 8; body.offset_right = -8
	body.offset_top = 8; body.offset_bottom = -8
	root.add_child(body)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	body.add_child(_build_topic_bar())
	body.add_child(_build_status())
	body.add_child(_build_chat())
	body.add_child(_build_input())
	body.add_child(_build_toolbar())

	# 结算面板（覆盖层，默认隐藏）
	_settle = _build_settle_panel()
	add_child(_settle)

	# 头像选择弹层（覆盖层，默认隐藏）
	_avatar_panel = _build_avatar_panel()
	add_child(_avatar_panel)

func _make_style(bg_color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb

# 让 RichTextLabel 高度随内容自适应，避免在容器内换行后文本/时间戳重叠。
# fit_content 在嵌套容器里的高度测量会滞后/缓存，这里用 get_content_height()
# 在 resized（宽度变化触发重排）后刷新 custom_minimum_size.y 兜底。
func _fit_rl_height(rl: RichTextLabel) -> void:
	rl.fit_content = true
	rl.scroll_active = false
	var refresh := Callable(self, "_apply_rl_height").bind(rl)
	rl.resized.connect(refresh)
	refresh.call_deferred()

func _apply_rl_height(rl: RichTextLabel) -> void:
	if rl == null:
		return
	var h := rl.get_content_height()
	if h > 0:
		rl.custom_minimum_size.y = h

func _make_avatar(tex: Texture2D, size: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t

# 可点击头像按钮：外观即圆形头像，点击弹出选择面板
# open_on_click=true 用于聊天/顶栏头像；false 用于面板内（只选择，不弹面板）
func _make_avatar_btn(tex: Texture2D, size: int, role: String, open_on_click := true) -> Button:
	var b := Button.new()
	b.icon = tex
	b.expand_icon = true
	b.custom_minimum_size = Vector2(size, size)
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("focus", empty)
	b.set_meta("avatar_role", role)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if open_on_click:
		b.pressed.connect(func() -> void: _open_avatar_panel(role))
	return b

func _build_header() -> Control:
	# 顶部导航栏：整条深海军蓝，内 HBox 放返回/头像/名称/更多
	var hdr := PanelContainer.new()
	hdr.custom_minimum_size = Vector2(0, 62)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_HEADER
	sb.set_corner_radius_all(0)
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	hdr.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	hdr.add_child(row)

	# 返回箭头
	var back_btn := Button.new()
	back_btn.flat = true
	back_btn.custom_minimum_size = Vector2(36, 36)
	back_btn.icon = _tex_back
	back_btn.expand_icon = true
	back_btn.tooltip_text = "返回（重置本局）"
	back_btn.pressed.connect(_on_reset)
	row.add_child(back_btn)

		# AI 圆形头像（可点击换头像）
	_header_avatar = _make_avatar_btn(_ai_avatar_tex, 40, "ai")
	row.add_child(_header_avatar)

	# 名称 + 状态
	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", 0)
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_col)

	var name_lbl := Label.new()
	name_lbl.text = "杠精老师 · 逻辑裁判"
	name_lbl.add_theme_color_override("font_color", COL_TEXT)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_col.add_child(name_lbl)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 4)
	name_col.add_child(status_row)
	var dot := Label.new()
	dot.text = "●"
	dot.add_theme_color_override("font_color", Color(0.35, 0.78, 0.45))
	dot.add_theme_font_size_override("font_size", 12)
	status_row.add_child(dot)
	var status_lbl := Label.new()
	status_lbl.text = "online · 随时杠"
	status_lbl.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_row.add_child(status_lbl)

	# LOGO + 更多按钮（⋯）
	var more := Button.new()
	more.flat = true
	more.text = "⋮"
	more.custom_minimum_size = Vector2(36, 36)
	more.add_theme_font_size_override("font_size", 22)
	more.add_theme_color_override("font_color", COL_TEXT)
	more.tooltip_text = "更多"
	more.pressed.connect(func() -> void: _app_toast("长按「难度」切换毒舌等级；点「结算」回放战果。"))
	row.add_child(more)

	return hdr

func _build_topic_bar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var btn := Button.new()
	btn.text = "换辩题"
	btn.custom_minimum_size = Vector2(84, 32)
	btn.pressed.connect(_on_next_topic)
	row.add_child(btn)
	# 辩题改为可点击：默认收起显示名称，点击展开完整详情，再点收起
	_topic_lbl = Button.new()
	_topic_lbl.text = ""
	_topic_lbl.flat = true
	_topic_lbl.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_topic_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_topic_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_topic_lbl.add_theme_color_override("font_color", Color(0.95, 0.8, 0.5))
	_topic_lbl.pressed.connect(_on_toggle_topic)
	row.add_child(_topic_lbl)
	return row

func _build_status() -> Control:
	# 简洁状态条：回合数 + 双方论证强度细条
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	_round_lbl = Label.new()
	_round_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_round_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.82))
	_round_lbl.add_theme_font_size_override("font_size", 13)
	_round_lbl.custom_minimum_size = Vector2(140, 0)
	row.add_child(_round_lbl)

	row.add_child(_make_bar("杠精AI", Color(0.95, 0.62, 0.48), true))
	row.add_child(_make_bar("你", Color(0.5, 0.85, 0.7), false))
	return row

func _make_bar(label_text: String, color: Color, is_ai: bool) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 12)
	box.add_child(lbl)
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = 0
	bar.custom_minimum_size = Vector2(0, 10)
	box.add_child(bar)
	if is_ai:
		_ai_bar = bar
	else:
		_user_bar = bar
	return box

func _build_chat() -> Control:
	# 聊天容器：圆角背景 + 内嵌滚动区，铺 chat_bg 纹理并压暗
	var wrap := Control.new()
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var bg_rect := TextureRect.new()
	bg_rect.texture = _tex_chat_bg
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(bg_rect)

	var dim := ColorRect.new()
	dim.color = Color(COL_CHAT_BG.r, COL_CHAT_BG.g, COL_CHAT_BG.b, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(dim)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_left = 8; _scroll.offset_right = -8
	_scroll.offset_top = 8; _scroll.offset_bottom = -8
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_child(_scroll)

	_chat = VBoxContainer.new()
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat.add_theme_constant_override("separation", 10)
	_scroll.add_child(_chat)
	return wrap

func _build_input() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# 圆角输入框
	var field := PanelContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := _make_style(Color(0.12, 0.16, 0.22), 22, 10)
	field.add_theme_stylebox_override("panel", sb)

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	field.add_child(inner)
	_input = LineEdit.new()
	_input.placeholder_text = "输入你的观点…"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.flat = true
	_input.add_theme_color_override("font_color", COL_TEXT)
	_input.text_submitted.connect(_on_submit)
	inner.add_child(_input)

	row.add_child(field)

	# 蓝色纸飞机发送按钮（圆形）
	var send := Button.new()
	send.custom_minimum_size = Vector2(48, 44)
	send.icon = _tex_send
	send.expand_icon = true
	var sb_send := StyleBoxFlat.new()
	sb_send.bg_color = COL_ACCENT
	sb_send.set_corner_radius_all(24)
	sb_send.content_margin_left = 10
	sb_send.content_margin_right = 10
	sb_send.content_margin_top = 10
	sb_send.content_margin_bottom = 10
	send.add_theme_stylebox_override("normal", sb_send)
	send.add_theme_stylebox_override("hover", sb_send)
	send.add_theme_stylebox_override("pressed", sb_send)
	send.pressed.connect(_on_send)
	row.add_child(send)

	return row

func _build_toolbar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_tool("求助", Callable(self, "_on_hint")))
	row.add_child(_make_tool("难度", Callable(self, "_on_cycle_difficulty")))
	row.add_child(_make_tool("结算", Callable(self, "_on_settle")))
	row.add_child(_make_tool("导出", Callable(self, "_on_export")))
	row.add_child(_make_tool("重开", Callable(self, "_on_reset")))
	return row

func _on_hint() -> void:
	_ai_say(engine.hint())

func _on_cycle_difficulty() -> void:
	var opts := ["温和", "毒舌", "归谬狂魔"]
	engine.set_difficulty((engine.difficulty + 1) % 3)
	_app_toast("难度 → %s" % opts[engine.difficulty])

func _make_tool(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 38)
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
	panel.custom_minimum_size = Vector2(300, 0)
	var sb := _make_style(Color(0.12, 0.16, 0.22), 18, 22)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	var logo_center := CenterContainer.new()
	inner.add_child(logo_center)
	var logo := _make_avatar(_tex_game, 64)
	logo_center.add_child(logo)

	var title := Label.new()
	title.text = "本轮结算"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COL_TEXT)
	title.add_theme_font_size_override("font_size", 22)
	inner.add_child(title)

	_settle_body = RichTextLabel.new()
	_settle_body.bbcode_enabled = true
	_settle_body.fit_content = true
	_settle_body.scroll_active = false
	_settle_body.custom_minimum_size = Vector2(250, 0)
	inner.add_child(_settle_body)
	_fit_rl_height(_settle_body)

	var close := Button.new()
	close.text = "继续 / 关闭"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(_on_close_settle)
	inner.add_child(close)

	return overlay

# ------------------------------------------------------------
#  头像选择面板（点击头像弹出，分组更换）
# ------------------------------------------------------------
func _build_avatar_panel() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	# 点暗底关闭
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			overlay.visible = false)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	var sb := _make_style(Color(0.10, 0.14, 0.20), 20, 18)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	var title := Label.new()
	title.name = "_avatar_title"
	title.text = "选择头像"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COL_TEXT)
	title.add_theme_font_size_override("font_size", 20)
	inner.add_child(title)

	inner.add_child(_build_avatar_group("杠精老师", AV_AI, "ai"))
	inner.add_child(_build_avatar_group("你", AV_USER, "user"))

	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(func() -> void: overlay.visible = false)
	inner.add_child(close)

	return overlay

func _build_avatar_group(label_text: String, paths: Array, role: String) -> Control:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	lbl.add_theme_font_size_override("font_size", 14)
	group.add_child(lbl)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	group.add_child(grid)

	for p in paths:
		var idx := paths.find(p)
		var tex := load(p) as Texture2D
		var b := _make_avatar_btn(tex, 64, role, false)
		# 面板内点击仅选择头像，不再弹面板
		b.pressed.connect(func() -> void: _select_avatar(role, idx))
		grid.add_child(b)
	return group

func _select_avatar(role: String, idx: int) -> void:
	if role == "ai":
		_ai_avatar_idx = idx
		_ai_avatar_tex = load(AV_AI[idx]) as Texture2D
	else:
		_user_avatar_idx = idx
		_user_avatar_tex = load(AV_USER[idx]) as Texture2D
	# 更新顶栏头像（若是 AI）
	if _header_avatar != null and role == "ai":
		_header_avatar.icon = _ai_avatar_tex
	# 刷新已有气泡头像（遍历 _chat 的子行）
	_refresh_avatar_bubbles()
	_avatar_panel.visible = false
	_app_toast("已切换头像")

func _open_avatar_panel(role: String) -> void:
	# 打开面板，高亮当前打开所在分组（用于提示从哪进来的）
	var prompt := "选择头像"
	if role == "ai":
		prompt = "选择「杠精老师」的头像"
	elif role == "user":
		prompt = "选择「你」的头像"
	# 更新面板标题（若已构建）
	if _avatar_panel != null:
		_update_avatar_title(prompt)
	_avatar_panel.visible = true

func _update_avatar_title(text: String) -> void:
	# 遍历面板第一个 VBox 的 Label 标题
	if _avatar_panel == null:
		return
	var title := _avatar_panel.find_child("_avatar_title", true, false) as Label
	if title != null:
		title.text = text

func _refresh_avatar_bubbles() -> void:
	for child in _chat.get_children():
		if child is HBoxContainer:
			for c in child.get_children():
				if c is Button and c.has_meta("avatar_role"):
					var role := String(c.get_meta("avatar_role"))
					if role == "ai" and _ai_avatar_tex != null:
						c.icon = _ai_avatar_tex
					elif role == "user" and _user_avatar_tex != null:
						c.icon = _user_avatar_tex

# ------------------------------------------------------------
#  消息气泡（TG 风格）
# ------------------------------------------------------------
func _ai_say(msg: String) -> void:
	_add_bubble(msg, true)

func _say_player(msg: String) -> void:
	_add_bubble(msg, false)

# VBoxContainer 没有 clear()，用 queue_free 移除所有消息行
func _clear_chat() -> void:
	if _chat == null:
		return
	for child in _chat.get_children():
		_chat.remove_child(child)
		child.queue_free()

func _add_bubble(text: String, is_ai: bool) -> void:
	if _chat.get_child_count() > MAX_LOG:
		var old := _chat.get_child(0)
		_chat.remove_child(old)
		old.queue_free()

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)

	# 气泡最大宽度：优先用视口宽度
	var view_w := 720.0
	var vp := get_viewport()
	if vp != null:
		view_w = vp.get_visible_rect().size.x
	if _scroll != null:
		view_w = maxf(view_w, _scroll.size.x)
	var max_w := maxf(220.0, view_w * 0.72)
	var min_w := minf(max_w, maxf(170.0, view_w * 0.22))

	# 圆形头像（可点击换头像）
	var avatar_tex := _ai_avatar_tex if is_ai else _user_avatar_tex
	var avatar_role := "ai" if is_ai else "user"
	var avatar := _make_avatar_btn(avatar_tex, 40, avatar_role)

	# 气泡面板
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(min_w, 0)
	panel.custom_maximum_size = Vector2(max_w, 0)
	panel.add_theme_stylebox_override("panel", _make_style(
		COL_AI_BUBBLE if is_ai else COL_USER_BUBBLE, 16, 9))

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	panel.add_child(body)

	if is_ai:
		var who := Label.new()
		who.text = "杠精老师"
		who.add_theme_font_size_override("font_size", 12)
		who.add_theme_color_override("font_color", Color(0.62, 0.76, 0.95))
		body.add_child(who)

	var msg := RichTextLabel.new()
	msg.bbcode_enabled = true
	msg.text = text
	msg.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	msg.add_theme_color_override("default_color", COL_TEXT)
	body.add_child(msg)
	# 关键：在内容/宽度变化后刷新高度，避免文本与时间戳重叠
	_fit_rl_height(msg)

	var ts := Label.new()
	ts.text = _now()
	ts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ts.add_theme_font_size_override("font_size", 10)
	ts.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68))
	body.add_child(ts)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if is_ai:
		row.add_child(avatar)
		row.add_child(panel)
		row.add_child(spacer)
	else:
		row.add_child(spacer)
		row.add_child(panel)
		row.add_child(avatar)
	_chat.add_child(row)

	# 记入导出文本（去除 bbcode 标记）
	_transcript += ("[%s] %s：%s\n" % [_now(), ("杠精AI" if is_ai else "你"), _strip_bbcode(text)])

	# 自动滚动到底
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
	var now := Time.get_ticks_msec()
	# 发送冷却：短时间内连点/刷屏，柔和拦截
	if now - _last_send_ms < SEND_COOLDOWN_MS:
		_app_toast("稍等，别刷屏——想清楚再发。")
		return
	_last_send_ms = now
	# 重复文本限制：同一句在窗口内重复，拦截并提示换角度/求助
	if t == _last_text and now - _last_text_ms < REPEAT_WINDOW_MS:
		_app_toast("这句你刚发过。换个说法，或点「求助」。")
		return
	_last_text = t
	_last_text_ms = now
	_input.clear()
	_say_player(t)
	var r: Dictionary = engine.respond(t)
	var reply := str(r.get("text", ""))
	if reply.strip_edges().is_empty():
		# 兜底：即便引擎意外返回空，也保证 AI 有回应，不出现空气泡
		reply = KnowledgeBase.pick(KnowledgeBase.ATTACKS)
	_ai_say(reply)
	if r.get("hit", false):
		_app_toast("命中：" + str(r.get("tone", "")))
	_refresh_hud()
	if engine.should_end() or engine.should_early_end():
		_on_settle()

func _on_next_topic() -> void:
	var msg := engine.setup_topic()
	_ai_say(msg + "  " + KnowledgeBase.emoji("open"))
	_topic_detail = msg
	_topic_expanded = false
	_set_topic_label(engine.current_topic)
	_refresh_hud()

func _on_reset() -> void:
	engine.reset()
	engine.max_rounds = 12
	_clear_chat()
	_transcript = ""
	_refresh_hud()
	_ai_say("已重开。抛个观点——先来个新辩题。 🔄")
	var topic_msg := engine.setup_topic()
	_ai_say(topic_msg + "  " + KnowledgeBase.emoji("open"))
	_topic_detail = topic_msg
	_topic_expanded = false
	_set_topic_label(engine.current_topic)

func _on_close_settle() -> void:
	_settle.visible = false

func _on_settle() -> void:
	var s: Dictionary = engine.settle()
	var verdict := str(s.get("verdict", ""))
	var verdict_text := str(s.get("text", ""))
	var label := str(s.get("label", ""))
	var diff := int(s.get("diff", 0))
	var icon := "⚖️"
	if verdict == "ai":
		icon = "🤖"
	elif verdict == "user":
		icon = "🏆"
	var tip := KnowledgeBase.pick(KnowledgeBase.PRINCIPLES)
	var stage := engine.current_stage_label()
	var integrity := engine.integrity()
	var ai_integ := int(integrity.get("ai_integrity", 100))
	var p_integ := int(integrity.get("player_integrity", 100))
	var head := "[color=#ffd98a][b]🏁 本轮结算[/b][/color]\n\n"
	var stage_l := "[color=#a6b3d4]阶段[/color]  %s ｜ 共 %d 回合\n" % [stage, engine.round_count()]
	var ai_l := "[color=#ff9a7a][b]杠精 AI[/b][/color]  %d 次谬误 ｜ 强度 %d%%\n" % [
		engine.ai_score(), ai_integ]
	var user_l := "[color=#8fd3a6][b]你[/b][/color]  %d 次讲理 ｜ 强度 %d%%\n" % [
		engine.user_score(), p_integ]
	var trap_l := "[color=#a6b3d4]你掉陷阱[/color] %d 次 ｜ 差值 %d\n" % [engine.user_hits(), diff]
	var verdict_l := "\n[color=#ffd98a][b]%s 判定：%s[/b][/color]\n%s\n" % [icon, label, verdict_text]
	var how_l := "\n[color=#a6b3d4]怎么赢：多给「主张+理由+可核验证据」，并针对攻击点有效反击。[/color]\n"
	var tip_l := "\n[color=#8fd3a6]复盘：%s[/color]" % tip
	_settle_body.text = head + stage_l + ai_l + user_l + trap_l + verdict_l + how_l + tip_l
	_settle.visible = true

func _on_export() -> void:
	var em := ExportManager.new()
	var path := em.export_transcript(_transcript)
	if path.is_empty():
		_app_toast("导出失败：" + str(FileAccess.get_open_error()))
		return
	_app_toast("已导出到：" + path)

func _refresh_hud() -> void:
	var ai := engine.ai_score()
	var us := engine.user_score()
	var integ := engine.integrity()
	var pi := int(integ.get("player_integrity", 100))
	var ai_integ := int(integ.get("ai_integrity", 100))
	_round_lbl.text = "回合 %d/%d ｜ %s ｜ 强度 你%d AI%d" % [
		engine.round_count(), engine.max_rounds, engine.current_stage_label(), pi, ai_integ]
	_ai_bar.value = clampf(ai_integ, 0, 100)
	_user_bar.value = clampf(pi, 0, 100)

func _set_topic_label(t: String) -> void:
	if _topic_lbl == null:
		return
	# 收起状态：只显示辩题名，点击展开完整详情
	_topic_lbl.text = "辩题：「%s」  ⌄" % t

func _on_toggle_topic() -> void:
	if _topic_lbl == null:
		return
	_topic_expanded = not _topic_expanded
	if _topic_expanded and _topic_detail != "":
		# 展开：显示完整详情（辩题 + 提示/出处/技战法）
		_topic_lbl.text = _topic_detail + "  ⌃"
	else:
		# 收起
		_topic_lbl.text = "辩题：「%s」  ⌄" % engine.current_topic

func _app_toast(msg: String) -> void:
	_ai_say("[b]▸ %s[/b]" % msg)
