@tool
class_name GodotFakePlayer
extends FakePlayer

## FakePlayer movement with the Fin Godot character visual and animation behavior.

@export var godotCharacter: GodotCharacter
@export_range(0.0, 1.0, 0.01) var characterOpacity: float = 0.5
@export var click_sync_bonus: bool = false
@export var click_sync_amount: float = 1.0

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
	if synchronismWithPlayer:
		# Follow Player.onturn so synchronized FakePlayers also work with autoplay.
		call_deferred("_connect_player_turn")

	if godotCharacter == null and _body:
		godotCharacter = _body.get_node_or_null("GodotCharacter") as GodotCharacter
	if godotCharacter == null:
		push_error("GodotFakePlayer requires a GodotCharacter below its CharacterBody3D host")
		return
	_make_character_transparent_unshaded(godotCharacter)
	call_deferred("_sync_animation_state", true)
	_setup_click_area()


## 调试用：点击残影热区给同步率 +1%（默认关闭，仅在手动测最高同步率时开启）。
func _setup_click_area() -> void:
	if not click_sync_bonus:
		return
	var area: Area3D = _body.get_node_or_null("ClickArea") as Area3D
	if not area:
		push_error("GodotFakePlayer: ClickArea not found under body")
		return
	area.input_event.connect(_on_click_area_input_event)
	area.monitoring = false
	area.monitorable = false


func _on_click_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not click_sync_bonus:
		return
	var is_click: bool = false
	if event is InputEventMouseButton:
		is_click = event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		is_click = event.pressed
	if not is_click:
		return
	var sync_node: Node = get_tree().current_scene.get_node_or_null("FullLevelSync")
	if sync_node and sync_node.has_method("restore_sync"):
		sync_node.call("restore_sync", click_sync_amount)


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


func _connect_player_turn() -> void:
	if not synchronismWithPlayer:
		return
	var player: Player = Player.instance
	if not player:
		if is_inside_tree():
			call_deferred("_connect_player_turn")
		return
	if player and not player.onturn.is_connected(_on_player_turn):
		player.onturn.connect(_on_player_turn)


func _on_player_turn() -> void:
	if state == FakePlayer.State.Moving:
		_create_turn_trigger()


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

	if state == FakePlayer.State.Stopped:
		_ensure_idle_animation()
	elif force or _was_dead or state != _last_visual_state:
		godotCharacter.set_moving(true)
	_was_dead = false
	_last_visual_state = state


func _ensure_idle_animation() -> void:
	var animation_player: AnimationPlayer = godotCharacter.animation_player
	if animation_player == null or animation_player.current_animation != GodotCharacter.IDLE_ANIMATION:
		godotCharacter.play_idle()


func _make_character_transparent_unshaded(character: Node) -> void:
	if character is MeshInstance3D:
		_prepare_mesh_materials(character as MeshInstance3D)
	for child: Node in character.get_children():
		_make_character_transparent_unshaded(child)


func _prepare_mesh_materials(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	for surface_index: int in range(mesh_instance.mesh.get_surface_count()):
		var source_material: Material = mesh_instance.get_active_material(surface_index)
		if source_material is BaseMaterial3D:
			var material: BaseMaterial3D = source_material.duplicate() as BaseMaterial3D
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var color: Color = material.albedo_color
			color.a = characterOpacity
			material.albedo_color = color
			mesh_instance.set_surface_override_material(surface_index, material)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var player: Player = Player.instance
	if player and player.onturn.is_connected(_on_player_turn):
		player.onturn.disconnect(_on_player_turn)
	super._exit_tree()
