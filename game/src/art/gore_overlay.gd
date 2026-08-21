extends Control
class_name GoreOverlay
# UI

# FX
# UI
# Text

# UI

const MAX_MARKS := 14

var _marks: Array = []      # {kind, pos, scale, rot, age, life, seed}
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(true)

func enabled() -> bool:
	return SaveSystem.gore_level() >= 2

## kind: handprint / smear / drip / edge / crack
func add_mark(kind: String, power: float = 1.0) -> void:
	if not enabled():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pos := Vector2(randf_range(0.12, 0.88), randf_range(0.16, 0.78))

	if kind == "handprint":
		pos.x = randf_range(0.08, 0.30) if randf() < 0.5 else randf_range(0.70, 0.92)
		pos.y = randf_range(0.22, 0.62)
	_marks.append({
		"kind": kind, "pos": pos,
		"scale": randf_range(0.8, 1.35) * clampf(power, 0.4, 1.6),
		"rot": randf_range(-0.5, 0.5),
		"age": 0.0, "life": randf_range(26.0, 52.0),
		"seed": rng.randi(),
	})
	while _marks.size() > MAX_MARKS:
		_marks.pop_front()
	queue_redraw()

func clear_marks() -> void:
	_marks.clear()
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _marks.is_empty():
		return
	if not enabled():
		_marks.clear()
		queue_redraw()
		return
	var i := _marks.size() - 1
	while i >= 0:
		_marks[i]["age"] = float(_marks[i]["age"]) + delta
		if float(_marks[i]["age"]) >= float(_marks[i]["life"]):
			_marks.remove_at(i)
		i -= 1
	queue_redraw()

func _draw() -> void:
	if not enabled() or _marks.is_empty():
		return
	var s := size
	if s.x <= 1.0 or s.y <= 1.0:
		return
	for m in _marks:
		var age := float(m["age"])
		var life := float(m["life"])
		var f := age / life
		# Time
		var alpha := (f / 0.08) if f < 0.08 else (1.0 - (f - 0.08) / 0.92)
		alpha = clampf(alpha, 0.0, 1.0) * 0.82
		if alpha <= 0.01:
			continue

		var wet: float = clampf(1.0 - f * 1.4, 0.0, 1.0)
		var col := Color(0.52, 0.06, 0.06).lerp(Color(0.24, 0.07, 0.05), 1.0 - wet)
		col.a = alpha
		var c := Vector2(float(m["pos"].x) * s.x, float(m["pos"].y) * s.y)
		var sc := float(m["scale"]) * s.y * 0.16
		match String(m["kind"]):
			"handprint": _draw_hand(c, sc, float(m["rot"]), col, int(m["seed"]))
			"smear": _draw_smear(c, sc, float(m["rot"]), col, int(m["seed"]))
			"drip": _draw_drip(c, sc, col, int(m["seed"]), f)
			"edge": _draw_edge(s, col, int(m["seed"]))
			"crack": _draw_crack(c, sc, col, int(m["seed"]))

func _draw_hand(c: Vector2, sc: float, rot: float, col: Color, sd: int) -> void:
	var tex := UITex.get_tex("handprint")
	if tex != null:
		var w := sc * 2.6
		draw_set_transform(c, rot, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-Vector2(w, w) * 0.5, Vector2(w, w)), false, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = sd

	var palm := sc * 0.40
	draw_circle(c, palm, col)
	draw_circle(c + Vector2(0, palm * 0.42), palm * 0.86, col)

	for i in 5:
		var base_a := -PI * 0.92 + i * 0.40 + rot
		var flen: float = sc * (0.78 if i != 0 else 0.60)
		var tip := c + Vector2(cos(base_a), sin(base_a)) * flen
		var w := sc * (0.155 if i != 0 else 0.185)
		draw_line(c + Vector2(cos(base_a), sin(base_a)) * palm * 0.7, tip, col, w)
		draw_circle(tip, w * 0.56, col)

	for i in 7:
		var a := rng.randf() * TAU
		var d := sc * rng.randf_range(0.5, 1.0)
		var c2 := Color(col.r, col.g, col.b, col.a * rng.randf_range(0.3, 0.7))
		draw_circle(c + Vector2(cos(a), sin(a)) * d, sc * rng.randf_range(0.02, 0.06), c2)

func _draw_smear(c: Vector2, sc: float, rot: float, col: Color, sd: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var dir := Vector2(cos(rot), sin(rot) * 0.35)
	var n := 16
	for i in n:
		var t := float(i) / n
		var p := c + dir * sc * 2.2 * t
		var r := sc * 0.30 * (1.0 - t * 0.85)
		var c2 := Color(col.r, col.g, col.b, col.a * (1.0 - t * 0.75))
		draw_circle(p, maxf(1.0, r), c2)
		if rng.randf() < 0.35:
			draw_circle(p + Vector2(rng.randf_range(-6, 6), rng.randf_range(-4, 4)),
				maxf(1.0, r * 0.35), c2)

func _draw_drip(c: Vector2, sc: float, col: Color, sd: int, f: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	draw_circle(c, sc * 0.22, col)
	# Time
	var n := 3 + (sd % 3)
	for i in n:
		var ox := rng.randf_range(-sc * 0.22, sc * 0.22)
		var len_ := sc * rng.randf_range(0.6, 2.4) * clampf(f * 3.0, 0.15, 1.0)
		var w := sc * rng.randf_range(0.05, 0.11)
		draw_rect(Rect2(c.x + ox - w * 0.5, c.y, w, len_), col)
		draw_circle(Vector2(c.x + ox, c.y + len_), w * 0.75, col)

func _draw_edge(s: Vector2, col: Color, sd: int) -> void:

	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var band := s.y * 0.07
	for i in 26:
		var x := rng.randf() * s.x
		var h := band * rng.randf_range(0.25, 1.0)
		var w := s.x * rng.randf_range(0.01, 0.045)
		var c2 := Color(col.r, col.g, col.b, col.a * rng.randf_range(0.25, 0.6))
		draw_rect(Rect2(x, 0, w, h), c2)
		draw_rect(Rect2(x, s.y - h, w, h), c2)

func _draw_crack(c: Vector2, sc: float, col: Color, sd: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for i in 9:
		var a := rng.randf() * TAU
		var p := c
		var seg := 5
		for k in seg:
			var np := p + Vector2(cos(a), sin(a)) * (sc * 0.6 / seg)
			var c2 := Color(col.r, col.g, col.b, col.a * (1.0 - float(k) / seg) * 0.8)
			draw_line(p, np, c2, maxf(0.8, sc * 0.035 * (1.0 - float(k) / seg)))
			a += rng.randf_range(-0.45, 0.45)
			p = np
