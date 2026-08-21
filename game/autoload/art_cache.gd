extends Node
# Perf
# Sprite

# Cache
# Chapters

# Chapters
# Story

const BG_ROOT := "res://assets/bg"
const SPRITE_ROOT := "res://assets/sprites"

# Background
const CHAPTER_BG := {
	0: ["keyvisual_school_rain", "office_day", "gate_clock"],
	1: ["canteen_day", "classroom_day", "classroom_evening",
		"classroom_evening_alllook", "classroom_window_reflection", "desk_carving_shen",
		"dorm_307_day", "dorm_307_deepnight", "dorm_307_night_shadow",
		"dorm_door_gap_shadows", "dorm_door_night", "hallway_day",
		"hallway_dusk", "library_counter", "library_dim", "office_day",
		"prop_broadcast_register", "prop_duty_roster", "prop_library_card",
		"prop_missing_poster", "prop_pencil_case", "title_school", "keyvisual_school_rain",
		"hallway_day_empty", "washroom_faucet"],
	2: ["broadcast_door_lightline", "broadcast_room_dark", "classroom_day",
		"dorm_307_deepnight", "dorm_307_night_shadow", "dorm_corridor_night",
		"duty_room_day", "duty_room_night", "hallway_day",
		"hallway_night_flicker", "infirmary_day", "library_counter",
		"library_stacks_night", "office_day", "old_building_classroom",
		"old_building_gate_rain", "old_building_stairs", "oldbuilding_out_night",
		"old_building_classroom_piled", "prop_torn_page", "schoolyard_night_path",
		"schoolyard_night", "stairwell_night",
		"title_school", "washroom_night", "library_stacks_dark", "stairwell_dark_descend"],
	3: ["classroom_evening", "dorm_307_deepnight", "dorm_307_night_namewall",
		"dorm_307_night_shadow", "dorm_door_night", "hallway_dusk",
		"hallway_night", "mirror_dark", "prop_bus_ticket",
		"prop_duty_roster", "prop_library_card", "prop_missing_poster",
		"prop_phone", "rooftop_night", "rooftop_overlook", "washroom_night_mirror", "rooftop_door_night"],
	4: ["archive_inner_door", "campus_rain", "classroom_day",
		"classroom_evening_alllook", "classroom_morning", "duty_room_keyboard",
		"duty_room_night", "graduation_photo_wall", "hallway_day",
		"history_hall_dusk", "history_hall_gate", "monitor_room", "office_night",
		"prop_logbook", "prop_notice_board", "prop_roster_core",
		"prop_videotapes", "school_history_hall", "dorm_307_deepnight", "office_night_lamp", "classroom_day_rollcall", "monitor_room_wall"],
	5: ["broadcast_door_lightline", "broadcast_room_dark", "broadcast_room_fireedge",
		"broadcast_room_master", "broadcast_room_white", "broadcast_shenhe_back",
		"classroom_evening_alllook", "office_day", "old_building_day",
		"old_building_gate_rain", "old_building_stairs", "oldbuilding_out_night",
		"prop_control_cabinet", "school_history_hall", "schoolgate_night",
		"schoolyard_aerial", "title_school"],
	6: ["playground_day", "schoolgate_day", "classroom_morning", "classroom_day",
		"desk_carving_shen", "old_building_day", "broadcast_room_white"],
}

# Sprite
const CHAPTER_CHARS := {
	0: ["linday"],
	1: ["canteen_aunt", "classmate_boy", "classmate_girl", "liangye", "unknown", "xuqing",
		"zhouxu"],
	2: ["classmate", "dorm_keeper", "liangye", "liheng", "oldqin", "shenhe",
		"unknown", "xuqing", "zhouxu"],
	3: ["liangye", "liheng", "oldqin", "shenhe", "unknown", "zhouxu"],
	4: ["liangye", "liheng", "oldqin", "shenhe", "xuqing", "zhouxu"],
	5: ["liangye", "shenhe", "unknown", "xuqing", "zhouxu"],
	# 番外（v1.4.1）：不整目录预载立绘。番外每人只用 1 个表情，按需加载即可，
	# 避免 5 个角色约 40 张立绘（~90MB 解码内存）一次性进内存导致低配机 OOM 闪退。
}

