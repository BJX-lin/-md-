extends Node
# Endings

signal var_changed(key: String, old_value: int, new_value: int)
signal time_changed(day: int, minute: int)
# Achievements（v1.4.0）：供 Ach 自动加载监听
signal clue_added(id: String)
signal item_gained(id: String)
signal loss_registered(who: String, kind: String)
signal ending_recorded(id: String)
signal run_reset()

var nums: Dictionary = {}
var flags: Dictionary = {}
var states: Dictionary = {}
var inventory: Array[String] = []
var clues: Array[String] = []
var visited_nodes: Dictionary = {}
var history: Array = []
# UI
# Save/Load
var player_name: String = "林昼"
var current_chapter: int = 1
# Save/Load
# Sprite
var save_tampered := false  # Save/Load
var scene_bg: String = "black"
var scene_variant: String = ""
var scene_actors: Array = []        # [{who, emo, pos}, ...]
var current_node: String = ""
# Time
var story_day: int = 1
var story_minute: int = 14 * 60 + 40
var play_seconds: float = 0.0
var deaths: Array[String] = []
var choice_log: Array = []

var persistent := {
	"endings": {},
	"clues_seen": [],  # Clues
	"cycles": 0,
	"gallery": [],  # FX
	"best_truth": 0,
	"items_seen": [],   # Items（跨周目收集，成就用）
	"achievements": {},  # Achievements（id -> {t}，由 Ach 维护）
}

# Items
const ITEMS := {
	"item_record_slip": {"name": "被揉皱的违纪记录表", "desc": "纸背印着一行被擦过的名字，笔压还在。终章可证明你被“看守”过。"},
	"item_library_card": {"name": "梁野的借书卡", "desc": "卡上名字被反复描过。终章可用来把梁野从名单里拉回一次。"},
	"item_page109": {"name": "第109页残片", "desc": "边缘焦黑。背面用铅笔写着“别替我答到”。"},
	"item_admin_key": {"name": "管理员钥匙", "desc": "老秦值班室的黄铜钥匙，齿口磨圆了。开校史馆内门与广播主控柜。"},
	"item_partial_roster": {"name": "残缺补位名单", "desc": "沈禾（删除未完成）/ 林昼（待定）。撕口很新。"},
	"item_night_roster": {"name": "夜间核对名单", "desc": "凌晨两点会自己改写的一页纸。真结局硬前置之一。"},
	"item_roster_core": {"name": "核心名单页", "desc": "总名单最中间的一页，写满了同一个名字。"},
	"item_log_fragment": {"name": "许清的日志残页", "desc": "在册 / 待定 / 删除未完成 —— 术语第一次被写全。"},
	"item_fire_tape": {"name": "火灾录像带", "desc": "五年前旧楼广播室的监控。画面里有人反锁了门。"},
	"item_broadcast_register": {"name": "广播值班登记册", "desc": "沈禾、沈禾、沈禾（删除）、林昼（补）、林昼（补）……"},
	"item_lighter": {"name": "老秦的打火机", "desc": "机身有烧灼痕。毁灭路线的火种。"},
	"item_candle": {"name": "半截蜡烛", "desc": "梁野塞给你的。停电时它比手机好用。"},
	"item_seat_chart": {"name": "旧座位表", "desc": "最后一排靠窗的名字被擦了三次，纸都毛了。"},
	"item_dorm_rules": {"name": "住宿生守则", "desc": "宿管给的旧打印件。前十条是正常校规，最后三条字体不同，是后来加上去的。"},
	"item_qin_list": {"name": "老秦的名单", "desc": "逐年手抄的学生名单，勾＝还记得脸，叉＝只记得名字。今年那页只剩三个勾，其中一个是你——「趁我还记得」。"},
	"item_backdoor_key": {"name": "东楼后门钥匙", "desc": "老秦一直没挂上钥匙板的真钥匙，怕它被换成假的。「待定的人才进得去。它防在册的人，不防待定的。」"},
	"item_practice_book": {"name": "抄满的练习册", "desc": "第四张床底下的练习册。同一句话抄了几百遍：「我记得我叫什么」。后面变成「但我不确定这是不是我的名字」。最后一页笔没水了，写的人不知道，一直往下写。"},
	"item_self_sms": {"name": "发给自己的短信", "desc": "「我叫林昼。转学生。高二三班最后一排靠窗。如果你读到这条不记得自己是谁，就照着上面念一遍。」"},
	"item_class_note": {"name": "数学书上的一行字", "desc": "「高二（3）班 四十一人／三月十七日 上午第三节 数学／他们都在」。在这个地方待久了，每个人最后都会开始记账。"},
	"item_missing_poster": {"name": "寻人启事", "desc": "从食堂墙上揭下来的。背面有铅笔字：「别贴了 她没走 她在楼里 每年都有人贴 每年都被撕」"},
	"item_bus_ticket": {"name": "周芸的车票", "desc": "座位号 42。背面是周叙写的：「如果到站没人接，就在原地等。别自己走。」"},
	"item_seat41_stub": {"name": "41 号票根", "desc": "藏在周芸手机电池底下。背面擦掉的压痕写着：「她让我坐这儿的。」"},
	"item_mirror_shard": {"name": "镜片碎片", "desc": "碎片里的你，总比你慢半拍。边缘割过手。"},
}

