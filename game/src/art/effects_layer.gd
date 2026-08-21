extends Control
class_name EffectsLayer
# Name

signal shake_offset(offset: Vector2)

var _effects: Array = []          # {type, t, dur, power}
var _t := 0.0
var _static_seed := 0
var _was_active := false
var _names_overlay: Array = []  # Name

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(true)

func play(name: String, power: float = 1.0) -> void:
	var dur := 0.6
	match name:
		"shake": dur = 0.5
		"bigshake": dur = 1.1
		"flash": dur = 0.35
		"redflash": dur = 0.5
		"glitch": dur = 0.9
		"static": dur = 1.2
		"blood": dur = 2.4
		"bloodburst": dur = 1.6
		"fog": dur = 4.0
		"heartbeat": dur = 3.0
		"names": dur = 3.2
		"darken": dur = 2.0
		"whiteout": dur = 1.4
		"scanlines": dur = 2.5
		"crack": dur = 1.8
		"handprint": dur = 3.0
		"eyes": dur = 2.6
		"rewind": dur = 1.5
	if name in ["shake", "bigshake"] and not bool(SaveSystem.settings.get("screen_shake", true)):
		return
	if name in ["flash", "whiteout", "redflash"] and not bool(SaveSystem.settings.get("flash", true)):
		power *= 0.25
	if name in ["blood", "bloodburst", "handprint"] and SaveSystem.gore_level() == 0:
		return
	if name in ["blood", "bloodburst"] and SaveSystem.gore_level() == 1:
		power *= 0.5
	_effects.append({"type": name, "t": 0.0, "dur": dur, "power": power})
	match name:
		"shake": AudioDirector.play_sfx("sfx_low_boom", 0.5)
		"bigshake": AudioDirector.play_sfx("sfx_low_boom", 1.0)
		"glitch": AudioDirector.play_sfx("sfx_broadcast_static", 0.7)
		"static": AudioDirector.play_sfx("sfx_broadcast_static", 0.9)
		"heartbeat": AudioDirector.play_sfx("sfx_heartbeat", 0.9)
		"bloodburst": AudioDirector.play_sfx("sfx_flesh", 1.0)
		"rewind": AudioDirector.play_sfx("sfx_rewind", 0.8)
		"names": AudioDirector.play_sfx("sfx_whisper", 0.8)
	if name == "names":
		_names_overlay = ["沈禾", "沈禾（删除）", "林昼（补）", "林昼（待定）", "梁野", "周叙", "第109次"]

func _process(delta: float) -> void:
	_t += delta
	var off := Vector2.ZERO
	var i := _effects.size() - 1
	while i >= 0:
		var e: Dictionary = _effects[i]
		e["t"] = float(e["t"]) + delta
		var f: float = float(e["t"]) / float(e["dur"])
		if f >= 1.0:
			_effects.remove_at(i)
		else:
			var p: float = float(e["power"]) * (1.0 - f)
			match String(e["type"]):
				"shake":
					off += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 9.0 * p
				"bigshake":
					off += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 26.0 * p
				"glitch":
					off += Vector2(randf_range(-1, 1) * 5.0 * p, 0)
		i -= 1
	# Perf
	# Conditions

	var active := not _effects.is_empty()
	if active or _was_active:
		shake_offset.emit(off)
		_static_seed = int(_t * 24.0)
		queue_redraw()
	_was_active = active

func has_active() -> bool:
	return not _effects.is_empty()

func _draw() -> void:
	var s := size
	for e in _effects:
		var f: float = float(e["t"]) / float(e["dur"])
		var p: float = float(e["power"])
		match String(e["type"]):
			"flash":
				draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, (1.0 - f) * 0.75 * p))
			"whiteout":
				var a: float = (1.0 - absf(f - 0.35) / 0.65) * p
				draw_rect(Rect2(Vector2.ZERO, s), Color(0.95, 0.95, 0.92, clampf(a, 0.0, 0.95)))
			"redflash":
				draw_rect(Rect2(Vector2.ZERO, s), Color(0.6, 0.05, 0.04, (1.0 - f) * 0.55 * p))
			"darken":
				draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, sin(PI * f) * 0.8 * p))
			"static":
				_draw_static(s, (1.0 - f) * p)
			"scanlines":
				_draw_scanlines(s, (1.0 - f) * p)
			"glitch":
				_draw_glitch(s, (1.0 - f) * p)
			"blood":
				_draw_blood_veil(s, (1.0 - f) * p, false)
			"bloodburst":
				_draw_blood_veil(s, (1.0 - f) * p, true)
			"fog":
				_draw_fog(s, sin(PI * f) * p)
			"heartbeat":
				_draw_heartbeat(s, f, p)
			"names":
				_draw_names(s, f, p)
			"crack":
				_draw_crack(s, f, p)
			"handprint":
				_draw_handprint(s, f, p)
			"eyes":
				_draw_eyes(s, f, p)
			"rewind":
				_draw_rewind(s, f, p)

