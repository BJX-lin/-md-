extends Node
## 成就系统（v1.4.0 新增）。
##
## 职责：
##   1) 成就定义表 ACHIEVEMENTS（单一数据源，面板与判定共用）；
##   2) 监听 GameState / StoryEngine 事件，判定并解锁成就；
##   3) 解锁结果写入 GameState.persistent["achievements"] 并落盘
##      （user://persistent.json，跨周目保留）；
##   4) 发出 unlocked(id) 信号，由游戏界面弹 Toast 提示。
##
## 触发源一览：
##   run_reset          —— 周目重置（清理单周目状态 / 自定义名判定）
##   clue_added         —— 线索收集（累计 10 条 / 全 36 条）
##   item_gained        —— 道具获得（累计 12 种 / 全 23 种）
##   loss_registered    —— 首次失去同伴
##   ending_recorded    —— 各结局 / 全结局 / 周目数 / 结局时数值结算
##   var_changed        —— 理智 <= 20 / 单周目真相 >= 1280
##   chapter_started    —— 到达第四章
##   notify_padlock_solved —— 单周目解开两把数字锁

signal unlocked(id: String)

## 成就定义：id -> {name, desc, hidden}
## hidden = 未解锁时面板只显示 ？？？（结局类成就不剧透）。
const ACHIEVEMENTS := {
	"ach_first_ending": {"name": "下课", "desc": "达成任意一个结局。", "hidden": true},
	"ach_end_true": {"name": "点名停止", "desc": "达成真结局《点名停止》。", "hidden": true},
	"ach_end_bittersweet": {"name": "留堂", "desc": "达成遗憾结局《留堂》。", "hidden": true},
	"ach_end_manager": {"name": "管理员", "desc": "达成管理者结局《管理员》。", "hidden": true},
	"ach_end_destroyer": {"name": "焚校", "desc": "达成毁灭结局《焚校》。", "hidden": true},
	"ach_end_empty": {"name": "到", "desc": "达成空席结局《到》。", "hidden": true},
	"ach_all_endings": {"name": "观测者", "desc": "集齐全部五个结局。", "hidden": false},
	"ach_true_clean": {"name": "一个都不少", "desc": "没有任何同伴失去，并达成真结局。", "hidden": true},
	"ach_ten_clues": {"name": "拾纸人", "desc": "累计收集 10 条线索。", "hidden": false},
	"ach_all_clues": {"name": "档案管理员", "desc": "集齐全部 36 条线索。", "hidden": false},
	"ach_half_items": {"name": "口袋里的证据", "desc": "累计获得 12 种道具。", "hidden": false},
	"ach_all_items": {"name": "收藏家", "desc": "集齐全部 23 种道具。", "hidden": false},
	"ach_all_galleries": {"name": "五段终幕", "desc": "在结局与记录中回放过全部五段终幕。", "hidden": false},
	"ach_reach_ch4": {"name": "旧楼在白天也很冷", "desc": "进入第四章。", "hidden": false},
	"ach_first_loss": {"name": "没能都带走", "desc": "第一次失去同伴。", "hidden": false},
	"ach_locksmith": {"name": "锁匠", "desc": "同一个周目里解开两把数字锁（0109 与 2119）。", "hidden": false},
	"ach_sanity_ghost": {"name": "镜子里的另一个", "desc": "理智值跌到 20 以下。", "hidden": false},
	"ach_truth_tier": {"name": "第七层", "desc": "单个周目内真相值达到 1280（最高阈值）。", "hidden": false},
	"ach_renamed": {"name": "不是我", "desc": "用自己的名字开始游戏。", "hidden": false},
	"ach_looper": {"name": "第 112 次重排", "desc": "完成 3 个周目。", "hidden": false},
	"ach_speedrun": {"name": "一次下课", "desc": "开始新游戏后 90 分钟内达成结局。", "hidden": true},
	"ach_sunny": {"name": "天晴", "desc": "完成番外《天晴》。", "hidden": true},
}

const MAIN_ENDINGS := [
	"ending_true_release",
	"ending_bittersweet_exchange",
	"ending_manager",
	"ending_destroyer",
	"ending_empty_seat",
]

## 单周目状态（run_reset 时清空）
var _run_padlocks: Array[String] = []

func _ready() -> void:
	GameState.run_reset.connect(_on_run_reset)
	GameState.clue_added.connect(_on_clue)
	GameState.item_gained.connect(_on_item)
	GameState.loss_registered.connect(_on_loss)
	GameState.ending_recorded.connect(_on_ending)
	GameState.var_changed.connect(_on_var_changed)
	StoryEngine.chapter_started.connect(_on_chapter)

#region 查询

