@tool
extends Node
class_name TutorialManager

## Fin 的 Part 1 教程层：监听 Player 事件，并用 BasicOBJ_Group/AnimationPlayer 控制节奏。
## 不修改 Player.gd，也不把 GuidanceBox 的触发逻辑改成教程逻辑。

enum TutorialStage { INTRO, TURN_PROMPT, RHYTHM, FIRST_STALL, STALL_ADAPT, COMPLETE }

const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"
const LANGUAGE_KEY: String = "language"
const CHINESE_LANGUAGE: String = "zh"
const ENGLISH_LANGUAGE: String = "en"
const CLICK_INDICATOR_TEXT: StringName = &"click_indicator"
const INTRO_TEXT: StringName = &"intro"
const TURN_TEXT: StringName = &"turn"
const RHYTHM_TEXT: StringName = &"rhythm"
const FIRST_STALL_TEXT: StringName = &"first_stall"
const ADAPT_TEXT: StringName = &"adapt"
const COMPLETE_TEXT: StringName = &"complete"
const SUMMON_PROMPT_TEXT: StringName = &"summon_prompt"
const NARRATIVE_TEXTS: Dictionary = {
	INTRO_TEXT: {CHINESE_LANGUAGE: "世界开始变慢，你还没意识到。", ENGLISH_LANGUAGE: "The world begins to slow before you notice."},
	TURN_TEXT: {CHINESE_LANGUAGE: "你试着移动——身体比意识慢了一拍。", ENGLISH_LANGUAGE: "You try to move - your body trails your mind by a beat."},
	RHYTHM_TEXT: {CHINESE_LANGUAGE: "跟着这个世界的脉搏，慢慢来。", ENGLISH_LANGUAGE: "Follow this world's pulse. Take it slow."},
	FIRST_STALL_TEXT: {CHINESE_LANGUAGE: "它停下来了。不是故障，是这个世界在呼吸。", ENGLISH_LANGUAGE: "It has stopped. Not a malfunction - this world is breathing."},
	ADAPT_TEXT: {CHINESE_LANGUAGE: "你开始习惯它的节奏——滞后，但可预测。", ENGLISH_LANGUAGE: "You are learning its rhythm: delayed, yet predictable."},
	COMPLETE_TEXT: {CHINESE_LANGUAGE: "前方的路，似乎有另一个你在等待。", ENGLISH_LANGUAGE: "Ahead, it seems another you is waiting."},
	SUMMON_PROMPT_TEXT: {CHINESE_LANGUAGE: "点击呼唤回声", ENGLISH_LANGUAGE: "Click to summon the echo."},
	CLICK_INDICATOR_TEXT: {CHINESE_LANGUAGE: "点击", ENGLISH_LANGUAGE: "CLICK"},
}

@export var animation_player_path: NodePath = NodePath("../AnimationPlayer")
@export var player_path: NodePath = NodePath("../Player")
@export var guidance_paths: Array[NodePath] = [
	NodePath("../GuidanceBoxHolder/GuidanceBox 0/Area3D"),
	NodePath("../GuidanceBoxHolder/GuidanceBox 1/Area3D"),
	NodePath("../GuidanceBoxHolder/GuidanceBox 2/Area3D"),
	NodePath("../GuidanceBoxHolder/GuidanceBox 3/Area3D")
]
@export var first_turn_slow_distance := 15.0
@export var turn_time_scale := 0.3
@export var turn_recover_time := 0.7
@export var narrative_hold := 2.5
@export var stall_duration := 0.5
@export var beats_per_stall := 8
@export var beat_interval := 0.5

var stage: TutorialStage = TutorialStage.INTRO
var elapsed := 0.0
var stall_count := 0
var _tutorial_started := false
var _active_guidance_index := -1
var _guidance_completed: Array[bool] = []
var _stall_running := false
var _last_animation_position := 0.0
var _last_beat_index := -1
var _fallback_beat_time := 0.0
var _animation_base_speed := 1.0
var _time_scale_value := 1.0
var _level_time_scale := 1.0
var level_data: LevelData

@onready var player: Node = get_node_or_null(player_path)
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer
@onready var narrative_label: Label = get_node_or_null("NarrativeUI/NarrativeLabel") as Label
@onready var narrative_ui: CanvasLayer = get_node_or_null("NarrativeUI") as CanvasLayer
var guidance_nodes: Array[Node3D] = []
var click_indicator: Panel
var click_indicator_label: Label
var click_indicator_tween: Tween
var click_indicator_world_position: Vector3 = Vector3.ZERO
var click_indicator_has_world_position: bool = false
var _language: String = CHINESE_LANGUAGE

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_deferred_bind()
	if narrative_label:
		narrative_label.modulate.a = 0.0
		narrative_label.text = ""

