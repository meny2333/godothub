# 主菜单与选关 UI

## 入口与流程

项目入口为 `res://[Scenes]/MainMenu/MainMenu.tscn`。

运行流程：

```text
MainMenu.tscn
  -> 开始界面
  -> 四段选关界面
  -> change_scene_to_file(关卡路径)
  -> 游戏场景
```

当前第 1、2、3 个槽位沿用原有段落场景，第 4 个槽位为完整关卡。第 2、3、4 个槽位按前一段完成状态解锁。

## 游戏命名

- **中文名：《弄影》**——取自苏轼《水调歌头》「起舞弄清影，何似在人间」。玩家操控线条（起舞），残影永远慢半拍相随（弄影），含蓄点出「滞后」主题而不直白。
- **英文名：AFTERIMAGE**——主菜单 `BrandTitle` 中英随语言切换：「弄影」/「AFTERIMAGE」。
- 应用名（`project.godot` `config/name`）为「弄影 Afterimage」。

## 四个场景槽位

场景路径统一维护在 `MainMenu.gd` 的 `STAGE_SCENE_PATHS`。四个槽位：

| 槽位 | 标题 | 副标题 |
|---|---|---|
| 1 | 初滞 / FIRST DELAY | 暖黄峡谷 / AMBER CANYON |
| 2 | 回声 / THE ECHO | 灰蓝山谷 / BLUE VALLEY |
| 3 | 终章 / GENTLE ARRIVAL | 镜面回廊 / MIRROR CORRIDOR |
| 4 | 回声之境 / ECHO REALM | 完整关卡 / FULL EXPERIENCE |

第 4 个槽位即完整关卡（全部段落连在一起），副标题为「完整关卡 / FULL EXPERIENCE」，不再是「镜面回廊」。

## 视觉与动画

- `EchoBackdrop.gd` 根据当前槽位绘制暖黄峡谷、灰蓝山谷、破晓拱门和镜面碎片意象。
- 背景的错位路径、残影光点和场景色彩会持续缓慢运动。
- `MirrorCarousel.tscn` 使用 `p1.png` 至 `p4.png` 作为关卡后景卡片，卡片沿轮盘环形关系切换，并带有缩放、旋转、景深层级和透明度过渡。
- `MirrorOverlay.gd` 在卡片之前绘制镜面碎边、轮盘刻度和持续扫过的反光，形成镜子前景。
- `LockGlyph.gd` 负责完整模式的锁芯发光、锁梁抬起和碎光释放；解锁时还会触发镜面闪白及封印遮罩退场。
- 开始页、选关页、设置面板和进入游戏均使用 Tween 过渡。
- 从主菜单进入关卡场景时使用一次性 `menu_launch_pending` 标记。`Player` 会跳过旧的游戏内 `StartPage` 并自动开始；直接在编辑器运行关卡场景时，原有 `StartPage` 仍然保留。

## 设置与语言

主菜单设置直接复用 `SetLatency` 和 `GraphicsQuality`，包含：

- 中文 / English
- 3D 抗锯齿
- 音量（HSlider，5% 步进）
- 音画延迟（**左右三角按钮 ±10ms 步进**，替代原 HSlider）
- **转向键（turn）键位设置**：点击按钮进入录制态，按任意键/鼠标键绑定，写入 `InputMap` 并持久化到 `user://settings.cfg` 的 `[input]` 段
- 阴影
- 后处理

设置写入 `user://settings.cfg`。语言使用 `[ui] language`，音频与画面选项继续使用项目已有的 `[audio]` 和 `[graphics]` 配置段，键位使用 `[input]` 段。

完整模式的解锁状态写入同一个配置文件的 `[progress] full_mode_unlocked`。重新进入菜单后，P4 会直接呈现已经解锁的镜面卡片，不会重复播放开锁动画。
