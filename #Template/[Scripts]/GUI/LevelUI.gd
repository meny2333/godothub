extends Control

const MAIN_MENU_SCENE_PATH: String = "res://[Scenes]/MainMenu/MainMenu.tscn"
const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"
const LANGUAGE_KEY: String = "language"
const FIN_STAGE_ENTRY_META: StringName = &"fin_stage_entry"

var levelname: String = "level name"
var _shown: bool = false
var _replay_requested: bool = false

@onready var normal_page: Control = $NormalPage
@onready var revive_page: Control = $RevivePage
@onready var backdrop: ColorRect = $ColorRect
@onready var title_label: Label = $NormalPage/title
@onready var normal_percentage: Label = $NormalPage/percentage
@onready var normal_fill: TextureRect = $NormalPage/ProgressFrame/Fill
@onready var collectible_label: Label = $NormalPage/Collectible/diamond
@onready var death_hint: Label = $death_hint
@onready var revive_percentage: Label = $RevivePage/percentage
@onready var revive_fill: TextureRect = $RevivePage/ProgressFrame/Fill
@onready var revive_prompt: Label = $RevivePage/AskingText
@onready var back_button: Button = $back

func _ready() -> void:
	_apply_language()
	if Player.instance and Player.instance.levelData:
		levelname = Player.instance.levelData.get_localized_title()
	else:
		push_error("LevelUI.gd: Player.instance 或 levelData 为空，无法读取关卡标题")
	visible = false
	if Player.instance:
		Player.instance.on_game_end.connect(_show_ui)

func _apply_language() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	revive_prompt.text = "要回到那个错误发生之前吗？\n你会失去这段路上拾起的一切" if is_chinese else "RETURN TO BEFORE THE MISTAKE?\nEVERYTHING GATHERED ON THIS PATH WILL BE LOST."
	back_button.tooltip_text = "返回主菜单" if is_chinese else "RETURN TO MAIN MENU"

func _show_ui() -> void:
	if _shown:
		return
	_shown = true

	var progress: float = clampf(float(LevelManager.percent) / 100.0, 0.0, 1.0)
	var percentage_text: String = "%d%%" % LevelManager.percent
	title_label.text = levelname
	normal_percentage.text = percentage_text
	revive_percentage.text = percentage_text
	collectible_label.text = "%d/10" % LevelManager.gem
	_set_progress(normal_fill, progress)
	_set_progress(revive_fill, progress)

	var can_revive: bool = Player.instance != null and not Player.instance.is_end \
		and is_instance_valid(LevelManager.current_checkpoint)
	normal_page.visible = not can_revive
	revive_page.visible = can_revive
	backdrop.color.a = 0.0 if can_revive else 0.639216
	visible = true

func set_level_name(value: String) -> void:
	if value.is_empty():
		return
	levelname = value
	title_label.text = levelname

## 完整关卡死亡/复活结算页显示"已跌倒 N/8"（由 FinStageEntry 在死亡时写入，两个结算页共用）。空文本隐藏。
func set_death_hint(value: String) -> void:
	death_hint.visible = not value.is_empty()
	death_hint.text = value

func _set_progress(fill: TextureRect, progress: float) -> void:
	fill.anchor_right = progress
	fill.offset_right = -6.0 if progress >= 0.02 else 6.0

func _on_back_pressed() -> void:
	if _replay_requested:
		return
	_replay_requested = true
	LevelManager.reset_to_defaults()
	var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		_replay_requested = false
		push_error("LevelUI.gd: 无法返回主菜单 (%s)" % error_string(error))

func _on_cancel_revive_pressed() -> void:
	revive_page.visible = false
	normal_page.visible = true
	backdrop.color.a = 0.639216

func _on_revive_pressed() -> void:
	_shown = false
	visible = false
	LevelManager.is_end = false
	if not Player.instance:
		push_error("LevelUI.gd: Player.instance 为空，无法复活")
		_on_gamereplay_pressed()
		return
	if Player.instance.is_end:
		_on_gamereplay_pressed()
	elif is_instance_valid(LevelManager.current_checkpoint):
		LevelManager.current_checkpoint.revive()
	else:
		_on_gamereplay_pressed()

func _on_gamereplay_pressed() -> void:
	if _replay_requested:
		return
	_replay_requested = true
	_preserve_scene_entry_metadata()
	LevelManager.reset_to_defaults()

	# Wait for a previous scene switch to settle before reading current_scene.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var current_scene: Node = get_tree().current_scene
	if not is_instance_valid(current_scene):
		_replay_requested = false
		push_error("LevelUI.gd: 当前场景为空，无法重新加载关卡")
		return

	var loading_scene: PackedScene = load("res://#Template/[Resources]/LoadingPage.tscn") as PackedScene
	if loading_scene:
		var loading_page: LoadingPage = loading_scene.instantiate() as LoadingPage
		if loading_page:
			current_scene.add_child(loading_page)
			var reveal_tween: Tween = loading_page.reveal(_get_loading_background_color())
			await reveal_tween.finished
	if not is_inside_tree():
		return
	var player: Player = Player.instance
	if is_instance_valid(player):
		player.reload()
	else:
		_replay_requested = false
		push_error("LevelUI.gd: Player.instance 为空，无法重新加载关卡")

func _preserve_scene_entry_metadata() -> void:
	var current_scene: Node = get_tree().current_scene
	if not is_instance_valid(current_scene) or not current_scene.has_meta(FIN_STAGE_ENTRY_META):
		return
	get_tree().root.set_meta(FIN_STAGE_ENTRY_META, int(current_scene.get_meta(FIN_STAGE_ENTRY_META)))

func _get_loading_background_color() -> Color:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera and camera.environment:
		return camera.environment.background_color
	return RenderingServer.get_default_clear_color()