# Clues
const CLUES := {
	"clue_mirror": {"name": "镜子里多一个", "ch": 2, "text": "水房镜子里比实际多一个人。他背对镜子却出现在镜中，头原地转了一百八十度，对口型说「你也别替我答到」。"},
	"clue_liheng": {"name": "被挪走的李恒", "ch": 2, "text": "307 门牌名单里，印刷体的「李恒」被记号笔写的「林昼」盖住。李恒还在上学，但他「住在这里」这件事被删掉了。"},
	"clue_room325": {"name": "325 号房", "ch": 2, "text": "走廊尽头没有名单的宿舍。通电、每周有人打扫、四个搪瓷缸杯底有水、四张床板是温的。"},
	"clue_rules": {"name": "住宿生守则后三条", "ch": 2, "text": "十一、查寝须应答。十二、查寝结束前不要照镜子。十三、走廊叫名字不要答应，除非叫了三遍——「叫三遍的是人」。"},
	"clue_rollcall": {"name": "许清念的是四十二个", "ch": 4, "text": "她每天点名念的是完整名册四十二个，你们只听见四十一个应答。念到某处那个短停顿，是在等一个不会来的回答。「因为不念，就真的没了。」"},
	"clue_shenhe_fire": {"name": "五月十七日的广播", "ch": 4, "text": "起火当晚广播话筒开着，全校喇叭响了四十分钟。沈禾在念高二三班名册，念完四十六个从头再念，念了七遍。一千多人听见，没有一个人应。"},
	"clue_shenhe_dead": {"name": "「已故」会褪成「转出」", "ch": 4, "text": "教务处原件写沈禾「转出临川第三中学」（该校不存在）。许清自己打印一份改成「已故」——但那两个字每年会自行变淡成「转出」。她已重打第五份。"},
	"clue_cycle": {"name": "间隔在缩短", "ch": 4, "text": "转出人数逐年上升，间隔从七个月缩到九天。「一开始它一年吃一个，现在它九天吃一个。」最后会变成零天——不需要间隔，就是一次拿走所有人。"},
	"clue_replacement": {"name": "补位机制", "ch": 4, "text": "三种状态：在册／待定／删除。待定＝名字还在、人也还在，但两边对不上号。位置空着就会有人补上来，然后你变成多余的那个。每一个补位的，都是上一轮被顶掉的——不是一个鬼在吃人，是一条队。"},
	"clue_gate": {"name": "入校 109，出校 0", "ch": 4, "text": "校门刷卡记录：你入校 4 次、出校 0 次。你记得刷卡、记得响声，却想不起闸门打开走过去那一秒。全校五年共 109 个学号有入校无出校——「第 109 次」「第 109 页」都是这个数。"},
	"clue_qin_records": {"name": "老秦的手抄名单", "ch": 4, "text": "躺椅底下一箱纸：从未贴出的寻人启事，和逐年手抄的名单。勾＝还记得脸，叉＝只记得名字。今年那页只剩三个勾：沈禾、每天数座位表的男生、以及你。"},
	"clue_empty_seat": {"name": "被照料的空位", "ch": 1, "text": "最后一排靠窗的桌子每天早上都是干净的。保洁只扫地不擦桌。没有人知道是谁擦的。"},
	"clue_duty_swap": {"name": "值日表上的修正液", "ch": 1, "text": "周三第四个位置被修正液盖了不止一层，最下面那层已经发黄。现在写着你的名字。"},
	"clue_shenhe_missing": {"name": "寻人启事", "ch": 1, "text": "食堂墙角的寻人启事，沈禾，5 月 17 日晚离校未归。同样的启事一层压一层贴了至少五张。"},
	"clue_bed_marks": {"name": "床板刻痕", "ch": 1, "text": "307 靠窗床板上的刻痕会自己增加。梁野上学期数是二十三道，上个月是二十四道。那张床一直空着。"},
	"clue_old_building": {"name": "从里面钉死的窗", "ch": 1, "text": "旧楼二十四扇窗，二十三扇木条横钉，三楼左起第三扇是竖钉的——那扇窗是从里面钉的。"},
	"clue_record_table": {"name": "违纪记录表", "ch": 1, "text": "报到第一天，桌上就压着一张写着你名字的违纪记录表。日期不是今天。"},
	"clue_erased_seat": {"name": "被擦掉的座位名", "ch": 1, "text": "座位表最后一排靠窗，被反复擦过三次。周叙不许你问。"},
	"clue_missing_one": {"name": "人数不对", "ch": 1, "text": "点名结束后，许清说了一句“人数不对”。全班没有人反驳。"},
	"clue_page109": {"name": "第109页", "ch": 1, "text": "图书馆那本书的第109页被撕走了。撕口是新的，每次都是新的。"},
	"clue_dont_answer": {"name": "别替我答到", "ch": 1, "text": "残页背面的铅笔字。全作最核心的一条规则。"},
	"clue_first_rollcall": {"name": "第一次异常点名", "ch": 1, "text": "广播念到一个只有姓的名字：“沈——”。后半个音被吃掉了。"},
	"clue_knock_pattern": {"name": "门外的敲门节奏", "ch": 1, "text": "三下，停，两下。宿管从来不这么敲。"},
	"clue_headcount": {"name": "影子数不对", "ch": 3, "text": "四个人的宿舍，地上有五道影子；查寝的人却只数四下。"},
	"clue_shampoo": {"name": "劣质洗发水味", "ch": 2, "text": "廉价洗发水混着烧焦电路的味道。她出现前，总是先有味道。"},
	"clue_repeat_name": {"name": "重复的名字", "ch": 2, "text": "值班登记册上，“林昼（补）”写了很多遍，字迹一次比一次浅。"},
	"clue_terms": {"name": "名单术语", "ch": 2, "text": "在册：安全。待定：可被替换。删除未完成：还留在这里的人。"},
	"clue_shenhe_name": {"name": "沈禾的全名", "ch": 2, "text": "沈禾。五年前旧楼火灾里，唯一没有被念完名字的人。"},
	"clue_zhouxu_fill": {"name": "周叙补过名字", "ch": 3, "text": "他每次替缺席的人答“到”，都是为了让晚自习能下课。"},
	"clue_xuqing_barefoot": {"name": "许清不穿鞋", "ch": 3, "text": "她在走廊上从不穿鞋，脚底干净得不像走过路。"},
	"clue_night_rewrite": {"name": "名单会在夜里改写", "ch": 3, "text": "凌晨两点十七分，纸上的墨会自己动。你的名字后面多了“可补”。"},
	"clue_109th": {"name": "第109次", "ch": 4, "text": "录像编号 109。你在其中的每一次，都坐在最后一排靠窗。"},
	"clue_xuqing_dead": {"name": "许清早已不在", "ch": 4, "text": "五年前的教师名录里，她的名字后面写着“已故”。她只是还在描线。"},
	"clue_self_repeat": {"name": "重复的你", "ch": 4, "text": "档案里有很多个林昼。照片上的脸，一次比一次模糊。"},
	"clue_rule_gap": {"name": "规则的漏洞", "ch": 4, "text": "删除未完成者，不能由同格替补直接覆盖。他们一直在跳步骤。"},
	"clue_fire_truth": {"name": "五年前的火", "ch": 4, "text": "广播室的门从外面被反锁。点名还在继续，没有人停下。"},
}

