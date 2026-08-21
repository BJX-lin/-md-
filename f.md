下面直接给你一套可落地的开发表。  
我按**可复制进 Excel / Notion / Google Sheet / CSV** 的思路来写，尽量统一字段名，方便你后面接程序。

---

```md
# 《晚自习之后》开发总表（可落地版）
## 含：全局变量总表 + 角色状态机表 + 关系变化规则表 + 章节场景总表 + 字数建议 + 结局权重与判定表

---

# 一、全局变量总表

## 1.1 数值变量表

| var_name | 中文名 | 类型 | 范围 | 默认值 | 所属系统 | 作用说明 |
|---|---|---|---|---:|---|---|
| truth | 真相值 | int | 0~30 | 0 | 核心 | 决定真相层级、规则理解、可开启高阶选项 |
| sanity | 理智值 | int | 0~100 | 70 | 核心 | 决定幻觉强度、误判概率、坏结局吸引度 |
| memory_echo | 回响值 | int | 0~15 | 0 | 核心 | 决定循环既视感、自我残影、前次痕迹文本 |
| shenhe_focus | 沈禾关注值 | int | 0~15 | 0 | 核心 | 决定沈禾/规则优先锁定你、点名频率和强制互动 |
| trust_zhouxu | 周叙信任 | int | -5~5 | 0 | 关系 | 决定周叙坦白、保护、利用、陪同深度 |
| trust_liangye | 梁野信任 | int | -5~5 | 0 | 关系 | 决定梁野是否成为情感锚、是否陪到终章 |
| trust_xuqing | 许清态度 | int | -5~3 | 0 | 关系 | 决定许清对你警惕度、信息投放量 |
| route_obedience | 守规倾向 | int | 0~10 | 0 | 路线 | 偏保命、偏拖延、偏按规则做事 |
| route_investigate | 调查倾向 | int | 0~10 | 0 | 路线 | 偏主动求真、撬信息、看记录 |
| route_empathy | 共情倾向 | int | 0~10 | 0 | 路线 | 偏救人、理解沈禾、保梁野 |
| route_hostility | 对抗倾向 | int | 0~10 | 0 | 路线 | 偏撕规则、反击、烧毁、硬闯 |
| taboo_count | 违规计数 | int | 0~20 | 0 | 风险 | 统计违规回应、照镜子、替答等行为 |
| save_route_score | 救人路线分 | int | 0~20 | 0 | 结局 | 真结局/遗憾结局重要权重 |
| end_cycle_score | 终止路线分 | int | 0~20 | 0 | 结局 | 毁灭结局重要权重 |
| control_route_score | 接管路线分 | int | 0~20 | 0 | 结局 | 管理者结局重要权重 |

---

## 1.2 布尔变量表（剧情标记）

| var_name | 中文名 | 类型 | 默认值 | 首次出现章节 | 作用说明 |
|---|---|---|---|---:|---|
| flag_admin_key | 获得管理员钥匙 | bool | false | 2 | 进入档案内门、接管线资源 |
| flag_oldqin_burndeath | 老秦烧死 | bool | false | 2 | 老秦支线死亡回流主线 |
| flag_partial_roster | 拿到残缺名单 | bool | false | 2 | 名单线前置 |
| flag_seen_repeat_name | 看见重复名字 | bool | false | 2 | 循环前置认知 |
| flag_broadcast_register | 见过广播登记册 | bool | false | 2 | 广播系统前置 |
| flag_shenhe_name_full | 知道沈禾全名 | bool | false | 2 | 真结局前置之一 |
| flag_first_face_to_face_shenhe | 第一次正面见沈禾 | bool | false | 2 | 沈禾线推进 |
| flag_old_building_entered | 进入旧楼 | bool | false | 2 | 主线章节门槛 |
| flag_dorm_rule_known | 已知宿舍应答规则 | bool | false | 3 | 第三章查寝核心 |
| flag_peeped_door | 看过门缝/门镜 | bool | false | 3 | 识破假查寝 |
| flag_shadow_count_wrong | 发现影子数不对 | bool | false | 3 | 规则理解推进 |
| flag_list_updated_night | 见过夜间名单改写 | bool | false | 3 | 名单真正生效前置 |
| flag_liangye_returned | 梁野以“人”状态回来 | bool | false | 3 | 梁野可救线 |
| flag_liangye_half_assimilated | 梁野半同化 | bool | false | 3 | 梁野特殊状态 |
| flag_zhouxu_confessed_part | 周叙部分坦白 | bool | false | 3 | 第四章深入坦白前置 |
| flag_used_admin_key_tonight | 当夜用过管理员钥匙 | bool | false | 3 | 规则识别强化 |
| flag_found_xuqing_log_fragment | 找到许清日志残页 | bool | false | 3 | 第四章档案线前置 |
| flag_heard_parent_voice | 听见熟人诱导开门 | bool | false | 3 | 理智打击标记 |
| flag_gave_up_roommate | 放弃室友/梁野 | bool | false | 3 | 冷路线、管理者结局加权 |
| flag_night_roster_taken | 拿到夜间核对名单 | bool | false | 3 | 真结局前置之一 |
| flag_name_written_back | 尝试写回沈禾名字 | bool | false | 3 | 真结局高风险前置 |
| flag_dorm_sacrifice_trigger | 触发宿舍献祭前置 | bool | false | 3 | 坏结局/接管线强化 |
| flag_archive_entered | 进入校史馆内档 | bool | false | 4 | 第四章真相场门槛 |
| flag_monitor_room_found | 找到监控室 | bool | false | 4 | 火灾录像与总名单前置 |
| flag_saw_fire_video | 看见火灾录像 | bool | false | 4 | 完整真相前置 |
| flag_saw_self_repeat | 看见多个林昼记录 | bool | false | 4 | 自我重复认知 |
| flag_true_linday_status_known | 明确林昼真实状态 | bool | false | 4 | 终章“名字不完整”前置 |
| flag_xuqing_identity_revealed | 揭露许清身份 | bool | false | 4 | 许清逻辑完整化 |
| flag_rule_terms_complete | 规则术语完整掌握 | bool | false | 4 | 拿规则反制规则 |
| flag_roster_core_taken | 拿到核心名单页 | bool | false | 4 | 真结局/管理者结局重要资源 |
| flag_chose_save_shenhe | 明确倾向救沈禾 | bool | false | 4 | 救人路线锁 |
| flag_chose_end_cycle | 明确倾向终止循环 | bool | false | 4 | 毁灭路线锁 |
| flag_chose_take_control | 明确倾向接管规则 | bool | false | 4 | 管理者路线锁 |
| flag_liangye_final_loss | 梁野本章最终失去 | bool | false | 4 | 终章情感锚缺失 |
| flag_zhouxu_final_confession | 周叙完整坦白 | bool | false | 4 | 终章站位深化 |
| flag_fakewall_opened | 打开假墙 | bool | false | 4 | 档案核心空间前置 |
| flag_archive_burn_started | 档案室开始崩塌/燃烧 | bool | false | 4 | 终章紧迫前置 |
| flag_terminal_broadcast_ready | 具备终章改写广播条件 | bool | false | 4 | 终章核心硬条件 |
| true_end_precondition_1 | 真结局前置1 | bool | false | 3 | 建议绑定写回名字 |
| true_end_precondition_2 | 真结局前置2 | bool | false | 3 | 建议绑定夜间名单 |
| archive_route_bonus | 档案路线奖励 | bool | false | 3 | 第四章更稳进入 |
| sanity_bonus_next | 下章节理智奖励 | bool | false | 3 | 用于过场补正 |

---

## 1.3 状态变量表（枚举）

| var_name | 中文名 | 类型 | 可选值 | 默认值 | 作用 |
|---|---|---|---|---|---|
| liangye_state | 梁野中段状态 | enum | normal / fear_alive / ally_shaken / missing_marked / half_assimilated | normal | 第二、三章分支状态 |
| oldqin_state | 老秦状态 | enum | alive / dead / burned / missing | alive | 老秦支线结果 |
| zhouxu_state | 周叙中段状态 | enum | normal / hiding / guarding / coercing | normal | 周叙中前期表现 |
| liangye_final_state_ch3 | 梁野第三章结算 | enum | anchor_alive / fragile_alive / rescued_half / missing / abandoned | fragile_alive | 终章前关键状态 |
| zhouxu_final_state_ch3 | 周叙第三章结算 | enum | confessor_protector / split_guard / coercer | split_guard | 终章站位来源 |
| truth_state | 真相层级 | enum | partial / high / complete | partial | 终章核心判定 |
| liangye_end_state | 梁野终章前状态 | enum | present_anchor / present_fragile_truth / present_unstable / absent_echo | present_unstable | 终章陪同与结局权重 |
| zhouxu_end_state | 周叙终章前状态 | enum | enter_with_player / follow_to_threshold / pressure_player | follow_to_threshold | 终章行为 |
```

