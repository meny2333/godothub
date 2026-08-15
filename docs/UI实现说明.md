# UI 实现说明

本文档记录当前已落地的 UI/系统实现细节，作为设计与代码之间的对照。与 `主菜单与选关UI.md`、`UI文字汇总.md` 配套阅读。

## 游戏命名

- **中文名：《弄影》** — 取自苏轼《水调歌头》「起舞弄清影，何似在人间」。
- **英文名：AFTERIMAGE**。
- 主菜单 `BrandTitle`：中英随语言切换「弄影」/「AFTERIMAGE」（`MainMenu.gd` `_apply_language()`）。
- `project.godot` `config/name`：弄影 Afterimage。

## 主菜单（MainMenu.tscn / MainMenu.gd）

- 顶部 `TopBar`：Brand（品牌标题）+ 章节 / 语言 / 设置按钮。
- 设置面板（`SettingsPanel`）内容：语言、抗锯齿、音量、音画延迟、转向键。
  - **音画延迟**：左右三角按钮（`arrow_left.png` / `arrow_right.png`）±10ms 步进（`LATENCY_STEP = 0.01`），范围 ±5000ms；不再使用 HSlider。显示 `%+d ms`。
  - **转向键（turn）**：点击「转向键」按钮进入录制态（显示「按任意键…」），按任意键盘键或鼠标键即绑定；ESC 取消。写入 `InputMap`（`physical_keycode` 或 `MouseButton`）并持久化到 `user://settings.cfg` 的 `[input]` 段（`turn_key` / `turn_key_mouse`）。设置面板内所有按钮 `focus_mode = FOCUS_NONE`，避免 Space/Enter 激活按钮干扰 turn 键。
- 选关卡片副标题（`STAGE_SUBTITLES`）：初滞=暖黄峡谷、回声=灰蓝山谷、终章=**镜面回廊**、回声之境=**完整关卡**。
- 完整关卡（第 4 槽位）通过 `FullLevelSync` 拥有同步率系统（见下）。

## 游戏内皮肤选择器（SkinSelector）

文件：`[Scenes]/Fin/Character/SkinSelector.tscn` / `.gd`

### 入口

- 右上角 `TopRightButtons`：「皮肤」按钮 + 齿轮按钮（`gear.png`，金色 SVG 生成）。
- 点击后右侧抽屉滑入（`SkinPanelHolder` / `SettingsPanelHolder`，`clip_contents = true` 固定尺寸裁剪，tween holder 的 offset 实现纯平移动画，避免子容器最小尺寸导致卡顿/缩放）。

### 皮肤面板（SkinPanel）

- 标题「皮肤 / SKINS」+「游戏开始前」副标题。
- 当前皮肤预览 + 名称。
- 两张选择卡片：
  - **经典 / CLASSIC**（原始角色）— 显示原始线条/Player 本体。
  - **Godot / LOW-POLY FORM**（低多边形角色）— 实例化 `SkinGodot.tscn`，通过 `Player.enable_henshin` 挂载。
- 选中 Godot 皮肤时显示 **动画预览按钮**（`ActionRow`）：
  - 「转弯动画 / TURN」→ `GodotCharacter.play_turn()`（`huachan.anim`）。
  - 「滑铲动画 / SLIDE」→ `GodotCharacter.play_slide()`（复用 `huachan.anim`，更快速度 2.6 播放，独立 `SLIDE_ANIMATION` 条目）。
- 面板打开时等一帧再滑入（`await get_tree().process_frame`），避免容器布局未完成导致子项被压缩。
- 收起时立即禁用面板内交互控件（`_set_panel_interactive` 只设 Button/OptionButton/HSlider 为 STOP，装饰控件保持 IGNORE——否则全宽 Image 会拦截点击导致按钮点不了），遮罩延迟到滑出动画结束再隐藏。
- 面板 `mouse_filter = STOP`，点击面板外区域（InputBlocker）关闭。

### 设置面板（SettingsPanel，游戏内齿轮打开）

与主菜单设置一致的交互：

- 语言切换（复用 `[ui] language`）。
- 抗锯齿（`GraphicsQuality`）。
- 音量 HSlider（5% 步进，实时应用到 Player 的 `MusicPlayer`）。
- 音画延迟 ±10ms 三角按钮（同步 `Player.musicDelay` + `SetLatency`）。
- 转向键录制（与主菜单共用 `[input]` 配置段）。
- ESC 关闭。

### 层级

`SkinSelector` 为 `CanvasLayer layer = 41`：在同步率 HUD（layer 40）之上、玩法介绍卡片（layer 90）与剧情片头（layer 128）之下。

## 同步率系统（FullLevelSync）

- 在 Part 2（stage 1）、Part 3（stage 2）、完整关卡（stage 3）激活（`FinStageEntry._add_part_sync`，`_stage_index > 0`）。
- HUD：`SyncHUD` CanvasLayer（layer 40），**右上角**（`PRESET_TOP_RIGHT`）竖向胶囊进度条 + 同步率 % + 标题「同步率 / SYNC RATE」。移至右上角以避开皮肤面板（右侧垂直居中）。
- 机制：随时间自然衰减；收集水晶/皇冠/穿过回响拱门恢复；同步率低时 `Engine.time_scale` 变慢（`minimum_time_scale`~`maximum_time_scale`），耗尽即失败。
- 跨段继承：Part 结束时把当前同步率写入 `get_tree().root` 的 `fin_inherited_sync`，下一段起点继承。

## 玩法介绍（TutorialManager.show_guide_panel）

- Part 2 / Part 3 开始前，叙事片头（`show_opening_intertitle`，全屏黑幕）之后显示**非全屏玩法介绍卡片**。
- 卡片定位：屏幕**右侧居中**（`PRESET_CENTER_RIGHT`，距右缘 40px）。
- 不暂停游戏、不遮挡全屏；全屏透明拦截层接收点击/按键关闭并吞掉事件（不触发转向）。
- 内容：「同步率 / SYNC RATE」标题 + 玩法说明（点击转向保持同步率、收集恢复、耗尽失败）+「点击任意处关闭」。

## 多结局（FinStageEntry._resolve_ending）

- **结局只在完整关卡（stage 3）显示**；Part 1–3 通关显示各自段落文案。
- 完整关卡按最终同步率分层：

| 条件 | 结局 |
|---|---|
| 最终同步率 ≥90% 且 part3 曾 100% | 完美同步 / PERFECT SYNC |
| ≥90% | 心意相通 / HEARTS CONNECTED |
| ≥60% | 渐入佳境 / GROWING RHYTHM |
| ≥30% | 迟来的抵达 / A LATE ARRIVAL |
| <30% | 残存的微光 / A FADING LIGHT |

- part3（stage 2）通关时同步率 ≥99.5%（`PART3_PERFECT_THRESHOLD`）写入 `user://settings.cfg` 的 `[endings] part3_perfect_sync = true`，作为完整关卡最高档结局的前置条件。
- 结局读取时机：玩家到达终点 `GameState == Completed` 后同步率冻结（FullLevelSync 只在 Playing 时衰减），`get_inherited_sync()` 返回最终值。
