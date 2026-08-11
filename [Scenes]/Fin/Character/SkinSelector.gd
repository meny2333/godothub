extends CanvasLayer
class_name SkinSelector

const CLASSIC_SKIN: String = "classic"
const GODOT_SKIN_ID: String = "godot"
const GODOT_SKIN: String = "res://[Scenes]/Fin/Character/SkinGodot.tscn"
const CLASSIC_IMAGE: String = "res://[Scenes]/Fin/classical.png"
const GODOT_IMAGE: String = "res://[Scenes]/Fin/godot.png"
const CAMERA_TRANSITION_DURATION: float = 0.45
const COLLAPSED_PANEL_TOP: float = -180.0
const OPEN_PANEL_TOP: float = -430.0
const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"

@onready var panel: PanelContainer = $Panel
@onready var skin_button: Button = $Panel/Contents/CurrentRow/SkinButton
@onready var current_preview: TextureRect = $Panel/Contents/CurrentRow/CurrentPreview
@onready var current_name: Label = $Panel/Contents/CurrentRow/CurrentInfo/CurrentName
@onready var options: VBoxContainer = $Panel/Contents/Options
@onready var classic_button: Button = $Panel/Contents/Options/Cards/ClassicButton
@onready var godot_button: Button = $Panel/Contents/Options/Cards/GodotButton
@onready var classic_selected_bar: ColorRect = $Panel/Contents/Options/Cards/ClassicButton/CardContent/ClassicSelectedBar
@onready var godot_selected_bar: ColorRect = $Panel/Contents/Options/Cards/GodotButton/CardContent/GodotSelectedBar
@onready var input_blocker: Control = $InputBlocker
@onready var modal_dimmer: ColorRect = $ModalDimmer

var player: Player = null
var godot_skin: GodotCharacter = null
var gameplay_camera: Camera3D = null
var preview_camera: Camera3D = null
var camera_tween: Tween = null
var original_camera_position: Vector3 = Vector3.ZERO
var original_camera_rotation: Vector3 = Vector3.ZERO
var original_camera_saved: bool = false
var current_skin: String = GODOT_SKIN_ID
var locked: bool = false
var is_chinese: bool = true

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("BasicOBJ_Group/Player") as Player
	panel.offset_top = COLLAPSED_PANEL_TOP
	options.visible = false
	input_blocker.visible = false
	modal_dimmer.visible = false
	var settings: ConfigFile = ConfigFile.new()
	settings.load(SETTINGS_PATH)
	is_chinese = str(settings.get_value(UI_SECTION, "language", "zh")) != "en"
	_apply_language()
	classic_button.pressed.connect(_select_classic)
	godot_button.pressed.connect(_select_godot)
	input_blocker.gui_input.connect(_on_input_blocker_gui_input)
	gameplay_camera = get_tree().current_scene.get_node_or_null(
		"BasicOBJ_Group/CameraRoot/Rotator/Scale/Camera3D") as Camera3D
	preview_camera = get_tree().current_scene.get_node_or_null(
		"BasicOBJ_Group/Camera3D") as Camera3D
	_update_selection_visual()
	if player:
		player.on_player_start.connect(_lock_selection)
		_select_godot.call_deferred()

func _toggle_options() -> void:
	if locked:
		return
	if options.visible:
		_close_options()
	else:
		_open_options()

func consumes_turn_input(event: InputEvent) -> bool:
	if locked or not visible:
		return false
	if options.visible:
		return event is InputEventMouseButton or event is InputEventScreenTouch
	if event is InputEventMouseButton:
		return event.pressed and panel.get_global_rect().has_point(event.position)
	if event is InputEventScreenTouch:
		return event.pressed and panel.get_global_rect().has_point(event.position)
	return false

func _on_input_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_close_options()
	elif event is InputEventScreenTouch and event.pressed:
		_close_options()