---

```md
# 二、角色状态机表

## 2.1 梁野状态机

| 当前状态 | 触发条件 | 进入状态 | 剧情意义 | 终章影响 |
|---|---|---|---|---|
| normal | 初始进入主线 | fear_alive / ally_shaken | 受异常影响开始不稳 | 轻度影响 |
| fear_alive | 遭遇点名/听见小名/夜间规则刺激 | ally_shaken / missing_marked | 可救、可稳、可崩 | 仍可成锚点 |
| ally_shaken | 你多次安抚/共同调查 | anchor_alive / half_assimilated | 关系深化的过渡态 | 真结局加分 |
| missing_marked | 门外被叫走/名字被写入待定 | missing / rescued_half | 支线死亡回流主线 | 真结局降权 |
| half_assimilated | 回来但异常明显/时态紊乱 | rescued_half / abandoned | 高真相态 | 真相加分、情感稳定减分 |
| anchor_alive | 第三章结算高信任保住 | present_anchor | 人性锚定成功 | 真结局强前置 |
| fragile_alive | 保住但信任一般/精神波动大 | present_unstable | 可陪终章但易崩 | 中性 |
| rescued_half | 从半同化态勉强拉回 | present_fragile_truth | 知道更多、也更危险 | 真相增强 |
| missing | 未救回 | absent_echo | 以声音/遗物回流 | 真结局难度上升 |
| abandoned | 被主动放弃 | absent_echo | 冷血路线成立 | 管理者路线强化 |

---

## 2.2 周叙状态机

| 当前状态 | 触发条件 | 进入状态 | 剧情意义 | 终章影响 |
|---|---|---|---|---|
| normal | 初始 | guarding / hiding | 他知道更多但不说 | 中性 |
| hiding | 玩家怀疑他/低信任 | coercing / split_guard | 信息控制更强 | 终章偏逼迫 |
| guarding | 玩家较信任他/多次配合 | confessor_protector | 愿意扛一次风险 | 真结局帮助大 |
| coercing | 多次敌对/他急于结束 | coercer | 会逼你快选 | 毁灭/接管加权 |
| confessor_protector | 第三章高信任结算 | enter_with_player | 跟你进广播室 | 真结局辅助 |
| split_guard | 中间态结算 | follow_to_threshold | 送到门口，不全进 | 中性偏保守 |
| coercer | 低信任结算 | pressure_player | 全程给压力 | 坏路线更重 |

---

## 2.3 许清状态机

| 当前状态 | 触发条件 | 进入状态 | 剧情意义 | 终章影响 |
|---|---|---|---|---|
| hidden | 前期只呈现异常教师形象 | suspected | 冷面控制者 | 中性 |
| suspected | 玩家注意裸足/日志/反常说话 | revealed | 身份可揭开 | 真相加速 |
| revealed | 第四章明确其已死/维护者身份 | destabilized / observer | 规则维护者成立 | 可阻拦也可退让 |
| destabilized | 被识破“只是站太久的人” | observer | 毁灭路线更通 | 终章干预减少 |
| observer | 不再强拦，只旁观结果 | observer | 终局见证者 | 余味增强 |

---

## 2.4 沈禾状态机

| 当前状态 | 触发条件 | 进入状态 | 剧情意义 | 终章影响 |
|---|---|---|---|---|
| echo | 前期仅声音/残字/镜像出现 | calling | 删除未完成者初现 | 轻度威胁 |
| calling | 叫名字/问答到/催你补位 | half_present | 规则与人开始混合 | 风险增大 |
| half_present | 旧楼见面/镜中出现 | seated_core | 广播室中心成立 | 终章核心 |
| seated_core | 终章坐在播音椅上 | released / exchanged / fused / burned | 多结局分流点 | 直接决定收束情感 |
| released | 真结局 | - | 获得离席 | 正收束 |
| exchanged | 遗憾结局 | - | 你替她坐下 | 牺牲 |
| fused | 管理者结局 | - | 她与规则/你部分融合 | 冷结局 |
| burned | 毁灭结局 | - | 与系统共崩 | 极端收束 |
```

