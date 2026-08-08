@tool
extends Node3D
class_name GodotCharacter

const IDLE_ANIMATION := "idle"
const RUN_ANIMATION := "run"
const TURN_ANIMATION := "turn"
const DIE_ANIMATION := "die"
const RUN_SPEED := 2.0
const TURN_SPEED := 1.8
const SMOOTH_TURN_SPEED := 10.0
const GLITCH_HEIGHT_OFFSET: float = 1.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var glitch_plane: MeshInstance3D = $GlitchPlane
@onready var glitch_delay_timer: Timer = $GlitchDelayTimer
@onready var glitch_hide_timer: Timer = $GlitchHideTimer
var is_dead := false
var _follow_player := false
var _target_yaw := 0.0
var _glitch_death_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	var parent_player := get_parent() as CharacterBody3D
	if parent_player:
		_follow_player = true
		top_level = true
		global_position = parent_player.global_position
		_target_yaw = parent_player.global_rotation.y
		rotation.y = _target_yaw
		if parent_player.has_signal("on_player_start"):
			parent_player.on_player_start.connect(_on_player_start)
	_setup_animation_library()
	_setup_blend_times()
	animation_player.animation_finished.connect(_on_animation_finished)
	glitch_delay_timer.ignore_time_scale = true
	glitch_hide_timer.ignore_time_scale = true
	glitch_delay_timer.timeout.connect(_show_glitch_plane)
	glitch_hide_timer.timeout.connect(_hide_glitch_plane)
	glitch_plane.visible = false
	if not Engine.is_editor_hint():
		LevelManager.add_revive_listener(revive)
	play_idle()

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		LevelManager.remove_revive_listener(revive)

func _on_player_start() -> void:
	play_run()

func _process(delta: float) -> void:
	if not _follow_player:
		return
	var parent_player := get_parent() as CharacterBody3D
	if not parent_player:
		return
	global_position = parent_player.global_position
	_target_yaw = parent_player.global_rotation.y
	rotation.y = lerp_angle(rotation.y, _target_yaw, min(delta * SMOOTH_TURN_SPEED, 1.0))

func _setup_animation_library() -> void:
	var library := AnimationLibrary.new()
	_add_animation(library, IDLE_ANIMATION, "res://[Scenes]/Fin/Character/anim/idle.anim")
	_add_animation(library, RUN_ANIMATION, "res://[Scenes]/Fin/Character/anim/run.anim")
	_add_animation(library, TURN_ANIMATION, "res://[Scenes]/Fin/Character/anim/huachan.anim")
	_add_animation(library, DIE_ANIMATION, "res://[Scenes]/Fin/Character/anim/hit.anim")
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")
	animation_player.add_animation_library("", library)

func _add_animation(library: AnimationLibrary, animation_name: String, resource_path: String) -> void:
	var animation := load(resource_path) as Animation
	if animation == null:
		push_error("GodotCharacter: unable to load animation: " + resource_path)
		return
	_normalize_head_rotation(animation)
	animation.resource_name = animation_name
	library.add_animation(animation_name, animation)

func _normalize_head_rotation(animation: Animation) -> void:
	for track_index in range(animation.get_track_count()):
		var track_path := str(animation.track_get_path(track_index)).to_lower()
		if not track_path.contains(":head"):
			continue
		if animation.track_get_type(track_index) != 2:
			continue
		for key_index in range(animation.track_get_key_count(track_index)):
			var value = animation.track_get_key_value(track_index, key_index)
			if value is Quaternion:
				var euler: Vector3 = (value as Quaternion).get_euler()
				euler.z -= deg_to_rad(0)
				animation.track_set_key_value(track_index, key_index, Quaternion.from_euler(euler))

func _setup_blend_times() -> void:
	animation_player.set_blend_time(IDLE_ANIMATION, RUN_ANIMATION, 0.16)
	animation_player.set_blend_time(RUN_ANIMATION, IDLE_ANIMATION, 0.16)
	animation_player.set_blend_time(RUN_ANIMATION, TURN_ANIMATION, 0.16)
	animation_player.set_blend_time(TURN_ANIMATION, RUN_ANIMATION, 0.16)
	animation_player.set_blend_time(RUN_ANIMATION, DIE_ANIMATION, 0.12)
	animation_player.set_blend_time(TURN_ANIMATION, DIE_ANIMATION, 0.12)
	animation_player.set_blend_time(DIE_ANIMATION, RUN_ANIMATION, 0.2)
	animation_player.set_blend_time(DIE_ANIMATION, IDLE_ANIMATION, 0.2)

func play_idle() -> void:
	if not is_dead and animation_player.has_animation(IDLE_ANIMATION):
		animation_player.play(IDLE_ANIMATION)

func play_run() -> void:
	is_dead = false
	if animation_player.has_animation(RUN_ANIMATION):
		animation_player.play(RUN_ANIMATION, -1.0, RUN_SPEED)

func play_turn() -> void:
	if not is_dead and animation_player.has_animation(TURN_ANIMATION):
		animation_player.play(TURN_ANIMATION, -1.0, TURN_SPEED)

func play_die() -> void:
	is_dead = true
	_schedule_glitch_plane()
	if animation_player.has_animation(DIE_ANIMATION):
		animation_player.play(DIE_ANIMATION)

func _schedule_glitch_plane() -> void:
	glitch_delay_timer.stop()
	glitch_hide_timer.stop()
	glitch_plane.visible = false
	_set_character_visible(true)
	_glitch_death_position = global_position
	glitch_delay_timer.start()

func _show_glitch_plane() -> void:
	if not is_dead:
		return
	_set_character_visible(false)
	glitch_plane.global_position = _glitch_death_position + Vector3.UP * GLITCH_HEIGHT_OFFSET
	var glitch_material: ShaderMaterial = glitch_plane.material_override as ShaderMaterial
	if glitch_material:
		glitch_material.set_shader_parameter("seed", randf() * 1000.0)
	glitch_plane.visible = true
	glitch_hide_timer.start()

func _hide_glitch_plane() -> void:
	glitch_plane.visible = false
	_set_character_visible(true)

func _set_character_visible(value: bool) -> void:
	var character_node: Node3D = get_node_or_null("Character") as Node3D
	if character_node:
		character_node.visible = value

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == TURN_ANIMATION and not is_dead:
		play_run()

func set_moving(moving: bool) -> void:
	if is_dead:
		return
	if moving:
		play_run()
	else:
		play_idle()

func revive() -> void:
	glitch_delay_timer.stop()
	glitch_hide_timer.stop()
	_hide_glitch_plane()
	is_dead = false
	play_idle()

func switch_skin(scene_path: String) -> void:
	var skin_scene := load(scene_path) as PackedScene
	if skin_scene == null:
		push_error("GodotCharacter: unable to load skin: " + scene_path)
		return
	var old_character := get_node_or_null("Character")
	var new_character := skin_scene.instantiate()
	new_character.name = "Character"
	if old_character:
		remove_child(old_character)
		old_character.queue_free()
	add_child(new_character)
	move_child(new_character, 0)
	animation_player.root_node = NodePath("../Character")
	if is_dead:
		play_die()
	else:
		play_run()