func is_unlocked(id: String) -> bool:
	var a: Dictionary = GameState.persistent.get("achievements", {})
	return a.has(id)

func unlocked_count() -> int:
	var a: Dictionary = GameState.persistent.get("achievements", {})
	return a.size()

func total_count() -> int:
	return ACHIEVEMENTS.size()

func name_of(id: String) -> String:
	return String(ACHIEVEMENTS.get(id, {}).get("name", id))

func desc_of(id: String) -> String:
	return String(ACHIEVEMENTS.get(id, {}).get("desc", ""))

func is_hidden(id: String) -> bool:
	return bool(ACHIEVEMENTS.get(id, {}).get("hidden", false))

func unlocked_time(id: String) -> String:
	var a: Dictionary = GameState.persistent.get("achievements", {})
	return String((a.get(id, {}) as Dictionary).get("t", ""))

#endregion

## 解锁一个成就。返回 true = 本次新解锁（已落盘并发出信号）。
func unlock(id: String) -> bool:
	if not ACHIEVEMENTS.has(id):
		return false
	var a: Dictionary = GameState.persistent.get("achievements", {})
	if a.has(id):
		return false
	a[id] = {"t": Time.get_datetime_string_from_system(true)}
	GameState.persistent["achievements"] = a
	SaveSystem.save_persistent()
	unlocked.emit(id)
	return true

## 密码锁解开回调（由 StoryEngine.padlock_done 成功分支调用）。
func notify_padlock_solved(code: String) -> void:
	if code == "":
		return
	if not _run_padlocks.has(code):
		_run_padlocks.append(code)
	if _run_padlocks.has("0109") and _run_padlocks.has("2119"):
		unlock("ach_locksmith")

#region 事件处理

func _on_run_reset() -> void:
	_run_padlocks.clear()
	# 自定义名：新周目开始时主角不叫「林昼」
	if GameState.player_name != "林昼" and GameState.player_name != "":
		unlock("ach_renamed")

func _on_clue(_id: String) -> void:
	var seen: int = (GameState.persistent.get("clues_seen", []) as Array).size()
	if seen >= 10:
		unlock("ach_ten_clues")
	if seen >= GameState.CLUES.size():
		unlock("ach_all_clues")

func _on_item(_id: String) -> void:
	var seen: int = (GameState.persistent.get("items_seen", []) as Array).size()
	if seen >= 12:
		unlock("ach_half_items")
	if seen >= GameState.ITEMS.size():
		unlock("ach_all_items")

func _on_loss(_who: String, _kind: String) -> void:
	unlock("ach_first_loss")

func _on_chapter(num: int, _title: String) -> void:
	# 只认主线第四章；番外（@chapter 6 天晴）不计入
	if num == 4:
		unlock("ach_reach_ch4")

func _on_var_changed(key: String, _old: int, new_value: int) -> void:
	if key == "sanity" and new_value <= 20:
		unlock("ach_sanity_ghost")
	elif key == "truth" and new_value >= 1280:
		unlock("ach_truth_tier")

func _on_ending(id: String) -> void:
	# 单结局成就（含番外）
	match id:
		"ending_true_release":
			unlock("ach_end_true")
		"ending_bittersweet_exchange":
			unlock("ach_end_bittersweet")
		"ending_manager":
			unlock("ach_end_manager")
		"ending_destroyer":
			unlock("ach_end_destroyer")
		"ending_empty_seat":
			unlock("ach_end_empty")
		"ending_extra_sunny":
			unlock("ach_sunny")
	unlock("ach_first_ending")

	# 汇总类：结局档案权重用（用持久层而非 match，避免漏加新结局）
	var got: Dictionary = GameState.persistent.get("endings", {})
	var main_got := 0
	for e in MAIN_ENDINGS:
		if got.has(e):
			main_got += 1
	if main_got >= MAIN_ENDINGS.size():
		unlock("ach_all_endings")

	# 干净的真结局
	if id == "ending_true_release" and GameState.deaths.is_empty():
		unlock("ach_true_clean")

	# 周目数
	if int(GameState.persistent.get("cycles", 0)) >= 3:
		unlock("ach_looper")

	# 结局时的单周目数值结算
	if GameState.get_num("truth") >= int(Cfg.BAR_MAX.get("truth", 1500)):
		unlock("ach_truth_tier")
	# 速通：单周目游戏时长（play_seconds 自 reset_run 起算）
	if GameState.play_seconds <= 90.0 * 60.0:
		unlock("ach_speedrun")

	# 终幕回放全收集（@gallery 与 @ending 相邻触发，此处统计即可）
	var gal: int = (GameState.persistent.get("gallery", []) as Array).size()
	if gal >= 5:
		unlock("ach_all_galleries")

#endregion
