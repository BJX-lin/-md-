extends Node
# Audio
# Audio
# Audio

const SR := 22050
const AUDIO_ROOT := "res://assets/audio"

var _music: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx := 0
var _cache: Dictionary = {}
var _cur_bgm := ""
var _cur_amb := ""

var master_volume := 1.0
var bgm_volume := 0.7
var sfx_volume := 0.85

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	add_child(_music)
	_amb = AudioStreamPlayer.new()
	_amb.bus = "Master"
	add_child(_amb)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)

func apply_settings(s: Dictionary) -> void:
	master_volume = float(s.get("vol_master", 1.0))
	bgm_volume = float(s.get("vol_bgm", 0.7))
	sfx_volume = float(s.get("vol_sfx", 0.85))
	_music.volume_db = linear_to_db(maxf(0.0001, bgm_volume * master_volume))
	_amb.volume_db = linear_to_db(maxf(0.0001, bgm_volume * master_volume * 0.8))

func play_bgm(id: String) -> void:
	if id == _cur_bgm and _music.playing:
		return
	_cur_bgm = id
	var st := _stream_for(id)
	if st == null:
		return
	_music.stream = st
	_music.volume_db = linear_to_db(maxf(0.0001, bgm_volume * master_volume))
	_music.play()

func stop_bgm() -> void:
	_cur_bgm = ""
	_music.stop()

func play_amb(id: String) -> void:
	if id == _cur_amb and _amb.playing:
		return
	_cur_amb = id
	var st := _stream_for(id)
	if st == null:
		return
	_amb.stream = st
	_amb.volume_db = linear_to_db(maxf(0.0001, bgm_volume * master_volume * 0.75))
	_amb.play()

func stop_amb() -> void:
	_cur_amb = ""
	_amb.stop()

func play_sfx(id: String, vol_scale: float = 1.0) -> void:
	var st := _stream_for(id)
	if st == null:
		return
	var p := _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	p.stream = st
	p.volume_db = linear_to_db(maxf(0.0001, sfx_volume * master_volume * vol_scale))
	p.pitch_scale = randf_range(0.96, 1.04)
	p.play()

func play_blip(char_key: String) -> void:
	var st := _stream_for("_blip")
	if st == null:
		return
	var p := _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	var base := float(Cfg.CHARACTERS.get(char_key, {}).get("pitch", 150.0))
	p.stream = st
	p.pitch_scale = clampf(base / 150.0, 0.6, 2.0) * randf_range(0.97, 1.03)
	p.volume_db = linear_to_db(maxf(0.0001, sfx_volume * master_volume * 0.16))
	p.play()

# Audio
# Audio
const SFX_CACHE_MAX := 12
var _lru: Array[String] = []

func _touch(id: String) -> void:
	_lru.erase(id)
	_lru.append(id)
	# Audio
	var sfx := _lru.filter(func(x): return x.begins_with("sfx_"))
	while sfx.size() > SFX_CACHE_MAX:
		var old: String = sfx.pop_front()
		_lru.erase(old)
		_cache.erase(old)

func _stream_for(id: String) -> AudioStream:
	if _cache.has(id):
		_touch(id)
		return _cache[id]
	# Audio
	# Audio
	var ext := _external_stream(id)
	if ext != null:
		_cache[id] = ext
		_touch(id)
		return ext

	var data := _synth(id)
	if data.is_empty():
		return null
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = SR
	st.stereo = false
	st.data = data
	if id.begins_with("bgm_") or id.begins_with("amb_"):
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = data.size() / 2
	_cache[id] = st
	return st

# Audio

func _external_stream(id: String) -> AudioStream:
	for ext in [".ogg", ".wav", ".mp3"]:
		var p := "%s/%s%s" % [AUDIO_ROOT, id, ext]
		if not ResourceLoader.exists(p):
			continue
		var st := load(p) as AudioStream
		if st == null:
			continue
		# Audio
		if id.begins_with("bgm_") or id.begins_with("amb_"):
			if st is AudioStreamWAV:
				var w := st as AudioStreamWAV
				w.loop_mode = AudioStreamWAV.LOOP_FORWARD
				w.loop_begin = 0
				w.loop_end = w.data.size() / 2
			elif st is AudioStreamOggVorbis:
				(st as AudioStreamOggVorbis).loop = true
			elif st is AudioStreamMP3:
				(st as AudioStreamMP3).loop = true
		return st
	return null

# Audio
# Audio
# Audio
func _synth(_id: String) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(int(SR * 0.05) * 2)
	return out