func _ready() -> void:
	reset_run()
	set_process(true)

func _process(delta: float) -> void:
	play_seconds += delta

func reset_run() -> void:
	nums = Cfg.NUM_DEFAULT.duplicate(true)
	flags = {}
	states = Cfg.ENUM_DEFAULT.duplicate(true)
	inventory = []
	clues = []
	visited_nodes = {}
	history = []
	choice_log = []
	deaths = []
	current_chapter = 1
	scene_bg = "black"
	scene_variant = ""
	scene_actors.clear()
	current_node = ""
	story_day = 1
	story_minute = 14 * 60 + 40
	play_seconds = 0.0

	var cyc: int = int(persistent.get("cycles", 0))
	if cyc > 0:
		nums["memory_echo"] = mini(3 + cyc, 8)
	run_reset.emit()

# Time
const DAY_LABEL: Array[String] = ["", "第一天", "第二天", "第三天", "第四天", "第五天"]

func set_story_time(day: int, minute: int) -> void:
	var before := story_day * 24 * 60 + story_minute
	story_day = maxi(1, day)
	story_minute = clampi(minute, 0, 24 * 60 - 1)

	# Time

	if OS.is_debug_build():
		var after := story_day * 24 * 60 + story_minute
		if after < before:
			var msg := "[时间倒流] @time 把时钟从 第%d天%02d:%02d 拨回 第%d天%02d:%02d；" % [
				before / 1440, (before % 1440) / 60, (before % 1440) % 60,
				story_day, story_minute / 60, story_minute % 60]
			push_warning(msg + "若该节点可被多条支线以不同顺序进入，请改用 @timeat。")
	time_changed.emit(story_day, story_minute)