---

```md
# 三、关系变化规则表

## 3.1 周叙关系变化规则

| 行为 | 数值变化 | 备注 |
|---|---:|---|
| 主动分享名单给周叙 | +2 | 说明你愿意信他 |
| 当面质问“你是不是一直在骗我” | -1~-2 | 取决于语气和时机 |
| 夜间查寝时听他指挥保持沉默 | +1 | 信任建立 |
| 把他过去补名字的事直接定性为凶手 | -2 | 会推向 coercer |
| 接受他带路去校史馆 | +1 | 第四章更稳 |
| 让他替你扛一次查寝对答 | +1 | 但风险给他 |
| 终章问“你跟不跟我走”且高信任 | +2 | 锁 enter_with_player |
| 多次在关键节点不听他劝反向操作 | -1~-3 | 视次数累计 |

---

## 3.2 梁野关系变化规则

| 行为 | 数值变化 | 备注 |
|---|---:|---|
| 帮他找蜡烛/打火机 | +2 | 恐惧状态安抚 |
| 宿舍查寝时先确认他床位 | +1 | 说明你记得他 |
| 他被点名时拉住他 | +3 | 真结局关键加分 |
| 给他看名单但不解释 | +1 或 -1 | 视当时状态 |
| 他崩时你先去听门外而不是拉他 | -1 | 情感损伤 |
| 主动放手让他冲门 | -5 | `flag_gave_up_roommate = true` |
| 终章把借书卡塞回他手里 | +2 | 强稳一次 |
| 明确告诉他“我不会丢下你” | +3 | 锚点强化 |

---

## 3.3 许清态度变化规则

| 行为 | 数值变化 | 备注 |
|---|---:|---|
| 对她保持礼貌、少挑衅 | +1 | 仅降低敌意，不等于信任 |
| 多次质问她是不是死人 | -1~-2 | 提前进入对抗 |
| 找到日志残页后直接拆穿 | -1 | 但真相推进快 |
| 遵守她给出的表层规则 | +1 | 她更愿意旁观 |
| 撕名单/攻击规则 | -2 | 她更强力阻拦 |
| 识破她“只是描线的人” | 特殊 | 不改信任，直接改状态 |

---

## 3.4 沈禾关注变化规则

| 行为 | 数值变化 | 备注 |
|---|---:|---|
| 补她名字/写回她名字 | +3~+4 | 高风险高绑定 |
| 对镜中她回话 | +2 | 容易被锁定 |
| 进入旧楼广播区域 | +1 | 自然增长 |
| 多次不替答、不回应 | -或不变 | 她关注不一定下降，但规则绑定减缓 |
| 拿走名单核心页 | +2 | 她会更直接找你 |
| 终章主动要求先点沈禾 | +2 | 真结局倾向同时上涨 |
```

