class_name KnowledgeBase
extends RefCounted

# ============================================================
#  知识库聚合入口（V2.1 阶段 0）
#  数据已拆分到 data/ 各子库；本类只做聚合与查询工具，原有引用
#  KnowledgeBase.X 保持不变，方便引擎/Main 无感迁移。
# ============================================================

# --- 聚合自 data/ 子库 ---
const FALLACIES = Fallacies.FALLACIES
const TOPICS = Topics.TOPICS
const OPENING = DebateMoves.OPENING
const ENDING = DebateMoves.ENDING
const PRAISE = DebateMoves.PRAISE
const SOCRATIC = DebateMoves.SOCRATIC
const ATTACKS = DebateMoves.ATTACKS
const REDUCTIO = DebateMoves.REDUCTIO
const DEBATE_MOVES = DebateMoves.DEBATE_MOVES
const FALLACY_RESPONSE_TEMPLATE = DebateMoves.FALLACY_RESPONSE_TEMPLATE
const VERDICT_AI_WIN = DebateMoves.VERDICT_AI_WIN
const VERDICT_USER_WIN = DebateMoves.VERDICT_USER_WIN
const VERDICT_DRAW = DebateMoves.VERDICT_DRAW
const DEBATES = EvidenceDatabase.DEBATES
const DEBATE_CASES = CounterExamples.DEBATE_CASES

# --- 引擎支持数据（保持在本类）---
const EMOJI := {
	# 命中用户逻辑谬误（高浓度嘲讽）
	"hit": [
		"🤡", "🫠", "🙃", "😏", "😅", "💀", "😬", "🤯", "🙄", "👀", "🥴", "😵", "🐒", "📉", "🎪",
	],
	# 用户像在讲理（AI 认可 / 阴阳夸）
	"good": [
		"👏", "🎉", "✨", "👍", "💪", "🌟", "😎", "🤓", "🔍", "📚", "🧠", "👌",
	],
	# 用户提问 / 追问时
	"ask": [
		"🤔", "🖊️", "❓", "🔎", "🧐",
	],
	# 通用拆解 / 兜底
	"generic": [
		"📌", "⚙️", "🎯", "✍️", "🧩", "🪞", "⏳", "🔁",
	],
	# 归谬
	"reductio": [
		"🤦", "🚩", "🎢", "🕳️", "🫥",
	],
	# 开场 / 换辩题
	"open": [
		"🎬", "🥊", "⚔️", "🛎️", "🎤",
	],
	# 结算
	"settle": [
		"🏁", "📊", "⚖️", "🧾",
	],
	# 情绪安抚 / 教学
	"calm": [
		"🫂", "🌿", "💧", "🍵", "🤝", "🌤️",
	],
}

const EMOTION_INSULT := [
	"我理解你现在有点火。但「{}」是情绪宣泄，不是逻辑前提。先把人身攻击收起来——你真正想论证的是什么？",
	"别急着骂。你丢来的是「{}」；骂人不能替我证明你对，但也不代表你就错。请回到主张与证据上，我认真接。",
	"看你去到情绪了。我知道你也想赢，可「{}」只会把话题带偏。换一句可核验的话，我陪你往下拆。",
	"这句「{}」我先收下情绪、不接里面的火。把你要论证的点换句话讲，我们好好谈。",
]

const EMOTION_SHORT := [
	"「{}」信息量不够，我猜你是被气到了，还是还没想好？先深呼吸，把完整观点讲出来，我陪你拆。",
	"这句「{}」有点没头没尾。你可以保留立场，但得补上理由与证据，我们才能往下谈。",
	"「{}」就这几个字，我没法判断你要争什么。多给一句前提，或直接抛你的结论。",
]