# Time

# Time

# Time
func seek_story_time(day: int, minute: int, min_advance: int = 5) -> void:
	var target := day * 24 * 60 + clampi(minute, 0, 24 * 60 - 1)
	var now := story_day * 24 * 60 + story_minute
	if target > now:
		story_day = maxi(1, day)
		story_minute = clampi(minute, 0, 24 * 60 - 1)
		time_changed.emit(story_day, story_minute)
	else:
		advance_time(maxi(0, min_advance))

func advance_time(minutes: int) -> void:
	var total := story_minute + minutes
	while total >= 24 * 60:
		total -= 24 * 60
		story_day += 1
	story_minute = total
	time_changed.emit(story_day, story_minute)

func time_hhmm() -> String:
	return "%02d:%02d" % [story_minute / 60, story_minute % 60]

func time_phase() -> String:
	var h := story_minute / 60
	if h < 5:
		return "凌晨"
	elif h < 8:
		return "清晨"
	elif h < 12:
		return "上午"
	elif h < 14:
		return "中午"
	elif h < 18:
		return "下午"
	elif h < 22:
		return "夜晚"
	return "深夜"

func time_display() -> String:
	var d: String = DAY_LABEL[clampi(story_day, 0, DAY_LABEL.size() - 1)] if story_day < DAY_LABEL.size() else ("第%d天" % story_day)
	return "%s　%s %s" % [d, time_phase(), time_hhmm()]

# Stats
func get_num(key: String) -> int:
	return int(nums.get(key, 0))

func set_num(key: String, value: int) -> void:
	var old := get_num(key)
	var nv := Cfg.clampi_var(key, value)
	nums[key] = nv
	if nv != old:
		var_changed.emit(key, old, nv)

func add_num(key: String, delta: int) -> void:
	set_num(key, get_num(key) + delta)

func get_flag(key: String) -> bool:
	return bool(flags.get(key, false))

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func get_state(key: String) -> String:
	return String(states.get(key, ""))

func set_state(key: String, value: String) -> void:
	states[key] = value

# Items
func has_item(id: String) -> bool:
	return inventory.has(id)

func add_item(id: String) -> void:
	if not inventory.has(id):
		inventory.append(id)
		# Achievements：跨周目道具收集记录
		var seen: Array = persistent.get("items_seen", [])
		if not seen.has(id):
			seen.append(id)
			persistent["items_seen"] = seen
		item_gained.emit(id)