---

```md
# 四、章节场景总表（可直接拆Excel）

## 4.1 第一章场景表

| scene_id | 章节 | 场景名 | 地点 | 类型 | 预计字数 | 核心功能 | 必须回收/埋伏笔 |
|---|---:|---|---|---|---:|---|---|
| ch1_sc1 | 1 | 办公室填表 | 办公室 | 开场/异常日常 | 1800~2600 | 入校、许清、违纪表 | 违纪记录表、许清异常 |
| ch1_sc2 | 1 | 初次进班 | 教室 | 人物登场 | 2200~3200 | 周叙、梁野、点名氛围 | 班级空位、人数不对 |
| ch1_sc3 | 1 | 午休走廊 | 走廊 | 连接/调查 | 1200~2000 | 第一次自由调查感 | 气味、广播杂音 |
| ch1_sc4 | 1 | 图书馆残页 | 图书馆 | 调查/规则文字 | 2200~3200 | 109页、借书卡、残字 | “别替我答到” |
| ch1_sc5 | 1 | 晚自习前 | 教室 | 压力推进 | 1800~2600 | 第一次点名临近 | 周叙敏感、梁野不安 |
| ch1_sc6 | 1 | 第一次异常点名 | 教室/广播 | 高压规则场 | 2800~4200 | 抛出核心规则 | 不完整名字、回应风险 |
| ch1_sc7 | 1 | 夜宿舍预警 | 307宿舍 | 章节收束 | 2000~3000 | 宿舍并不安全 | 门外敲门模式 |

### 第一章建议总字数
```text
约 1.4万 ~ 2.2万（轻量）
完整版建议 2.5万 ~ 4万
```

---

## 4.2 第二章场景表

| scene_id | 章节 | 场景名 | 地点 | 类型 | 预计字数 | 核心功能 | 必须回收/埋伏笔 |
|---|---:|---|---|---|---:|---|---|
| ch2_sc1 | 2 | 白天余波 | 教室 | 回流/怀疑 | 1800~2500 | 第一章异常落地 | 人数错位 |
| ch2_sc2 | 2 | 值班室接触老秦 | 值班室 | 高功能支线 | 2200~3200 | 钥匙/名单/管理员线 | 老秦状态 |
| ch2_sc3 | 2 | 旧楼入口 | 旧楼入口 | 气氛推进 | 1500~2200 | 是否进入旧楼 | 雨前湿气 |
| ch2_sc4 | 2 | 旧楼楼道 | 楼道 | 恐怖推进 | 2200~3200 | 楼层错位、声源异常 | 影子/广播感 |
| ch2_sc5 | 2 | 广播室门外 | 广播室门外 | 核心对峙 | 3000~4500 | 沈禾、名单、门内规则 | 问“谁替我答到” |
| ch2_sc6 | 2 | 名单争夺/观察 | 门口/走廊 | 分支场 | 2500~3800 | 抢名单/递东西/撤退 | 待定、删除未完成 |
| ch2_sc7 | 2 | 回宿舍路上 | 教学楼外/走廊 | 收束 | 1800~2600 | 把旧楼后果带回现实 | 门没锁、宿舍转场 |

### 第二章建议总字数
```text
约 2.2万 ~ 3.8万
```

---

## 4.3 第三章场景表

| scene_id | 章节 | 场景名 | 地点 | 类型 | 预计字数 | 核心功能 | 必须回收/埋伏笔 |
|---|---:|---|---|---|---:|---|---|
| ch3_sc1 | 3 | 从旧楼回宿舍 | 宿舍门口 | 回流场 | 1800~2800 | 第二章变量接回 | 名单/钥匙/梁野状态 |
| ch3_sc2 | 3 | 307规则纸 | 宿舍 | 规则揭示 | 2200~3200 | 宿舍应答规则 | 图书馆残字回收 |
| ch3_sc3 | 3 | 梁野状态回流 | 宿舍 | 角色状态场 | 2200~3600 | 梁野活/失踪/半同化 | 情感锚铺垫 |
| ch3_sc4 | 3 | 查寝前对话 | 宿舍 | 关系/真相场 | 1800~2800 | 周叙部分坦白 | 补名历史 |
| ch3_sc5 | 3 | 许清残页 | 宿舍/桌下 | 支线回主线 | 1800~2600 | 术语解释前置 | 在册/待定/删除 |
| ch3_sc6 | 3 | 第一次正式查寝 | 宿舍/门口 | 高压规则场 | 3000~4500 | 数影子、熟人诱导 | 规则实战 |
| ch3_sc7 | 3 | 夜间名单改写 | 宿舍 | 核心系统场 | 2500~3800 | 名单真正生效 | 夜间核对名单 |
| ch3_sc8 | 3 | 梁野救或弃 | 宿舍/门口 | 高情感分支 | 2500~4000 | 真结局软条件 | 放弃梁野标记 |
| ch3_sc9 | 3 | 周叙坦白前桥 | 宿舍 | 真相推进 | 1800~2600 | 五年前事件片段 | 第四章桥 |
| ch3_sc10 | 3 | 前往校史馆理由成立 | 宿舍结尾 | 章节收束 | 1800~2600 | 第四章入口 | “可补”出现 |

### 第三章建议总字数
```text
约 3万 ~ 4.8万
```

---

## 4.4 第四章场景表

| scene_id | 章节 | 场景名 | 地点 | 类型 | 预计字数 | 核心功能 | 必须回收/埋伏笔 |
|---|---:|---|---|---|---:|---|---|
| ch4_sc1 | 4 | 雨后校史馆 | 校史馆外 | 过渡/压迫 | 1500~2400 | 汇集合流 | 梁野/周叙状态 |
| ch4_sc2 | 4 | 进入校史馆 | 校史馆入口 | 门槛场 | 1800~2800 | 钥匙/替代入场 | 待定者开门 |
| ch4_sc3 | 4 | 假墙与内门 | 校史馆内 | 调查/机关 | 2200~3200 | 假墙、旧照片 | 自我重复伏笔 |
| ch4_sc4 | 4 | 许清现身 | 假墙前 | 真相对峙 | 2200~3400 | 许清身份揭露 | 她的真实功能 |
| ch4_sc5 | 4 | 监控内档室 | 内档室 | 真相核心场 | 3500~5500 | 录像、名单、日志 | 第109次 |
| ch4_sc6 | 4 | 梁野与周叙站位 | 内档室 | 关系定型 | 2200~3400 | 终章陪同判定 | 情感锚与罪责 |
| ch4_sc7 | 4 | 三路线锁定 | 内档室 | 路线选择场 | 1800~2600 | 选名单/录像/钥匙 | 救人/终止/接管 |
| ch4_sc8 | 4 | 档案崩塌 | 内档室/走廊 | 高压收束 | 2200~3200 | 许清最后阻拦 | 终章紧迫 |
| ch4_sc9 | 4 | 冲向旧楼 | 校园/雨夜 | 桥接 | 1200~2000 | 无缝接终章 | 第109次补录开始 |

### 第四章建议总字数
```text
约 2.5万 ~ 4.2万
```

---

## 4.5 终章场景表

| scene_id | 章节 | 场景名 | 地点 | 类型 | 预计字数 | 核心功能 | 必须回收/埋伏笔 |
|---|---:|---|---|---|---:|---|---|
| fin_sc1 | 终 | 冲回旧楼 | 旧楼外/楼道 | 高压过渡 | 1500~2400 | 汇总道具/同行者 | 终章站位 |
| fin_sc2 | 终 | 广播室门外对峙 | 门外 | 最终门槛 | 2200~3600 | 沈禾试探、门外站位 | 持有物回收 |
| fin_sc3 | 终 | 广播室内部显形 | 广播室 | 核心真相场 | 2500~4200 | 沈禾真面目、规则实体 | 自我镜像 |
| fin_sc4 | 终 | 最后一次点名 | 广播室 | 决策场 | 3000~5000 | 名单点名、应答分流 | 替答/不答/改名 |
| fin_sc5 | 终 | 终极抉择 | 广播室主控 | 分结局场 | 2800~4800 | 真/遗憾/接管/毁灭/空席 | 所有资源落地 |
| fin_sc6 | 终 | 尾声 | 各结局不同 | 收束场 | 2500~6000 | 结局情感闭环 | 全伏笔回收 |

### 终章建议总字数
```text
约 2万 ~ 3.8万
```
```

