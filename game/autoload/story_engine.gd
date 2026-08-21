extends Node
# Engine

# Background
##   @bgm id / @amb id / @sfx id / @stopbgm
# FX
# Sprite

##   @item +id|-id           @clue id
# Time

# Time

# Text

# Text
# Conditions
# Endings
# Title
# Text
# Text
# Text
# Text
# Text
# Text
# Text

signal node_started(node_id: String)
signal line_ready(line: Dictionary)
signal choices_ready(choices: Array)
signal story_finished(ending_id: String)
signal chapter_started(chapter: int, title: String)
signal effect_requested(name: String, power: float)
signal scene_requested(kind: String, value: String, extra: String)
signal actor_requested(kind: String, who: String, emo: String, pos: String)
signal overlay_requested(kind: String, payload: Dictionary)

const STORY_DIR := "res://story"

var nodes: Dictionary = {}          # node_id -> Array[instruction]
var _ip: int = 0
var _cur: Array = []
var _cur_id: String = ""
var running := false
var waiting_choice := false
# Password lock
var _padlock: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	nodes.clear()
	var dir := DirAccess.open(STORY_DIR)
	if dir == null:
		push_error("找不到剧本目录：" + STORY_DIR)
		return
	var files: Array[String] = []
	for f in dir.get_files():
		var fn := f
		if fn.ends_with(".remap"):
			fn = fn.trim_suffix(".remap")
		if fn.ends_with(".avg") and not files.has(fn):
			files.append(fn)
	files.sort()
	for f in files:
		parse_file(STORY_DIR + "/" + f)
	print("[StoryEngine] 载入剧本 %d 个文件 / %d 节点" % [files.size(), nodes.size()])

func parse_file(path: String) -> void:
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		push_warning("剧本为空：" + path)
		return
	parse_text(txt, path)

func parse_text(txt: String, src: String = "") -> void:
	var lines := txt.replace("\r\n", "\n").split("\n")
	var cur_id := ""
	var prog: Array = []
	var if_stack: Array = []
	var last_choice_block: Array = []

	for raw_line in lines:
		var line := String(raw_line)
		var stripped := line.strip_edges()
		if stripped.is_empty():
			last_choice_block = []
			continue
		if stripped.begins_with("--"):
			continue

		if stripped.begins_with("=="):
			if cur_id != "":
				_finalize_node(cur_id, prog, src)
			cur_id = stripped.substr(2).strip_edges()
			prog = []
			if_stack = []
			last_choice_block = []
			continue

		if cur_id == "":
			continue

		# Choices
		if not last_choice_block.is_empty() and line.begins_with(" ") and stripped.begins_with("@"):
			var eff := _parse_command(stripped)
			if not eff.is_empty():
				var last_ch: Dictionary = last_choice_block[last_choice_block.size() - 1]
				var arr: Array = last_ch.get("effects", [])
				arr.append(eff)
				last_ch["effects"] = arr
			continue

		# Choices
		if stripped.begins_with("*"):
			var ch := _parse_choice(stripped.substr(1).strip_edges())
			if ch.is_empty():
				continue
			var need_new := true
			if not prog.is_empty():
				var lastop: Dictionary = prog[prog.size() - 1]
				if lastop.get("op", "") == "choices":
					need_new = false
					var cl: Array = lastop["choices"]
					cl.append(ch)
					last_choice_block = cl
			if need_new:
				var cl2: Array = [ch]
				prog.append({"op": "choices", "choices": cl2})
				last_choice_block = cl2
			continue
		last_choice_block = []

		if stripped.begins_with("@"):
			var head := stripped.substr(1).split(" ", true, 1)[0].to_lower()
			match head:
				"if":
					prog.append({"op": "branch", "cond": stripped.substr(3).strip_edges(), "jump": -1})
					if_stack.append({"cond_idx": prog.size() - 1, "exits": []})
				"elif":
					if if_stack.is_empty():
						push_error("@elif 缺少 @if: " + src)
						continue
					var frame: Dictionary = if_stack[if_stack.size() - 1]
					prog.append({"op": "jump", "jump": -1})
					(frame["exits"] as Array).append(prog.size() - 1)
					prog[int(frame["cond_idx"])]["jump"] = prog.size()
					prog.append({"op": "branch", "cond": stripped.substr(5).strip_edges(), "jump": -1})
					frame["cond_idx"] = prog.size() - 1
				"else":
					if if_stack.is_empty():
						continue
					var frame2: Dictionary = if_stack[if_stack.size() - 1]
					prog.append({"op": "jump", "jump": -1})
					(frame2["exits"] as Array).append(prog.size() - 1)
					prog[int(frame2["cond_idx"])]["jump"] = prog.size()
					frame2["cond_idx"] = -1
				"endif":
					if if_stack.is_empty():
						continue
					var frame3: Dictionary = if_stack.pop_back()
					if int(frame3["cond_idx"]) >= 0:
						prog[int(frame3["cond_idx"])]["jump"] = prog.size()
					for e in frame3["exits"]:
						prog[int(e)]["jump"] = prog.size()
				_:
					var cmd := _parse_command(stripped)
					if not cmd.is_empty():
						prog.append(cmd)
			continue

		# Text
		if stripped.begins_with(">"):
			prog.append({"op": "say", "who": "", "emo": "", "text": stripped.substr(1).strip_edges(), "style": "note"})
			continue

		# Text
		prog.append(_parse_say(stripped))

	if cur_id != "":
		_finalize_node(cur_id, prog, src)

