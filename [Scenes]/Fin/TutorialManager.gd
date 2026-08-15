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
const AFTERIMAGE_PROMPT_TEXT: StringName = &"afterimage_prompt"
signal opening_intertitle_continue_requested
const NARRATIVE_TEXTS: Dictionary = {
	INTRO_TEXT: {CHINESE_LANGUAGE: "世界开始变慢，你还没意识到。", ENGLISH_LANGUAGE: "The world begins to slow before you notice."},
	TURN_TEXT: {CHINESE_LANGUAGE: "你试着移动——身体比意识慢了一拍。", ENGLISH_LANGUAGE: "You try to move - your body trails your mind by a beat."},
	RHYTHM_TEXT: {CHINESE_LANGUAGE: "跟着这个世界的脉搏，慢慢来。", ENGLISH_LANGUAGE: "Follow this world's pulse. Take it slow."},
	FIRST_STALL_TEXT: {CHINESE_LANGUAGE: "它停下来了。不是故障，是这个世界在呼吸。", ENGLISH_LANGUAGE: "It has stopped. Not a malfunction - this world is breathing."},
	ADAPT_TEXT: {CHINESE_LANGUAGE: "你开始习惯它的节奏——滞后，但可预测。", ENGLISH_LANGUAGE: "You are learning its rhythm: delayed, yet predictable."},
	COMPLETE_TEXT: {CHINESE_LANGUAGE: "前方的路，似乎有另一个你在等待。", ENGLISH_LANGUAGE: "Ahead, it seems another you is waiting."},
	SUMMON_PROMPT_TEXT: {CHINESE_LANGUAGE: "点击呼唤回声", ENGLISH_LANGUAGE: "Click to summon the echo."},
	AFTERIMAGE_PROMPT_TEXT: {CHINESE_LANGUAGE: "这是你的残影——它慢三秒，重复着你的每一步。\n点击它，与它同步，继续前行。", ENGLISH_LANGUAGE: "This is your afterimage - repeating your every step, three seconds behind.\nClick it to sync and move on."},
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
var _narrative_tween: Tween
var click_indicator_world_position: Vector3 = Vector3.ZERO
var click_indicator_has_world_position: bool = false
var _language: String = CHINESE_LANGUAGE
var _tutorial_enabled: bool = true
var _waiting_for_opening_intertitle: bool = false
var _opening_intertitle_input_consumed: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if not _tutorial_enabled:
		return
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
	if Engine.is_editor_hint() or not _tutorial_enabled or not _tutorial_started or stage == TutorialStage.COMPLETE:
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
	if not _tutorial_enabled or _tutorial_started:
		return
	_tutorial_started = true
	elapsed = 0.0
	_set_stage(TutorialStage.INTRO, INTRO_TEXT)

func _on_turn() -> void:
	if not _tutorial_enabled or not _tutorial_started:
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


func show_narrative(text: String, hold_override: float = -1.0) -> void:
	_refresh_language()
	_show_narrative(_translate_external_narrative(text), hold_override)


func set_tutorial_slow_motion(slow: bool) -> void:
	_set_slow_motion(slow)

func set_tutorial_enabled(enabled: bool) -> void:
	_tutorial_enabled = enabled
	_tutorial_started = enabled
	if not enabled and narrative_label:
		narrative_label.modulate.a = 0.0

func show_opening_intertitle(title: String, body: String) -> void:
	_refresh_language()
	var was_tree_paused: bool = get_tree().paused
	get_tree().paused = true
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 128
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var blackout: ColorRect = ColorRect.new()
	blackout.color = Color.BLACK
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.mouse_filter = Control.MOUSE_FILTER_STOP
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
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.86, 1.0))
	copy.add_child(title_label)
	var body_label: Label = Label.new()
	body_label.text = body
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(360.0, 0.0)
	body_label.add_theme_font_size_override("font_size", 17)
	body_label.add_theme_color_override("font_color", Color(0.7, 0.76, 0.8, 1.0))
	copy.add_child(body_label)
	var continue_label: Label = Label.new()
	if _tutorial_enabled:
		# Part 1 开场即提示玩家核心操作：空格或点击。
		continue_label.text = "按 空格 或 点击 开始" if _language == CHINESE_LANGUAGE else "PRESS SPACE OR CLICK TO START"
	else:
		continue_label.text = "点击或按任意键继续" if _language == CHINESE_LANGUAGE else "CLICK OR PRESS ANY KEY TO CONTINUE"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_label.add_theme_font_size_override("font_size", 13)
	continue_label.add_theme_color_override("font_color", Color(0.58, 0.65, 0.69, 1.0))
	continue_label.modulate.a = 0.0
	copy.add_child(continue_label)
	var opening_tween: Tween = create_tween()
	opening_tween.set_ignore_time_scale(true)
	opening_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	opening_tween.tween_property(copy, "modulate:a", 1.0, 0.4).set_delay(0.16)
	opening_tween.tween_interval(2.0)
	await opening_tween.finished
	_waiting_for_opening_intertitle = true
	var prompt_tween: Tween = create_tween()
	prompt_tween.set_ignore_time_scale(true)
	prompt_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	prompt_tween.tween_property(continue_label, "modulate:a", 1.0, 0.25)
	await opening_intertitle_continue_requested
	var closing_tween: Tween = create_tween().set_parallel()
	closing_tween.set_ignore_time_scale(true)
	closing_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	closing_tween.tween_property(copy, "modulate:a", 0.0, 0.35)
	closing_tween.tween_property(blackout, "modulate:a", 0.0, 0.45)
	await closing_tween.finished
	layer.queue_free()
	get_tree().paused = was_tree_paused