func _deferred_bind() -> void:
	await get_tree().process_frame
	_refresh_language()
	player = get_node_or_null(player_path)
	animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	narrative_label = get_node_or_null("NarrativeUI/NarrativeLabel") as Label
	narrative_ui = get_node_or_null("NarrativeUI") as CanvasLayer
	_ensure_click_indicator()
	var viewport: Viewport = get_viewport()
	if viewport and not viewport.size_changed.is_connected(_position_click_indicator):
		viewport.size_changed.connect(_position_click_indicator)
	guidance_nodes.clear()
	for path in guidance_paths:
		guidance_nodes.append(get_node_or_null(path) as Node3D)
	_guidance_completed.resize(guidance_nodes.size())
	_guidance_completed.fill(false)
	if animation_player:
		_animation_base_speed = animation_player.speed_scale
	if player:
		level_data = player.get("level_data") as LevelData
	if level_data:
		_level_time_scale = level_data.timeScale
		_time_scale_value = _level_time_scale
	# 不依赖启动点击信号，避免 Player 在管理器连接前已经发出 on_player_start。
	_tutorial_started = true
	_set_stage(TutorialStage.INTRO, INTRO_TEXT)
	if not player:
		return
	if player.has_signal("on_player_start") and not player.is_connected("on_player_start", _on_player_start):
		player.connect("on_player_start", _on_player_start)
	if player.has_signal("onturn") and not player.is_connected("onturn", _on_turn):
		player.connect("onturn", _on_turn)

func _process(delta: float) -> void:
	if click_indicator and click_indicator.visible:
		_position_click_indicator()
	if Engine.is_editor_hint() or not _tutorial_started or stage == TutorialStage.COMPLETE:
		return
	elapsed += delta
	_update_guidance_turn_window()
	_update_stall_clock(delta)

## 玩家接近每个 GuidanceBox 0-3、但尚未触碰前，先进入该盒子的慢速窗口。
func _update_guidance_turn_window() -> void:
	if _active_guidance_index >= 0 or not player:
		return
	for i in range(guidance_nodes.size()):
		var guidance := guidance_nodes[i]
		if not guidance or _guidance_completed[i]:
			continue
		var distance: float = player.global_position.distance_to(guidance.global_position)
		if distance <= first_turn_slow_distance:
			_active_guidance_index = i
			_set_stage(TutorialStage.TURN_PROMPT, TURN_TEXT)
			_set_slow_motion(true)
			return

func _on_player_start() -> void:
	if _tutorial_started:
		return
	_tutorial_started = true
	elapsed = 0.0
	_set_stage(TutorialStage.INTRO, INTRO_TEXT)

func _on_turn() -> void:
	if not _tutorial_started:
		return
	# 每个 GuidanceBox 前的窗口都预先减速；完成转向后恢复并继续节奏教学。
	if _active_guidance_index >= 0:
		_guidance_completed[_active_guidance_index] = true
		_active_guidance_index = -1
		_set_slow_motion(false)
		_set_stage(TutorialStage.RHYTHM, RHYTHM_TEXT)

func _set_slow_motion(slow: bool) -> void:
	var target_scale: float = turn_time_scale if slow else _level_time_scale
	var current_scale := Engine.time_scale
	if slow:
		_time_scale_value = target_scale
		_apply_runtime_time_scale(target_scale)
		return
	# 由 AnimationPlayer 实际控制动画进度，而不是用独立的教程计时器推进场景。
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_method(_apply_time_scale, current_scale, target_scale, turn_recover_time)

func _apply_time_scale(value: float) -> void:
	_time_scale_value = value
	_apply_runtime_time_scale(value)

func _apply_runtime_time_scale(value: float) -> void:
	if level_data:
		level_data.timeScale = value
	Engine.time_scale = value
	if player and player.has_node("MusicPlayer"):
		(player.get_node("MusicPlayer") as AudioStreamPlayer).pitch_scale = value
	if animation_player and not _stall_running:
		animation_player.speed_scale = _animation_base_speed * value

func _update_stall_clock(delta: float) -> void:
	if stage == TutorialStage.INTRO or stage == TutorialStage.TURN_PROMPT or _stall_running:
		return
	var position := -1.0
	if animation_player and animation_player.is_playing():
		position = animation_player.current_animation_position
	if position >= 0.0 and position < _last_animation_position:
		_last_animation_position = position
		_last_beat_index = -1
		return
	if position >= 0.0:
		_last_animation_position = position
		var beat_index := int(floor(position / beat_interval))
		if beat_index != _last_beat_index:
			_last_beat_index = beat_index
			if beat_index > 0 and beat_index % beats_per_stall == 0:
				_trigger_stall()
	else:
		_fallback_beat_time += delta
		if _fallback_beat_time >= beat_interval * beats_per_stall:
			_fallback_beat_time = 0.0
			_trigger_stall()

func _trigger_stall() -> void:
	if _stall_running or stage == TutorialStage.COMPLETE:
		return
	_stall_running = true
	stall_count += 1
	if stall_count == 1:
		_set_stage(TutorialStage.FIRST_STALL, FIRST_STALL_TEXT)
	elif stall_count >= 3:
		_set_stage(TutorialStage.STALL_ADAPT, ADAPT_TEXT)
	if animation_player:
		# 卡顿作用在 AnimationPlayer 的进度上，线条动画会实际减速。
		animation_player.speed_scale = _animation_base_speed * 0.35
	await get_tree().create_timer(stall_duration, true, false, true).timeout
	_stall_running = false
	if animation_player:
		_apply_runtime_time_scale(_time_scale_value)
	if stall_count >= 3 and stage == TutorialStage.STALL_ADAPT:
		_set_stage(TutorialStage.COMPLETE, COMPLETE_TEXT)

