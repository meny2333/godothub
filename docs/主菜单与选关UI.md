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

当前第 1 个槽位指向 `res://[Scenes]/Fin/Fin.tscn`。第 2、3 个槽位可以选择和预览，但启动按钮显示“制作中”，不会尝试加载不存在的资源。第 4 个槽位是锁定的完整模式入口，首次选择后可播放解锁动画；解锁后仍保持场景占位状态。

## 四个场景槽位

场景路径统一维护在 `MainMenu.gd` 的 `STAGE_SCENE_PATHS`：

```gdscript
const STAGE_SCENE_PATHS: Array[String] = [
	"res://[Scenes]/Fin/Fin.tscn",
	"",
	"",
	"",
]
```

后续场景完成后，按“初滞、回声、终章、回声之境”的顺序填入路径即可。空字符串代表占位场景，菜单会自动禁用进入按钮。

## 视觉与动画

- `EchoBackdrop.gd` 根据当前槽位绘制暖黄峡谷、灰蓝山谷、破晓拱门和镜面碎片意象。
- 背景的错位路径、残影光点和场景色彩会持续缓慢运动。
- `MirrorCarousel.tscn` 使用 `p1.png` 至 `p4.png` 作为关卡后景卡片，卡片沿轮盘环形关系切换，并带有缩放、旋转、景深层级和透明度过渡。
- `MirrorOverlay.gd` 在卡片之前绘制镜面碎边、轮盘刻度和持续扫过的反光，形成镜子前景。
- `LockGlyph.gd` 负责完整模式的锁芯发光、锁梁抬起和碎光释放；解锁时还会触发镜面闪白及封印遮罩退场。
- 开始页、选关页、设置面板和进入游戏均使用 Tween 过渡。
- 从主菜单进入 `Fin.tscn` 时使用一次性 `menu_launch_pending` 标记。`Player` 会跳过旧的游戏内 `StartPage` 并自动开始；直接在编辑器运行 `Fin.tscn` 时，原有 `StartPage` 仍然保留。

## 设置与语言

主菜单设置直接复用 `SetLatency` 和 `GraphicsQuality`，包含：

- 中文 / English
- 画质等级
- 3D 抗锯齿
- 音量
- 音画延迟
- 阴影
- 后处理

设置写入 `user://settings.cfg`。语言使用 `[ui] language`，音频与画面选项继续使用项目已有的 `[audio]` 和 `[graphics]` 配置段。

完整模式的解锁状态写入同一个配置文件的 `[progress] full_mode_unlocked`。重新进入菜单后，P4 会直接呈现已经解锁的镜面卡片，不会重复播放开锁动画。