func _draw_static(s: Vector2, a: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _static_seed
	for i in 700:
		var x := rng.randf() * s.x
		var y := rng.randf() * s.y
		draw_rect(Rect2(x, y, 3, 2), Color(0.85, 0.87, 0.85, rng.randf() * 0.35 * a))

func _draw_scanlines(s: Vector2, a: float) -> void:
	var y := 0.0
	while y < s.y:
		draw_rect(Rect2(0, y, s.x, 1.5), Color(0, 0, 0, 0.18 * a))
		y += 4.0
	var band := fmod(_t * 0.35, 1.0) * s.y
	draw_rect(Rect2(0, band, s.x, 26), Color(0.7, 0.9, 0.85, 0.05 * a))

func _draw_glitch(s: Vector2, a: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _static_seed * 7
	for i in 12:
		var y := rng.randf() * s.y
		var h := rng.randf_range(4, 34)
		var dx := rng.randf_range(-40, 40) * a
		draw_rect(Rect2(dx, y, s.x, h), Color(0.9, 0.2, 0.2, 0.06 * a))
		draw_rect(Rect2(-dx, y + 3, s.x, h), Color(0.2, 0.9, 0.85, 0.06 * a))

func _draw_blood_veil(s: Vector2, a: float, burst: bool) -> void:
	var lv := SaveSystem.gore_level()
	if lv == 0:
		return
	var col: Color = Cfg.PALETTE["blood_bright"]

	for i in 20:
		var f := float(i) / 20.0
		draw_rect(Rect2(0, 0, s.x, s.y * 0.06 * (1.0 - f)), Color(col.r, col.g * 0.4, col.b * 0.4, 0.05 * a))
		draw_rect(Rect2(0, s.y - s.y * 0.06 * (1.0 - f), s.x, s.y * 0.06 * (1.0 - f)), Color(col.r, col.g * 0.4, col.b * 0.4, 0.05 * a))
	if burst:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1234
		var n := 40 if lv == 2 else 16
		for i in n:
			var c := Vector2(rng.randf() * s.x, rng.randf() * s.y)
			var r := rng.randf_range(8, 46) * a
			draw_circle(c, r, Color(col.r, 0.05, 0.05, 0.55 * a))
			if lv == 2:
				draw_rect(Rect2(c.x - r * 0.14, c.y, r * 0.28, r * rng.randf_range(1.0, 4.0)), Color(col.r * 0.8, 0.04, 0.04, 0.4 * a))

func _draw_fog(s: Vector2, a: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 26:
		var bx := fmod(rng.randf() * s.x + _t * rng.randf_range(4.0, 16.0), s.x + 300.0) - 150.0
		var by := rng.randf() * s.y
		var r := rng.randf_range(80.0, 260.0)
		draw_circle(Vector2(bx, by), r, Color(0.66, 0.70, 0.72, 0.022 * a))

func _draw_heartbeat(s: Vector2, f: float, p: float) -> void:
	var beat: float = pow(maxf(0.0, sin(f * PI * 6.0)), 6.0)
	var a := beat * 0.42 * p
	var steps := 12
	for i in steps:
		var t := float(i) / steps
		var m := s * 0.5 * (0.5 + t * 0.5)
		draw_rect(Rect2(0, 0, s.x, m.y * 0.4), Color(0.35, 0.02, 0.02, a * 0.1))
		draw_rect(Rect2(0, s.y - m.y * 0.4, s.x, m.y * 0.4), Color(0.35, 0.02, 0.02, a * 0.1))

func _draw_names(s: Vector2, f: float, p: float) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	for i in _names_overlay.size():
		var txt := String(_names_overlay[i])
		var x := rng.randf_range(0.05, 0.7) * s.x
		var y := rng.randf_range(0.12, 0.9) * s.y
		var local_f: float = clampf((f - i * 0.06) * 1.6, 0.0, 1.0)
		var a := sin(PI * local_f) * 0.5 * p
		var sz := int(rng.randf_range(26, 58))
		font.draw_string(get_canvas_item(), Vector2(x, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0.85, 0.85, 0.82, a))

func _draw_crack(s: Vector2, f: float, p: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31337
	var origin := Vector2(s.x * 0.5, s.y * 0.42)
	var a := clampf(f * 3.0, 0.0, 1.0) * p * 0.6
	for i in 14:
		var ang := rng.randf() * TAU
		var pt := origin
		var len_ := rng.randf_range(60.0, s.x * 0.5) * clampf(f * 2.0, 0.0, 1.0)
		var steps := 6
		for k in steps:
			var np := pt + Vector2(cos(ang), sin(ang)) * (len_ / steps)
			draw_line(pt, np, Color(0.85, 0.88, 0.9, a), maxf(0.6, 2.5 - k * 0.3))
			ang += rng.randf_range(-0.35, 0.35)
			pt = np

func _draw_handprint(s: Vector2, f: float, p: float) -> void:
	if SaveSystem.gore_level() == 0:
		return
	var col: Color = Cfg.PALETTE["blood"]
	var a := sin(PI * clampf(f * 1.2, 0.0, 1.0)) * p * 0.75
	var c := Vector2(s.x * 0.72, s.y * 0.44)
	var scale := s.y * 0.16
	draw_circle(c, scale * 0.42, Color(col.r, col.g, col.b, a))
	for i in 5:
		var ang := -PI * 0.85 + i * 0.42
		var tip := c + Vector2(cos(ang), sin(ang)) * scale * 0.75
		draw_line(c, tip, Color(col.r, col.g, col.b, a), scale * 0.16)
		draw_circle(tip, scale * 0.09, Color(col.r, col.g, col.b, a))

func _draw_eyes(s: Vector2, f: float, p: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var a := sin(PI * f) * 0.5 * p
	for i in 9:
		var c := Vector2(rng.randf() * s.x, rng.randf() * s.y * 0.85)
		var r := rng.randf_range(6.0, 15.0)
		draw_circle(c, r, Color(0.9, 0.9, 0.88, a * 0.5))
		draw_circle(c, r * 0.42, Color(0.05, 0.05, 0.06, a))

func _draw_rewind(s: Vector2, f: float, p: float) -> void:
	var a := (1.0 - f) * p
	var y := 0.0
	while y < s.y:
		var dx := sin((y / s.y) * 40.0 + _t * 30.0) * 12.0 * a
		draw_rect(Rect2(dx, y, s.x, 2.0), Color(0.8, 0.9, 0.88, 0.08 * a))
		y += 7.0
	_draw_static(s, a * 0.6)