func _finalize_node(id: String, prog: Array, src: String) -> void:
	if nodes.has(id):
		push_warning("重复节点 %s（%s）" % [id, src])
	nodes[id] = prog

func _parse_choice(s: String) -> Dictionary:
	var cond := ""
	var lock := ""
	var body := s
	while body.begins_with("["):
		var close := body.find("]")
		if close < 0:
			break
		var tag := body.substr(1, close - 1).strip_edges()
		body = body.substr(close + 1).strip_edges()
		if tag.begins_with("if "):
			cond = tag.substr(3).strip_edges()
		elif tag.begins_with("lock "):
			lock = tag.substr(5).strip_edges()
	var target := ""
	var arrow := body.rfind("->")
	if arrow >= 0:
		target = body.substr(arrow + 2).strip_edges()
		body = body.substr(0, arrow).strip_edges()
	return {"text": body, "target": target, "cond": cond, "lock": lock, "effects": []}

func _parse_command(s: String) -> Dictionary:
	var body := s.substr(1)
	var parts := body.split(" ", false)
	if parts.is_empty():
		return {}
	var cmd := String(parts[0]).to_lower()
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(String(parts[i]))
	var rest := ""
	if body.length() > cmd.length():
		rest = body.substr(cmd.length()).strip_edges()
	return {"op": "cmd", "cmd": cmd, "args": args, "rest": rest}

func _parse_say(s: String) -> Dictionary:
	var idx := s.find("：")
	var idx2 := s.find(":")
	if idx < 0 or (idx2 >= 0 and idx2 < idx):
		idx = idx2
	if idx > 0 and idx <= 24:
		var head := s.substr(0, idx).strip_edges()
		var text := s.substr(idx + 1).strip_edges()
		var emo := ""
		var p := head.find("(")
		if p < 0:
			p = head.find("（")
		if p > 0:
			var e_end := head.length() - 1
			emo = head.substr(p + 1, e_end - p - 1).strip_edges()
			head = head.substr(0, p).strip_edges()
		if Cfg.CHARACTERS.has(head):
			return {"op": "say", "who": head, "emo": emo, "text": text, "style": "line"}
	return {"op": "say", "who": "", "emo": "", "text": s, "style": "narration"}

func start(node_id: String) -> void:
	if not nodes.has(node_id):
		push_error("节点不存在：" + node_id)
		return
	_cur_id = node_id
	_cur = nodes[node_id]
	_ip = 0
	running = true
	waiting_choice = false
	GameState.current_node = node_id
	GameState.visited_nodes[node_id] = int(GameState.visited_nodes.get(node_id, 0)) + 1
	node_started.emit(node_id)
	advance()

func has_story_node(id: String) -> bool:
	return nodes.has(id)

func advance() -> void:
	if not running or waiting_choice:
		return
	while _ip < _cur.size():
		var ins: Dictionary = _cur[_ip]
		_ip += 1
		match String(ins.get("op", "")):
			"say":
				var l := ins.duplicate(true)
				l["text"] = _resolve_text(String(l["text"]))
				_append_history(String(l.get("who", "")), String(l["text"]))
				line_ready.emit(l)
				return
			"branch":
				if not eval_cond(String(ins.get("cond", ""))):
					_ip = int(ins.get("jump", _cur.size()))
			"jump":
				_ip = int(ins.get("jump", _cur.size()))
			"choices":
				var visible: Array = []
				for c in ins["choices"]:
					var ch: Dictionary = c
					if String(ch.get("cond", "")) != "" and not eval_cond(String(ch["cond"])):
						continue
					var d := ch.duplicate(true)
					d["text"] = _resolve_text(String(d["text"]))
					d["enabled"] = String(ch.get("lock", "")) == "" or eval_cond(String(ch["lock"]))
					d["hint"] = _lock_hint(String(ch.get("lock", "")))
					visible.append(d)
				if visible.is_empty():
					continue
				waiting_choice = true
				choices_ready.emit(visible)
				return
			"cmd":
				var stop := _exec_cmd(ins)
				if stop:
					return

	running = false

