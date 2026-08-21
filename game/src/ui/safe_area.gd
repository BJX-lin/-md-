extends MarginContainer
class_name SafeArea
## 刘海屏/挖孔屏安全区适配容器（移植自 VNShell，去掉外部单例依赖）。
##
## 核心：DisplayServer.get_display_safe_area() 返回物理像素，
## canvas_items 拉伸下 UI 用的是设计分辨率（本项目 1280x720），
## 必须按比例换算，否则高分辨率手机上边距会小得看不见。

var extra_left := 16
var extra_top := 16
var extra_right := 16
var extra_bottom := 16

func _ready() -> void:
	refresh()
	get_tree().root.size_changed.connect(refresh)

func _exit_tree() -> void:
	var root := get_tree().root if get_tree() else null
	if root and root.size_changed.is_connected(refresh):
		root.size_changed.disconnect(refresh)

func refresh() -> void:
	var m := compute_margins()
	add_theme_constant_override("margin_left", m.x)
	add_theme_constant_override("margin_top", m.y)
	add_theme_constant_override("margin_right", m.z)
	add_theme_constant_override("margin_bottom", m.w)

func compute_margins() -> Vector4i:
	var l := extra_left
	var t := extra_top
	var r := extra_right
	var b := extra_bottom
	var inset := get_safe_insets()
	l += inset.x
	t += inset.y
	r += inset.z
	b += inset.w
	return Vector4i(l, t, r, b)

## 四边安全区内缩（视口像素，已换算 stretch 缩放）
static func get_safe_insets() -> Vector4i:
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return Vector4i.ZERO
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4i.ZERO
	var raw_l := maxi(0, safe.position.x)
	var raw_t := maxi(0, safe.position.y)
	var raw_r := maxi(0, win.x - (safe.position.x + safe.size.x))
	var raw_b := maxi(0, win.y - (safe.position.y + safe.size.y))
	var vp := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))
	var sx := vp.x / float(win.x)
	var sy := vp.y / float(win.y)
	return Vector4i(int(raw_l * sx), int(raw_t * sy), int(raw_r * sx), int(raw_b * sy))

## 软键盘弹起高度（物理像素 → 视口像素）
static func keyboard_inset() -> int:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return 0
	var kh := DisplayServer.virtual_keyboard_get_height()
	if kh <= 0:
		return 0
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0
	var vp_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	return int(kh * vp_h / float(win.y))