func _open_options() -> void:
	_save_original_camera_pose()
	panel.offset_top = OPEN_PANEL_TOP
	options.visible = true
	input_blocker.visible = true
	modal_dimmer.visible = true
	_tween_camera_to(preview_camera)

func _close_options() -> void:
	options.visible = false
	panel.offset_top = COLLAPSED_PANEL_TOP
	input_blocker.visible = false
	modal_dimmer.visible = false
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
	player.reset_henshin_state()
	_remove_godot_skin()
	current_skin = CLASSIC_SKIN
	_update_selection_visual()
	if options.visible:
		_tween_camera_to(preview_camera)

func _select_godot() -> void:
	if not player or locked:
		return
	_remove_godot_skin()
	player.reset_henshin_state()
	var skin_scene: PackedScene = load(GODOT_SKIN) as PackedScene
	if not skin_scene:
		push_error("SkinSelector: unable to load " + GODOT_SKIN)
		return
	godot_skin = skin_scene.instantiate() as GodotCharacter
	if not godot_skin:
		push_error("SkinSelector: invalid Godot skin scene")
		return
	godot_skin.name = "SkinGodot"
	player.add_child(godot_skin)
	player.enable_henshin(godot_skin, Vector3.ZERO, false, false, 0.1)
	player.onturn.connect(godot_skin.play_turn)
	player.on_game_over.connect(godot_skin.play_die)
	current_skin = GODOT_SKIN_ID
	_update_selection_visual()
	if options.visible:
		_tween_camera_to(preview_camera)

func _remove_godot_skin() -> void:
	if is_instance_valid(godot_skin):
		godot_skin.queue_free()
	godot_skin = null
	if not player:
		return
	var existing: Node = player.get_node_or_null("SkinGodot")
	if existing:
		existing.queue_free()

func _update_selection_visual() -> void:
	var is_classic: bool = current_skin == CLASSIC_SKIN
	var preview_texture: Texture2D = load(CLASSIC_IMAGE if is_classic else GODOT_IMAGE) as Texture2D
	current_preview.texture = preview_texture
	current_name.text = ("经典" if is_chinese else "CLASSIC") if is_classic else "Godot"
	classic_selected_bar.visible = is_classic
	godot_selected_bar.visible = not is_classic

func _apply_language() -> void:
	$Panel/Contents/Header/TitleStack/Title.text = "皮肤" if is_chinese else "SKINS"
	$Panel/Contents/CurrentRow/CurrentInfo/CurrentCaption.text = "当前使用" if is_chinese else "CURRENT"
	skin_button.text = "更换" if is_chinese else "CHANGE"
	skin_button.tooltip_text = "打开皮肤选择" if is_chinese else "OPEN SKIN SELECTOR"
	$Panel/Contents/Options/OptionsHeader/Title.text = "选择角色外观" if is_chinese else "CHOOSE A SKIN"
	$Panel/Contents/Options/OptionsHeader/Hint.text = "游戏开始前" if is_chinese else "BEFORE START"
	$Panel/Contents/Options/Cards/ClassicButton/CardContent/Name.text = "经典" if is_chinese else "CLASSIC"
	$Panel/Contents/Options/Cards/ClassicButton/CardContent/Detail.text = "原始角色" if is_chinese else "ORIGINAL FORM"
	$Panel/Contents/Options/Cards/GodotButton/CardContent/Detail.text = "低多边形角色" if is_chinese else "LOW-POLY FORM"
	$Panel/Contents/Options/BottomHint.text = "点击面板外区域关闭" if is_chinese else "CLICK OUTSIDE TO CLOSE"
	classic_button.tooltip_text = "选择经典皮肤" if is_chinese else "SELECT CLASSIC SKIN"
	godot_button.tooltip_text = "选择 Godot 皮肤" if is_chinese else "SELECT GODOT SKIN"

func _lock_selection() -> void:
	locked = true
	options.visible = false
	input_blocker.visible = false
	modal_dimmer.visible = false
	hide()
