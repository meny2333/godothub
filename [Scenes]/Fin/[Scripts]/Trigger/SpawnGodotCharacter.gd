extends Node3D

## 在触发器位置生成一个小 Godot 角色，并沿指定方向移动。
## 作为 BaseTrigger 的子节点使用，由父节点负责碰撞检测。

const GODOT_CHARACTER_SCENE: PackedScene = preload("res://[Scenes]/Fin/Character/SkinGodot.tscn")
const CLICK_SUCCESS_EFFECT_SCENE: PackedScene = preload("res://[Scenes]/Fin/GodotCharacterClickEffect.tscn")
const RUN_ANIMATION: StringName = &"run"
const SUMMON_PROMPT: String = "点击呼唤回声"
const PROMPT_GROUP: StringName = &"spawn_godot_character_prompt"

signal click_succeeded

## 角色移动的全局方向；使用前会归一化。
@export var direction: Vector3 = Vector3.BACK
## 每秒移动距离。
@export var speed: float = 3.0
## 实例存在时间（秒）。
@export_range(0.0, 60.0, 0.1, "or_greater") var duration: float = 2.0
## 横轴为归一化生命周期，纵轴 0 表示透明、1 表示不透明。
@export var alphaCurve: Curve

@export_group("回声呼唤")
## 角色生成后等待多久再显示点击提示并进入慢速。
@export_range(0.0, 10.0, 0.1, "or_greater") var prompt_delay: float = 1.5
## 进入提示后，玩家必须在此时间内成功转向。
@export_range(0.1, 10.0, 0.1, "or_greater") var response_timeout: float = 1.0
## 点击位置距离角色投影点的最大像素距离。
@export_range(16.0, 256.0, 4.0, "or_greater") var click_radius: float = 72.0
## 场景没有 TutorialManager 时使用的备用慢速倍率。
@export_range(0.05, 1.0, 0.05) var fallback_time_scale: float = 0.3

var _interaction_running: bool = false
var _waiting_for_click: bool = false
var _interaction_token: int = 0
var _active_player: Player
var _tutorial_manager: Node
var _slow_motion_active: bool = false
var _fallback_restore_time_scale: float = 1.0
var _spawned_character: Node3D
var _spawned_characters: Array[Node3D] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	LevelManager.add_revive_listener(_on_revive)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	LevelManager.remove_revive_listener(_on_revive)
	_cancel_interaction()


func _process(_delta: float) -> void:
	if not _waiting_for_click or not is_instance_valid(_spawned_character):
		return
	if not is_instance_valid(_tutorial_manager):
		_tutorial_manager = _find_tutorial_manager()
	if _tutorial_manager and _tutorial_manager.has_method("update_click_indicator"):
		_tutorial_manager.call("update_click_indicator", _spawned_character.global_position)


func _input(event: InputEvent) -> void:
	_consume_click_event(event)


## 在 Player 的普通 turn() 之前调用，避免目标点击先穿透到 Player。
func consume_turn_input(event: InputEvent) -> bool:
	return _consume_click_event(event)


func _consume_click_event(event: InputEvent) -> bool:
	if not _interaction_running or not _waiting_for_click:
		return false

	var click_position: Vector2 = Vector2.ZERO
	var has_click_position: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			click_position = mouse_event.position
			has_click_position = true
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			click_position = touch_event.position
			has_click_position = true

	if not has_click_position or not _is_click_on_spawned_character(click_position):
		return false

	get_viewport().set_input_as_handled()
	_accept_target_click()
	return true