func remove_item(id: String) -> void:
	inventory.erase(id)

func add_clue(id: String) -> void:
	if not clues.has(id):
		clues.append(id)
		var seen: Array = persistent.get("clues_seen", [])
		if not seen.has(id):
			seen.append(id)
			persistent["clues_seen"] = seen
		clue_added.emit(id)

func item_name(id: String) -> String:
	return String(ITEMS.get(id, {}).get("name", id))

func register_loss(who: String, kind: String) -> void:
	var rec := "%s:%s" % [who, kind]
	if not deaths.has(rec):
		deaths.append(rec)
		loss_registered.emit(who, kind)

# Chapters
# Chapters
func settle_chapter_1() -> void:
	if get_flag("flag_liangye_library") and get_flag("flag_library_page109"):
		set_state("liangye_state", "fear_alive")
	elif get_num("trust_liangye") < 0 and not get_flag("flag_liangye_library"):
		set_state("liangye_state", "missing_marked")
	elif get_num("trust_liangye") >= 4:
		set_state("liangye_state", "ally_shaken")
	else:
		set_state("liangye_state", "normal")

	if get_num("trust_zhouxu") >= 2:
		set_state("zhouxu_state", "guarding")
	elif get_num("trust_zhouxu") <= -5:
		set_state("zhouxu_state", "hiding")
	else:
		set_state("zhouxu_state", "normal")

	if get_num("shenhe_focus") >= 9:
		set_state("shenhe_state", "calling")
	else:
		set_state("shenhe_state", "echo")

	if get_num("trust_xuqing") <= -3:
		set_state("xuqing_state", "suspected")
	current_chapter = 2

# Chapters
func settle_chapter_2() -> void:
	if get_flag("flag_liangye_marked") and get_num("trust_liangye") < 0:
		set_state("liangye_state", "missing_marked")
		add_item("item_library_card")
		add_num("truth", 2)
		register_loss("梁野", "被点名带走")
	elif get_flag("flag_liangye_half"):
		set_state("liangye_state", "half_assimilated")
	elif get_num("trust_liangye") >= 4:
		set_state("liangye_state", "ally_shaken")
	elif get_flag("flag_liangye_library") and get_flag("flag_library_page109"):
		set_state("liangye_state", "fear_alive")
	else:
		set_state("liangye_state", "fear_alive")

	if get_num("trust_zhouxu") >= 2:
		set_state("zhouxu_state", "guarding")
	elif get_num("trust_zhouxu") <= -5:
		set_state("zhouxu_state", "coercing")
	else:
		set_state("zhouxu_state", "hiding")

	if get_flag("flag_oldqin_survived"):
		set_state("oldqin_state", "alive")
	elif get_flag("flag_oldqin_burndeath"):
		set_state("oldqin_state", "burned")
		register_loss("老秦", "值班室起火")
	elif get_flag("flag_oldqin_missing"):
		set_state("oldqin_state", "missing")
		register_loss("老秦", "失踪")

	if get_num("shenhe_focus") >= 20 or get_flag("flag_first_face_to_face_shenhe"):
		set_state("shenhe_state", "half_present")
	elif get_num("shenhe_focus") >= 9:
		set_state("shenhe_state", "calling")

	if get_num("trust_xuqing") <= -3 or get_flag("flag_found_xuqing_log_fragment"):
		set_state("xuqing_state", "suspected")
	current_chapter = 3

