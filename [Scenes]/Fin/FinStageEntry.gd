extends Node3D

const FIN_STAGE_ENTRY_META: StringName = &"fin_stage_entry"
const PART1_PATH: NodePath = NodePath("Scene_Group/part1")
const PART2_PATH: NodePath = NodePath("Scene_Group/part2")
const PART2_PYRAMID_PATH: NodePath = NodePath("Scene_Group/part2/Pyramid")
const PART3_PATH: NodePath = NodePath("Scene_Group/part3")
const PART2_CHECKPOINT_PATH: NodePath = NodePath("collection/Crown2/Area3D/CrownCheckpoint")
const PART3_CHECKPOINT_PATH: NodePath = NodePath("collection/Crown/Area3D/CrownCheckpoint")
const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"
const LANGUAGE_KEY: String = "language"
const PART_TITLES_ZH: Array[String] = ["初滞", "回声", "终章", "回声之境"]
const PART_TITLES_EN: Array[String] = ["FIRST DELAY", "THE ECHO", "GENTLE ARRIVAL", "ECHO REALM"]
const PART_SUBTITLES_ZH: Array[String] = ["暖黄峡谷", "灰蓝山谷", "破晓拱门", "镜面回廊"]
const PART_SUBTITLES_EN: Array[String] = ["AMBER CANYON", "BLUE VALLEY", "DAWN ARCH", "MIRROR CORRIDOR"]

func _ready() -> void:
	call_deferred("_apply_menu_stage_entry")

func _apply_menu_stage_entry() -> void:
	var scene_tree: SceneTree = get_tree()
	var stage_index: int = 0
	if scene_tree.root.has_meta(FIN_STAGE_ENTRY_META):
		stage_index = int(scene_tree.root.get_meta(FIN_STAGE_ENTRY_META))
		scene_tree.root.remove_meta(FIN_STAGE_ENTRY_META)
	match stage_index:
		0:
			_remove_part(PART2_PATH)
			_remove_part(PART3_PATH)
		1:
			_remove_part(PART1_PATH)
			_restore_checkpoint(PART2_CHECKPOINT_PATH)
		2:
			_remove_part(PART1_PATH)
			_remove_part(PART2_PYRAMID_PATH)
			_restore_checkpoint(PART3_CHECKPOINT_PATH)
	_set_level_ui_title(stage_index)
	_show_part_title(stage_index)

func _set_level_ui_title(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= PART_TITLES_ZH.size():
		return
	var level_ui: Control = get_node_or_null("BasicOBJ_Group/gameui") as Control
	if not level_ui or not level_ui.has_method("set_level_name"):
		return
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	var titles: Array[String] = PART_TITLES_ZH if is_chinese else PART_TITLES_EN
	level_ui.call("set_level_name", titles[stage_index])

func _show_part_title(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= PART_TITLES_ZH.size():
		return
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	var titles: Array[String] = PART_TITLES_ZH if is_chinese else PART_TITLES_EN
	var subtitles: Array[String] = PART_SUBTITLES_ZH if is_chinese else PART_SUBTITLES_EN
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title_box.position.y = 68.0
	title_box.add_theme_constant_override("separation", 4)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(title_box)
	var title_label: Label = Label.new()
	title_label.text = "PART %d  |  %s" % [stage_index + 1, titles[stage_index]]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(0.09, 0.2, 0.3, 0.95))
	title_label.add_theme_constant_override("outline_size", 6)
	title_box.add_child(title_label)
	var subtitle_label: Label = Label.new()
	subtitle_label.text = subtitles[stage_index]
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.94, 0.96, 0.92))
	title_box.add_child(subtitle_label)
	title_box.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(title_box, "modulate:a", 1.0, 0.35)
	tween.tween_interval(2.4)
	tween.tween_property(title_box, "modulate:a", 0.0, 0.55)
	tween.tween_callback(layer.queue_free)

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
		push_error("FinStageEntry: checkpoint or player was unavailable for stage entry")
		return
	checkpoint._enter_trigger(player)
	checkpoint.revive()
