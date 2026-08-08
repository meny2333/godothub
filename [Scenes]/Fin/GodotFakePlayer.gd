@tool
class_name GodotFakePlayer
extends FakePlayer

## FakePlayer movement with the Fin Godot character visual and animation behavior.

@export var godotCharacter: GodotCharacter

var _last_visual_state: FakePlayer.State = FakePlayer.State.Stopped
var _was_dead: bool = false


func _ready() -> void:
	_body = _resolve_body()
	if not _body:
		push_error("GodotFakePlayer must be attached below a CharacterBody3D")
		return
	if Engine.is_editor_hint():
		return

	startPosition = _body.global_position
	var collision: CollisionShape3D = _body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not collision:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		collision.shape = BoxShape3D.new()
		collision.shape.size = Vector3(0.3, 0.3, 0.3)
		_body.add_child(collision)

	add_to_group("fake_players")
	var current_scene: Node = get_tree().current_scene
	if createTurnTrigger:
		_trigger_holder = Node3D.new()
		_trigger_holder.name = "FakePlayerTriggerHolder"
		if current_scene:
			current_scene.add_child.call_deferred(_trigger_holder)

	_set_world_position(startPosition)
	_set_world_rotation(firstDirection)
	state = FakePlayer.State.Stopped
	_setup_collision_layers()

	if godotCharacter == null and _body:
		godotCharacter = _body.get_node_or_null("GodotCharacter") as GodotCharacter
	if godotCharacter == null:
		push_error("GodotFakePlayer requires a GodotCharacter below its CharacterBody3D host")
		return
	call_deferred("_sync_animation_state", true)


func _process(delta: float) -> void:
	super._process(delta)
	if Engine.is_editor_hint():
		return
	_sync_animation_state()


func turn() -> void:
	super.turn()
	if is_instance_valid(godotCharacter):
		godotCharacter.play_turn()


func _create_tail() -> void:
	pass


func set_reset_data(data: Dictionary) -> void:
	super.set_reset_data(data)
	_sync_animation_state(true)


func _sync_animation_state(force: bool = false) -> void:
	if not is_instance_valid(godotCharacter):
		return

	var is_dead: bool = LevelManager.GameState == LevelManager.GameStatus.Died
	if is_dead:
		if force or not _was_dead:
			godotCharacter.play_die()
		_was_dead = true
		_last_visual_state = state
		return

	if force or _was_dead or state != _last_visual_state:
		godotCharacter.set_moving(state == FakePlayer.State.Moving)
	_was_dead = false
	_last_visual_state = state
