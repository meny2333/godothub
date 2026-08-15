extends Control

signal stage_selected(index: int)

const CARD_SIZE: Vector2 = Vector2(480.0, 258.0)
const STAGE_COLORS: Array[Color] = [
	Color("#e6b14c"),
	Color("#86a9bf"),
	Color("#f0d18d"),
	Color("#b7e8ed"),
]

@onready var cards: Array[Control] = [$Card01, $Card02, $Card03, $Card04]
@onready var card_buttons: Array[Button] = [$Card01/HitTarget, $Card02/HitTarget, $Card03/HitTarget, $Card04/HitTarget]
@onready var card_indexes: Array[Label] = [$Card01/Copy/Index, $Card02/Copy/Index, $Card03/Copy/Index, $Card04/Copy/Index]
@onready var card_titles: Array[Label] = [$Card01/Copy/Title, $Card02/Copy/Title, $Card03/Copy/Title, $Card04/Copy/Title]
@onready var card_subtitles: Array[Label] = [$Card01/Copy/Subtitle, $Card02/Copy/Subtitle, $Card03/Copy/Subtitle, $Card04/Copy/Subtitle]
@onready var card_statuses: Array[Label] = [$Card01/Copy/Status, $Card02/Copy/Status, $Card03/Copy/Status, $Card04/Copy/Status]
@onready var previous_button: Button = $PreviousButton
@onready var next_button: Button = $NextButton
@onready var counter_label: Label = $CounterLabel
@onready var mirror_overlay: Control = $MirrorOverlay
@onready var lock_shade: ColorRect = $Card04/LockShade
@onready var lock_glyph: Control = $Card04/LockGlyph
@onready var card_shades: Array[ColorRect] = []

var selected_index: int = 0
var _layout_tween: Tween
var _unlocking: bool = false
var _full_mode_unlocked: bool = false
var _focus_mode: bool = false