---

```md
# 五、章节字数总建议表

| 章节 | 最低可用字数 | 推荐字数 | 丰满版字数 |
|---|---:|---:|---:|
| 第一章 | 14000 | 28000 | 40000 |
| 第二章 | 22000 | 32000 | 45000 |
| 第三章 | 30000 | 38000 | 50000 |
| 第四章 | 25000 | 33000 | 45000 |
| 终章 | 20000 | 30000 | 40000 |
| 系统补充文本 | 10000 | 18000 | 30000 |

### 推荐总量
```text
完整商用开发建议：18万 ~ 28万字
你这个题材最舒服的落点：21万 ~ 24万字
```
```

---

```md
# 六、数值阈值与效果表

## 6.1 truth 真相值阈值

| 阈值 | 解锁效果 |
|---:|---|
| 5 | 能确认异常不是错觉 |
| 10 | 能读懂基础规则文本 |
| 15 | 能理解待定/删除的危险差别 |
| 18 | 第三章末可稳定推进校史馆线 |
| 20 | 可主动质问补位/循环 |
| 25 | 真相层级可判为 `complete` 候选 |
| 28 | 可见高阶真相文本、自我重复更明确 |

---

## 6.2 sanity 理智值阈值

| 阈值 | 状态 | 影响 |
|---:|---|---|
| 80+ | 稳定 | 文本清晰、误判少 |
| 60~79 | 轻微波动 | 熟人声音与气味异常增多 |
| 40~59 | 不稳 | 镜像、影子、自动补句风险增加 |
| 20~39 | 高危 | 更易被沈禾/规则诱导 |
| 0~19 | 崩溃边缘 | 空席结局吸引大幅增加 |

---

## 6.3 memory_echo 回响值阈值

| 阈值 | 解锁效果 |
|---:|---|
| 3 | 轻微既视感文本 |
| 6 | 场景中出现“你来过”的暗示 |
| 8 | 可在录像/镜中辨认自己 |
| 10 | 理解“同一格子里两层字” |
| 12 | 终章可见高阶自我回声文本 |

---

## 6.4 shenhe_focus 阈值

| 阈值 | 效果 |
|---:|---|
| 3 | 沈禾开始优先点你 |
| 6 | 镜中/广播中更多出现她 |
| 8 | 宿舍查寝重点锁定你 |
| 10 | 可触发名单共鸣开门 |
| 12 | 终章她直接叫你全名 |
| 14+ | 高风险绑定，坏结局和高真相同时增强 |
```

