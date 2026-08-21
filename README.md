# 《第十三节课》 THE 13TH PERIOD

国产校园恐怖文字互动视觉小说（AVG）。

- 引擎：Godot Engine 4.7.2 stable
- 目标平台：Android 手机（竖屏/横屏自适应，渲染后端 Mobile）
- 时长：约 2~3 小时，4 章 + 终章 + 真结局解锁番外，多结局
- 玩法：文本剧情 / 选项分支 / 密码锁解谜 / 线索与道具收集 / 理智与信任数值系统 / 存档读档 / 周目循环 / 成就系统

## 直接下载（GitHub raw 直链）

**v1.4.16 分卷下载（无压缩 store 打包，三卷均 <100MB）**

```
https://github.com/BJX-lin/-md-/raw/arena/01a0234d-md/dist/The13thPeriod_v1.4.16_part1_project.zip
https://github.com/BJX-lin/-md-/raw/arena/01a0234d-md/dist/The13thPeriod_v1.4.16_part2_bg.zip
https://github.com/BJX-lin/-md-/raw/arena/01a0234d-md/dist/The13thPeriod_v1.4.16_part3_sprites_audio.zip
```

> 分卷使用方法：三个 ZIP **解压到同一个文件夹**即可合并——
> Part 1（3.8MB）工程核心（代码/剧本/UI/图标/工具，含开屏 AI 图标）+ `docs/` + 设计文档；
> Part 2（73.4MB）`game/assets/bg` 全部背景图；
> Part 3（30.4MB）`game/assets/sprites|audio` 立绘与音频。
>
> 解压后用 Godot Engine 4.7.2 stable 打开 `game/project.godot` 即可运行 / 导出 Android。

**历史版本（v1.3.1）** 仍在游戏仓库 `BJX-lin/md` 的 `arena/01a018ff-md` 分支 `dist/` 下：

```
https://github.com/BJX-lin/md/raw/arena/01a018ff-md/dist/The13thPeriod_v1.3.1_full_project.zip
https://github.com/BJX-lin/md/raw/arena/01a018ff-md/dist/The13thPeriod_v1.3.1_part1_project.zip
https://github.com/BJX-lin/md/raw/arena/01a018ff-md/dist/The13thPeriod_v1.3.1_part2_assets.zip
```

> 分卷使用方法：把两个 ZIP **解压到同一个文件夹**即可合并——
> Part 1 含 `game/` 工程核心（代码/剧本/UI/图标）与 `docs/`；
> Part 2 含 `game/assets/bg|sprites|audio` 全部美术与音频资源。

## 目录结构

```
game/                  # Godot 工程（直接用 Godot 4.7.2 打开 game/project.godot）
├── autoload/          # 全局单例：配置 / 状态 / 剧情引擎 / 音频 / 存档 / 成就 / 资源缓存 / 完整性
├── src/               # 界面与演出：标题 / 开屏 / 游戏主界面 / 密码锁 / 命名界面 等
├── story/             # 剧本（.avg DSL，共 25 个文件、564 个节点；60_extra.avg 为番外）
├── assets/            # 背景 / 立绘 / UI 贴图 / 程序化音频占位
├── tools/             # 开发工具：gen_integrity.py / check_avg.py / check_gdscript.py
└── export_presets.cfg # Android / Windows / Linux 导出预设
docs/                  # 剧本全文、技术文档、引擎开发规范、防破解与发行加固指南
```

## 常用开发命令

```bash
# 校验剧本（节点引用、@if 配对、@padlock 参数、未知指令）
python3 game/tools/check_avg.py game/story

# 无 Godot 环境时的 GDScript 静态检查（括号配平 / 路径 / 缩进 / 信号）
python3 game/tools/check_gdscript.py

# 改动核心文件后重新生成完整性清单（autoload/integrity_manifest.gd）
python3 game/tools/gen_integrity.py --write

# 无头冒烟测试（21 组：剧情引擎 / 密码锁 / 命名插值 / 条件 / 序列化 / 成就 / 番外）
godot --headless --path game res://tools/smoke_runner.tscn
```

## 剧本 DSL 速查

```
== 节点id                节点开始
@bg 场景 [变体]          背景      @bgm/@amb/@sfx 音乐/环境/音效
@show 角色 表情 [位置]   立绘      @fx 特效 强度
@set 变量 +N|-N|=N       数值      @flag 名 / @state 键 值
@item +id|-id            道具      @clue id  线索
@padlock 密码 成功节点 [失败节点] 提示文本     数字密码锁
@if 条件 / @elif / @else / @endif / @goto 节点 / @ending 结局id
* 选项文本 -> 目标节点              （可加 [if 条件] 隐藏 / [lock 条件] 灰显）
角色: 台词      > 旁白强调行      普通行 = 旁白
```

