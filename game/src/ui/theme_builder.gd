extends RefCounted
# Theme
## 现代扁平深色主题（VNShell 风格）：纯 StyleBoxFlat，无贴图依赖。
## 色板与交互规范对齐 VNShell ui_kit.gd。

# Palette
const BG := Color("#161a22")          # 页面背景（最深）
const PANEL := Color("#212734")       # 面板 / 按钮底色
const PANEL_HI := Color("#2b3345")    # 面板高亮态
const ACCENT := Color("#4a8cff")      # 主强调（蓝）
const ACCENT_2 := Color("#ff7a9c")    # 次强调（粉）
const TEXT := Color("#e8eaed")        # 正文字色
const DIM := Color("#8b93a3")         # 次要文字
const LOCKED := Color("#4a505e")      # 锁定灰
const OK := Color("#4ad991")          # 成功绿
const WARN := Color("#ffb454")        # 警示橙（理智/恐怖演出保留色）

static func build() -> Theme:
	var t := Theme.new()
	var font := _load_font()
	if font:
		t.default_font = font
	t.default_font_size = 26

	# ---- Button（hover 提亮 / pressed 压暗 / focus 描边 / disabled 灰）
	var b_norm := _sb(PANEL, 12)
	var b_hover := _sb(PANEL.lightened(0.12), 12)
	var b_press := _sb(PANEL.darkened(0.18), 12)
	var b_dis := _sb(LOCKED.darkened(0.3), 12)
	for s in [b_norm, b_hover, b_press, b_dis]:
		s.content_margin_left = 24
		s.content_margin_right = 24
		s.content_margin_top = 14
		s.content_margin_bottom = 14
	t.set_stylebox("normal", "Button", b_norm)
	t.set_stylebox("hover", "Button", b_hover)
	t.set_stylebox("pressed", "Button", b_press)
	t.set_stylebox("disabled", "Button", b_dis)
	t.set_stylebox("focus", "Button", _sb(Color.TRANSPARENT, 12, 3, ACCENT))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", DIM.darkened(0.3))
	t.set_font_size("font_size", "Button", 26)

	# ---- Panel
	t.set_stylebox("panel", "Panel", _sb(PANEL, 20))
	t.set_stylebox("panel", "PanelContainer", _sb(PANEL, 20))

	# ---- Labels
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 26)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 28)
	t.set_stylebox("normal", "RichTextLabel", _sb(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT))

	# ---- Scroll / Slider / Check
	t.set_stylebox("panel", "ScrollContainer", _sb(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT))
	var grabber := _sb(ACCENT.darkened(0.15), 6)
	t.set_stylebox("grabber_area", "VScrollBar", grabber)
	t.set_stylebox("grabber_area_highlight", "VScrollBar", _sb(ACCENT, 6))
	t.set_stylebox("scroll", "VScrollBar", _sb(Color(1, 1, 1, 0.08), 6))
	t.set_stylebox("slider", "HSlider", _sb(PANEL_HI, 6))
	t.set_stylebox("grabber_area", "HSlider", _sb(ACCENT.darkened(0.15), 6))
	t.set_stylebox("grabber_area_highlight", "HSlider", _sb(ACCENT, 6))
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_color", "CheckBox", TEXT)

	# ---- LineEdit（命名输入）
	t.set_stylebox("normal", "LineEdit", _sb(PANEL_HI, 12))
	t.set_stylebox("focus", "LineEdit", _sb(PANEL_HI, 12, 3, ACCENT))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", DIM)

	# ---- Popup
	t.set_stylebox("panel", "PopupPanel", _sb(PANEL, 20))
	return t

static func _sb(bg: Color, radius: int, bw: int = 0, border_color := Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.set_border_width_all(bw)
		s.border_color = border_color
	s.anti_aliasing = true
	return s

static func _load_font() -> Font:
	var candidates := [
		"res://assets/fonts/main.ttf", "res://assets/fonts/main.otf",
		"res://assets/fonts/NotoSerifSC.ttf",
	]
	for p in candidates:
		if ResourceLoader.exists(p):
			var f = load(p)
			if f is Font:
				return f
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray([
		"Noto Serif CJK SC", "Source Han Serif SC", "Songti SC", "SimSun",
		"Noto Sans CJK SC", "Source Han Sans SC", "Microsoft YaHei", "PingFang SC",
		"WenQuanYi Zen Hei", "Droid Sans Fallback", "sans-serif",
	])
	sf.allow_system_fallback = true
	sf.multichannel_signed_distance_field = false
	return sf