---

```md
# 七、结局权重总表

## 7.1 真结局《点名停止》权重表

### 硬条件
| 条件 | 必须 |
|---|---|
| true_end_precondition_1 = true | 是 |
| true_end_precondition_2 = true | 是 |
| flag_rule_terms_complete = true | 是 |
| flag_terminal_broadcast_ready = true | 是 |
| truth_state = complete | 是 |
| flag_gave_up_roommate = false | 是 |
| liangye_end_state != absent_echo（建议至少可沟通） | 强建议 |

### 软权重
| 来源 | 分值 |
|---|---:|
| flag_name_written_back | +2 |
| flag_night_roster_taken | +2 |
| flag_chose_save_shenhe | +3 |
| trust_liangye >= 3 | +2 |
| liangye_end_state = present_anchor | +2 |
| trust_zhouxu >= 3 | +1 |
| flag_saw_fire_video | +1 |
| flag_true_linday_status_known | +1 |

### 推荐判定
```text
总分 >= 8 且硬条件满足，可进真结局
```

---

## 7.2 遗憾结局《留堂》权重表

### 适合条件
| 条件 | 说明 |
|---|---|
| 救人分高 | 想救沈禾 |
| 规则理解不完整 | 没法彻底停课 |
| 梁野缺席或过于不稳 | 情感锚不足 |
| 玩家主动说“我来，但只到点名结束” | 直接强倾向 |

### 软权重
| 来源 | 分值 |
|---|---:|
| save_route_score >= 4 | +2 |
| liangye_end_state = absent_echo | +1 |
| truth_state = high 非 complete | +1 |
| player_chose_self_substitute | +3 |

---

## 7.3 管理者结局《管理员》权重表

### 硬倾向来源
| 来源 | 分值 |
|---|---:|
| flag_chose_take_control | +3 |
| control_route_score | 按当前值计 |
| flag_admin_key | +1 |
| flag_roster_core_taken | +2 |
| flag_gave_up_roommate | +2 |
| 梁野缺席/死亡 | +1 |
| 多次以规则压人 | +1 |

### 推荐判定
```text
control_route_score >= 5
或 控制资源足够 + 放弃他人
```

---

## 7.4 毁灭结局《焚校》权重表

### 硬倾向来源
| 来源 | 分值 |
|---|---:|
| flag_chose_end_cycle | +3 |
| end_cycle_score | 按当前值计 |
| 持有录像带 | +2 |
| 持有线路图/主控资源 | +1 |
| route_hostility >= 4 | +1 |
| 反杀/绕过许清 | +1 |
| 终章点燃主控/拉断线路 | +3 |

### 推荐判定
```text
end_cycle_score >= 5 且触发破坏行为
```

---

## 7.5 空席结局《到》权重表

### 吸引条件
| 条件 | 说明 |
|---|---|
| truth_state = partial | 读不懂发生了什么 |
| sanity <= 20 | 理智崩溃 |
| 终章既不应答也不改规则 | 规则代选 |
| 没有终章核心资源 | 无法主动操作 |
| 多次拖延 | 被动失败 |

### 推荐判定
```text
若前四结局均不满足，则进入空席结局
```
```

