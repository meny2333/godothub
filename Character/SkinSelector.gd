extends CanvasLayer
class_name SkinSelector

const CLASSIC_SKIN := "classic"
const GODOT_SKIN := "res://Character/SkinGodot.tscn"

@onready var skin_button: Button = $Panel/Contents/SkinButton
@onready var options: VBoxContainer = $Panel/Contents/Options
@onready var classic_button: Button = $Panel/Contents/Options/ClassicButton
@onready var godot_button: Button = $Panel/Contents/Options/GodotButton

var player: Player
var godot_skin: GodotCharacter
var locked := false

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("BasicOBJ_Group/Player") as Player
	options.visible = false
	classic_button.pressed.connect(_select_classic)
	godot_button.pressed.connect(_select_godot)
	if player:
		player.on_player_start.connect(_lock_selection)
		_select_godot()

func _toggle_options() -> void:
	if not locked:
		options.visible = not options.visible

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
	options.visible = false

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
	options.visible = false

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
	hide()
