extends Node3D

## 作为 BaseTrigger 的子组件使用，触发指定 MobileMirror 的破碎效果。

const DEFAULT_SHATTER_CLIP: AudioStream = preload("res://#Template/[Resources]/Hit.wav")

@export_node_path("Node3D") var targetMirrorPath: NodePath
@export var playSound: bool = true
@export var customShatterClip: AudioStream


func trigger(body: Node3D) -> void:
	var mirror: MobileMirror = get_node_or_null(targetMirrorPath) as MobileMirror
	if mirror == null:
		push_warning("ShatterMirror: target MobileMirror is unavailable")
		return
	if not mirror.shatter(body.global_position):
		return
	if playSound:
		var clip: AudioStream = customShatterClip if customShatterClip != null else DEFAULT_SHATTER_CLIP
		AudioManager.play_clip(clip)