---

```md
# 八、角色对结局的权重影响表

## 8.1 梁野

| 状态 | 真结局 | 遗憾结局 | 管理者结局 | 毁灭结局 | 空席结局 |
|---|---:|---:|---:|---:|---:|
| present_anchor | +2 | 0 | -1 | -1 | -1 |
| present_fragile_truth | +1 | +1 | 0 | 0 | 0 |
| present_unstable | 0 | +1 | 0 | 0 | +1 |
| absent_echo | -2 | +1 | +1 | +1 | +1 |
| abandoned系后果 | -3 | 0 | +2 | +1 | +2 |

---

## 8.2 周叙

| 状态 | 真结局 | 遗憾结局 | 管理者结局 | 毁灭结局 | 空席结局 |
|---|---:|---:|---:|---:|---:|
| enter_with_player | +1 | +1 | 0 | 0 | -1 |
| follow_to_threshold | 0 | 0 | 0 | 0 | 0 |
| pressure_player | -1 | 0 | +1 | +1 | +1 |

---

## 8.3 许清

| 状态 | 影响 |
|---|---|
| hidden | 真相获取慢，空席概率微升 |
| revealed | 真相完整度提高，真结局/管理者都更稳定 |
| destabilized | 毁灭结局更易，接管结局风险更高 |
| observer | 终章不再硬拦，玩家自主度增加 |
```

