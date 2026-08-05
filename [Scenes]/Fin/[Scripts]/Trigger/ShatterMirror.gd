extends Node3D

## 作为 BaseTrigger 的子组件使用，触发指定 MobileMirror 的破碎效果。

const DEFAULT_SHATTER_CLIP: AudioStream = preload("res://#Template/[Resources]/Hit.wav")

@export_node_path("Node3D") var targetMirrorPath: NodePath
@export var playSound: bool = true
@export var customShatterClip: AudioStream

var _checkpointIndex: int = -1


func _ready() -> void:
	if not Engine.is_editor_hint():
		LevelManager.add_revive_listener(_onRevive)


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		LevelManager.remove_revive_listener(_onRevive)


func trigger(body: Node3D) -> void:
	var mirror: MobileMirror = _getTargetMirror()
	if mirror == null:
		push_warning("ShatterMirror: target MobileMirror is unavailable")
		return
	if not mirror.shatter(body.global_position):
		return
	_checkpointIndex = LevelManager.checkpoint_count
	if playSound:
		var clip: AudioStream = customShatterClip if customShatterClip != null else DEFAULT_SHATTER_CLIP
		AudioManager.play_clip(clip)


func _onRevive() -> void:
	if _checkpointIndex < 0:
		return
	LevelManager.CompareCheckpointIndex(_checkpointIndex, func() -> void:
		var mirror: MobileMirror = _getTargetMirror()
		if mirror:
			mirror.resetShatter()
		var triggerContainer: BaseTrigger = get_parent() as BaseTrigger
		if triggerContainer:
			triggerContainer.set("_used", false)
		_checkpointIndex = -1
	)


func _getTargetMirror() -> MobileMirror:
	return get_node_or_null(targetMirrorPath) as MobileMirror