func pick_choice(choice: Dictionary) -> void:
	waiting_choice = false
	GameState.choice_log.append({
		"node": _cur_id, "text": String(choice.get("text", "")), "target": String(choice.get("target", ""))
	})
	if GameState.choice_log.size() > 100:
		GameState.choice_log.pop_front()
	_append_history("__choice__", String(choice.get("text", "")))
	for eff in choice.get("effects", []):
		_exec_cmd(eff)
	var target := String(choice.get("target", ""))
	if target != "" and nodes.has(target):
		start(target)
	elif target != "":
		push_error("选项目标节点不存在：" + target)
		advance()
	else:
		advance()

# Password lock
func padlock_done(success: bool) -> void:
	var p := _padlock
	_padlock = {}
	if p.is_empty():
		return
	if success:
		AudioDirector.play_sfx("sfx_unlock", 1.0)
		Ach.notify_padlock_solved(String(p.get("code", "")))
		var ok := String(p.get("ok", ""))
		if nodes.has(ok):
			start(ok)
		else:
			push_error("@padlock 成功节点不存在：" + ok)
			advance()
	else:
		AudioDirector.play_sfx("sfx_wrong", 1.0)
		var fail := String(p.get("fail", ""))
		if fail != "" and nodes.has(fail):
			start(fail)
		else:
			if fail != "":
				push_error("@padlock 失败节点不存在：" + fail)
			advance()

func _append_history(who: String, text: String) -> void:
	GameState.history.append({"who": who, "text": text})
	if GameState.history.size() > 400:
		GameState.history.pop_front()

func _exec_cmd(ins: Dictionary) -> bool:
	var cmd := String(ins.get("cmd", ""))
	var args: Array = ins.get("args", [])
	var rest := String(ins.get("rest", ""))
	match cmd:
		"bg":
			# Save/Load
			GameState.scene_bg = _arg(args, 0)
			GameState.scene_variant = _arg(args, 1)
			scene_requested.emit("bg", _arg(args, 0), _arg(args, 1))
		"bgm":
			AudioDirector.play_bgm(_arg(args, 0))
		"stopbgm":
			AudioDirector.stop_bgm()
		"amb":
			AudioDirector.play_amb(_arg(args, 0))
		"stopamb":
			AudioDirector.stop_amb()
		"sfx":
			AudioDirector.play_sfx(_arg(args, 0), float(_arg(args, 1, "1.0")))
		"fx":
			effect_requested.emit(_arg(args, 0), float(_arg(args, 1, "1.0")))
		"show":
			_record_actor("show", _arg(args, 0), _arg(args, 1, "normal"), _arg(args, 2, "center"))
			actor_requested.emit("show", _arg(args, 0), _arg(args, 1, "normal"), _arg(args, 2, "center"))
		"hide":
			_record_actor("hide", _arg(args, 0), "", "")
			actor_requested.emit("hide", _arg(args, 0), "", "")
		"clearchars":
			_record_actor("clear", "", "", "")
			actor_requested.emit("clear", "", "", "")
		"set":
			_apply_set(_arg(args, 0), _arg(args, 1))
		"flag":
			GameState.set_flag(_arg(args, 0), _arg(args, 1, "true").to_lower() != "false")
		"state":
			GameState.set_state(_arg(args, 0), _arg(args, 1))
		"item":
			var a := _arg(args, 0)
			if a.begins_with("-"):
				GameState.remove_item(a.substr(1))
			else:
				GameState.add_item(a.trim_prefix("+"))
				overlay_requested.emit("item", {"id": a.trim_prefix("+")})
		"clue":
			GameState.add_clue(_arg(args, 0))
			overlay_requested.emit("clue", {"id": _arg(args, 0)})
		"death":
			GameState.register_loss(_arg(args, 0), rest.substr(_arg(args, 0).length()).strip_edges())
		"gallery":
			GameState.unlock_gallery(_arg(args, 0))
		"title":
			overlay_requested.emit("title", {"text": rest})
			return true
		"roster":
			overlay_requested.emit("roster", {})
			return true
		"padlock":
			# Text
			var code := _arg(args, 0)
			var ok_node := _arg(args, 1)
			if code.is_empty() or ok_node.is_empty():
				push_error("格式应为 @padlock 密码 成功节点 [失败节点] 提示文本")
				return false
			# Text
			var hint := rest
			var strip_n := mini(args.size(), 3)
			for i in strip_n:
				var s := String(args[i])
				if hint.begins_with(s):
					hint = hint.substr(s.length()).strip_edges()
			_padlock = {
				"code": code,
				"hint": _resolve_text(hint),
				"ok": ok_node,
				"fail": _arg(args, 2),
			}
			overlay_requested.emit("padlock", _padlock.duplicate())
			return true
		"note":
			overlay_requested.emit("note", {"text": rest})
			return true
		"time":
			var d := int(_arg(args, 0, "1"))
			var hm := _arg(args, 1, "0:00").split(":")
			var mi := 0
			if hm.size() >= 2:
				mi = int(hm[0]) * 60 + int(hm[1])
			GameState.set_story_time(d, mi)
		"timeat":

			# Time
			var d2 := int(_arg(args, 0, "1"))
			var hm2 := _arg(args, 1, "0:00").split(":")
			var mi2 := 0
			if hm2.size() >= 2:
				mi2 = int(hm2[0]) * 60 + int(hm2[1])
			GameState.seek_story_time(d2, mi2, int(_arg(args, 2, "5")))
		"advtime":
			GameState.advance_time(int(_arg(args, 0, "0")))
		"wait":
			overlay_requested.emit("wait", {"time": float(_arg(args, 0, "1.0"))})
			return true
		"chapter":
			var num := int(_arg(args, 0))
			GameState.current_chapter = num
			var t := rest.substr(_arg(args, 0).length()).strip_edges()
			chapter_started.emit(num, t)
			return true
		"settle":
			match int(_arg(args, 0)):
				1: GameState.settle_chapter_1()
				2: GameState.settle_chapter_2()
				3: GameState.settle_chapter_3()
				4: GameState.settle_chapter_4()
		"autosave":
			SaveSystem.autosave()
		"goto":
			var t2 := _arg(args, 0)
			if t2 == "__ending__":
				t2 = GameState.determine_ending()
			if nodes.has(t2):
				start(t2)
				return true
			push_error("@goto 目标不存在：" + t2)
		"ending":
			var eid := _arg(args, 0)
			if eid == "auto":
				eid = GameState.determine_ending()
			running = false
			GameState.record_ending(eid)
			story_finished.emit(eid)
			return true
		"return":
			running = false
			return true
		_:
			push_warning("未知指令：@" + cmd)
	return false

