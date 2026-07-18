@tool
extends Node
class_name TutorialManager

## Part 1 教程层：监听 Player 事件，并用 BasicOBJ_Group/AnimationPlayer 控制节奏。
## 不修改 Player.gd，也不把 GuidanceBox 的触发逻辑改成教程逻辑。

enum TutorialStage { INTRO, TURN_PROMPT, RHYTHM, FIRST_STALL, STALL_ADAPT, COMPLETE }

const INTRO_TEXT := "世界开始变慢，你还没意识到。"
const TURN_TEXT := "你试着移动——身体比意识慢了一拍。"
const RHYTHM_TEXT := "跟着这个世界的脉搏，慢慢来。"
const FIRST_STALL_TEXT := "它停下来了。不是故障，是这个世界在呼吸。"
const ADAPT_TEXT := "你开始习惯它的节奏——滞后，但可预测。"
const COMPLETE_TEXT := "前方的路，似乎有另一个你在等待。"

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
var guidance_nodes: Array[Node3D] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_deferred_bind()
	if narrative_label:
		narrative_label.modulate.a = 0.0
		narrative_label.text = ""

func _deferred_bind() -> void:
	await get_tree().process_frame
	player = get_node_or_null(player_path)
	animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	narrative_label = get_node_or_null("NarrativeUI/NarrativeLabel") as Label
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
	else:
		_set_slow_motion(true)

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

func _set_stage(next_stage: TutorialStage, text: String) -> void:
	stage = next_stage
	_show_narrative(text)

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

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_apply_runtime_time_scale(_level_time_scale)
