extends Control
class_name BGLayer
# Background
# Draw
# Background
##   res://assets/bg/<file_name>.png

# Engine

const BG_ROOT := "res://assets/bg"

var scene_id := "black"
var variant := ""
var flicker := 0.0
var blood_amount := 0.0
var wet := 0.0

var _tex: Texture2D = null
var _t := 0.0
var _cur_key := ""
var _cur_tex_path := ""

# Background
const BG_MAP := {
	"office": {
		"": ["office_day"], "day": ["office_day"], "dusk": ["office_day"],
		"night": ["office_night_lamp", "office_night", "office_day"],
		"dark": ["office_night_lamp", "office_night", "office_day"],
		"lamp": ["office_night_lamp", "office_night"],
		"dawn": ["office_dawn", "office_night"],
	},
	"classroom": {
		"": ["classroom_day", "classroom_evening"],
		"day": ["classroom_day", "classroom_evening"],
		"rollcall_day": ["classroom_day_rollcall", "classroom_day"],
		"morning": ["classroom_morning", "classroom_day"],
		"dawn": ["classroom_empty_dawn", "classroom_morning"],
		"empty": ["classroom_empty_dawn", "classroom_evening_missingseat"],
		"dusk": ["classroom_evening", "classroom_day"],
		"rain": ["classroom_evening_rain", "classroom_evening", "classroom_day"],
		"night": ["classroom_evening_alllook", "classroom_evening"],
		"reflection": ["classroom_window_reflection", "classroom_evening"],
		"rollcall": ["classroom_window_reflection", "classroom_evening"],
		"dark": ["classroom_evening_alllook", "classroom_evening"],
		"blood": ["classroom_evening_missingseat", "classroom_evening"],
	},
	"hallway": {
		"": ["hallway_day", "hallway_night"],
		"day": ["hallway_day", "hallway_night"],
		"empty": ["hallway_day_empty", "hallway_day"],
		"break": ["hallway_day_empty", "hallway_day"],
		"dusk": ["hallway_dusk", "hallway_night", "hallway_day"],
		"flicker": ["hallway_night_flicker", "hallway_night"],
		"night": ["hallway_night"],
		"dark": ["hallway_night"],
		"dawn": ["hallway_dawn", "hallway_day"],
		"morning": ["hallway_dawn", "hallway_day"],
	},
	"library": {
		"": ["library_day"],
		"day": ["library_day"],
		"dusk": ["library_counter", "library_dim", "library_day"],
		"counter": ["library_counter", "library_day"],
		"night": ["library_stacks_dark", "library_stacks_night", "library_dim", "library_day"],
		"dark": ["library_stacks_dark", "library_stacks_night", "library_dim", "library_day"],
		"stacks": ["library_stacks_dark", "library_stacks_night", "library_dim"],
	},
	"dorm": {
		"": ["dorm_307_day", "dorm_307_night"],
		"day": ["dorm_307_day", "dorm_307_night"],
		"night": ["dorm_307_night_shadow", "dorm_307_night"],
		"dark": ["dorm_307_deepnight", "dorm_307_night_shadow", "dorm_307_night"],
		"deepnight": ["dorm_307_deepnight", "dorm_307_night_shadow", "dorm_307_night"],
		"shadow": ["dorm_307_night_shadow", "dorm_307_night"],
		"names": ["dorm_307_night_namewall", "dorm_307_night"],
		"wet": ["dorm_307_night_wetfloor", "dorm_307_night"],
		"blood": ["dorm_307_night_wetfloor", "dorm_307_night"],
	},
	"dorm_door": {
		"": ["dorm_door_night", "dorm_corridor_night", "hallway_night"],
		"gap": ["dorm_door_gap_shadows", "dorm_door_night"],
		"dark_gap": ["dorm_door_gap_shadows", "dorm_door_night"],
		"night": ["dorm_door_night", "dorm_corridor_night", "hallway_night"],
		"dark": ["dorm_door_night", "dorm_corridor_night", "hallway_night"],
	},
	"duty_room": {
		"": ["duty_room", "office_day"],
		"day": ["duty_room_day", "duty_room", "office_day"],
		"night": ["duty_room_night", "duty_room", "office_day"],
		"dark": ["duty_room_night", "duty_room", "office_day"],
	},
	"oldbuilding_out": {
		"": ["old_building_gate_rain"],
		"rain": ["old_building_gate_rain"],
		"dusk": ["old_building_gate_rain"],
		"day": ["old_building_day", "old_building_gate_rain"],
		"night": ["oldbuilding_out_night", "old_building_gate_rain"],
	},
	"prop": {
		"": ["prop_pencil_case"],
		"pencil_case": ["prop_pencil_case"],
		"videotape": ["prop_videotapes"],
		"ticket": ["prop_bus_ticket"],
		"torn_page": ["prop_torn_page"],
		"library_card": ["prop_library_card"],
		"register": ["prop_broadcast_register"],
		"roster": ["prop_roster_core"],
		"poster": ["prop_missing_poster"],
		"duty": ["prop_duty_roster"],
		"logbook": ["prop_logbook"],
		"notice": ["prop_notice_board"],
		"cabinet": ["prop_control_cabinet"],
		"phone": ["prop_phone"],
	},
	"desk": {
		"": ["desk_carving_shen"], "dark": ["desk_carving_shen"],
		"carving": ["desk_carving_shen"],
	},
	"gate_room": {
		"": ["gate_clock", "schoolgate_dusk"], "night": ["gate_clock"],
		"dusk": ["gate_clock"],
	},
	"stairwell": {
		"": ["stairwell_night"], "night": ["stairwell_night"],
		"dark": ["stairwell_dark_descend", "stairwell_night"],
		"down": ["stairwell_dark_descend", "stairwell_night"],
	},
	"infirmary": {
		"": ["infirmary_day"], "day": ["infirmary_day"], "dusk": ["infirmary_day"],
		"night": ["infirmary_night", "infirmary_day"],
		"dark": ["infirmary_night", "infirmary_day"],
	},
	"schoolgate": {
		"": ["schoolgate_dusk"], "dusk": ["schoolgate_dusk"],
		"day": ["schoolgate_day", "schoolgate_dusk"], "night": ["schoolgate_night", "schoolgate_dusk"],
	},
	"rooftop": {
		"": ["rooftop_night"], "night": ["rooftop_night"], "dark": ["rooftop_night"],
		"door": ["rooftop_door_night", "rooftop_night"],
		"overlook": ["rooftop_overlook", "rooftop_night"],
	},
	"oldbuilding_class": {
		"": ["old_building_classroom"], "dark": ["old_building_classroom"],
		"night": ["old_building_classroom"],
		"piled": ["old_building_classroom_piled", "old_building_classroom"],
	},
	"photo_wall": {
		"": ["graduation_photo_wall", "school_history_hall"],
		"dark": ["graduation_photo_wall", "school_history_hall"],
		"dusk": ["graduation_photo_wall", "history_hall_dusk"],
	},
	"keyboard": {
		"": ["duty_room_keyboard", "duty_room"],
		"day": ["duty_room_keyboard", "duty_room_day"],
		"night": ["duty_room_keyboard", "duty_room"],
	},
	"oldbuilding_stair": {
		"": ["old_building_stairs", "old_building_corridor"],
		"dark": ["old_building_stairs", "old_building_corridor"],
		"night": ["old_building_stairs", "old_building_corridor"],
		"red": ["old_building_corridor_red", "old_building_corridor"],
		"water": ["old_building_corridor_water", "old_building_corridor"],
		"blood": ["old_building_corridor_red", "old_building_corridor"],
	},
	"broadcast_door": {
		"": ["broadcast_door_lightline", "broadcast_door"],
		"dark": ["broadcast_door_lightline", "broadcast_door"],
		"night": ["broadcast_door_lightline", "broadcast_door"],
		"open": ["broadcast_door_opencrack", "broadcast_door"],
	},
	"broadcast_room": {
		"": ["broadcast_room_emptyseat", "broadcast_room"],
		"shenhe": ["broadcast_shenhe_back", "broadcast_room"],
		"back": ["broadcast_shenhe_back", "broadcast_room"],
		"dark": ["broadcast_room_dark", "broadcast_room_emptyseat", "broadcast_room"],
		"emptyseat": ["broadcast_room_emptyseat", "broadcast_room"],
		"fire": ["broadcast_room_fireedge", "broadcast_room"],
		"master": ["broadcast_room_master", "broadcast_room"],
		"void": ["void_broadcast_edge", "broadcast_room"],
		"white": ["broadcast_room_white", "void_broadcast_edge"],
		"blood": ["broadcast_room"],
	},
	"history_hall": {
		"": ["school_history_hall", "library_day"],
		"dusk": ["history_hall_dusk", "school_history_hall", "library_day"],
		"dark": ["school_history_hall", "library_day"],
		"gate": ["history_hall_gate", "history_hall_dusk", "school_history_hall"],
	},
	"archive": {
		"": ["archive_inner_door", "monitor_room"],
		"dark": ["archive_inner_door", "monitor_room"],
		"snow": ["monitor_room_snow", "monitor_room"],
	},
	"monitor_room": {
		"": ["monitor_room"], "dark": ["monitor_room"],
		"wall": ["monitor_room_wall", "monitor_room"],
		"grid": ["monitor_room_wall", "monitor_room"],
		"snow": ["monitor_room_snow", "monitor_room"],
	},
	"schoolyard": {
		"": ["campus_rain", "old_building_gate_rain"],
		"rain": ["campus_rain", "old_building_gate_rain"],
		"night": ["schoolyard_night_path", "schoolyard_night", "campus_rain", "old_building_gate_rain"],
		"path": ["schoolyard_night_path", "schoolyard_night"],
		"aerial": ["schoolyard_aerial", "campus_rain"],
		"day": ["playground_day", "title_school", "campus_rain"],
		"keyvisual": ["keyvisual_school_rain", "title_school"],
		"dusk": ["title_school", "campus_rain", "old_building_gate_rain"],
	},
	"lab_hallway": {
		"": ["experiment_hallway"], "day": ["experiment_hallway"],
		"night": ["experiment_hallway"], "dark": ["experiment_hallway"],
	},
	"dorm_hall": {
		"": ["dorm_corridor_night"], "night": ["dorm_corridor_night"], "dark": ["dorm_corridor_night"], "day": ["hallway_day"],
	},
	"washroom": {
		"": ["washroom_night"], "night": ["washroom_night"],
		"dark": ["washroom_night_mirror", "washroom_night"],
		"mirror": ["washroom_night_mirror", "washroom_night"],
		"faucet": ["washroom_faucet", "washroom_night"],
	},
	"canteen": {
		"": ["canteen_day"], "day": ["canteen_day"],
		"night": ["canteen_night", "canteen_day"],
		"dark": ["canteen_night", "canteen_day"],
	},
	"mirror": {
		"": ["mirror_dark", "dorm_307_night"], "dark": ["mirror_dark", "dorm_307_night"],
		"day": ["dorm_307_day"],
	},
}