var _cache := {}          # path -> Texture2D
var _lru: Array[String] = []  # 稳定性（v1.4.1）：最近使用顺序，队首最旧
var _hits := 0
var _misses := 0

## 稳定性（v1.4.1）：贴图缓存硬上限。超过后淘汰最久未用的贴图，
## 防止长会话/多周目下缓存无限增长导致 Android 低内存设备 OOM 闪退。
## 当前显示的场景与立绘因刚刚被访问而位于队尾，不会被误淘汰。
const MAX_CACHE := 64

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Cache
func get_tex(path: String) -> Texture2D:
	if _cache.has(path):
		_hits += 1
		_touch(path)
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	_misses += 1
	var t := load(path) as Texture2D
	if t != null:
		_store(path, t)
	return t

func put(path: String, res: Resource) -> void:
	var t := res as Texture2D
	if t != null:
		_store(path, t)

func has(path: String) -> bool:
	return _cache.has(path)

func _touch(path: String) -> void:
	_lru.erase(path)
	_lru.append(path)

func _store(path: String, t: Texture2D) -> void:
	_cache[path] = t
	_touch(path)
	while _cache.size() > MAX_CACHE:
		var oldest := _lru.pop_front()
		if oldest == path or oldest == "":
			break
		_cache.erase(oldest)

func paths_for_chapter(chapter: int) -> Array[String]:
	var out: Array[String] = []
	for name in CHAPTER_BG.get(chapter, []):
		var p := "%s/%s.png" % [BG_ROOT, String(name)]
		if ResourceLoader.exists(p) and not _cache.has(p):
			out.append(p)
	for cid in CHAPTER_CHARS.get(chapter, []):
		var dir := "%s/%s" % [SPRITE_ROOT, String(cid)]
		var da := DirAccess.open(dir)
		if da == null:
			continue
		for f in da.get_files():
			if not f.ends_with(".png"):
				continue
			var sp := "%s/%s" % [dir, f]
			if not _cache.has(sp):
				out.append(sp)
	return out

# Cache
func release_stale(chapter: int, keep: Array[String] = []) -> int:
	# 稳定性（v1.4.1）：上限不再硬编码 6，跟随 CHAPTER_BG 实际键位（含番外章 6）
	var max_ch := 0
	for k in CHAPTER_BG:
		max_ch = maxi(max_ch, int(k))
	var needed := {}
	for ch in range(chapter, max_ch + 1):
		for p in paths_for_chapter_all(ch):
			needed[p] = true
	for p in keep:
		needed[p] = true
	var drop: Array[String] = []
	for p in _cache:
		if not needed.has(p):
			drop.append(p)
	for p in drop:
		_cache.erase(p)
		_lru.erase(p)
	return drop.size()

# Cache
func paths_for_chapter_all(chapter: int) -> Array[String]:
	var out: Array[String] = []
	for name in CHAPTER_BG.get(chapter, []):
		var p := "%s/%s.png" % [BG_ROOT, String(name)]
		if ResourceLoader.exists(p):
			out.append(p)
	for cid in CHAPTER_CHARS.get(chapter, []):
		var dir := "%s/%s" % [SPRITE_ROOT, String(cid)]
		var da := DirAccess.open(dir)
		if da == null:
			continue
		for f in da.get_files():
			if f.ends_with(".png"):
				out.append("%s/%s" % [dir, f])
	return out

func stats() -> Dictionary:
	return {"cached": _cache.size(), "hits": _hits, "misses": _misses}

func clear_all() -> void:
	_cache.clear()
	_lru.clear()
