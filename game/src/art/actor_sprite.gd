extends Control
class_name ActorSprite
# Sprite
# Sprite
##   res://assets/sprites/<char_id>/<char_id>_pose<NN>_<exp>.png

# Story
# Story

# Sprite

const SPRITE_ROOT := "res://assets/sprites"

# Sprite
const UPPER_RATIO := 0.58

var who := "linzhou"
var emo := "normal"
var active := true
var glitch := 0.0
var wounded := 0.0
var pose := ""  # State

var _tex: Texture2D = null
var _t := 0.0
var _cur_key := ""
var _rng := RandomNumberGenerator.new()  # Gore

# Sprite
const CHAR_DIR := {
	"linzhou": "linday", "me": "linday",
	"zhouxu": "zhouxu", "liangye": "liangye",
	"xuqing": "xuqing", "shenhe": "shenhe", "oldqin": "oldqin",
}

const POSES := {
	"zhouxu": ["pose01"],
	"liangye": ["pose01"],
	"xuqing": ["pose01"],
	"shenhe": ["pose01"],
	"oldqin": ["pose01"],
	"linday": ["pose01"],
	"liheng": ["pose01"],
	"dorm_keeper": ["pose01"],
	"canteen_aunt": ["pose01"],
	"classmate": ["pose01"],
	"classmate_girl": ["pose01"],
	"classmate_boy": ["pose01"],
	"unknown": ["pose01"],
}