## 非全屏玩法介绍：屏幕下方居中的卡片浮层，不暂停游戏、不遮挡全屏，
## 点击任意处继续（由透明拦截层处理，不会触发转向）。
func show_guide_panel(title: String, body: String) -> void:
	_refresh_language()
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "GuideLayer"
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	# 全屏透明拦截层：点击关闭面板，同时吞掉事件避免触发转向。
	var blocker: Control = Control.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.gui_input.connect(_on_guide_blocker_input)
	layer.add_child(blocker)
	var container: CenterContainer = CenterContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	container.offset_left = -380.0
	container.offset_right = -40.0
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(container)
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.047, 0.059, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.89, 0.68, 0.31, 0.45)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(18.0)
	panel.add_theme_stylebox_override("panel", style)
	container.add_child(panel)
	var copy: VBoxContainer = VBoxContainer.new()
	copy.add_theme_constant_override("separation", 8)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.custom_minimum_size = Vector2(340.0, 0.0)
	panel.add_child(copy)
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.54, 1.0))
	copy.add_child(title_label)
	var body_label: Label = Label.new()
	body_label.text = body
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 14)
	body_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.82, 1.0))
	copy.add_child(body_label)
	var hint_label: Label = Label.new()
	hint_label.text = "点击任意处，继续你的路" if _language == CHINESE_LANGUAGE else "CLICK ANYWHERE TO CONTINUE"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(0.47, 0.52, 0.56, 1.0))
	copy.add_child(hint_label)
	panel.modulate.a = 0.0
	var fade_in: Tween = create_tween()
	fade_in.set_ignore_time_scale(true)
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(panel, "modulate:a", 1.0, 0.3)
	_guide_active = true
	# 等待关闭（点击拦截层或按键）；不暂停游戏。
	while _guide_active:
		await get_tree().process_frame
	var fade_out: Tween = create_tween().set_parallel()
	fade_out.set_ignore_time_scale(true)
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(panel, "modulate:a", 0.0, 0.22)
	await fade_out.finished
	layer.queue_free()

var _guide_active: bool = false

func _on_guide_blocker_input(event: InputEvent) -> void:
	if not _guide_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_guide_active = false
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_guide_active = false
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if _guide_active:
		# 引导面板显示期间：按键立即关闭，鼠标由拦截层处理。
		if event is InputEventKey and event.pressed and not event.echo:
			_guide_active = false
			get_viewport().set_input_as_handled()
			return
		return
	if not _waiting_for_opening_intertitle:
		return
	var should_continue: bool = false
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		should_continue = key_event.pressed and not key_event.echo
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		should_continue = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if not should_continue:
		return
	_waiting_for_opening_intertitle = false
	# Keep this event consumed through Player._unhandled_input(). The signal
	# resumes the scene, so set_input_as_handled() alone is not sufficient.
	_opening_intertitle_input_consumed = true
	call_deferred("_clear_opening_intertitle_input_consumed")
	get_viewport().set_input_as_handled()
	opening_intertitle_continue_requested.emit()

func consumes_turn_input(event: InputEvent) -> bool:
	return _opening_intertitle_input_consumed and event.is_action_pressed("turn")

func _clear_opening_intertitle_input_consumed() -> void:
	_opening_intertitle_input_consumed = false


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


func _show_narrative(text: String, hold_override: float = -1.0) -> void:
	if not narrative_label:
		return
	if _narrative_tween and _narrative_tween.is_valid():
		_narrative_tween.kill()
	narrative_label.text = text
	narrative_label.modulate.a = 0.0
	_narrative_tween = create_tween()
	_narrative_tween.set_ignore_time_scale(true)
	_narrative_tween.tween_property(narrative_label, "modulate:a", 1.0, 0.35)
	_narrative_tween.tween_interval(narrative_hold if hold_override < 0.0 else hold_override)
	_narrative_tween.tween_property(narrative_label, "modulate:a", 0.0, 0.65)


## 立即清除当前叙事文案（用于完全暂停结束时隐藏残影玩法说明）。
func clear_narrative() -> void:
	if _narrative_tween and _narrative_tween.is_valid():
		_narrative_tween.kill()
		_narrative_tween = null
	if narrative_label:
		narrative_label.text = ""
		narrative_label.modulate.a = 0.0


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
