extends CanvasLayer
class_name SkinSelector

const CLASSIC_SKIN := "classic"
const GODOT_SKIN := "res://Character/SkinGodot.tscn"

@onready var skin_button: Button = $Panel/Contents/SkinButton
@onready var options: VBoxContainer = $Panel/Contents/Options
@onready var classic_button: Button = $Panel/Contents/Options/ClassicButton
@onready var godot_button: Button = $Panel/Contents/Options/GodotButton
@onready var input_blocker: Control = $InputBlocker

var player: Player
var godot_skin: GodotCharacter
var locked := false
var gameplay_camera: Camera3D
var preview_camera: Camera3D
var camera_tween: Tween
var original_camera_position := Vector3.ZERO
var original_camera_rotation := Vector3.ZERO
var original_camera_saved := false

const CAMERA_TRANSITION_DURATION := 0.45

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("BasicOBJ_Group/Player") as Player
	options.visible = false
	input_blocker.visible = false
	classic_button.pressed.connect(_select_classic)
	godot_button.pressed.connect(_select_godot)
	input_blocker.gui_input.connect(_on_input_blocker_gui_input)
	gameplay_camera = get_tree().current_scene.get_node_or_null(
		"BasicOBJ_Group/CameraRoot/Rotator/Scale/Camera3D") as Camera3D
	preview_camera = get_tree().current_scene.get_node_or_null(
		"BasicOBJ_Group/Camera3D") as Camera3D
	if player:
		player.on_player_start.connect(_lock_selection)
		_select_godot()

func _toggle_options() -> void:
	if locked:
		return
	if options.visible:
		_close_options()
	else:
		_open_options()
func _on_input_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_close_options()
	elif event is InputEventScreenTouch and event.pressed:
		_close_options()

func _open_options() -> void:
	_save_original_camera_pose()
	options.visible = true
	input_blocker.visible = true
	_tween_camera_to(preview_camera)

func _close_options() -> void:
	options.visible = false
	input_blocker.visible = false
	if original_camera_saved and gameplay_camera:
		_tween_camera_to_pose(original_camera_position, original_camera_rotation)

func _save_original_camera_pose() -> void:
	if original_camera_saved or not gameplay_camera:
		return
	original_camera_position = gameplay_camera.global_position
	original_camera_rotation = gameplay_camera.global_rotation
	original_camera_saved = true

func _tween_camera_to(target_camera: Camera3D) -> void:
	if target_camera:
		_tween_camera_to_pose(target_camera.global_position, target_camera.global_rotation)

func _tween_camera_to_pose(target_position: Vector3, target_rotation: Vector3) -> void:
	if not gameplay_camera:
		return
	if camera_tween:
		camera_tween.kill()
	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(gameplay_camera, "global_position", target_position,
			CAMERA_TRANSITION_DURATION)
	camera_tween.tween_property(gameplay_camera, "global_rotation", target_rotation,
			CAMERA_TRANSITION_DURATION)

func _select_classic() -> void:
	if not player or locked:
		return
	_remove_godot_skin()
	player.set_tail_enabled(true)
	player.set_death_particles_enabled(true)
	var classic_mesh := player.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if classic_mesh:
		classic_mesh.visible = true
	skin_button.text = "皮肤：经典"
	if options.visible:
		_tween_camera_to(preview_camera)

func _select_godot() -> void:
	if not player or locked:
		return
	_remove_godot_skin()
	player.set_tail_enabled(false)
	player.set_death_particles_enabled(false)
	var classic_mesh := player.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if classic_mesh:
		classic_mesh.visible = false
	var skin_scene := load(GODOT_SKIN) as PackedScene
	if not skin_scene:
		push_error("SkinSelector: unable to load " + GODOT_SKIN)
		return
	godot_skin = skin_scene.instantiate() as GodotCharacter
	godot_skin.name = "SkinGodot"
	player.add_child(godot_skin)
	player.onturn.connect(godot_skin.play_turn)
	player.on_game_over.connect(godot_skin.play_die)
	skin_button.text = "皮肤：Godot"
	if options.visible:
		_tween_camera_to(preview_camera)

func _remove_godot_skin() -> void:
	if is_instance_valid(godot_skin):
		godot_skin.queue_free()
	godot_skin = null
	var existing := player.get_node_or_null("SkinGodot")
	if existing:
		existing.queue_free()

func _lock_selection() -> void:
	locked = true
	options.visible = false
	input_blocker.visible = false
	hide()