# Story
const EMO_FALLBACK := {

	"normal": ["normal", "neutral", "calm", "flat"],
	"neutral": ["neutral", "normal", "calm", "flat"],
	"calm": ["calm", "neutral", "normal", "flat"],

	"flat": ["flat", "neutral", "normal", "calm"],
	"cold": ["cold", "dark", "stare", "frown", "neutral", "normal", "flat"],
	"frown": ["frown", "displeased", "serious", "neutral", "normal"],
	"serious": ["serious", "frown", "neutral", "normal"],
	"urgent": ["urgent", "serious", "frown", "neutral", "normal"],
	"dark": ["dark", "cold", "serious", "neutral", "normal"],
	"soft": ["soft", "relief", "neutral", "normal"],
	"tired": ["tired", "sad", "neutral", "normal", "calm"],

	"annoyed": ["annoyed", "displeased", "frown", "normal"],
	"nervous": ["nervous", "scared", "fear", "normal"],
	"fear": ["fear", "nervous", "scared", "normal"],
	"scared": ["scared", "nervous", "fear", "normal"],
	"terrified": ["terrified", "scared", "nervous", "fear", "urgent", "serious", "frown", "normal", "neutral"],
	"panic": ["panic", "terrified", "scared", "nervous", "normal"],
	"blank": ["blank", "hollow", "empty", "half", "normal"],
	"relief": ["relief", "soft", "fragile", "normal"],
	"fragile": ["fragile", "relief", "sad", "normal"],
	"half": ["half", "blank", "hollow", "empty", "normal"],
	"half_assimilated": ["half", "blank", "hollow", "empty", "normal"],

	"stare": ["stare", "cold", "empty", "neutral", "normal"],
	"displeased": ["displeased", "frown", "angry", "neutral", "normal"],
	"faintsmile": ["faintsmile", "faint_smile", "smile", "smirk", "neutral", "normal", "flat"],
	"faint_smile": ["faintsmile", "faint_smile", "smile", "smirk", "neutral"],
	"smile": ["smile", "faintsmile", "faint_smile", "relief", "soft", "neutral", "normal", "calm", "flat"],
	"smirk": ["smirk", "faintsmile", "faint_smile", "smile", "neutral"],
	"empty": ["empty", "hollow", "blank", "void", "neutral"],
	"unstable": ["unstable", "empty", "hollow", "neutral"],

	"sad": ["sad", "tired", "hurt", "fragile", "empty", "calm", "neutral", "normal"],
	"hurt": ["hurt", "sad", "tired", "calm"],
	"hollow": ["hollow", "empty", "blank", "void", "calm"],
	"release": ["release", "faintsmile", "faint_smile", "calm"],
	"void": ["void", "hollow", "empty", "blank", "calm"],
	"dead": ["dead", "hollow", "empty", "calm"],

	"warning": ["warning", "nervous", "serious", "normal"],
	"shocked": ["shocked", "terrified", "scared", "nervous", "normal"],

	"confused": ["confused", "neutral", "normal"],
	"determined": ["determined", "serious", "neutral", "normal"],

	"angry": ["angry", "displeased", "frown", "serious", "stare", "hurt", "sad", "normal", "neutral", "calm"],
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	_refresh()

func setup(who_id: String, emotion: String, pose_id: String = "") -> void:
	who = who_id
	emo = emotion if emotion != "" else "normal"
	pose = pose_id
	_refresh()

func _refresh() -> void:
	var key := "%s/%s/%s" % [who, emo, _auto_pose()]
	if key == _cur_key:
		return
	_cur_key = key
	_tex = _find_texture(who, emo)
	# Sprite

	queue_redraw()

# State
func _auto_pose() -> String:
	if pose != "":
		return pose
	# v1.1.4 立绘重做后全部角色统一单姿势
	return "pose01"

func _find_texture(char_id: String, emotion: String) -> Texture2D:
	var dir := String(CHAR_DIR.get(char_id, char_id))
	var chain: Array = EMO_FALLBACK.get(emotion, [emotion, "normal", "neutral", "calm"])
	var want := _auto_pose()

	for e in chain:
		var p := "%s/%s/%s_%s_%s.png" % [SPRITE_ROOT, dir, dir, want, String(e)]
		if ResourceLoader.exists(p):
			return ArtCache.get_tex(p)

	var all_poses: Array = POSES.get(dir, ["pose01"])
	for e in chain:
		for pz in all_poses:
			var p2 := "%s/%s/%s_%s_%s.png" % [SPRITE_ROOT, dir, dir, String(pz), String(e)]
			if ResourceLoader.exists(p2):
				return ArtCache.get_tex(p2)

	for pz in all_poses:
		for e in ["neutral", "normal", "calm"]:
			var p3 := "%s/%s/%s_%s_%s.png" % [SPRITE_ROOT, dir, dir, String(pz), e]
			if ResourceLoader.exists(p3):
				return ArtCache.get_tex(p3)
	return null

var _redraw_acc := 0.0

func _process(delta: float) -> void:
	_t += delta
	if _tex == null and not active:
		return
	# Perf: idle breathe redraw ~14fps; full speed only for glitch/gore
	if glitch > 0.02 or wounded > 0.0:
		queue_redraw()
		return
	_redraw_acc += delta
	if _redraw_acc >= 0.07:
		_redraw_acc = 0.0
		queue_redraw()

func _draw() -> void:
	var s := size
	if _tex == null:
		return
	if s.x <= 1.0 or s.y <= 1.0:
		return
	var tw := float(_tex.get_width())
	var th := float(_tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return

	var src := Rect2(0.0, 0.0, tw, th * UPPER_RATIO)
	var breathe := sin(_t * 1.1) * 1.5
	var pos := Vector2(0.0, breathe)
	var dst := Rect2(pos, s)
	var tint := Color(1, 1, 1, 1) if active else Color(0.55, 0.58, 0.62, 0.92)

	if glitch > 0.02:
		var off := Vector2(sin(_t * 7.0) * 9.0 * glitch, 0.0)
		draw_texture_rect_region(_tex, Rect2(pos + off, s), src,
			Color(0.65, 0.95, 0.92, 0.16 * glitch))
		draw_texture_rect_region(_tex, Rect2(pos - off, s), src,
			Color(0.95, 0.55, 0.55, 0.13 * glitch))

	draw_texture_rect_region(_tex, dst, src, tint)

	if wounded > 0.0 and SaveSystem.gore_level() > 0:
		var lv := SaveSystem.gore_level()
		var amount: float = wounded * (0.5 if lv == 1 else 1.0)
		var blood: Color = Cfg.PALETTE["blood_bright"]
		_rng.seed = hash(who) * 3 + 11
		var n := int(6 * amount) + 1
		for i in n:
			var px := pos.x + s.x * _rng.randf_range(0.25, 0.75)
			var py := pos.y + s.y * _rng.randf_range(0.15, 0.85)
			draw_circle(Vector2(px, py), _rng.randf_range(4, 13) * amount,
				Color(blood.r * 0.7, blood.g * 0.4, blood.b * 0.4, 0.75 * amount))
			if lv == 2:
				draw_rect(Rect2(px - 2, py, 4, _rng.randf_range(10, 46) * amount),
					Color(blood.r * 0.6, 0.05, 0.05, 0.6 * amount))
