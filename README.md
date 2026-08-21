# 《第十三节课》 THE 13TH PERIOD

国产校园恐怖文字互动视觉小说（AVG）。

- 引擎：Godot Engine 4.7.2 stable
- 目标平台：Android 手机（竖屏/横屏自适应，渲染后端 Mobile）
- 时长：约 2~3 小时，4 章 + 终章 + 真结局解锁番外，多结局
- 玩法：文本剧情 / 选项分支 / 密码锁解谜 / 线索与道具收集 / 理智与信任数值系统 / 存档读档 / 周目循环 / 成就系统

## 直接下载（GitHub raw 直链）

**v1.4.0 分卷下载（无压缩 store 打包，两卷均 <100MB，规避 GitHub 单文件上限）**

```
https://github.com/BJX-lin/-md-/raw/arena/01a0234d-md/dist/The13thPeriod_v1.4.0_part1_project.zip
https://github.com/BJX-lin/-md-/raw/arena/01a0234d-md/dist/The13thPeriod_v1.4.0_part2_assets.zip
```

> 分卷使用方法：把两个 ZIP **解压到同一个文件夹**即可合并——
> Part 1（3.4MB）含 `game/` 工程核心（代码/剧本/UI/图标/工具）与 `docs/`、设计文档；
> Part 2（98.9MB）含 `game/assets/bg|sprites|audio` 全部美术与音频资源。
> 两卷均为 store 无压缩打包，图片/音频本就是压缩格式，不二次压缩以加快打包与校验。
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

## v1.4.0 更新（本分支最新）

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