func _set_stage(next_stage: TutorialStage, text_key: StringName) -> void:
	stage = next_stage
	_show_narrative(_get_text(text_key))


func show_narrative(text: String) -> void:
	_refresh_language()
	_show_narrative(_translate_external_narrative(text))


func set_tutorial_slow_motion(slow: bool) -> void:
	_set_slow_motion(slow)


func show_click_indicator(world_position: Vector3) -> void:
	_refresh_language()
	_ensure_click_indicator()
	if click_indicator == null:
		return
	click_indicator_world_position = world_position
	click_indicator_has_world_position = true
	_position_click_indicator()
	click_indicator.visible = true
	click_indicator.scale = Vector2.ONE
	if click_indicator_tween and click_indicator_tween.is_valid():
		click_indicator_tween.kill()
	click_indicator_tween = create_tween()
	click_indicator_tween.set_ignore_time_scale(true)
	click_indicator_tween.set_loops()
	click_indicator_tween.tween_property(click_indicator, "scale", Vector2(1.18, 1.18), 0.45)
	click_indicator_tween.tween_property(click_indicator, "scale", Vector2.ONE, 0.45)


func update_click_indicator(world_position: Vector3) -> void:
	click_indicator_world_position = world_position
	click_indicator_has_world_position = true
	if click_indicator and click_indicator.visible:
		_position_click_indicator()


func hide_click_indicator() -> void:
	if click_indicator_tween and click_indicator_tween.is_valid():
		click_indicator_tween.kill()
	if click_indicator:
		click_indicator.visible = false
		click_indicator.scale = Vector2.ONE
	click_indicator_has_world_position = false


func _ensure_click_indicator() -> void:
	if click_indicator or not narrative_ui:
		return
	click_indicator = Panel.new()
	click_indicator.name = "ClickIndicator"
	click_indicator.size = Vector2(112.0, 112.0)
	click_indicator.custom_minimum_size = click_indicator.size
	click_indicator.pivot_offset = click_indicator.size / 2.0
	click_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_indicator.z_index = 3

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.78, 0.2, 0.16)
	style.border_color = Color(1.0, 0.94, 0.55, 0.98)
	style.set_border_width_all(4)
	style.set_corner_radius_all(56)
	click_indicator.add_theme_stylebox_override("panel", style)

	click_indicator_label = Label.new()
	click_indicator_label.text = _get_text(CLICK_INDICATOR_TEXT)
	click_indicator_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	click_indicator_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	click_indicator_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_indicator_label.add_theme_font_size_override("font_size", 22)
	click_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.82, 1.0))
	click_indicator_label.add_theme_color_override("font_outline_color", Color(0.08, 0.12, 0.2, 0.95))
	click_indicator_label.add_theme_constant_override("outline_size", 6)
	click_indicator.add_child(click_indicator_label)
	narrative_ui.add_child(click_indicator)
	click_indicator.visible = false


func _position_click_indicator() -> void:
	if not click_indicator:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var screen_position: Vector2 = viewport_size * Vector2(0.5, 0.7)
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera and click_indicator_has_world_position:
		var target_position: Vector3 = click_indicator_world_position + Vector3.UP * 1.0
		if not camera.is_position_behind(target_position):
			screen_position = camera.unproject_position(target_position)

	click_indicator.position = screen_position - click_indicator.size * 0.5


func _show_narrative(text: String) -> void:
	if not narrative_label:
		return
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.kill()
	narrative_label.text = text
	narrative_label.modulate.a = 0.0
	tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(narrative_label, "modulate:a", 1.0, 0.35)
	tween.tween_interval(narrative_hold)
	tween.tween_property(narrative_label, "modulate:a", 0.0, 0.65)


func _refresh_language() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	_language = ENGLISH_LANGUAGE if str(config.get_value(UI_SECTION, LANGUAGE_KEY, CHINESE_LANGUAGE)) == ENGLISH_LANGUAGE else CHINESE_LANGUAGE
	if click_indicator_label:
		click_indicator_label.text = _get_text(CLICK_INDICATOR_TEXT)


func _get_text(text_key: StringName) -> String:
	var translations: Dictionary = NARRATIVE_TEXTS.get(text_key, {}) as Dictionary
	return str(translations.get(_language, translations.get(CHINESE_LANGUAGE, "")))


func _translate_external_narrative(text: String) -> String:
	for text_key: StringName in NARRATIVE_TEXTS:
		var translations: Dictionary = NARRATIVE_TEXTS[text_key] as Dictionary
		if text == str(translations.get(CHINESE_LANGUAGE, "")) or text == str(translations.get(ENGLISH_LANGUAGE, "")):
			return _get_text(text_key)
	return text

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_apply_runtime_time_scale(_level_time_scale)
