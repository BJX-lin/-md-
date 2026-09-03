class_name DebateStateMachine
extends RefCounted

# ============================================================
#  辩论回合状态机（V2.1）
#  一局默认：OPENING 1 段 → ARGUMENT 3 → COUNTER 3 → CROSS_EXAM 2 → FINAL 1
#  用于给 AI 决策提供“当前阶段”信息，让攻击/让步概率随阶段变化。
#  纯离线状态机，不联网。
# ============================================================

enum Stage { OPENING, ARGUMENT, COUNTER, CROSS_EXAM, FINAL }
enum Phase { AI_TURN, PLAYER_TURN, SETTLE }

const STAGE_LABEL := ["开场", "立论", "交锋", "交叉质询", "结辩"]
const STAGE_LEN := [1, 3, 3, 2, 1]   # 每段回合数（可调）

var _stage: Stage = Stage.OPENING
var _round_in_stage := 0
var _phase: Phase = Phase.PLAYER_TURN

func reset() -> void:
	_stage = Stage.OPENING
	_round_in_stage = 0
	_phase = Phase.PLAYER_TURN

func advance() -> void:
	_round_in_stage += 1
	# 若当前段结束，进入下一段
	if _round_in_stage >= STAGE_LEN[_stage]:
		_round_in_stage = 0
		if _stage < Stage.FINAL:
			_stage = _stage + 1
		else:
			_stage = Stage.FINAL   # 结辩后保持 FINAL，等待 SETTLE

func current_stage() -> Stage:
	return _stage

func current_stage_label() -> String:
	return STAGE_LABEL[_stage]

func round_in_stage() -> int:
	return _round_in_stage

func set_phase(p: Phase) -> void:
	_phase = p

func phase() -> Phase:
	return _phase

func is_final() -> bool:
	return _stage == Stage.FINAL

func total_stages() -> int:
	return STAGE_LEN.size()

# 该阶段对应的“策略权重”（供 AI 决策：回合计分/回合阶段策略）
func stage_strategy_weight() -> float:
	match _stage:
		Stage.OPENING:
			return 0.2
		Stage.ARGUMENT:
			return 0.4
		Stage.COUNTER:
			return 0.6
		Stage.CROSS_EXAM:
			return 0.8
		Stage.FINAL:
			return 1.0
	return 0.5
