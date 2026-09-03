class_name SettlementSystem
extends RefCounted

# ============================================================
#  结算系统（V2.1）
#  汇总 ScoreSystem 的完整度/得分/反击/让步，判定胜负。
#  支持：四档差值胜负 + 双输（双方完整度都过低）+ 动态提前结束。
#  纯离线。
# ============================================================

const LOW_INTEGRITY := 40      # 低于此：该方“论证不足”
const CORE_COLLAPSE := 20      # 核心论证崩溃阈值（提前结束）
const DOUBLE_LOSS_BOTH := 40   # 双方都低于此 → 双输

# 综合双方表现，返回 { verdict, text, detail }
func settle(score: ScoreSystem, player_integrity: int, ai_integrity: int, player_hits: int, ai_hits: int) -> Dictionary:
	var p_total := score.player_score + player_integrity + score.player_rebuttals + score.ai_rebuttals - player_hits
	var a_total := score.ai_score + ai_integrity + score.player_hits + score.player_concessions - ai_hits
	var diff := p_total - a_total

	# 双输：双方论证完整度都过低
	if player_integrity < DOUBLE_LOSS_BOTH and ai_integrity < DOUBLE_LOSS_BOTH:
		return _make("draw_loss", "逻辑平局 / 双方论证均未成立", "双方都频繁掉进逻辑陷阱，没有一方把论证立住。", p_total, a_total, diff)

	var verdict := "draw"
	var label := "平局"
	if diff >= 20:
		verdict = "user"; label = "明显胜利"
	elif diff >= 10:
		verdict = "user"; label = "小胜"
	elif diff <= -20:
		verdict = "ai"; label = "明显失败"
	elif diff <= -10:
		verdict = "ai"; label = "小败"

	var text := _verdict_text(verdict, diff)
	return _make(verdict, label, text, p_total, a_total, diff)

func _make(verdict: String, label: String, text: String, p: int, a: int, diff: int) -> Dictionary:
	return { "verdict": verdict, "label": label, "text": text, "p_total": p, "a_total": a, "diff": diff }

func _verdict_text(verdict: String, _diff: int) -> String:
	match verdict:
		"user":
			return KnowledgeBase.pick(KnowledgeBase.VERDICT_USER_WIN)
		"ai":
			return KnowledgeBase.pick(KnowledgeBase.VERDICT_AI_WIN)
	return KnowledgeBase.pick(KnowledgeBase.VERDICT_DRAW)

# 动态提前结束：若一方核心论证强度跌破阈值
func should_early_end(player_integrity: int, ai_integrity: int) -> bool:
	return player_integrity < CORE_COLLAPSE or ai_integrity < CORE_COLLAPSE