文本插值：`{pname}` 玩家名、`{num:truth}` 数值、`{item:item_xxx}` 道具名、
`{if 条件?A|B}` 条件文本。玩家改名后正文中的「林昼」自动替换为玩家名字。

## v1.4.16 更新（本分支最新 · 场景图重绘第 9 批，累计 85/105）

- 变体补全 10 张：点名教室 / 窗反射（玻璃里的教室多一张桌子）/ 走廊频闪 /
  下行楼梯（数到黑）/ 门房键盘（磨亮的键）/ 布告栏层贴 / 旧楼红光走廊 /
  办公桌黎明（刚离开的人）/ 桌沿刻痕（第一百零九道更新）/ 门房（慢四分钟的钟）
- 剩余 20 张为最后一~两批（含主视觉 title/keyvisual、旧楼夜景、镜像、天台俯瞰等）
- 版本 1.4.16（versionCode 24）

## v1.4.15 更新

- 外围校园 10 张：食堂日/夜（收摊后灯带）/ 操场正午 / 校园黄昏俯瞰
  （东边那栋黑楼）/ 校门黄昏 / 医务室日/夜 / 天台夜 / 天台门 /
  旧楼教室"桌椅塔"变体
- 版本 1.4.15（versionCode 23）

## v1.4.14 更新

- 道具特写 10 张：109 页残片（焦边+铅笔痕）/ 借书卡（名字描到笔压透纸）/
  日志残页 / 广播值班登记册（同名渐淡）/ 核心名单页（一页全是同一个名字）/
  值日表（层层修正液）/ 寻人启事（照片晕成空白）/ 车票 / 铁皮文具盒 /
  录像带（编号过百）
- 所有文字均以"模糊不可读"处理，避免 AI 生成乱码字
- 版本 1.4.14（versionCode 22）

## v1.4.13 更新

- 校史馆与档案系 7 张：校史馆大厅 / 黄昏 / 门厅 / 毕业照墙（中间一框全班
  面目褪成模糊）/ 档案内门（转盘锁）/ 监控雪花墙 / 监控画面墙
- 图书馆借书台（反复描写的名字）/ 307 夜之影（墙上多一道不匹配任何家具的影子）
- 旧楼铁丝网雨夜（网上的破口）
- 版本 1.4.13（versionCode 21）

## v1.4.12 更新

- 广播室系 7 张：铁门 / 门缝漏光（特写）/ 天晴白（终章后日）/ 火光边缘
  （五年前闪回）/ 主控台特写（胶木开关+VU 表）/ 沈禾背影（窗前）/ 虚空中继
  （房间边缘溶解进灰白）
- 旧楼 3 张：走廊 / 水浸走廊（黑色镜面）/ 楼梯（一百零九级）
- 版本 1.4.12（versionCode 20）

## v1.4.11 更新

- 教室变体 4 张：晨光 / 雨夜晚自习 / 全员回头（无面剪影构图）/ 靠窗缺座
- 办公室 3 张：日 / 夜（百叶月光）/ 台灯（灯圈下摊开的名册）
- 门房日景 / 旧楼废弃教室（叠桌积灰+封窗光刃）/ 图书馆书架夜（过道比楼更长）
- 版本 1.4.11（versionCode 19）

## v1.4.10 更新

- 宿舍系 6 张：307 日景 / 307 深夜（凌晨三点质感）/ 307 门牌名字墙（一个名字
  被手写覆盖）/ 宿舍走廊夜 / 宿舍门夜（门缝漏光）/ 门缝阴影
- 水房系 2 张：水房夜（滴水+闪烁灯管）/ 镜子（倒影微妙不对）
- 走廊黄昏 / 楼梯间夜
- 版本 1.4.10（versionCode 18）

## v1.4.9 更新

- 第 2 批 10 张实装：广播室暗 / 广播室空椅 / 雨夜校园主视觉 / 校门日 / 校门夜 /
  夜校园道路 / 旧楼外观日（含"竖钉的新窗"细节）/ 图书馆 / 值班室夜 / 监控室
- 统一管线：16:9 生成 → 1376×768 cover 裁切 → 256 色量化（135-430KB/张）
- 版本 1.4.9（versionCode 17）

## v1.4.8 更新