# Chapters
func settle_chapter_3() -> void:

	if get_flag("flag_gave_up_roommate"):
		set_state("liangye_final_state_ch3", "abandoned")
		register_loss("梁野", "被放弃")
	elif get_flag("flag_liangye_half_assimilated"):
		set_state("liangye_final_state_ch3", "rescued_half" if get_num("trust_liangye") >= 3 else "missing")
	elif get_flag("flag_liangye_returned") and get_num("trust_liangye") >= 4:
		set_state("liangye_final_state_ch3", "anchor_alive")
	elif get_flag("flag_liangye_returned"):
		set_state("liangye_final_state_ch3", "fragile_alive")
	elif get_state("liangye_state") == "missing_marked":
		set_state("liangye_final_state_ch3", "missing")
		register_loss("梁野", "未救回")
	else:
		set_state("liangye_final_state_ch3", "fragile_alive")

	if get_num("trust_zhouxu") >= 4 and get_flag("flag_zhouxu_confessed_part"):
		set_state("zhouxu_final_state_ch3", "confessor_protector")
	elif get_num("trust_zhouxu") <= -5:
		set_state("zhouxu_final_state_ch3", "coercer")
	else:
		set_state("zhouxu_final_state_ch3", "split_guard")

	# Endings
	if get_flag("flag_name_written_back"):
		set_flag("true_end_precondition_1", true)
	if get_flag("flag_night_roster_taken") or has_item("item_night_roster"):
		set_flag("true_end_precondition_2", true)
	if get_flag("flag_found_xuqing_log_fragment") and get_num("truth") >= 640:
		set_flag("archive_route_bonus", true)
	current_chapter = 4

# Chapters
func settle_chapter_4() -> void:
	# Endings
	# Conditions

	if get_flag("flag_name_written_back"):
		set_flag("true_end_precondition_1", true)
	if get_flag("flag_night_roster_taken") or has_item("item_night_roster"):
		set_flag("true_end_precondition_2", true)

	# Truth
	var t := get_num("truth")
	var core := get_flag("flag_saw_fire_video") and get_flag("flag_saw_self_repeat") and get_flag("flag_rule_terms_complete")
	# Truth

	# Truth
	# Endings
	var th_complete := 740 if get_flag("flag_testimony_given") else 820
	if t >= th_complete and core and get_flag("flag_true_linday_status_known"):
		set_state("truth_state", "complete")
	elif t >= 640 and (get_flag("flag_saw_fire_video") or get_flag("flag_roster_core_taken")):
		set_state("truth_state", "high")
	else:
		set_state("truth_state", "partial")

	# State
	match get_state("liangye_final_state_ch3"):
		"anchor_alive":
			set_state("liangye_end_state", "present_anchor" if not get_flag("flag_liangye_final_loss") else "absent_echo")
		"rescued_half":
			set_state("liangye_end_state", "present_fragile_truth" if not get_flag("flag_liangye_final_loss") else "absent_echo")
		"fragile_alive":
			set_state("liangye_end_state", "present_unstable" if not get_flag("flag_liangye_final_loss") else "absent_echo")
		_:
			set_state("liangye_end_state", "absent_echo")

	# State
	match get_state("zhouxu_final_state_ch3"):
		"confessor_protector":
			set_state("zhouxu_end_state", "enter_with_player" if get_num("trust_zhouxu") >= 4 else "follow_to_threshold")
		"coercer":
			set_state("zhouxu_end_state", "pressure_player")
		_:
			set_state("zhouxu_end_state", "follow_to_threshold")

	# Conditions
	var ready_broadcast := (has_item("item_roster_core") or has_item("item_night_roster")) \
		and (has_item("item_admin_key") or get_flag("flag_fakewall_opened")) \
		and get_num("truth") >= 863
	if ready_broadcast:
		set_flag("flag_terminal_broadcast_ready", true)
	current_chapter = 5

# Endings
func _true_end_weight() -> int:
	var w := 0
	if get_flag("flag_name_written_back"):
		w += 2
	if get_flag("flag_night_roster_taken"):
		w += 2
	if get_flag("flag_chose_save_shenhe"):
		w += 3
	if get_num("trust_liangye") >= 4:
		w += 2
	match get_state("liangye_end_state"):
		"present_anchor":
			w += 2
		"present_fragile_truth":
			w += 1
		"absent_echo":
			w -= 2
	if get_num("trust_zhouxu") >= 3:
		w += 1
	if get_state("zhouxu_end_state") == "enter_with_player":
		w += 1
	if get_flag("flag_saw_fire_video"):
		w += 1
	if get_flag("flag_true_linday_status_known"):
		w += 1
	return w

func can_true_end() -> bool:
	return (
		get_state("truth_state") == "complete"
		and get_flag("true_end_precondition_1")
		and get_flag("true_end_precondition_2")
		and get_num("save_route_score") >= 100
		and get_flag("flag_rule_terms_complete")
		and get_flag("flag_terminal_broadcast_ready")
		and not get_flag("flag_gave_up_roommate")
		and get_state("liangye_end_state") in ["present_anchor", "present_fragile_truth"]
		and _true_end_weight() >= 8
	)