func _arg(a: Array, i: int, def: String = "") -> String:
	return String(a[i]) if i < a.size() else def

func _apply_set(key: String, expr: String) -> void:
	if expr.is_empty():
		return
	if expr.begins_with("+"):
		GameState.add_num(key, int(expr.substr(1)))
	elif expr.begins_with("-"):
		GameState.add_num(key, -int(expr.substr(1)))
	elif expr.begins_with("="):
		GameState.set_num(key, int(expr.substr(1)))
	else:
		GameState.add_num(key, int(expr))

# Text

# Name
func _resolve_text(t: String) -> String:
	var out := t
	while true:
		var s := out.find("{")
		if s < 0:
			break
		var e := out.find("}", s)
		if e < 0:
			break
		var token := out.substr(s + 1, e - s - 1)
		out = out.substr(0, s) + _eval_token(token) + out.substr(e + 1)
	if GameState.player_name != "林昼":
		out = out.replace("林昼", GameState.player_name)
	return out

func _eval_token(tok: String) -> String:
	if tok == "pname":
		return GameState.player_name
	if tok.begins_with("num:"):
		return str(GameState.get_num(tok.substr(4)))
	if tok.begins_with("item:"):
		return GameState.item_name(tok.substr(5))
	if tok.begins_with("name:"):
		var k := tok.substr(5)
		if k in ["me", "linzhou", "linday"]:
			return GameState.player_name
		return String(Cfg.CHARACTERS.get(k, {}).get("name", k))
	if tok.begins_with("state:"):
		return GameState.get_state(tok.substr(6))
	if tok.begins_with("if "):
		var body := tok.substr(3)
		var q := body.find("?")
		if q < 0:
			return ""
		var cond := body.substr(0, q).strip_edges()
		var rest := body.substr(q + 1)
		var bar := rest.find("|")
		var a := rest if bar < 0 else rest.substr(0, bar)
		var b := "" if bar < 0 else rest.substr(bar + 1)
		return a if eval_cond(cond) else b
	return ""

# Conditions