## 由父节点 BaseTrigger 调用的入口方法。
func trigger(body: Node3D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_live or _interaction_running:
		return

	_interaction_running = true
	_active_player = player
	_interaction_token += 1
	var character: Node3D = _spawn_character()
	if character == null:
		_interaction_running = false
		_active_player = null
		return
	_run_interaction(_interaction_token, player)


func _run_interaction(token: int, player: Player) -> void:
	await _wait_real_seconds(prompt_delay)
	if not _is_active_interaction(token, player):
		return

	_begin_click_prompt(player)
	_wait_for_click_timeout(token, player)


func _wait_for_click_timeout(token: int, player: Player) -> void:
	await _wait_real_seconds(response_timeout)
	if not _is_active_interaction(token, player) or not _waiting_for_click:
		return

	_hide_click_indicator()
	_spawn_character()
	_set_slow_motion(false)
	_finish_interaction()
	if not _uses_part_sync() and is_instance_valid(player) and player.is_live:
		player.die()


func _wait_real_seconds(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var timer: SceneTreeTimer = get_tree().create_timer(seconds, true, false, true)
	await timer.timeout


func _is_active_interaction(token: int, player: Player) -> bool:
	return _interaction_running \
		and _interaction_token == token \
		and _active_player == player \
		and is_instance_valid(player)


func _begin_click_prompt(_player: Player) -> void:
	_tutorial_manager = _find_tutorial_manager()
	_set_slow_motion(true)
	_show_prompt()
	var target_position: Vector3 = global_position
	if is_instance_valid(_spawned_character):
		target_position = _spawned_character.global_position
	_show_click_indicator(target_position)
	_waiting_for_click = true
	add_to_group(PROMPT_GROUP)


func _accept_target_click() -> void:
	var effect_position: Vector3 = global_position
	if is_instance_valid(_spawned_character):
		effect_position = _spawned_character.global_position
	_spawn_click_success_effect(effect_position)
	click_succeeded.emit()
	_hide_click_indicator()
	_set_slow_motion(false)
	_finish_interaction()


func _spawn_click_success_effect(world_position: Vector3) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return

	var effect: Node3D = CLICK_SUCCESS_EFFECT_SCENE.instantiate() as Node3D
	if effect == null:
		push_warning("SpawnGodotCharacter: failed to instantiate click success effect")
		return

	scene_root.add_child(effect)
	effect.global_position = world_position


func _is_click_on_spawned_character(click_position: Vector2) -> bool:
	if not is_instance_valid(_spawned_character):
		return false
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return false
	var target_position: Vector3 = _spawned_character.global_position + Vector3.UP
	if camera.is_position_behind(target_position):
		return false
	var projected_position: Vector2 = camera.unproject_position(target_position)
	return projected_position.distance_to(click_position) <= click_radius


func _finish_interaction() -> void:
	_interaction_token += 1
	_waiting_for_click = false
	_interaction_running = false
	_active_player = null
	if is_in_group(PROMPT_GROUP):
		remove_from_group(PROMPT_GROUP)


func _cancel_interaction() -> void:
	_hide_click_indicator()
	_set_slow_motion(false)
	_finish_interaction()
	for character: Node3D in _spawned_characters:
		if is_instance_valid(character):
			character.queue_free()
	_spawned_characters.clear()
	_spawned_character = null


func _on_revive() -> void:
	_cancel_interaction()


func _find_tutorial_manager() -> Node:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return null
	var manager: Node = scene_root.get_node_or_null("BasicOBJ_Group/TutorialManager")
	if manager == null:
		manager = scene_root.find_child("TutorialManager", true, false)
	return manager

func _uses_part_sync() -> bool:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null or not scene_root.has_meta("fin_stage_entry"):
		return false
	var stage_index: int = int(scene_root.get_meta("fin_stage_entry"))
	return stage_index > 0 and stage_index < 3


func _show_prompt() -> void:
	if not is_instance_valid(_tutorial_manager):
		_tutorial_manager = _find_tutorial_manager()
	if _tutorial_manager and _tutorial_manager.has_method("show_narrative"):
		_tutorial_manager.call("show_narrative", SUMMON_PROMPT)


func _show_click_indicator(world_position: Vector3) -> void:
	if not is_instance_valid(_tutorial_manager):
		_tutorial_manager = _find_tutorial_manager()
	if _tutorial_manager and _tutorial_manager.has_method("show_click_indicator"):
		_tutorial_manager.call("show_click_indicator", world_position)


func _hide_click_indicator() -> void:
	if _tutorial_manager and _tutorial_manager.has_method("hide_click_indicator"):
		_tutorial_manager.call("hide_click_indicator")


func _set_slow_motion(slow: bool) -> void:
	if slow:
		if _slow_motion_active:
			return
		_fallback_restore_time_scale = Engine.time_scale
		if not is_instance_valid(_tutorial_manager):
			_tutorial_manager = _find_tutorial_manager()
		if _tutorial_manager and _tutorial_manager.has_method("set_tutorial_slow_motion"):
			_tutorial_manager.call("set_tutorial_slow_motion", true)
		else:
			_apply_fallback_time_scale(fallback_time_scale)
		_slow_motion_active = true
		return

	if not _slow_motion_active:
		return
	if _tutorial_manager and _tutorial_manager.has_method("set_tutorial_slow_motion"):
		_tutorial_manager.call("set_tutorial_slow_motion", false)
	else:
		_apply_fallback_time_scale(_fallback_restore_time_scale)
	_slow_motion_active = false


func _apply_fallback_time_scale(value: float) -> void:
	Engine.time_scale = value
	var player: Player = _active_player if is_instance_valid(_active_player) else Player.instance
	if player == null:
		return
	var music_player: AudioStreamPlayer = player.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if music_player:
		music_player.pitch_scale = value


func _spawn_character() -> Node3D:
	var sceneRoot: Node = get_tree().current_scene
	if sceneRoot == null:
		push_error("SpawnGodotCharacter: current scene is unavailable")
		return null

	var character: Node3D = GODOT_CHARACTER_SCENE.instantiate() as Node3D
	if character == null:
		push_error("SpawnGodotCharacter: failed to instantiate SkinGodot.tscn")
		return null

	sceneRoot.add_child(character)
	_spawned_character = character
	character.global_position = global_position
	var movementDirection: Vector3 = direction.normalized()
	if movementDirection.is_zero_approx():
		push_warning("SpawnGodotCharacter: direction must not be zero")
		character.queue_free()
		_spawned_character = null
		return null
	var upDirection: Vector3 = Vector3.UP
	if absf(movementDirection.dot(upDirection)) > 0.999:
		upDirection = Vector3.FORWARD
	character.global_basis = Basis.looking_at(-movementDirection, upDirection)
	_spawned_characters.append(character)

	_playRunLoop(character)
	var spawn_duration: float = maxf(duration, prompt_delay + response_timeout + 0.1)
	_animateCharacter(character, movementDirection, spawn_duration)
	return character


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


func _animateCharacter(
		character: Node3D,
		movementDirection: Vector3,
		spawn_duration: float) -> void:
	var fadeMaterials: Array[BaseMaterial3D] = []
	var baseAlphas: Array[float] = []
	_collectFadeMaterials(character, fadeMaterials, baseAlphas)
	var initialAlpha: float = _sampleAlpha(0.0)
	_setAlpha(fadeMaterials, baseAlphas, initialAlpha)

	if spawn_duration <= 0.0:
		character.queue_free()
		return

	var destination: Vector3 = character.global_position + movementDirection * speed * spawn_duration
	var tween: Tween = character.create_tween()
	tween.set_parallel(true)
	tween.tween_property(character, "global_position", destination, spawn_duration)
	tween.tween_method(
		func(progress: float) -> void:
			_setAlpha(fadeMaterials, baseAlphas, _sampleAlpha(progress)),
		0.0,
		1.0,
		spawn_duration
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