- **表情收敛**：老秦/梁野/林昼/男同学/许清 5 组差分重绘为克制自然系
  （惊恐=僵住、震惊=微怔、怒视=平视凝住，不再夸张变形），共 20 张
- **场景图重绘启动**（全 104 张计划，每轮 10 张）：第 1 批 5 张已实装——
  白天教室 / 晚自习教室 / 白天走廊 / 夜走廊 / 307 宿舍夜；
  统一 16:9 生成 → cover 裁切 1376×768 → 256 色量化（~200-330KB/张，与原库同规格）
- 版本 1.4.8（versionCode 16）

## v1.4.7 更新

- **13 个角色立绘全部重绘**（2×2 表情表生成 → 纯白底抠透明 → 768 规格）：
  周叙/梁野/沈禾/许清/老秦/李恒/林昼(备用)/？？？/食堂阿姨/宿管阿姨/同学×3
- 每角色保留 4 个差分（按剧本使用频率选取，含回退根表情），全表情链校验：
  剧本 44 种 @show 引用 0 缺失，17 种按链回退（fear→nervous、smirk→smile 等）
- 许清新增腕表细节（呼应 22:07 停摆表设定）；unknown 保留无面影形象
- 版本 1.4.7（versionCode 15）

## v1.4.6 更新

- **开屏重做（双图标合并）**：塞博仓鼠(AI) 图标从左、Godot 图标从右向中间移动
  → 合并闪光后只保留 Godot → **放大 0.5 秒后复原** → **跑马灯字幕带**扫过
  （作品名 / 塞博仓鼠×AI 制作 / Godot 4.7.2 致意 / 耳机提示）→ 进入作品标示页；
  点击逐段前进 / Esc 跳过的进入方式保留
- **剧本设定调整（男频向）**：移除「许清不穿鞋」设定及其全部线索，改为
  **「灯下无影」**（与"影子数不对"母题呼应，线索总数仍 36）；她的忏悔重写为
  **停在 22:07 的表**（呼应"十点零七分"广播母题：那晚折返换名册的两分钟）；
  第四章"脚冷吗"追问分支改为"您在那儿站了多久"；相关监控/目击/旁白全部同步
- **无歧视复查**：全剧本扫描性别/地域/群体类敏感词（30+ 词根）零命中；
  沈禾真结局两处"赤脚走出声音"为她本人的高光段落，予以保留
- **立绘更新**：周叙 / 梁野 / 沈禾 三位核心角色重绘（表情表生成 → 白底抠透明
  → 768 规格），各保留使用频率最高的 4 个表情，其余旧表情移除、由回退链
  自动落到新画风；`release/void/dead` 回退链终点补 `normal` 防悬空
- 版本 1.4.6（versionCode 14）；剧本 564 节点 / 28 脚本 / 线索 36 项校验全绿

## v1.4.5 更新（开屏与稳定性）

- **开屏动画三段式重做**：Godot 引擎致意（新增「该游戏使用 Godot 4.7.2 制作」）→
  制作信息（**塞博仓鼠 🐹 × AI 制作** + AI 生成图标）→ 作品标示
- **新进入方式**：点击/触摸/任意键**逐段前进**（每段最短停留 0.35s 防误触连跳），
  **Esc 一键跳过**；底部动态提示「点击进入下一段 · Esc 跳过」
- **AI 图标**：`assets/ui/agent_hamster.png`（AI 生成的赛博仓鼠，代表参与制作的 AI，
  512px）；缺图时代码绘制发光仓鼠回退
- **修复：切后台音频不停**——Android 按 Home 键回桌面后 BGM/环境音继续播放
  （漏音+耗电），现在应用暂停/失焦时全部 AudioStreamPlayer 挂起，恢复时续播
- **加固：存档原子落盘**——设置/持久层/存档/自动存档统一「先写 .tmp 再改名」，
  写入途中进程被杀不会留下半截坏档
- 版本 1.4.5（versionCode 13）；28 脚本语法解析 + 静态检查 0 错误

## v1.4.4 更新（创作者音频实装）

- **实装 16 个替换音频**（素材来自 md 仓库 main 分支上传）：4 首 BGM（主场景/真相/
  结局坏/调查）+ 4 组环境音（白噪声/蝉鸣/雨声/光电流）+ 8 个音效，统一转码为
  44.1kHz 单声道 OGG Vorbis（限幅 -3dB），映射表见 `docs/音频替换指南.md`