func _init() -> void:

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0.0
	offset_bottom = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(true)
	# Draw
	resized.connect(queue_redraw)
	queue_redraw()

func set_scene(id: String, v: String = "") -> void:
	scene_id = id
	variant = v
	var key := id + "|" + v
	if key == _cur_key:
		return
	_cur_key = key
	_tex = _find_texture(id, v)

	# Draw
	queue_redraw()

func current_texture_path() -> String:
	return _cur_tex_path

func _find_texture(id: String, v: String) -> Texture2D:
	if id == "black" or id == "white":
		return null
	var candidates: Array = []
	if BG_MAP.has(id):
		var table: Dictionary = BG_MAP[id]
		if table.has(v):
			candidates.append_array(table[v])
		if table.has("") and v != "":
			candidates.append_array(table[""])

		for k in table:
			candidates.append_array(table[k])
	# Name
	candidates.append(id + ("_" + v if v != "" else ""))
	candidates.append(id)
	for name in candidates:
		var p := "%s/%s.png" % [BG_ROOT, String(name)]
		if ResourceLoader.exists(p):
			_cur_tex_path = p
			return ArtCache.get_tex(p)
	return null

func _process(delta: float) -> void:
	# Perf
	# Time
	var animated := flicker > 0.001 or wet > 0.01 or variant == "rain" or blood_amount > 0.001
	if not animated:
		return
	_t += delta
	if _tex != null:
		queue_redraw()

