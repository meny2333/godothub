extends Node3D

const FIN_STAGE_ENTRY_META: StringName = &"fin_stage_entry"
const FULL_SYNC_SCRIPT: Script = preload("res://[Scenes]/Fin/FullLevelSync.gd")
const INHERITED_SYNC_META: StringName = &"fin_inherited_sync"
const INHERITED_SYNC_SOURCE_META: StringName = &"fin_inherited_sync_source"
const PART1_PATH: NodePath = NodePath("Scene_Group/part1")
const PART1_PYRAMID_PATH: NodePath = NodePath("Scene_Group/part1/Pyramid")
const PART2_PATH: NodePath = NodePath("Scene_Group/part2")
const PART2_PYRAMID_PATH: NodePath = NodePath("Scene_Group/part2/Pyramid")
const PART3_PATH: NodePath = NodePath("Scene_Group/part3")
const PART3_PYRAMID2_PATH: NodePath = NodePath("Scene_Group/part3/Pyramid2")
const PART3_MIRROR_FIN_PATH: NodePath = NodePath("Scene_Group/part3/p2mirrorl/fin")
const PART3_FINACTIVE_PATH: NodePath = NodePath("Scene_Group/part3/finactive")
const PART2_CHECKPOINT_PATH: NodePath = NodePath("collection/Crown2/Area3D/CrownCheckpoint")
const PART3_CHECKPOINT_PATH: NodePath = NodePath("collection/Crown/Area3D/CrownCheckpoint")
const MAIN_MENU_SCENE_PATH: String = "res://[Scenes]/MainMenu/MainMenu.tscn"
const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"
const LANGUAGE_KEY: String = "language"
const PROGRESS_SECTION: String = "progress"
const UNLOCKED_STAGE_COUNT_KEY: String = "unlocked_stage_count"
const FULL_MODE_UNLOCKED_KEY: String = "full_mode_unlocked"
const STAGE_COUNT: int = 4
const FULL_LEVEL_JUST_UNLOCKED_META: StringName = &"full_level_just_unlocked"
const STAGE_TITLES_ZH: Array[String] = ["初滞", "回声", "终章", "回声之境"]
const STAGE_TITLES_EN: Array[String] = ["FIRST DELAY", "THE ECHO", "GENTLE ARRIVAL", "ECHO REALM"]
const INTRO_BODIES_ZH: Array[String] = ["你是一台用于记录道路节拍的小机器人。\n核心记录已经遗失，只剩一条提示：跟随前方微光，别停下。", "灰蓝色的山谷里，一个慢三秒的残影正在重复你的动作。\n先观察它走过的路，再决定下一次转向。", "雾正在散去，前方的发光拱门像是出口。\n穿过它，看看微光把你带向哪里。", "拱门之后并非终点。破碎镜面映出所有未走的路；\n跟随残影，穿过回声之境。"]
const INTRO_BODIES_EN: Array[String] = ["YOU ARE A SMALL ROBOT BUILT TO RECORD THE ROAD'S BEAT.\nYOUR CORE RECORDS ARE GONE. ONE PROMPT REMAINS: FOLLOW THE FLICKERING LIGHT. DO NOT STOP.", "IN THE BLUE VALLEY, A THREE-SECOND ECHO REPEATS YOUR MOVES.\nWATCH THE PATH IT TAKES BEFORE YOUR NEXT TURN.", "THE FOG IS LIFTING. A LUMINOUS ARCH AHEAD LOOKS LIKE AN EXIT.\nPASS THROUGH IT AND SEE WHERE THE LIGHT LEADS.", "THE ARCH WAS NOT THE END. BROKEN MIRRORS SHOW EVERY ROAD YOU DID NOT TAKE.\nFOLLOW THE ECHO THROUGH THE ECHO REALM."]
const COMPLETION_TITLES_ZH: Array[String] = ["微光仍在前方", "残影走向破晓", "你以为已经抵达", "迟到的温柔，终于抵达。"]
const COMPLETION_TITLES_EN: Array[String] = ["THE LIGHT CONTINUES", "THE ECHO WALKS TOWARD DAWN", "YOU THOUGHT YOU HAD ARRIVED", "THE LATE TENDERNESS HAS ARRIVED."]
const COMPLETION_BODIES_ZH: Array[String] = ["峡谷尽头的山谷，已经向你打开。", "它们已与你并肩。前方的拱门正在发亮。", "真正的终点仍在更远处。回声之境已解锁。", "你与所有回声，终于同步。"]
const COMPLETION_BODIES_EN: Array[String] = ["THE VALLEY AT THE END OF THE CANYON IS OPEN.", "THE ECHO WALKS BESIDE YOU. THE ARCH AHEAD IS GLOWING.", "THE TRUE END LIES FARTHER ON. THE ECHO REALM IS UNLOCKED.", "YOU AND EVERY ECHO ARE IN SYNC AT LAST."]