func can_bittersweet_exchange() -> bool:
	return (
		get_num("save_route_score") >= 80
		and get_flag("flag_terminal_broadcast_ready")
		and (
			get_state("liangye_end_state") == "absent_echo"
			or not get_flag("flag_rule_terms_complete")
			or get_flag("flag_player_self_substitute")
		)
	)

func can_destroyer() -> bool:
	return (
		get_num("end_cycle_score") >= 7
		and get_flag("flag_terminal_broadcast_ready")
		and get_flag("flag_chose_end_cycle")
	)

func can_manager() -> bool:
	return (
		get_num("control_route_score") >= 7
		or (get_flag("flag_gave_up_roommate") and get_num("control_route_score") >= 5)
	)

func determine_ending() -> String:
	# Endings

	if save_tampered:
		return "ending_empty_seat"
	if flags.get("flag_count_overflow", false):
		states["truth_state"] = "complete"
		flags["flag_terminal_broadcast_ready"] = true
		flags["true_end_precondition_1"] = true
		flags["true_end_precondition_2"] = true
		flags["flag_rule_terms_complete"] = true
	if can_true_end():
		return "ending_true_release"
	elif can_bittersweet_exchange():
		return "ending_bittersweet_exchange"
	elif can_destroyer():
		return "ending_destroyer"
	elif can_manager():
		return "ending_manager"
	return "ending_empty_seat"

func record_ending(id: String) -> void:
	var e: Dictionary = persistent.get("endings", {})
	e[id] = int(e.get(id, 0)) + 1
	persistent["endings"] = e
	persistent["cycles"] = int(persistent.get("cycles", 0)) + 1
	persistent["best_truth"] = maxi(int(persistent.get("best_truth", 0)), get_num("truth"))
	SaveSystem.save_persistent()
	ending_recorded.emit(id)

func unlock_gallery(id: String) -> void:
	var g: Array = persistent.get("gallery", [])
	if not g.has(id):
		g.append(id)
		persistent["gallery"] = g
		SaveSystem.save_persistent()

# Save/Load
func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"nums": nums.duplicate(true),
		"flags": flags.duplicate(true),
		"states": states.duplicate(true),
		"inventory": inventory.duplicate(),
		"clues": clues.duplicate(),
		"visited": visited_nodes.duplicate(true),
		"chapter": current_chapter,
		"node": current_node,
		"time": play_seconds,
		"story_day": story_day,
		"story_minute": story_minute,
		"deaths": deaths.duplicate(),
		"choice_log": choice_log.duplicate(true),
		"history": history.slice(maxi(0, history.size() - 200)),
		"scene_bg": scene_bg,
		"scene_variant": scene_variant,
		"scene_actors": scene_actors.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	player_name = String(d.get("player_name", "林昼"))
	nums = Cfg.NUM_DEFAULT.duplicate(true)
	for k in d.get("nums", {}):
		nums[k] = int(d["nums"][k])
	flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	states = Cfg.ENUM_DEFAULT.duplicate(true)
	for k in d.get("states", {}):
		states[k] = String(d["states"][k])
	inventory.clear()
	for i in d.get("inventory", []):
		inventory.append(String(i))
	clues.clear()
	for c in d.get("clues", []):
		clues.append(String(c))
	visited_nodes = (d.get("visited", {}) as Dictionary).duplicate(true)
	current_chapter = int(d.get("chapter", 1))
	current_node = String(d.get("node", ""))
	save_tampered = bool(d.get("_tampered", false))
	scene_bg = String(d.get("scene_bg", "black"))
	scene_variant = String(d.get("scene_variant", ""))
	scene_actors = (d.get("scene_actors", []) as Array).duplicate(true)
	play_seconds = float(d.get("time", 0.0))
	story_day = int(d.get("story_day", 1))
	story_minute = int(d.get("story_minute", 14 * 60 + 40))
	deaths.clear()
	for x in d.get("deaths", []):
		deaths.append(String(x))
	choice_log = (d.get("choice_log", []) as Array).duplicate(true)
	history = (d.get("history", []) as Array).duplicate(true)
