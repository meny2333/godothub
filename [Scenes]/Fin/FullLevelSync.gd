extends Node

const FIN_STAGE_ENTRY_META: StringName = &"fin_stage_entry"
const INHERITED_SYNC_META: StringName = &"fin_inherited_sync"
const INHERITED_SYNC_SOURCE_META: StringName = &"fin_inherited_sync_source"
const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"
const LANGUAGE_KEY: String = "language"
const CRYSTAL_SCRIPT_PATH: String = "res://#Template/[Scripts]/Trigger/Crystal.gd"
const SPAWN_GODOT_SCRIPT_PATH: String = "res://[Scenes]/Fin/[Scripts]/Trigger/SpawnGodotCharacter.gd"

@export_range(1.0, 100.0, 1.0) var initial_sync: float = 72.0
@export_range(0.1, 20.0, 0.1) var decay_per_second: float = 3.5
@export_range(1.0, 100.0, 1.0) var crystal_restore: float = 15.0
@export_range(1.0, 100.0, 1.0) var crown_restore: float = 15.0
@export_range(1.0, 100.0, 1.0) var echo_restore: float = 35.0
@export_range(0.1, 10.0, 0.1) var guidance_restore: float = 0.7
@export_range(0.1, 1.0, 0.05) var minimum_time_scale: float = 0.8
@export_range(1.0, 2.0, 0.05) var maximum_time_scale: float = 1.1

var sync_value: float = 0.0
var _active: bool = false
var _depleted: bool = false
var _tracked_crystals: Array[Node] = []
var _tracked_crowns: Array[CrownCheckpoint] = []
var _tracked_states: Dictionary = {}
var _bar: ProgressBar
var _value_label: Label

func _ready() -> void:
	call_deferred("_initialize")

func _exit_tree() -> void:
	if _active:
		LevelManager.remove_revive_listener(_on_revive)
		_restore_normal_speed()

func _process(delta: float) -> void:
	if not _active or _depleted:
		return
	_track_collections()
	if LevelManager.GameState != LevelManager.GameStatus.Playing:
		return
	var real_delta: float = delta / maxf(Engine.time_scale, 0.01)
	set_sync_value(sync_value - decay_per_second * real_delta)
	if sync_value <= 0.0:
		_depleted = true
		if is_instance_valid(Player.instance) and Player.instance.is_live:
			# Sync depletion always opens the normal LevelUI path, never checkpoint revive.
			LevelManager.current_checkpoint = null
			Player.instance.die()

func restore_sync(amount: float) -> void:
	if not _active or amount <= 0.0:
		return
	set_sync_value(sync_value + amount)

func set_sync_value(value: float) -> void:
	sync_value = clampf(value, 0.0, 100.0)
	_apply_speed()
	_update_hud()

func _initialize() -> void:
	# LevelHolder applies the menu entry in its deferred _ready callback.
	await get_tree().process_frame
	var scene_root: Node = get_tree().current_scene
	if not scene_root:
		queue_free()
		return
	_active = true
	var stage_index: int = int(scene_root.get_meta(FIN_STAGE_ENTRY_META, 0))
	if stage_index <= 0 or stage_index >= 3:
		queue_free()
		return
	var inherited_sync: float = _get_inherited_sync(scene_root, stage_index)
	set_sync_value(inherited_sync)
	_create_hud()
	_collect_sources(scene_root)
	LevelManager.add_revive_listener(_on_revive)

func _collect_sources(scene_root: Node) -> void:
	for node: Node in scene_root.find_children("*", "", true, false):
		if node is GuidanceBox:
			var guidance_callback: Callable = Callable(self, "_on_guidance_activated")
			if not node.activated.is_connected(guidance_callback):
				node.activated.connect(guidance_callback)
			continue
		if node is CrownCheckpoint:
			var crown: CrownCheckpoint = node as CrownCheckpoint
			_tracked_crowns.append(crown)
			_tracked_states[crown.get_instance_id()] = crown.used
			continue
		var script: Script = node.get_script() as Script
		if script and script.resource_path == CRYSTAL_SCRIPT_PATH:
			_tracked_crystals.append(node)
			_tracked_states[node.get_instance_id()] = bool(node.get("_collected"))
		elif script and script.resource_path == SPAWN_GODOT_SCRIPT_PATH:
			var callback: Callable = Callable(self, "_on_echo_clicked")
			if node.has_signal("click_succeeded") and not node.is_connected("click_succeeded", callback):
				node.connect("click_succeeded", callback)

func _track_collections() -> void:
	for crystal: Node in _tracked_crystals:
		if not is_instance_valid(crystal):
			continue
		var id: int = crystal.get_instance_id()
		var collected: bool = bool(crystal.get("_collected"))
		if collected and not bool(_tracked_states.get(id, false)):
			restore_sync(crystal_restore)
		_tracked_states[id] = collected
	for crown: CrownCheckpoint in _tracked_crowns:
		if not is_instance_valid(crown):
			continue
		var id: int = crown.get_instance_id()
		if crown.used and not bool(_tracked_states.get(id, false)):
			restore_sync(crown_restore)
		_tracked_states[id] = crown.used

func _on_echo_clicked() -> void:
	restore_sync(echo_restore)

func _on_guidance_activated() -> void:
	restore_sync(guidance_restore)

func _on_revive() -> void:
	_depleted = false

func get_inherited_sync() -> float:
	return sync_value

func _get_inherited_sync(scene_root: Node, stage_index: int) -> float:
	var source_stage: int = int(scene_root.get_meta(INHERITED_SYNC_SOURCE_META, -1))
	if stage_index > 0 and source_stage == stage_index - 1:
		return clampf(float(scene_root.get_meta(INHERITED_SYNC_META, initial_sync)), 0.0, 100.0)
	return initial_sync

func _apply_speed() -> void:
	if not _active:
		return
	var time_scale: float = lerpf(minimum_time_scale, maximum_time_scale, sync_value / 100.0)
	Engine.time_scale = time_scale
	AudioManager.pitch = time_scale

func _restore_normal_speed() -> void:
	Engine.time_scale = 1.0
	AudioManager.pitch = 1.0

func _create_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "SyncHUD"
	layer.layer = 40
	add_child(layer)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	holder.position = Vector2(-82.0, 0.0)
	holder.size = Vector2(54.0, 260.0)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(holder)
	var title: Label = Label.new()
	title.text = _get_sync_title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(-18.0, 4.0)
	title.size = Vector2(90.0, 24.0)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0, 1.0))
	holder.add_child(title)
	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.show_percentage = false
	_bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	_bar.position = Vector2(11.0, 33.0)
	_bar.size = Vector2(32.0, 194.0)
	_bar.add_theme_stylebox_override("background", _capsule_style(Color(0.025, 0.075, 0.12, 0.86)))
	_bar.add_theme_stylebox_override("fill", _capsule_style(Color(0.23, 0.84, 0.95, 0.96)))
	holder.add_child(_bar)
	_value_label = Label.new()
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.position = Vector2(-8.0, 232.0)
	_value_label.size = Vector2(70.0, 24.0)
	_value_label.add_theme_font_size_override("font_size", 15)
	_value_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	holder.add_child(_value_label)
	_update_hud()

func _capsule_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.65, 0.93, 1.0, 0.5)
	return style

func _update_hud() -> void:
	if _bar:
		_bar.value = sync_value
	if _value_label:
		_value_label.text = "%d%%" % roundi(sync_value)

func _get_sync_title() -> String:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var is_chinese: bool = str(config.get_value(UI_SECTION, LANGUAGE_KEY, "zh")) != "en"
	return "同步率" if is_chinese else "SYNC RATE"
