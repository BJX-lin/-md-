extends Control
class_name LoadingOverlay

# State
# Chapters
# Chapters

signal finished

const STAGE_TEXT := {
	"release": "正在释放性能…",
	"preload": "正在载入后续场景…",
	"settle": "正在整理记忆…",
	"done": "完成",
}

var _paths: Array[String] = []
var _idx := 0
var _released := 0
var _t := 0.0
var _stage := "release"
var _min_time := 0.9
var _elapsed := 0.0
var _done := false

var _panel: PanelContainer
var _hint: Label  # State
var _detail: Label
var _bar: ProgressBar

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # Story
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0.0
	offset_bottom = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	set_process(true)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.075, 0.96)
	sb.border_color = Color(0.46, 0.42, 0.38, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var grain := UITex.get_tex("panel_frame")
	if grain != null:
		var holder := CenterContainer.new()
		holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := TextureRect.new()
		tr.texture = grain
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color(1, 1, 1, 0.26)

		_panel.resized.connect(func():
			tr.custom_minimum_size = _panel.size
			tr.size = _panel.size)
		holder.add_child(tr)
		add_child(holder)
		move_child(holder, _panel.get_index())

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size.x = 520
	_panel.add_child(v)

	# State
	_hint = Label.new()
	_hint.text = STAGE_TEXT["release"]
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(0.88, 0.86, 0.80))
	v.add_child(_hint)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.value = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(520, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.62, 0.58, 0.50)
	fill.set_corner_radius_all(2)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.16, 0.16, 0.19)
	bg.set_corner_radius_all(2)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", bg)
	v.add_child(_bar)

	_detail = Label.new()
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.add_theme_font_size_override("font_size", 14)
	_detail.add_theme_color_override("font_color", Color(0.58, 0.56, 0.54))
	v.add_child(_detail)

# Chapters
func begin(chapter: int, keep_paths: Array[String] = []) -> void:
	# Chapters
	_stage = "release"
	_released = ArtCache.release_stale(chapter, keep_paths)

	_paths = ArtCache.paths_for_chapter(chapter)
	_idx = 0
	for p in _paths:
		ResourceLoader.load_threaded_request(p)
	if _paths.is_empty():
		_stage = "settle"

func _process(delta: float) -> void:
	_t += delta
	_elapsed += delta
	if _done:
		return

	var ratio := 1.0 if _paths.is_empty() else float(_idx) / float(_paths.size())
	_bar.value = lerpf(_bar.value, ratio * 100.0, clampf(delta * 8.0, 0.0, 1.0))

	match _stage:
		"release":
			_detail.text = "已释放 %d 项过场资源" % _released
			if _elapsed > 0.28:
				_stage = "preload" if not _paths.is_empty() else "settle"
		"preload":

			var budget := 3
			while _idx < _paths.size() and budget > 0:
				var p := _paths[_idx]
				var st := ResourceLoader.load_threaded_get_status(p)
				if st == ResourceLoader.THREAD_LOAD_LOADED:
					ArtCache.put(p, ResourceLoader.load_threaded_get(p))
					_idx += 1
					budget -= 1
				elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
					_idx += 1
					budget -= 1
				else:
					break
			_hint.text = STAGE_TEXT["preload"]
			_detail.text = "%d / %d" % [_idx, _paths.size()]
			if _idx >= _paths.size():
				_stage = "settle"
		"settle":
			_hint.text = STAGE_TEXT["settle"]
			_detail.text = "已释放 %d 项，已预载 %d 项" % [_released, _idx]
			_bar.value = 100.0
			if _elapsed >= _min_time:
				_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	_hint.text = STAGE_TEXT["done"]
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func():
		finished.emit()
		queue_free()
	)