func _draw() -> void:
	var s := size

	if s.x <= 1.0 or s.y <= 1.0:
		var p := get_parent_control()
		if p != null and p.size.x > 1.0:
			s = p.size
		else:
			s = get_viewport_rect().size
	if _tex == null:

		draw_rect(Rect2(Vector2.ZERO, s),
			Color(0.93, 0.93, 0.95) if scene_id == "white" else Color(0.02, 0.02, 0.03), true)
		return
	var tw := float(_tex.get_width())
	var th := float(_tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return

	var scale := maxf(s.x / tw, s.y / th)
	var dw := tw * scale
	var dh := th * scale
	var pos := Vector2((s.x - dw) * 0.5, (s.y - dh) * 0.5)
	var lm := 1.0 - flicker * 0.55

	var tint := Color(lm, lm, lm, 1.0)
	match variant:
		"night", "dark":
			tint = Color(lm * 0.62, lm * 0.66, lm * 0.78, 1.0)
		"dusk":
			tint = Color(lm * 0.92, lm * 0.78, lm * 0.68, 1.0)
		"rain":
			tint = Color(lm * 0.74, lm * 0.80, lm * 0.88, 1.0)
		"blood":
			tint = Color(lm * 1.0, lm * 0.62, lm * 0.60, 1.0)
		"fire":
			tint = Color(lm * 1.0, lm * 0.74, lm * 0.52, 1.0)
	draw_texture_rect(_tex, Rect2(pos, Vector2(dw, dh)), false, tint)

	if wet > 0.01 or variant == "rain":
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		for i in 110:
			var sp := 1.0 + rng.randf() * 2.0
			var x := fmod(rng.randf() * s.x + _t * 40.0 * sp, s.x)
			var y := fmod(rng.randf() * s.y + _t * 900.0 * sp, s.y)
			draw_line(Vector2(x, y), Vector2(x - 5, y + 26 * sp),
				Color(0.75, 0.82, 0.88, 0.15), 1.2)

	if blood_amount > 0.01 and SaveSystem.gore_level() > 0:
		var lv := SaveSystem.gore_level()
		var col: Color = Cfg.PALETTE["blood"]
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = hash(scene_id) + 7
		var n := int(blood_amount * (10 if lv == 1 else 24))
		for i in n:
			var cx := rng2.randf() * s.x
			var cy := s.y * (0.35 + rng2.randf() * 0.6)
			var r := rng2.randf_range(6.0, 32.0) * (0.6 if lv == 1 else 1.0)
			draw_circle(Vector2(cx, cy), r, Color(col.r, col.g, col.b, 0.5 * blood_amount))
			if lv == 2 and rng2.randf() < 0.6:
				var hh := rng2.randf_range(20.0, 110.0) * blood_amount
				draw_rect(Rect2(cx - r * 0.18, cy, r * 0.36, hh),
					Color(col.r, col.g, col.b, 0.38 * blood_amount))

	var steps := 14
	for i in steps:
		var f := float(i) / steps
		var m := s * 0.5 * f * 0.9
		draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, m.y)), Color(0, 0, 0, 0.012))
		draw_rect(Rect2(0, s.y - m.y, s.x, m.y), Color(0, 0, 0, 0.012))
		draw_rect(Rect2(0, 0, m.x, s.y), Color(0, 0, 0, 0.010))
		draw_rect(Rect2(s.x - m.x, 0, m.x, s.y), Color(0, 0, 0, 0.010))
