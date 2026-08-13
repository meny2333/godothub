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
const ECHO_REALM_SCENE_PATH: String = "res://[Scenes]/EchoRealm/EchoRealm.tscn"
const ECHO_REALM_STAGE_INDEX: int = 3
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
const CREDITS_THEME_ZH: String = "有些答案，总在错过之后才抵达。"
const CREDITS_THEME_EN: String = "SOME ANSWERS ONLY ARRIVE AFTER YOU MISS THEM."
const CREDITS_POEM_ZH: String = "此情可待成追忆，只是当时已惘然。"
const CREDITS_POEM_EN: String = "THE MOMENT, ONCE GONE, RETURNS ONLY IN MEMORY.\nTHEN, I DID NOT UNDERSTAND IT AT ALL."
const CREDITS_POEM_SOURCE_ZH: String = "—— 李商隐《锦瑟》"
const CREDITS_POEM_SOURCE_EN: String = "— LI SHANGYIN, \"THE ORNATE ZITHER\""
const CREDITS_THANKS_ZH: String = "感谢游玩\n—— meny233"
const CREDITS_THANKS_EN: String = "THANKS FOR PLAYING\n— meny233"
const CREDITS_SOURCES_TITLE_ZH: String = "灵感来源"
const CREDITS_SOURCES_TITLE_EN: String = "INSPIRED BY"
const CREDITS_SOURCES_ZH: String = "Dancing Line · Through the Fog · DLMTP"
const CREDITS_SOURCES_EN: String = "DANCING LINE · THROUGH THE FOG · DLMTP"
const CREDITS_THE_END_ZH: String = "终"
const CREDITS_THE_END_EN: String = "THE END"
const CREDITS_RETURN_ZH: String = "返回主菜单"
const CREDITS_RETURN_EN: String = "RETURN TO MAIN MENU"

var _stage_index: int = 0
var _completion_processed: bool = false
var _returning_to_menu: bool = false

func _ready() -> void:
	call_deferred("_apply_menu_stage_entry")

func _apply_menu_stage_entry() -> void:
	var scene_tree: SceneTree = get_tree()
	var current_scene: Node = scene_tree.current_scene
	if scene_tree.root.has_meta(FIN_STAGE_ENTRY_META):
		_stage_index = clampi(int(scene_tree.root.get_meta(FIN_STAGE_ENTRY_META)), 0, STAGE_COUNT - 1)
		scene_tree.root.remove_meta(FIN_STAGE_ENTRY_META)
	elif current_scene != null and current_scene.scene_file_path == ECHO_REALM_SCENE_PATH:
		# Directly running EchoRealm has no menu metadata; use its full-content entry.
		_stage_index = ECHO_REALM_STAGE_INDEX
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
	var full_mode_just_unlocked: bool = _stage_index == STAGE_COUNT - 2 and not full_mode_was_unlocked
	config.set_value(PROGRESS_SECTION, UNLOCKED_STAGE_COUNT_KEY, unlocked_count)
	config.set_value(PROGRESS_SECTION, FULL_MODE_UNLOCKED_KEY, full_mode_was_unlocked or full_mode_just_unlocked)
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("EchoRealmStageEntry: failed to save progress (%s)" % error_string(error))
		return false
	return full_mode_just_unlocked

func _return_to_main_menu(full_level_just_unlocked: bool) -> void:
	await _show_completion_caption()
	if _stage_index == STAGE_COUNT - 1:
		await _show_credits_roll()
		return
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
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(blackout, "modulate:a", 1.0, 0.5)
	tween.tween_property(copy, "modulate:a", 1.0, 0.38).set_delay(0.18)
	tween.tween_interval(2.4)
	tween.tween_property(copy, "modulate:a", 0.0, 0.4)
	await tween.finished

