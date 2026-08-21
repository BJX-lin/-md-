extends Node
## 冒烟测试：驱动 StoryEngine 验证 padlock / 命名插值 / 条件 / 剧情跳转 / 序列化。
## 用法：godot --headless --path game --script res://tools/smoke_test.gd
## 退出码：0 全部通过，1 存在失败。

var _frame := 0
var _fail := 0
var _lines: Array = []

func _ready() -> void:
	_run()
	get_tree().quit(1 if _fail > 0 else 0)

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] ", msg)
	else:
		_fail += 1
		print("  [FAIL] ", msg)

func _collect() -> void:
	StoryEngine.line_ready.connect(func(l: Dictionary):
		_lines.append(String(l.get("who", "")) + "|" + String(l.get("text", "")))
	)

func _drain(max_steps := 40) -> void:
	var i := 0
	while i < max_steps:
		if StoryEngine.waiting_choice or not StoryEngine.running:
			return
		StoryEngine.advance()
		i += 1

func _run() -> void:
	print("SMOKE: StoryEngine nodes = ", StoryEngine.nodes.size())
	_check(StoryEngine.nodes.size() == 564, "564 个剧情节点已解析")
	_check(StoryEngine.nodes.has("ch4_inner_lock"), "第四章密码锁节点存在")
	_check(StoryEngine.nodes.has("final_cabinet_lock"), "终章密码锁节点存在")
	_check(StoryEngine.nodes.has("extra_sunny_day"), "番外《天晴》入口节点存在")

	# 1) 文本插值：玩家改名后「林昼」应被替换
	GameState.player_name = "江晚"
	_collect()
	StoryEngine.start("ch1_s2_b")   # me/zhouxu 台词含 林昼
	_drain()
	var joined := " / ".join(_lines)
	_check(joined.contains("江晚"), "正文中的林昼被替换为玩家名")
	_check(joined.contains("zhouxu|江晚。"), "周叙台词显示玩家名")

	# 2) 密码锁：成功路径
	StoryEngine.start("ch4_inner_lock")
	_drain()
	_check(not StoryEngine._padlock.is_empty(), "进入密码锁节点后引擎挂起")
	_check(String(StoryEngine._padlock.get("code", "")) == "0109", "第四章密码为 0109")
	StoryEngine.padlock_done(true)
	_check(GameState.current_node == "ch4_wall_open", "密码正确 -> 跳到 ch4_wall_open（实际 %s）" % GameState.current_node)

	# 3) 密码锁：失败路径
	StoryEngine.start("ch4_inner_lock")
	_drain()
	StoryEngine.padlock_done(false)
	_check(GameState.current_node == "ch4_inner_lock_fail", "密码错误 -> 跳到失败节点（实际 %s）" % GameState.current_node)

	# 4) 终章密码锁 2119
	StoryEngine.start("final_cabinet_lock")
	_drain()
	_check(String(StoryEngine._padlock.get("code", "")) == "2119", "终章密码为 2119")
	StoryEngine.padlock_done(true)
	_check(GameState.current_node == "final_cabinet_open", "终章密码正确 -> final_cabinet_open")

	# 5) final_a_broadcast 可自然推进到密码锁
	StoryEngine.start("final_a_broadcast")
	_drain()
	_check(not StoryEngine._padlock.is_empty(), "final_a_broadcast 推进到密码锁")

	# 6) 存档序列化包含玩家名
	var d := GameState.to_dict()
	_check(String(d.get("player_name", "")) == "江晚", "to_dict 包含玩家名")
	GameState.player_name = "林昼"
	GameState.from_dict(d)
	_check(GameState.player_name == "江晚", "from_dict 恢复玩家名")

	# 7) {pname} 插值
	var out := StoryEngine._resolve_text("你叫{pname}，高二三班。")
	_check(out == "你叫江晚，高二三班。", "{pname} 插值（%s）" % out)

	# 8) 条件求值
	GameState.set_flag("flag_test", true)
	_check(StoryEngine.eval_cond("flag_test and truth>=0"), "条件求值 flag and num")
	_check(not StoryEngine.eval_cond("item:item_admin_key"), "条件求值：未持有道具")
	GameState.add_item("item_admin_key")
	_check(StoryEngine.eval_cond("item:item_admin_key"), "条件求值：持有道具")

	# 9) 回顾长度封顶
	for i in 500:
		StoryEngine._append_history("me", "第 %d 行" % i)
	_check(GameState.history.size() == 400, "回想记录封顶 400（实际 %d）" % GameState.history.size())

	# 10) 跳选（快进到下一选项）：fast 模式下应在选项处自动停止
	StoryEngine.start("prologue")
	StoryEngine.fast_mode = true
	var steps := 0
	while StoryEngine.fast_mode and steps < 300:
		StoryEngine.advance()
		steps += 1
	_check(not StoryEngine.fast_mode, "跳选模式在遇到选项后自动解除")
	_check(StoryEngine.waiting_choice, "跳选停止时引擎处于选项等待（实际 %s）" % str(StoryEngine.waiting_choice))
	# 清理：恢复引擎状态
	StoryEngine.fast_mode = false
	StoryEngine.waiting_choice = false

	# 11) 成就系统（v1.4.0）：定义表 / 事件解锁 / 持久化
	_check(Ach.ACHIEVEMENTS.size() == 22, "成就定义表共 22 项（实际 %d）" % Ach.ACHIEVEMENTS.size())
	GameState.persistent["achievements"] = {}
	GameState.persistent["clues_seen"] = []
	GameState.persistent["items_seen"] = []
	GameState.player_name = "江晚"
	GameState.reset_run()
	_check(Ach.is_unlocked("ach_renamed"), "自定义名开局 -> 解锁「不是我」")
	GameState.player_name = "林昼"
	GameState.set_num("sanity", 15)
	_check(Ach.is_unlocked("ach_sanity_ghost"), "理智<=20 -> 解锁「镜子里的另一个」")
	GameState.set_num("truth", 1280)
	_check(Ach.is_unlocked("ach_truth_tier"), "真相>=1280 -> 解锁「第七层」")
	for c in ["clue_mirror", "clue_liheng", "clue_room325", "clue_rules", "clue_rollcall",
			"clue_shenhe_fire", "clue_shenhe_dead", "clue_cycle", "clue_replacement",
			"clue_gate"]:
		GameState.add_clue(c)
	_check(Ach.is_unlocked("ach_ten_clues"), "累计 10 条线索 -> 解锁「拾纸人」")
	for it in ["item_record_slip", "item_library_card", "item_page109", "item_admin_key",
			"item_partial_roster", "item_night_roster", "item_roster_core", "item_log_fragment",
			"item_fire_tape", "item_broadcast_register", "item_lighter", "item_candle"]:
		GameState.add_item(it)
	_check(Ach.is_unlocked("ach_half_items"), "累计 12 种道具 -> 解锁「口袋里的证据」")
	_check((GameState.persistent.get("items_seen", []) as Array).size() == 12, "道具收集写入持久层")
	GameState.register_loss("梁野", "冒烟测试")
	_check(Ach.is_unlocked("ach_first_loss"), "首次失去同伴 -> 解锁「没能都带走」")
	Ach.notify_padlock_solved("0109")
	Ach.notify_padlock_solved("2119")
	_check(Ach.is_unlocked("ach_locksmith"), "单周目两把锁 -> 解锁「锁匠」")
	GameState.set_num("truth", 1500)
	GameState.record_ending("ending_true_release")
	_check(Ach.is_unlocked("ach_first_ending"), "任意结局 -> 解锁「下课」")
	_check(Ach.is_unlocked("ach_end_true"), "真结局 -> 解锁「点名停止」")
	_check(Ach.is_unlocked("ach_speedrun"), "90 分钟内结局 -> 解锁「一次下课」")
	_check(not Ach.is_unlocked("ach_true_clean"), "有失去记录时不解锁「一个都不少」")
	GameState.record_ending("ending_bittersweet_exchange")
	GameState.record_ending("ending_manager")
	_check(Ach.is_unlocked("ach_looper"), "完成 3 周目 -> 解锁「第 112 次重排」")

	# 12) 番外《天晴》：可完整推进到番外结局
	GameState.reset_run()
	_lines.clear()
	StoryEngine.start("extra_sunny_day")
	_drain(400)
	_check(StoryEngine.waiting_choice, "番外推进到「笔的去处」选项")
	var extra_ending := ""
	StoryEngine.story_finished.connect(func(e): extra_ending = e)
	StoryEngine.pick_choice({"text": "把笔放到旧楼广播室的窗台上去", "target": "extra_sunny_broadcast", "cond": "", "lock": "", "effects": []})
	_check(extra_ending == "ending_extra_sunny", "番外选项 -> 广播室分支 -> 番外结局（实际 %s）" % extra_ending)
	_check(Ach.is_unlocked("ach_sunny"), "完成番外 -> 解锁「天晴」")

	print("SMOKE: done, failures = ", _fail)