var _stage_index: int = 0
var _completion_processed: bool = false

func _ready() -> void:
	call_deferred("_apply_menu_stage_entry")

func _apply_menu_stage_entry() -> void:
	var scene_tree: SceneTree = get_tree()
	if scene_tree.root.has_meta(FIN_STAGE_ENTRY_META):
		_stage_index = clampi(int(scene_tree.root.get_meta(FIN_STAGE_ENTRY_META)), 0, STAGE_COUNT - 1)
		scene_tree.root.remove_meta(FIN_STAGE_ENTRY_META)
	# Preserve the resolved stage during this scene's lifetime so replay can
	# recreate the same entry point after reload.
	get_tree().current_scene.set_meta(FIN_STAGE_ENTRY_META, _stage_index)
	match _stage_index:
		0:
			_remove_part(PART2_PATH)
			_remove_part(PART3_PATH)
		1:
			_remove_part(PART1_PATH)
			_restore_checkpoint(PART2_CHECKPOINT_PATH)
		2:
			_remove_part(PART1_PATH)
			_remove_part(PART2_PYRAMID_PATH)
			_remove_part(PART3_PYRAMID2_PATH)
			_remove_part(PART3_MIRROR_FIN_PATH)
			_remove_part(PART3_FINACTIVE_PATH)
			_restore_checkpoint(PART3_CHECKPOINT_PATH)
		3:
			_remove_part(PART1_PYRAMID_PATH)
			_remove_part(PART2_PYRAMID_PATH)
	if _stage_index > 0 and _stage_index < STAGE_COUNT - 1:
		_add_part_sync()
	_configure_tutorial()
	_connect_completion_listener()
	_set_level_ui_title(_stage_index)
	await _show_part_intro(_stage_index)

func _configure_tutorial() -> void:
	var tutorial_manager: TutorialManager = get_node_or_null("BasicOBJ_Group/TutorialManager") as TutorialManager
	if tutorial_manager:
		tutorial_manager.set_tutorial_enabled(_stage_index == 0)

func _add_part_sync() -> void:
	if get_node_or_null("FullLevelSync"):
		return
	var sync_controller: Node = FULL_SYNC_SCRIPT.new() as Node
	if sync_controller == null:
		push_error("EchoRealmStageEntry: failed to create part sync controller")
		return
	sync_controller.name = "FullLevelSync"
	add_child(sync_controller)

func _connect_completion_listener() -> void:
	var player: Player = Player.instance
	if not player:
		push_error("EchoRealmStageEntry: Player was unavailable for completion tracking")
		return
	if not player.on_game_end.is_connected(_on_player_game_end):
		player.on_game_end.connect(_on_player_game_end)

func _on_player_game_end() -> void:
	if _completion_processed or LevelManager.GameState != LevelManager.GameStatus.Completed:
		return
	_completion_processed = true
	var full_level_just_unlocked: bool = _save_completion_progress()
	call_deferred("_return_to_main_menu", full_level_just_unlocked)

func _save_completion_progress() -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var full_mode_was_unlocked: bool = bool(config.get_value(PROGRESS_SECTION, FULL_MODE_UNLOCKED_KEY, false))
	var current_unlocked_count: int = int(config.get_value(
		PROGRESS_SECTION,
		UNLOCKED_STAGE_COUNT_KEY,
		1
	))
	var unlocked_count: int = clampi(maxi(current_unlocked_count, _stage_index + 2), 1, STAGE_COUNT)
	var full_mode_just_unlocked: bool = _stage_index == STAGE_COUNT - 1 and not full_mode_was_unlocked
	config.set_value(PROGRESS_SECTION, UNLOCKED_STAGE_COUNT_KEY, unlocked_count)
	config.set_value(PROGRESS_SECTION, FULL_MODE_UNLOCKED_KEY, full_mode_was_unlocked or full_mode_just_unlocked)
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("EchoRealmStageEntry: failed to save progress (%s)" % error_string(error))
		return false
	return full_mode_just_unlocked