func _show_credits_roll() -> void:
	var was_tree_paused: bool = get_tree().paused
	get_tree().paused = false
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	var theme: String = CREDITS_THEME_ZH if is_chinese else CREDITS_THEME_EN
	var poem: String = CREDITS_POEM_ZH if is_chinese else CREDITS_POEM_EN
	var poem_source: String = CREDITS_POEM_SOURCE_ZH if is_chinese else CREDITS_POEM_SOURCE_EN
	var thanks: String = CREDITS_THANKS_ZH if is_chinese else CREDITS_THANKS_EN
	var sources_title: String = CREDITS_SOURCES_TITLE_ZH if is_chinese else CREDITS_SOURCES_TITLE_EN
	var sources: String = CREDITS_SOURCES_ZH if is_chinese else CREDITS_SOURCES_EN
	var the_end: String = CREDITS_THE_END_ZH if is_chinese else CREDITS_THE_END_EN
	var return_text: String = CREDITS_RETURN_ZH if is_chinese else CREDITS_RETURN_EN

	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	var blackout: ColorRect = ColorRect.new()
	blackout.color = Color.BLACK
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.mouse_filter = Control.MOUSE_FILTER_STOP
	blackout.modulate.a = 0.0
	layer.add_child(blackout)
	var tween_in: Tween = create_tween()
	tween_in.set_ignore_time_scale(true)
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(blackout, "modulate:a", 1.0, 0.6)
	await tween_in.finished

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var roll: VBoxContainer = VBoxContainer.new()
	roll.add_theme_constant_override("separation", 40)
	roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll.position = Vector2(0.0, viewport_size.y + 80.0)
	roll.size = Vector2(viewport_size.x, 0.0)
	layer.add_child(roll)

	var theme_label: Label = Label.new()
	theme_label.text = theme
	theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_label.add_theme_font_size_override("font_size", 24)
	theme_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.86, 1.0))
	roll.add_child(theme_label)
	var poem_label: Label = Label.new()
	poem_label.text = poem
	poem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poem_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	poem_label.add_theme_font_size_override("font_size", 20)
	poem_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.93, 1.0))
	roll.add_child(poem_label)
	var poem_source_label: Label = Label.new()
	poem_source_label.text = poem_source
	poem_source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poem_source_label.add_theme_font_size_override("font_size", 14)
	poem_source_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.66, 1.0))
	roll.add_child(poem_source_label)
	var thanks_label: Label = Label.new()
	thanks_label.text = thanks
	thanks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks_label.add_theme_font_size_override("font_size", 19)
	thanks_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 1.0))
	roll.add_child(thanks_label)
	var sources_title_label: Label = Label.new()
	sources_title_label.text = sources_title
	sources_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sources_title_label.add_theme_font_size_override("font_size", 16)
	sources_title_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.74, 1.0))
	roll.add_child(sources_title_label)
	var sources_label: Label = Label.new()
	sources_label.text = sources
	sources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sources_label.add_theme_font_size_override("font_size", 18)
	sources_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.93, 1.0))
	roll.add_child(sources_label)

	var roll_speed: float = 60.0
	var end_reveal: Control = Control.new()
	end_reveal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_reveal.modulate.a = 0.0
	layer.add_child(end_reveal)
	var end_center: CenterContainer = CenterContainer.new()
	end_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_reveal.add_child(end_center)
	var end_box: VBoxContainer = VBoxContainer.new()
	end_box.add_theme_constant_override("separation", 28)
	end_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_center.add_child(end_box)
	var end_title: Label = Label.new()
	end_title.text = the_end
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 42)
	end_title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.86, 1.0))
	end_box.add_child(end_title)
	var return_button: Button = Button.new()
	return_button.text = return_text
	return_button.custom_minimum_size = Vector2(220.0, 46.0)
	return_button.add_theme_font_size_override("font_size", 17)
	return_button.mouse_filter = Control.MOUSE_FILTER_STOP
	return_button.pressed.connect(_return_to_main_menu_pressed)
	return_button.focus_mode = Control.FOCUS_NONE
	return_button.disabled = true
	end_box.add_child(return_button)

	await get_tree().process_frame
	var total_height: float = roll.get_combined_minimum_size().y
	var distance: float = total_height + viewport_size.y + 160.0
	var scroll_duration: float = distance / roll_speed
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(roll, "position:y", -total_height - 120.0, scroll_duration)
	tween.tween_callback(_reveal_credits_end.bind(end_reveal, return_button))
	await tween.finished

func _reveal_credits_end(end_reveal: Control, return_button: Button) -> void:
	if not is_instance_valid(end_reveal) or not is_instance_valid(return_button):
		return
	var end_tween: Tween = create_tween()
	end_tween.set_ignore_time_scale(true)
	end_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	end_tween.tween_property(end_reveal, "modulate:a", 1.0, 0.7)
	return_button.disabled = false

func _return_to_main_menu_pressed() -> void:
	if _returning_to_menu:
		return
	_returning_to_menu = true
	LevelManager.reset_to_defaults()
	var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		_returning_to_menu = false
		push_error("EchoRealmStageEntry: failed to return to main menu (%s)" % error_string(error))

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