---

```md
# 九、推荐程序判定伪代码

## 9.1 真相层级判定

```python
if truth >= 25 and flag_rule_terms_complete and flag_saw_fire_video:
    truth_state = "complete"
elif truth >= 18:
    truth_state = "high"
else:
    truth_state = "partial"
```

## 9.2 梁野终章状态判定

```python
if liangye_final_state_ch3 == "anchor_alive" and trust_liangye >= 5:
    liangye_end_state = "present_anchor"
elif liangye_final_state_ch3 == "rescued_half":
    liangye_end_state = "present_fragile_truth"
elif liangye_final_state_ch3 in ["missing", "abandoned"]:
    liangye_end_state = "absent_echo"
else:
    liangye_end_state = "present_unstable"
```

## 9.3 周叙终章状态判定

```python
if zhouxu_final_state_ch3 == "confessor_protector":
    zhouxu_end_state = "enter_with_player"
elif zhouxu_final_state_ch3 == "coercer":
    zhouxu_end_state = "pressure_player"
else:
    zhouxu_end_state = "follow_to_threshold"
```

## 9.4 主结局判定优先级

```python
def can_true_end():
    return (
        truth_state == "complete"
        and true_end_precondition_1
        and true_end_precondition_2
        and flag_rule_terms_complete
        and flag_terminal_broadcast_ready
        and not flag_gave_up_roommate
        and save_route_score >= 5
        and liangye_end_state in ["present_anchor", "present_fragile_truth"]
    )

def can_bittersweet():
    return (
        save_route_score >= 4
        and flag_terminal_broadcast_ready
        and (
            liangye_end_state == "absent_echo"
            or truth_state != "complete"
            or player_chose_self_substitute
        )
    )

def can_destroyer():
    return (
        end_cycle_score >= 5
        and flag_terminal_broadcast_ready
        and player_triggered_fire_sequence
    )

def can_manager():
    return (
        control_route_score >= 5
        or (flag_gave_up_roommate and control_route_score >= 4)
    )

def determine_ending():
    if can_true_end():
        return "ending_true_release"
    elif can_bittersweet():
        return "ending_bittersweet_exchange"
    elif can_destroyer():
        return "ending_destroyer"
    elif can_manager():
        return "ending_manager"
    else:
        return "ending_empty_seat"
```
```

---

```md
# 十、Excel工作簿建议结构

## 工作簿1：总控
1. `variables`
2. `characters`
3. `items`
4. `endings`

## 工作簿2：剧情
1. `scenes`
2. `scene_nodes`
3. `choices`
4. `conditional_lines`

## 工作簿3：数值
1. `trust_rules`
2. `route_weights`
3. `ending_weights`
4. `thresholds`

## 工作簿4：文本管理
1. `main_dialogue`
2. `variant_dialogue`
3. `item_desc`
4. `epilogues`
```

---

如果你愿意，我下一条可以继续直接给你两种非常实用的东西之一：

1. **Excel可直接复制版 CSV 模板**
2. **Godot / Ren'Py 可用的剧情配置字段模板**

如果你要，我也可以直接继续补：
**《道具表 + CG表 + BGM/音效触发表 + UI提示表》**。