- **修复 4 个假扩展名文件**：主场景.ogg / 真相.ogg / 结局坏.mp3 / 调查.mp3 实为
  视频容器（Theora/AAC），直接放进工程会触发 Godot「Ogg Vorbis decoding failed」；
  已剥离视频轨只取音频，重新封装为标准 Vorbis
- 分包调整：资源卷增至两卷（part2 背景 71MB / part3 立绘+音频 30MB），全部 <100MB
- `tools/check_audio.py` 全目录 55 项自检通过
- 版本 1.4.4（versionCode 12）

## v1.4.3 更新（音频）

- **重编码 `bgm_unease.ogg`**：从另一开发线的原始 WAV 母带重新编码为标准 Ogg Vorbis
  （22050Hz 单声道 12s），全新字节流。原文件经页结构/完整解码/串号三重校验本身合法，
  Godot 端导入失败多为本地副本损坏或 `.godot` 导入缓存损坏——遇此报错先右键
  Reimport，仍不行删除 `game/.godot/` 重开编辑器全量重导。
- **新增 `tools/check_audio.py`**：55 个 OGG 的魔数/页结构/EOS/串号唯一性自检，
  装了 soundfile 则做完整解码验证（当前全目录通过）。
- **新增 `docs/音频替换指南.md`**：怎么替换/新增 BGM、环境音、音效（同名覆盖即可，
  文件名即 ID，循环与混音由前缀自动处理），含音量体系与常见问题。
- 版本 1.4.3（versionCode 11）。

## v1.4.2 更新（兼容性修复）

- **修复严格模式编译错误**：`ArtCache._store()` 中 `var oldest := _lru.pop_front()`
  由 Variant 推断类型，触发 Godot「INFERENCE_ON_VARIANT（警告视为错误）」解析错误，
  导致工程无法启动。已改为显式标型 `var oldest: String = ...`（与既有
  `audio_director.gd` 惯例一致）。
- **防再犯**：`tools/check_gdscript.py` 新增规则 10c——`:=` 最外层表达式直接是
  `.get() / .pop_front() / .pop_back() / parse_string()` 时报错（转换函数包裹的
  合法写法不误报），本轮全库扫描 0 违规。
- 版本 1.4.2（versionCode 10）。

## v1.4.1 更新（稳定性修复）

- **修复多周目闪退（关键）**：游戏界面对 autoload 信号（`GameState.time_changed /
  var_changed`、`StoryEngine.story_finished`、`Ach.unlocked`）原先用 lambda 连接，
  旧界面销毁后连接残留，第二周目触发信号时调用已释放实例 → Android 闪退。
  现全部改为命名方法连接，节点销毁时自动断开。
- **修复贴图缓存无限增长（OOM 防护）**：`ArtCache` 新增 LRU 硬上限
  `MAX_CACHE = 64`，超限淘汰最久未用贴图；`release_stale` 章节上限不再硬编码 6，
  跟随 `CHAPTER_BG` 实际键位（含番外章）。
- **番外开场内存减负**：番外章不再整目录预载 5 个角色约 40 张立绘
  （~90MB 解码内存），立绘按需加载；背景预载清单收敛为实际用到的 7 张。
  低配手机进入番外不再有 OOM 风险。
- 章节卡片对番外章显示「番外」而非「第 终 章」。
- 全部 28 个脚本通过 GDScript 4 语法解析校验（gdtoolkit）与静态检查；
  版本 1.4.1（versionCode 9）。

## v1.4.0 更新

- **成就系统（22 项）**：新增 `autoload/achievements.gd`（autoload 名 `Ach`）。
  结局 / 周目 / 线索 / 道具 / 密码锁 / 数值阈值全程监听，解锁写入
  `user://persistent.json` 跨周目保留；游戏顶栏新增「成就」按钮
  （`MenuPanels.achievement_panel()`），解锁瞬间右上角 Toast 弹出提示。
  结局类与速通类成就解锁前显示 ？？？，防剧透。
- **番外《天晴》**：真结局《点名停止》后标题页解锁「番外《天晴》」入口
  （`story/60_extra.avg`，4 节点 / `@chapter 6`）。雨停三天的清晨：闸机开始记
  「出校」、四十一就是四十一、那支笔有了去处——两个分支两种还法，最终抵达
  番外结局 `ending_extra_sunny`（结局画面含专属文案与 BGM）。
- **收集统计补全**：`GameState.persistent` 新增 `items_seen`（跨周目道具收集）与
  `achievements`；`add_item` 发出 `item_gained` 信号。
