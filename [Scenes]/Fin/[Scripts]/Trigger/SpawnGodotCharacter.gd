extends Node3D

## 在触发器位置生成一个小 Godot 角色，并沿指定方向移动。
## 作为 BaseTrigger 的子节点使用，由父节点负责碰撞检测。

const GODOT_CHARACTER_SCENE: PackedScene = preload("res://Character/SkinGodot.tscn")
const RUN_ANIMATION: StringName = &"run"

## 角色移动的全局方向；使用前会归一化。
@export var direction: Vector3 = Vector3.BACK
## 每秒移动距离。
@export var speed: float = 5.0
## 实例存在时间（秒）。
@export_range(0.0, 60.0, 0.1, "or_greater") var duration: float = 2.0
## 横轴为归一化生命周期，纵轴 0 表示透明、1 表示不透明。
@export var alphaCurve: Curve


## 由父节点 BaseTrigger 调用的入口方法。
func trigger(_body: Node3D) -> void:
	var sceneRoot: Node = get_tree().current_scene
	if sceneRoot == null:
		push_error("SpawnGodotCharacter: current scene is unavailable")
		return

	var character: Node3D = GODOT_CHARACTER_SCENE.instantiate() as Node3D
	if character == null:
		push_error("SpawnGodotCharacter: failed to instantiate SkinGodot.tscn")
		return

	sceneRoot.add_child(character)
	character.global_position = global_position
	var movementDirection: Vector3 = direction.normalized()
	if movementDirection.is_zero_approx():
		push_warning("SpawnGodotCharacter: direction must not be zero")
		character.queue_free()
		return
	var upDirection: Vector3 = Vector3.UP
	if absf(movementDirection.dot(upDirection)) > 0.999:
		upDirection = Vector3.FORWARD
	character.global_basis = Basis.looking_at(-movementDirection, upDirection)

	_playRunLoop(character)
	_animateCharacter(character, movementDirection)


func _playRunLoop(character: Node3D) -> void:
	var animationPlayer: AnimationPlayer = character.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animationPlayer == null or not animationPlayer.has_animation(RUN_ANIMATION):
		push_warning("SpawnGodotCharacter: run animation is unavailable")
		return

	var runAnimation: Animation = animationPlayer.get_animation(RUN_ANIMATION)
	if runAnimation != null:
		var localRunAnimation: Animation = runAnimation.duplicate() as Animation
		localRunAnimation.loop_mode = Animation.LOOP_LINEAR
		var animationLibrary: AnimationLibrary = animationPlayer.get_animation_library("")
		animationLibrary.remove_animation(RUN_ANIMATION)
		animationLibrary.add_animation(RUN_ANIMATION, localRunAnimation)
	animationPlayer.play(RUN_ANIMATION)


func _animateCharacter(character: Node3D, movementDirection: Vector3) -> void:
	var fadeMaterials: Array[BaseMaterial3D] = []
	var baseAlphas: Array[float] = []
	_collectFadeMaterials(character, fadeMaterials, baseAlphas)
	var initialAlpha: float = _sampleAlpha(0.0)
	_setAlpha(fadeMaterials, baseAlphas, initialAlpha)

	if duration <= 0.0:
		character.queue_free()
		return

	var destination: Vector3 = character.global_position + movementDirection * speed * duration
	var tween: Tween = character.create_tween()
	tween.set_parallel(true)
	tween.tween_property(character, "global_position", destination, duration)
	tween.tween_method(
		func(progress: float) -> void:
			_setAlpha(fadeMaterials, baseAlphas, _sampleAlpha(progress)),
		0.0,
		1.0,
		duration
	)
	tween.chain().tween_callback(character.queue_free)


func _collectFadeMaterials(
		node: Node,
		fadeMaterials: Array[BaseMaterial3D],
		baseAlphas: Array[float]) -> void:
	if node is MeshInstance3D:
		_prepareMeshMaterials(node as MeshInstance3D, fadeMaterials, baseAlphas)
	for child: Node in node.get_children():
		_collectFadeMaterials(child, fadeMaterials, baseAlphas)


func _prepareMeshMaterials(
		meshInstance: MeshInstance3D,
		fadeMaterials: Array[BaseMaterial3D],
		baseAlphas: Array[float]) -> void:
	var overrideMaterial: Material = meshInstance.material_override
	if overrideMaterial is BaseMaterial3D:
		var localOverride: BaseMaterial3D = overrideMaterial.duplicate() as BaseMaterial3D
		meshInstance.material_override = localOverride
		_registerFadeMaterial(localOverride, fadeMaterials, baseAlphas)
		return

	if meshInstance.mesh == null:
		return
	for surfaceIndex: int in range(meshInstance.mesh.get_surface_count()):
		var sourceMaterial: Material = meshInstance.get_active_material(surfaceIndex)
		if sourceMaterial is BaseMaterial3D:
			var localMaterial: BaseMaterial3D = sourceMaterial.duplicate() as BaseMaterial3D
			meshInstance.set_surface_override_material(surfaceIndex, localMaterial)
			_registerFadeMaterial(localMaterial, fadeMaterials, baseAlphas)


func _registerFadeMaterial(
		material: BaseMaterial3D,
		fadeMaterials: Array[BaseMaterial3D],
		baseAlphas: Array[float]) -> void:
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fadeMaterials.append(material)
	baseAlphas.append(material.albedo_color.a)


func _sampleAlpha(progress: float) -> float:
	if alphaCurve == null:
		return 1.0
	return clampf(alphaCurve.sample_baked(clampf(progress, 0.0, 1.0)), 0.0, 1.0)


func _setAlpha(
		fadeMaterials: Array[BaseMaterial3D],
		baseAlphas: Array[float],
		alpha: float) -> void:
	for index: int in range(fadeMaterials.size()):
		var material: BaseMaterial3D = fadeMaterials[index]
		if is_instance_valid(material):
			var color: Color = material.albedo_color
			color.a = baseAlphas[index] * alpha
			material.albedo_color = color