const EMOTION_RHETORIC := [
	"这声「{}」我当成你在宣泄，不接它里面的逻辑。等你给一个可论证的点，我们再正面谈。",
	"「{}」我收下了。可辩论比的是论据、不是气势——你具体想反驳我哪一点？",
	"哈，这句是情绪不是论证。要不点「求助」，我教你一招怎么漂亮地反杀。",
	"「{}」没错，但它在气势上赢，不在逻辑上赢。你有什么可核验的依据要摆吗？",
]

const INSULT_WORDS := [
	"蠢货", "白痴", "傻逼", "脑残", "垃圾", "废物", "智障", "神经病", "有病", "沙雕", "低能", "脑瘫",
	"他妈", "妈的", "尼玛", "你妈逼", "傻叉", "贱人", "婊子", "去死", "该死", "蠢蛋", "傻蛋",
	"你蠢", "你傻", "你无知", "你没文化", "你垃圾", "你水平差", "你都不懂", "你弱爆", "白痴",
]

const RHETORIC_WORDS := [
	"凭什么", "凭啥", "呵呵", "哈哈哈", "哈哈", "笑死", "我服了", "醉了", "牛逼", "你行你上",
	"说得好听", "切", "醒醒", "别逗", "什么鬼", "扯淡", "无语", "有病吧", "屁", "急眼", "放屁", "搞笑", "呵呵哒",
]

const CONCESSIONS := [
	"不过呢——你要真能拿出可核验的数据，我这一点就算认了。",
	"当然，补一条客观证据，我这就把杠收回。",
	"我杠的是逻辑，不是你的结论。你证明对了，我认输。",
	"给你个台阶：把这个断言补成「前提+证据」，我就夸你一句。",
	"行，这一条我暂时让步。你给了依据，它就不再是空口断言。",
	"要是你愿意把「大家都」换成具体数据，这一局我甚至可以夸你。",
]

const HINTS := [
	"教你一招：别急着表态，先用「在你看来…」复述对方立场，再指出它哪儿站不住——这叫防御稻草人。",
	"对方甩「大家都…」时，你回一个反例就够了：多数人也可能集体错，个数不等于证据。",
	"想反驳，先拆它的前提：它默认「A 必然导致 B」。你能指出其中一步可以被别的机制叫停吗？",
	"善用「具体化」：把「很多人」换成「多少、哪一年、哪份数据」。一具体，模糊的断言就漏了。",
	"拿不准就先定义：把「应该」改成「在什么情况下应该」。限定词一说清，论证就立住了。",
	"对方说「只有两种可能」？大概率是假两难。找一条中间路，或第三种选项。",
	"对方举「大家都成功」？那是在钓幸存者偏差。你问他：那些失败的人去哪了？",
]

const PRINCIPLES := [
	"四不判定：不相干（与论点无关）、不一致（前后矛盾）、不充分（证据不足），命中任一论证即站不住。",
	"好论证三件套：主张(结论)+理由(为什么)+证据(可核验的支撑)。缺了证据，只是断言。",
	"区分强度：是「必然」还是「很可能」？把限定词说清楚，才不会被抓。",
	"反驳的铁律：别攻击人，攻击论证；别歪曲对方，先复述再反驳。",
	"好辩论比的是证据密度与结构，不是嗓门大小、更不是谁先急眼。",
	"让对方「自圆其说」的最好方式，是顺着他的话往下推一步，看他接不接得住自己的结论。",
]

# ------------------------------------------------------------
#  工具函数
# ------------------------------------------------------------
static func pick(arr: Array) -> String:
	if arr.is_empty():
		return ""
	return str(arr[randi() % arr.size()])

static func pick_dict(arr: Array) -> Dictionary:
	if arr.is_empty():
		return {}
	return arr[randi() % arr.size()]

# 从 EMOJI 库按场景取一个 emoji（场景不存在则返回空）
static func emoji(scene: String) -> String:
	var slot: Variant = EMOJI.get(scene)
	if slot is Array and not slot.is_empty():
		return str(slot[randi() % slot.size()])
	return ""