func _ready() -> void:
	clip_contents = true
	for index: int in range(card_buttons.size()):
		card_buttons[index].pressed.connect(_on_card_pressed.bind(index))
	previous_button.pressed.connect(_select_relative.bind(-1))
	next_button.pressed.connect(_select_relative.bind(1))
	resized.connect(_on_resized)
	# 为 Card01-Card03 创建黑色遮罩（未解锁时显示，无锁图标）
	for index: int in range(cards.size() - 1):
		var shade: ColorRect = ColorRect.new()
		shade.color = Color(0.005, 0.012, 0.016, 0.68)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.visible = false
		cards[index].add_child(shade)
		card_shades.append(shade)
	await get_tree().process_frame
	_apply_layout(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or _unlocking or not event.pressed or event.echo:
		return
	if event.keycode == KEY_LEFT:
		_select_relative(-1)
	elif event.keycode == KEY_RIGHT:
		_select_relative(1)

func configure_copy(titles: Array[String], subtitles: Array[String], statuses: Array[String]) -> void:
	for index: int in range(cards.size()):
		card_indexes[index].text = "%02d" % (index + 1)
		card_titles[index].text = titles[index]
		card_subtitles[index].text = subtitles[index]
		card_statuses[index].text = statuses[index]
		# 未解锁的 part 卡片显示黑色遮罩（Card04 有自己的 LockShade）
		if index < card_shades.size():
			card_shades[index].visible = not _is_playable(statuses[index])

## 根据状态文字判断卡片是否可进入。
func _is_playable(status: String) -> bool:
	return status == "回声在等你" or status == "AN ECHO WAITS"

func set_selected(index: int, animate: bool = true) -> void:
	var clamped_index: int = clampi(index, 0, cards.size() - 1)
	if clamped_index == selected_index and animate:
		return
	selected_index = clamped_index
	_apply_layout(animate)

func set_focus(focused: bool) -> void:
	if _focus_mode == focused:
		return
	_focus_mode = focused
	_apply_layout(true)

func play_unlock() -> void:
	if _unlocking or _full_mode_unlocked:
		return
	_unlocking = true
	set_selected(3, true)
	var settle: Tween = create_tween()
	settle.tween_interval(0.42)
	await settle.finished
	lock_glyph.visible = true
	lock_shade.visible = true
	lock_glyph.set("unlock_progress", 0.0)
	lock_glyph.scale = Vector2(0.82, 0.82)
	lock_glyph.modulate.a = 1.0
	var anticipation: Tween = create_tween().set_parallel()
	anticipation.tween_property(lock_glyph, "scale", Vector2.ONE, 0.34).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	anticipation.tween_property(cards[3], "self_modulate", Color(1.08, 1.08, 1.08, 1.0), 0.34)
	await anticipation.finished
	var release: Tween = create_tween().set_parallel()
	release.tween_property(lock_glyph, "unlock_progress", 1.0, 1.05).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	release.tween_property(mirror_overlay, "unlock_flash", 1.0, 0.58).set_delay(0.47)
	await release.finished
	var reveal: Tween = create_tween().set_parallel()
	reveal.tween_property(mirror_overlay, "unlock_flash", 0.0, 0.65)
	reveal.tween_property(lock_shade, "modulate:a", 0.0, 0.7).set_delay(0.12)
	reveal.tween_property(lock_glyph, "modulate:a", 0.0, 0.52).set_delay(0.18)
	reveal.tween_property(cards[3], "self_modulate", Color.WHITE, 0.65)
	await reveal.finished
	_full_mode_unlocked = true
	lock_shade.visible = false
	lock_shade.modulate.a = 1.0
	lock_glyph.visible = false
	lock_glyph.modulate.a = 1.0
	_unlocking = false

func set_full_mode_unlocked(is_unlocked: bool) -> void:
	_full_mode_unlocked = is_unlocked
	lock_shade.visible = not is_unlocked
	lock_glyph.visible = not is_unlocked
	if is_unlocked:
		lock_glyph.set("unlock_progress", 1.0)

func _on_card_pressed(index: int) -> void:
	if _unlocking:
		return
	if index == selected_index:
		_focus_mode = true
	else:
		_focus_mode = false
		selected_index = index
	_apply_layout(true)
	stage_selected.emit(index)

func _select_relative(direction: int) -> void:
	if _unlocking:
		return
	selected_index = wrapi(selected_index + direction, 0, cards.size())
	_focus_mode = false
	_apply_layout(true)
	stage_selected.emit(selected_index)

func _apply_layout(animate: bool) -> void:
	if not is_node_ready() or size.x <= 1.0:
		return
	if _layout_tween and _layout_tween.is_valid():
		_layout_tween.kill()
	_layout_tween = create_tween().set_parallel()
	var center_x: float = size.x * 0.5
	for index: int in range(cards.size()):
		var delta: int = wrapi(index - selected_index + 2, 0, cards.size()) - 2
		var target_position: Vector2 = _position_for_delta(delta, center_x)
		var target_scale: Vector2 = _scale_for_delta(delta)
		var target_rotation: float = float(delta) * 0.035 if absi(delta) == 1 else 0.0
		var target_alpha: float
		if _focus_mode:
			target_alpha = 1.0 if delta == 0 else 0.0
		else:
			target_alpha = 1.0 if delta == 0 else (0.56 if absi(delta) == 1 else 0.18)
		cards[index].z_index = 10 if delta == 0 else (6 if absi(delta) == 1 else 2)
		cards[index].pivot_offset = CARD_SIZE * 0.5
		if animate:
			_layout_tween.tween_property(cards[index], "position", target_position, 0.58).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			_layout_tween.tween_property(cards[index], "scale", target_scale, 0.52).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			_layout_tween.tween_property(cards[index], "rotation", target_rotation, 0.52).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			_layout_tween.tween_property(cards[index], "modulate:a", target_alpha, 0.34)
		else:
			cards[index].position = target_position
			cards[index].scale = target_scale
			cards[index].rotation = target_rotation
			cards[index].modulate.a = target_alpha
	counter_label.text = "%02d  /  %02d" % [selected_index + 1, cards.size()]
	if mirror_overlay.has_method("set_stage"):
		mirror_overlay.call("set_stage", selected_index)

func _position_for_delta(delta: int, center_x: float) -> Vector2:
	match delta:
		0:
			return Vector2(center_x - CARD_SIZE.x * 0.5, 8.0)
		-1:
			return Vector2(center_x - CARD_SIZE.x * 0.5 - 310.0, 42.0)
		1:
			return Vector2(center_x - CARD_SIZE.x * 0.5 + 310.0, 42.0)
		_:
			return Vector2(center_x - CARD_SIZE.x * 0.5, 74.0)

func _scale_for_delta(delta: int) -> Vector2:
	if delta == 0:
		return Vector2.ONE
	if absi(delta) == 1:
		return Vector2(0.72, 0.72)
	return Vector2(0.52, 0.52)

func _on_resized() -> void:
	call_deferred("_apply_layout", false)