- 事件信号：GameState 新增 `run_reset / clue_added / item_gained / loss_registered /
  ending_recorded`；`StoryEngine.padlock_done` 成功时回调 `Ach.notify_padlock_solved`。
- 冒烟测试从 19 项扩至 21 组（成就判定 15 项断言 + 番外全流程推演）；节点总数
  560 → 564；`tools/check_gdscript.py`（无 Godot 环境的静态检查）并入本工程。
- 版本号 1.4.0（versionCode 8）。

## v1.3.1 更新

- 引擎升级：Godot Engine 4.7.1 stable → 4.7.2 stable（Android 编辑器）
- 4.7.2 变更日志核验：全部为 bug 修复、无 GDScript API 破坏；
  其中与本作直接相关——Android 熄屏启动崩溃修复 / 安卓编辑器回归修复 /
  GUI 容器 maximum_size 缓存修复
- 工程适配并通过 4.7.2 源码编译的无头验证（26 脚本 / 560 节点 /
  21 项冒烟测试）

## v1.3.0 更新

- UI 整体更新为 VNShell 现代扁平深色蓝调风格（纯代码 StyleBoxFlat）：
  深蓝灰面板 #212734 / 主强调蓝 #4a8cff / 大圆角 12~20px，
  对话框/顶栏/选项/菜单/密码锁/标题/结局界面全部换色
- 删除 9 张旧恐怖风 UI 贴图（代码均有纯色回落，功能无损）
- 新增刘海屏安全区适配（移植 VNShell SafeArea，物理像素→视口换算）：
  顶栏/对话框/菜单面板自动避开刘海挖孔与手势条
- 版本号 1.3.0（versionCode 6）

## v1.2.0 更新

- 横屏显示：窗口方向改为传感器横屏（支持左右两个方向，手机横屏体验）
- 新增「跳选」按钮：快进到下一选项（多周目速通），遇选项/密码锁/结局自动停止
- 新增触觉震动：惊吓演出（sting/bigshake/bloodburst）与密码错误时手机震动，设置面板可关
- 新增文字大小调节（小/中/大 三档），保存设置后即时应用
- 设置面板新增两行：触觉震动开关、文字大小

## v1.1.1 更新（本分支）

> 追加：开屏动画取消游戏图标，统一使用官方 Godot 引擎图标（原生 boot splash 亦恢复引擎默认 Godot 标识，游戏内开屏第二段改为纯文字）；新增 AI 生成的深色雨夜氛围底图（splash_bg.png，压暗+缓慢缩放，Godot 引擎图标浮于其上，缺图自动回退纯色底）

- 游戏名更改为《第十三节课》，同步更新开屏 / 标题 / 工程配置 / 安卓包名（`com.example.the13thperiod`）与全部图标（含自适应图标）
- 开屏动画统一使用官方 Godot 引擎图标（原生 boot splash + 游戏内开屏，均带无贴图兜底），不再使用游戏图标
- 移除创意工坊（workshop / workshop_panels / content_policy），精简完整性清单
- 新增解谜系统：数字密码锁（第四章校史馆内门 0109、终章广播主控柜 2119），配合道具与线索推进
- 新增自定义角色名：新游戏前可为主角命名，正文、名牌与存档同步
- 场景图完善：新增俯瞰夜景、主控柜特写、白天旧楼等场景并接入剧本（真结局“天晴”等场景实装）
- 性能与代码清理：删除无用变量、限制回想/选择日志长度、预取清单更新

> **关于 GitHub 100MB 硬限制**：git 推送的单文件上限是 100MB，服务端强制、
> 无法关闭。当 ZIP 超过 100MB 时，请改用 **GitHub Releases** 发布
> （单附件上限 2GB，且不再占用仓库体积）：
>
> ```bash
> # 在你自己的电脑上（网络可达 uploads.github.com）执行，把 ZIP 挂到 v1.1.2 Release：
> gh release upload v1.3.1 dist/The13thPeriod_v1.3.1_full_project.zip --repo BJX-lin/md
> ```
>
> 上传完成后，下载地址为：
> `https://github.com/BJX-lin/md/releases/download/v1.3.1/The13thPeriod_v1.3.1_full_project.zip`
>
> 其他备选方案：Git LFS（单文件 2~5GB，但免费存储/流量额度有限）、
> 分包压缩（拆成多个 <100MB 的分卷）。注意：曾经提交进 git 历史的旧 ZIP
> 会永久占仓库体积，如需彻底瘦身需重写历史（`git filter-repo`，有风险）。
