class_name ScoreSystem
extends RefCounted

# ============================================================
#  计分系统（V2.1）
#  维护双方“论证生命值/完整度” + 各类得分。
#  有效攻击扣对方生命，致命攻击扣更多；有效反击回血（有上限）。
#  提供结算所需的总分/完整度/命中/讲理/让步统计。
# ============================================================

const MAX_INTEGRITY := 100
const REPAIR_CAP_PER_GAME := 30    # 每局“回血”总上限
const MIN_INTEGRITY_REPAIR := 12

var player_integrity := MAX_INTEGRITY
var ai_integrity := MAX_INTEGRITY

var player_score := 0      # 玩家讲理/证据得分
var ai_score := 0          # AI 命中玩家谬误得分
var player_hits := 0       # 玩家掉进谬误/情绪次数
var player_rebuttals := 0  # 有效反击次数
var ai_rebuttals := 0      # AI 让步次数
var player_concessions := 0
var _repair_used := 0

func reset() -> void:
	player_integrity = MAX_INTEGRITY
	ai_integrity = MAX_INTEGRITY
	player_score = 0
	ai_score = 0
	player_hits = 0
	player_rebuttals = 0
	ai_rebuttals = 0
	player_concessions = 0
	_repair_used = 0

# AI 成功攻击玩家：按杀伤力扣玩家生命
func apply_ai_attack(severity: float) -> void:
	var dmg := 5 + int(round(severity * 15.0))   # 5~20
	player_integrity = maxi(0, player_integrity - dmg)
	ai_score += 1
	player_hits += 1

# 玩家掉进谬误（也扣生命 + 计入 hits）
func apply_player_fallacy(severity: float) -> void:
	var dmg := 4 + int(round(severity * 10.0))
	player_integrity = maxi(0, player_integrity - dmg)
	player_hits += 1

# 玩家讲理得分 + 小幅回血（有上限）
func apply_player_good_move() -> void:
	player_score += 1
	_repair(player_integrity, 5, MIN_INTEGRITY_REPAIR)

func apply_player_rebuttal(quality: float) -> void:
	player_rebuttals += 1
	ai_integrity = maxi(0, ai_integrity - int(round(quality * 8.0)))
	var bonus := int(round(quality * 4.0))    # 逻辑分 +0~4
	player_score += maxi(0, bonus)

func apply_ai_concession(level: int) -> void:
	ai_rebuttals += 1
	player_concessions += 1
	# 让步让 AI 生命小幅降低（以示“认输了一回合”）
	ai_integrity = maxi(0, ai_integrity - level * 4)

func _repair(current: int, amount: int, cap: int) -> void:
	# 回血：不超过 per-amount、不越过 MAX、不超每局回血上限
	var room := MAX_INTEGRITY - current
	var avail := cap - _repair_used
	var heal := mini(amount, mini(room, avail))
	var new_val := current + heal
	_repair_used += heal
	player_integrity = new_val

func integrity_report() -> Dictionary:
	return {
		"player_integrity": player_integrity,
		"ai_integrity": ai_integrity,
		"player_score": player_score,
		"ai_score": ai_score,
		"player_hits": player_hits,
		"player_rebuttals": player_rebuttals,
		"ai_rebuttals": ai_rebuttals,
		"player_concessions": player_concessions,
	}