##   truth>=5 / sanity<40 / trust_liangye>=2
##   flag_xxx / !flag_xxx
##   item:item_page109 / !item:item_admin_key
##   state:liangye_end_state==present_anchor
##   ending:true  / chapter>=3 / cycles>=1 / gore>=1
func eval_cond(expr: String) -> bool:
	var e := expr.strip_edges()
	if e.is_empty():
		return true

	if e.contains(" or "):
		for part in e.split(" or "):
			if eval_cond(String(part)):
				return true
		return false
	if e.contains(" and "):
		for part in e.split(" and "):
			if not eval_cond(String(part)):
				return false
		return true
	return _eval_atom(e)

func _eval_atom(a: String) -> bool:
	var s := a.strip_edges()
	if s.begins_with("!"):
		return not _eval_atom(s.substr(1))
	if s.begins_with("item:"):
		return GameState.has_item(s.substr(5))
	if s.begins_with("clue:"):
		return GameState.clues.has(s.substr(5))
	if s.begins_with("state:"):
		var body := s.substr(6)
		var op_i := body.find("==")
		if op_i > 0:
			var k := body.substr(0, op_i).strip_edges()
			var v := body.substr(op_i + 2).strip_edges()
			if v.contains("|"):
				return v.split("|").has(GameState.get_state(k))
			return GameState.get_state(k) == v
		var ne := body.find("!=")
		if ne > 0:
			return GameState.get_state(body.substr(0, ne).strip_edges()) != body.substr(ne + 2).strip_edges()
		return false
	if s.begins_with("visited:"):
		return GameState.visited_nodes.has(s.substr(8))
	if s.begins_with("cycles"):
		return _cmp_num(int(GameState.persistent.get("cycles", 0)), s.substr(6))
	if s.begins_with("chapter"):
		return _cmp_num(GameState.current_chapter, s.substr(7))
	if s.begins_with("gore"):
		return _cmp_num(int(SaveSystem.settings.get("gore", 2)), s.substr(4))
	if s.begins_with("death:"):
		var who := s.substr(6)
		for d in GameState.deaths:
			if String(d).begins_with(who):
				return true
		return false
	for op in ["<=", ">=", "==", "!=", "<", ">"]:
		var i := s.find(op)
		if i > 0:
			var key := s.substr(0, i).strip_edges()
			var tail := s.substr(i)
			if Cfg.NUM_RANGE.has(key):
				return _cmp_num(GameState.get_num(key), tail)
			return false

	if Cfg.NUM_RANGE.has(s):
		return GameState.get_num(s) > 0
	return GameState.get_flag(s)

func _cmp_num(v: int, tail: String) -> bool:
	var t := tail.strip_edges()
	if t.begins_with(">="):
		return v >= int(t.substr(2))
	if t.begins_with("<="):
		return v <= int(t.substr(2))
	if t.begins_with("=="):
		return v == int(t.substr(2))
	if t.begins_with("!="):
		return v != int(t.substr(2))
	if t.begins_with(">"):
		return v > int(t.substr(1))
	if t.begins_with("<"):
		return v < int(t.substr(1))
	return v != 0

func _lock_hint(lock: String) -> String:
	if lock.is_empty():
		return ""
	var s := lock.strip_edges()
	if s.begins_with("item:"):
		return "需要：" + GameState.item_name(s.substr(5))
	if s.begins_with("flag_") or GameState.flags.has(s):
		return "条件未满足"
	for op in [">=", ">"]:
		var i := s.find(op)
		if i > 0:
			var k := s.substr(0, i).strip_edges()
			if Cfg.NUM_LABEL.has(k):
				return "需要 %s %s" % [Cfg.NUM_LABEL[k], s.substr(i)]
	return "条件未满足"

# Save/Load
func _record_actor(kind: String, who: String, emo: String, pos: String) -> void:	match kind:
		"show":
			for a in GameState.scene_actors:
				if String((a as Dictionary).get("who", "")) == who:
					(a as Dictionary)["emo"] = emo
					(a as Dictionary)["pos"] = pos
					return
			GameState.scene_actors.append({"who": who, "emo": emo, "pos": pos})
		"hide":
			for i in range(GameState.scene_actors.size() - 1, -1, -1):
				var d: Dictionary = GameState.scene_actors[i]
				if String(d.get("who", "")) == who:
					GameState.scene_actors.remove_at(i)
		"clear":
			GameState.scene_actors.clear()

# Save/Load
func snapshot() -> Dictionary:
	return {"node": _cur_id, "ip": _ip}

func restore(node_id: String) -> void:
	if nodes.has(node_id):
		start(node_id)