func _return_to_main_menu(full_level_just_unlocked: bool) -> void:
	await _show_completion_caption()
	_store_sync_for_next_part()
	if full_level_just_unlocked:
		get_tree().root.set_meta(FULL_LEVEL_JUST_UNLOCKED_META, true)
	LevelManager.reset_to_defaults()
	var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		push_error("EchoRealmStageEntry: failed to return to main menu (%s)" % error_string(error))

func _store_sync_for_next_part() -> void:
	if _stage_index >= STAGE_COUNT - 1:
		return
	var sync_controller: Node = get_node_or_null("FullLevelSync")
	if sync_controller == null or not sync_controller.has_method("get_inherited_sync"):
		return
	get_tree().root.set_meta(INHERITED_SYNC_META, float(sync_controller.call("get_inherited_sync")))
	get_tree().root.set_meta(INHERITED_SYNC_SOURCE_META, _stage_index)

func _show_completion_caption() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	var titles: Array[String] = COMPLETION_TITLES_ZH if is_chinese else COMPLETION_TITLES_EN
	var bodies: Array[String] = COMPLETION_BODIES_ZH if is_chinese else COMPLETION_BODIES_EN
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	var blackout: ColorRect = ColorRect.new()
	blackout.color = Color.BLACK
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.mouse_filter = Control.MOUSE_FILTER_STOP
	blackout.modulate.a = 0.0
	layer.add_child(blackout)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var copy: VBoxContainer = VBoxContainer.new()
	copy.add_theme_constant_override("separation", 14)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.modulate.a = 0.0
	center.add_child(copy)
	var title_label: Label = Label.new()
	title_label.text = titles[_stage_index]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.86, 1.0))
	copy.add_child(title_label)
	var body_label: Label = Label.new()
	body_label.text = bodies[_stage_index]
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 17)
	body_label.add_theme_color_override("font_color", Color(0.7, 0.76, 0.8, 1.0))
	copy.add_child(body_label)
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(blackout, "modulate:a", 1.0, 0.5)
	tween.tween_property(copy, "modulate:a", 1.0, 0.38).set_delay(0.18)
	tween.tween_interval(2.4)
	tween.tween_property(copy, "modulate:a", 0.0, 0.4)
	await tween.finished

func _set_level_ui_title(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= STAGE_TITLES_ZH.size():
		return
	var level_ui: Control = get_node_or_null("BasicOBJ_Group/gameui") as Control
	if not level_ui or not level_ui.has_method("set_level_name"):
		return
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	var titles: Array[String] = STAGE_TITLES_ZH if is_chinese else STAGE_TITLES_EN
	level_ui.call("set_level_name", titles[stage_index])

func _show_part_intro(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= STAGE_TITLES_ZH.size():
		return
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	var titles: Array[String] = STAGE_TITLES_ZH if is_chinese else STAGE_TITLES_EN
	var bodies: Array[String] = INTRO_BODIES_ZH if is_chinese else INTRO_BODIES_EN
	var tutorial_manager: TutorialManager = get_node_or_null("BasicOBJ_Group/TutorialManager") as TutorialManager
	if not tutorial_manager:
		push_error("EchoRealmStageEntry: TutorialManager was unavailable for the opening intertitle")
		return
	await tutorial_manager.show_opening_intertitle(titles[stage_index], bodies[stage_index])

func _remove_part(part_path: NodePath) -> void:
	var part: Node = get_node_or_null(part_path)
	if not part:
		return
	var parent: Node = part.get_parent()
	if parent:
		parent.remove_child(part)
	part.queue_free()

func _restore_checkpoint(checkpoint_path: NodePath) -> void:
	var checkpoint: Checkpoint = get_node_or_null(checkpoint_path) as Checkpoint
	var player: Player = Player.instance
	if not checkpoint or not player:
		push_error("EchoRealmStageEntry: checkpoint or player was unavailable for stage entry")
		return
	checkpoint._enter_trigger(player)
	checkpoint.revive()
