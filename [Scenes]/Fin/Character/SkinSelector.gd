extends CanvasLayer
class_name SkinSelector

const CLASSIC_SKIN: String = "classic"
const GODOT_SKIN_ID: String = "godot"
const GODOT_SKIN: String = "res://[Scenes]/Fin/Character/SkinGodot.tscn"
const CLASSIC_IMAGE: String = "res://[Scenes]/Fin/classical-transparent.png"
const GODOT_IMAGE: String = "res://[Scenes]/Fin/godot-transparent.png"
const CAMERA_TRANSITION_DURATION: float = 0.45
const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"
const FIN_STAGE_ENTRY_META: StringName = &"fin_stage_entry"
const PART1_STAGE_INDEX: int = 0
const FULL_LEVEL_STAGE_INDEX: int = 3
const LATENCY_MIN: float = -5.0
const LATENCY_MAX: float = 5.0
const LATENCY_STEP: float = 0.01
const SLIDE_DURATION: float = 0.32
const SKIN_PANEL_OPEN_LEFT: float = -380.0
const SKIN_PANEL_OPEN_RIGHT: float = 0.0
const SKIN_PANEL_CLOSED_LEFT: float = 24.0
const SKIN_PANEL_CLOSED_RIGHT: float = 404.0
const SETTINGS_PANEL_OPEN_LEFT: float = -340.0
const SETTINGS_PANEL_OPEN_RIGHT: float = 0.0
const SETTINGS_PANEL_CLOSED_LEFT: float = 24.0
const SETTINGS_PANEL_CLOSED_RIGHT: float = 364.0
const INPUT_SECTION: String = "input"
const TURN_ACTION: StringName = &"turn"
const DEFAULT_TURN_KEY: Key = KEY_SPACE
@onready var top_right_buttons: HBoxContainer = $TopRightButtons
@onready var skin_entry_button: Button = $TopRightButtons/SkinEntryButton
@onready var gear_button: Button = $TopRightButtons/GearButton
@onready var shade: ColorRect = $Shade
@onready var input_blocker: Control = $InputBlocker
@onready var skin_panel_holder: Control = $SkinPanelHolder
@onready var settings_panel_holder: Control = $SettingsPanelHolder
@onready var skin_panel: PanelContainer = $SkinPanelHolder/SkinPanel
@onready var settings_panel: PanelContainer = $SettingsPanelHolder/SettingsPanel
@onready var skin_title: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Header/TitleStack/Title
@onready var skin_subtitle: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Header/TitleStack/Subtitle
@onready var skin_close_button: Button = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Header/CloseButton
@onready var current_preview: TextureRect = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/CurrentRow/CurrentPreview
@onready var current_caption: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/CurrentRow/CurrentInfo/CurrentCaption
@onready var current_name: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/CurrentRow/CurrentInfo/CurrentName
@onready var options_title: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/OptionsHeader/Title
@onready var classic_button: Button = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Cards/ClassicButton
@onready var godot_button: Button = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Cards/GodotButton
@onready var classic_selected_bar: ColorRect = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Cards/ClassicButton/CardContent/ClassicSelectedBar
@onready var godot_selected_bar: ColorRect = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Cards/GodotButton/CardContent/GodotSelectedBar
@onready var classic_name: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Cards/ClassicButton/CardContent/Name
@onready var classic_detail: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Cards/ClassicButton/CardContent/Detail
@onready var godot_detail: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/Cards/GodotButton/CardContent/Detail
@onready var action_row: HBoxContainer = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/ActionRow
@onready var turn_preview_checkbox: CheckBox = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/ActionRow/TurnPreviewCheckBox
@onready var slide_preview_checkbox: CheckBox = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/ActionRow/SlidePreviewCheckBox
@onready var bottom_hint: Label = $SkinPanelHolder/SkinPanel/PanelMargin/Contents/BottomHint
@onready var settings_title: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/Header/SettingsTitle
@onready var settings_close_button: Button = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/Header/CloseButton
@onready var settings_intro: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/SettingsIntro
@onready var language_label: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/LanguageRow/LanguageLabel
@onready var language_value_button: Button = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/LanguageRow/LanguageValue
@onready var antialiasing_label: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/AntiAliasingRow/AntiAliasingLabel
@onready var antialiasing_option: OptionButton = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/AntiAliasingRow/AntiAliasingOption
@onready var volume_title: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/VolumeBlock/VolumeHeader/VolumeTitle
@onready var volume_value: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/VolumeBlock/VolumeHeader/VolumeValue
@onready var volume_slider: HSlider = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/VolumeBlock/VolumeSlider
@onready var latency_title: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyHeader/LatencyTitle
@onready var latency_value: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyHeader/LatencyValue
@onready var latency_arrow_left: Button = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyControls/LatencyArrowLeft
@onready var latency_arrow_right: Button = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyControls/LatencyArrowRight
@onready var settings_note: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/SettingsNote
@onready var turn_key_label: Label = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/TurnKeyRow/TurnKeyLabel
@onready var turn_key_value_button: Button = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/TurnKeyRow/TurnKeyValue
@onready var turn_key_remove_button: Button = $SettingsPanelHolder/SettingsPanel/PanelMargin/SettingsContent/TurnKeyRow/TurnKeyRemove

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
var _skin_open: bool = false
var _settings_open: bool = false
var _music_delay: float = 0.0
var _music_volume: float = 1.0
var _slide_tween: Tween = null
var _panel_tweens: Dictionary = {}
var _closing_panel: Control = null
var _recording_turn_key: bool = false
var _turn_keys: Array[int] = [DEFAULT_TURN_KEY]
var _turn_buttons: Array[int] = [MOUSE_BUTTON_LEFT]

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("BasicOBJ_Group/Player") as Player
	skin_panel_holder.offset_left = SKIN_PANEL_CLOSED_LEFT
	skin_panel_holder.offset_right = SKIN_PANEL_CLOSED_RIGHT
	settings_panel_holder.offset_left = SETTINGS_PANEL_CLOSED_LEFT
	settings_panel_holder.offset_right = SETTINGS_PANEL_CLOSED_RIGHT
	skin_panel_holder.visible = false
	settings_panel_holder.visible = false
	shade.visible = false
	input_blocker.visible = false
	_load_preferences()
	_populate_options()
	_apply_language()
	_update_selection_visual()
	_apply_turn_key_binding()
	_set_buttons_focus_none()
	gameplay_camera = get_tree().current_scene.get_node_or_null(
			"BasicOBJ_Group/CameraRoot/Rotator/Scale/Camera3D") as Camera3D
	preview_camera = get_tree().current_scene.get_node_or_null(
			"BasicOBJ_Group/Camera3D") as Camera3D
	if player:
		player.on_player_start.connect(_lock_selection)
		_select_godot.call_deferred()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _recording_turn_key:
			_recording_turn_key = false
			_update_turn_key_button()
			_release_focus()
			get_viewport().set_input_as_handled()
			return
		if _skin_open or _settings_open:
			_close_all()
			get_viewport().set_input_as_handled()
		return
	if _recording_turn_key:
		if event is InputEventKey and event.pressed and not event.echo:
			_apply_turn_key(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed:
			# 鼠标键也能绑定：用按钮索引映射到 InputMap 的鼠标事件
			_apply_turn_key_mouse(event.button_index)
			get_viewport().set_input_as_handled()

func consumes_turn_input(event: InputEvent) -> bool:
	if locked or not visible:
		return false
	if _recording_turn_key:
		return event is InputEventMouseButton or event is InputEventScreenTouch
	if _skin_open or _settings_open:
		return event is InputEventMouseButton or event is InputEventScreenTouch
	if event is InputEventMouseButton:
		return event.pressed and top_right_buttons.get_global_rect().has_point(event.position)
	if event is InputEventScreenTouch:
		return event.pressed and top_right_buttons.get_global_rect().has_point(event.position)
	return false

## 面板内的按钮不需要键盘焦点：避免 Space/Enter/鼠标点击后被激活，干扰 turn 键。
func _set_buttons_focus_none() -> void:
	for panel: PanelContainer in [skin_panel, settings_panel]:
		for child: Node in panel.find_children("*", "Button", true, false):
			var button: Button = child as Button
			if button:
				button.focus_mode = Control.FOCUS_NONE

func _release_focus() -> void:
	for panel: PanelContainer in [skin_panel, settings_panel]:
		if panel.has_focus():
			panel.release_focus()
	get_viewport().gui_release_focus()

# === 抽屉面板开关 ===

func _open_skin_panel() -> void:
	if locked or _skin_open:
		return
	if _settings_open:
		_close_settings()
	_skin_open = true
	_save_original_camera_pose()
	_show_shade()
	skin_panel_holder.visible = true
	_set_panel_interactive(skin_panel, true)
	_release_focus()
	# 等一帧让容器完成布局，避免滑入时子容器被压缩/缩放
	await get_tree().process_frame
	_slide_panel(skin_panel_holder, SKIN_PANEL_OPEN_LEFT, SKIN_PANEL_OPEN_RIGHT)
	if _allows_camera_preview():
		_tween_camera_to(preview_camera)

func _close_skin_panel() -> void:
	if not _skin_open:
		return
	_skin_open = false
	# 立即禁用面板交互，避免收起过程中点击落到子控件上
	_set_panel_interactive(skin_panel, false)
	_release_focus()
	_slide_panel(skin_panel_holder, SKIN_PANEL_CLOSED_LEFT, SKIN_PANEL_CLOSED_RIGHT, true)
	_schedule_shade_hide()
	if _allows_camera_preview() and original_camera_saved and gameplay_camera:
		_tween_camera_to_pose(original_camera_position, original_camera_rotation)

func _open_settings() -> void:
	if locked or _settings_open:
		return
	if _skin_open:
		_close_skin_panel()
	_settings_open = true
	_show_shade()
	settings_panel_holder.visible = true
	_set_panel_interactive(settings_panel, true)
	_release_focus()
	await get_tree().process_frame
	_slide_panel(settings_panel_holder, SETTINGS_PANEL_OPEN_LEFT, SETTINGS_PANEL_OPEN_RIGHT)

func _close_settings() -> void:
	if not _settings_open:
		return
	_settings_open = false
	_set_panel_interactive(settings_panel, false)
	_release_focus()
	_slide_panel(settings_panel_holder, SETTINGS_PANEL_CLOSED_LEFT, SETTINGS_PANEL_CLOSED_RIGHT, true)
	_schedule_shade_hide()

func _close_all() -> void:
	if _skin_open:
		_close_skin_panel()
	if _settings_open:
		_close_settings()

func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_close_all()
	elif event is InputEventScreenTouch and event.pressed:
		_close_all()

func _show_shade() -> void:
	shade.visible = true
	input_blocker.visible = true
	shade.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(shade, "modulate:a", 1.0, 0.22)

func _schedule_shade_hide() -> void:
	# 延迟到滑出动画结束再隐藏遮罩，防止收起过程中点击被面板控件拦截
	var tween: Tween = _panel_tweens.get(_closing_panel) as Tween
	if tween and tween.is_valid():
		tween.tween_callback(_hide_shade)
	else:
		_hide_shade()

func _hide_shade() -> void:
	if _skin_open or _settings_open:
		return
	input_blocker.visible = false
	var tween: Tween = create_tween()
	tween.tween_property(shade, "modulate:a", 0.0, 0.2)
	tween.tween_callback(shade.hide)

func _set_panel_interactive(panel: Control, interactive: bool) -> void:
	# 只把可交互控件设为 STOP，装饰控件（Label/TextureRect/ColorRect）保持 IGNORE，
	# 否则 Image 等全宽装饰会拦截点击，导致按钮收不到事件。
	var filter: int = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = filter
	for child: Node in panel.find_children("*", "Control", true, false):
		var control: Control = child as Control
		if not control:
			continue
		if child is Button or child is OptionButton or child is HSlider or child is Slider:
			control.mouse_filter = filter

func _slide_panel(holder: Control, target_left: float, target_right: float, hide_on_finish: bool = false) -> void:
	var existing: Tween = _panel_tweens.get(holder) as Tween
	if existing and existing.is_valid():
		existing.kill()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "offset_left", target_left, SLIDE_DURATION)
	tween.tween_property(holder, "offset_right", target_right, SLIDE_DURATION)
	if hide_on_finish:
		tween.tween_callback(_finish_panel_close.bind(holder))
	_panel_tweens[holder] = tween
	_closing_panel = holder if hide_on_finish else null

func _finish_panel_close(holder: Control) -> void:
	_panel_tweens.erase(holder)
	if _closing_panel == holder:
		_closing_panel = null
	holder.hide()

# === 相机预览 ===

func _allows_camera_preview() -> bool:
	var current_scene: Node = get_tree().current_scene
	if not is_instance_valid(current_scene):
		return false
	var stage_index: int = int(current_scene.get_meta(FIN_STAGE_ENTRY_META, PART1_STAGE_INDEX))
	return stage_index == PART1_STAGE_INDEX or stage_index == FULL_LEVEL_STAGE_INDEX

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

# === 皮肤选择 ===

func _select_classic() -> void:
	if not player or locked:
		return
	player.reset_henshin_state()
	_remove_godot_skin()
	current_skin = CLASSIC_SKIN
	_update_selection_visual()
	if _skin_open and _allows_camera_preview():
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
	_apply_godot_animation_config()
	if _skin_open and _allows_camera_preview():
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

func _on_turn_preview_toggled(button_pressed: bool) -> void:
	if godot_skin and is_instance_valid(godot_skin):
		godot_skin.enable_turn_anim = button_pressed

func _on_slide_preview_toggled(button_pressed: bool) -> void:
	if godot_skin and is_instance_valid(godot_skin):
		godot_skin.enable_slide_anim = button_pressed

func _update_selection_visual() -> void:
	var is_classic: bool = current_skin == CLASSIC_SKIN
	var preview_texture: Texture2D = load(CLASSIC_IMAGE if is_classic else GODOT_IMAGE) as Texture2D
	current_preview.texture = preview_texture
	current_name.text = ("经典" if is_chinese else "CLASSIC") if is_classic else "Godot"
	classic_selected_bar.visible = is_classic
	godot_selected_bar.visible = not is_classic
	action_row.visible = not is_classic

## 将 checkbox 的勾选状态同步到 GodotCharacter 的动画开关，控制游戏内转弯/滑铲是否播放动画。
func _apply_godot_animation_config() -> void:
	if godot_skin and is_instance_valid(godot_skin):
		godot_skin.enable_turn_anim = turn_preview_checkbox.button_pressed
		godot_skin.enable_slide_anim = slide_preview_checkbox.button_pressed

# === 设置 ===

func _load_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	is_chinese = str(config.get_value(UI_SECTION, "language", "zh")) != "en"
	var audio_settings: Dictionary = SetLatency.load_settings()
	_music_delay = float(audio_settings.get("delay", 0.0))
	_music_volume = float(audio_settings.get("volume", 1.0))
	GraphicsQuality.load_settings()
	volume_slider.set_value_no_signal(_music_volume)
	_update_setting_values()
	_update_turn_key_button()

func _populate_options() -> void:
	antialiasing_option.clear()
	for index: int in range(GraphicsQuality.ANTIALIASING_LABELS.size()):
		antialiasing_option.add_item(GraphicsQuality.ANTIALIASING_LABELS[index], index)
	antialiasing_option.select(GraphicsQuality.antialiasing)

func _save_language() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(UI_SECTION, "language", "zh" if is_chinese else "en")
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("SkinSelector.gd: failed to save language (%s)" % error_string(error))

func _toggle_language() -> void:
	is_chinese = not is_chinese
	_save_language()
	_apply_language()

func _on_antialiasing_selected(index: int) -> void:
	GraphicsQuality.antialiasing = index
	GraphicsQuality.apply_antialiasing(get_viewport())
	GraphicsQuality.save_settings()

func _on_volume_changed(value: float) -> void:
	_music_volume = value
	_apply_volume_to_player()
	SetLatency.save_settings(_music_delay, _music_volume)
	_update_setting_values()

func _apply_volume_to_player() -> void:
	if not player or not player.has_node("MusicPlayer"):
		return
	var music_player: AudioStreamPlayer = player.get_node("MusicPlayer") as AudioStreamPlayer
	if music_player.playing:
		music_player.volume_db = linear_to_db(max(_music_volume, 0.001))

func _on_latency_decrease() -> void:
	_set_music_delay(_music_delay - LATENCY_STEP)

func _on_latency_increase() -> void:
	_set_music_delay(_music_delay + LATENCY_STEP)

func _set_music_delay(value: float) -> void:
	_music_delay = clampf(value, LATENCY_MIN, LATENCY_MAX)
	if player:
		player.musicDelay = _music_delay
	SetLatency.save_settings(_music_delay, _music_volume)
	_update_setting_values()

# === turn 键位 ===

func _on_turn_key_button_pressed() -> void:
	if _recording_turn_key:
		return
	_recording_turn_key = true
	turn_key_value_button.text = _get_recording_hint()

## 删除最后一个绑定的键。若键列表和鼠标列表都非空，优先删除键盘键。
func _on_turn_key_remove_pressed() -> void:
	if _recording_turn_key:
		_recording_turn_key = false
		_update_turn_key_button()
		return
	if not _turn_keys.is_empty():
		_turn_keys.pop_back()
	elif not _turn_buttons.is_empty():
		_turn_buttons.pop_back()
	else:
		return
	_write_turn_key_to_input_map()
	_save_turn_key()
	_update_turn_key_button()
	_release_focus()

## 录制新键：追加到键列表，不覆盖已有键（多按键）。
func _apply_turn_key(key: int) -> void:
	_recording_turn_key = false
	if not _turn_keys.has(key):
		_turn_keys.append(key)
		_write_turn_key_to_input_map()
		_save_turn_key()
	_update_turn_key_button()
	_release_focus()

func _apply_turn_key_mouse(button: int) -> void:
	if button == MOUSE_BUTTON_NONE:
		return
	_recording_turn_key = false
	if not _turn_buttons.has(button):
		_turn_buttons.append(button)
		_write_turn_key_to_input_map()
		_save_turn_key()
	_update_turn_key_button()
	_release_focus()

func _write_turn_key_to_input_map() -> void:
	if not InputMap.has_action(TURN_ACTION):
		InputMap.add_action(TURN_ACTION)
	for existing: InputEvent in InputMap.action_get_events(TURN_ACTION):
		InputMap.action_erase_event(TURN_ACTION, existing)
	# 添加所有键盘键
	for keycode: int in _turn_keys:
		if keycode > 0:
			var key_event: InputEventKey = InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(TURN_ACTION, key_event)
	# 添加所有鼠标键
	for button_index: int in _turn_buttons:
		if button_index > 0:
			var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
			mouse_event.button_index = button_index
			InputMap.action_add_event(TURN_ACTION, mouse_event)

func _apply_turn_key_binding() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	_turn_keys.clear()
	_turn_buttons.clear()
	# 读取保存的键盘键列表（逗号分隔）
	var keys_str: String = str(config.get_value(INPUT_SECTION, "turn_keys", ""))
	if not keys_str.is_empty():
		for part: String in keys_str.split(",", false):
			var code: int = int(part)
			if code > 0 and not _turn_keys.has(code):
				_turn_keys.append(code)
	# 读取保存的鼠标按钮列表（逗号分隔）
	var mouse_str: String = str(config.get_value(INPUT_SECTION, "turn_mouse", ""))
	if not mouse_str.is_empty():
		for part: String in mouse_str.split(",", false):
			var idx: int = int(part)
			if idx > 0 and not _turn_buttons.has(idx):
				_turn_buttons.append(idx)
	# 若没有任何保存的绑定，添加默认键（Space）
	if _turn_keys.is_empty() and _turn_buttons.is_empty():
		_turn_keys.append(DEFAULT_TURN_KEY)
		_turn_buttons.append(MOUSE_BUTTON_LEFT)
	_write_turn_key_to_input_map()
	_update_turn_key_button()

func _save_turn_key() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(INPUT_SECTION, "turn_keys", ",".join(_turn_keys.map(func(v): return str(v))))
	config.set_value(INPUT_SECTION, "turn_mouse", ",".join(_turn_buttons.map(func(v): return str(v))))
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("SkinSelector.gd: failed to save turn key (%s)" % error_string(error))

func _update_turn_key_button() -> void:
	if _recording_turn_key:
		turn_key_value_button.text = _get_recording_hint()
		return
	turn_key_value_button.text = _get_turn_key_display_name()

func _get_recording_hint() -> String:
	return "按任意键…" if is_chinese else "PRESS ANY KEY…"

func _get_turn_key_display_name() -> String:
	var names: PackedStringArray = []
	for keycode: int in _turn_keys:
		var name: String = OS.get_keycode_string(keycode)
		if not name.is_empty():
			names.append(name)
	for button_index: int in _turn_buttons:
		match button_index:
			MOUSE_BUTTON_LEFT:
				names.append("鼠标左键" if is_chinese else "LMB")
			MOUSE_BUTTON_RIGHT:
				names.append("鼠标右键" if is_chinese else "RMB")
			MOUSE_BUTTON_MIDDLE:
				names.append("鼠标中键" if is_chinese else "MMB")
			_:
				names.append("M%d" % button_index)
	if names.is_empty():
		return "未绑定" if is_chinese else "UNBOUND"
	return " / ".join(names)

func _update_setting_values() -> void:
	volume_value.text = "%d%%" % roundi(_music_volume * 100.0)
	latency_value.text = "%+d ms" % roundi(_music_delay * 1000.0)

# === 语言 ===

func _apply_language() -> void:
	skin_title.text = "皮肤" if is_chinese else "SKINS"
	skin_subtitle.text = "游戏开始前" if is_chinese else "BEFORE START"
	skin_close_button.text = "关闭" if is_chinese else "CLOSE"
	skin_entry_button.text = "皮肤" if is_chinese else "SKINS"
	skin_entry_button.tooltip_text = "打开皮肤选择" if is_chinese else "OPEN SKIN SELECTOR"
	gear_button.tooltip_text = "设置" if is_chinese else "SETTINGS"
	current_caption.text = "当前使用" if is_chinese else "CURRENT"
	options_title.text = "选择角色外观" if is_chinese else "CHOOSE A SKIN"
	classic_name.text = "经典" if is_chinese else "CLASSIC"
	classic_detail.text = "原始角色" if is_chinese else "ORIGINAL FORM"
	godot_detail.text = "低多边形角色" if is_chinese else "LOW-POLY FORM"
	turn_preview_checkbox.text = "转弯动画" if is_chinese else "TURN"
	turn_preview_checkbox.tooltip_text = "预览转弯动画" if is_chinese else "PREVIEW TURN"
	slide_preview_checkbox.text = "滑铲动画" if is_chinese else "SLIDE"
	slide_preview_checkbox.tooltip_text = "预览滑铲动画" if is_chinese else "PREVIEW SLIDE"
	bottom_hint.text = "点击面板外区域关闭" if is_chinese else "CLICK OUTSIDE TO CLOSE"
	classic_button.tooltip_text = "选择经典皮肤" if is_chinese else "SELECT CLASSIC SKIN"
	godot_button.tooltip_text = "选择 Godot 皮肤" if is_chinese else "SELECT GODOT SKIN"
	settings_title.text = "设置" if is_chinese else "SETTINGS"
	settings_close_button.text = "关闭" if is_chinese else "CLOSE"
	settings_intro.text = "调整音画同步。改动会立即保存。" if is_chinese else "TUNE AUDIO SYNC. CHANGES SAVE IMMEDIATELY."
	language_label.text = "语言" if is_chinese else "LANGUAGE"
	language_value_button.text = "中文" if is_chinese else "ENGLISH"
	antialiasing_label.text = "抗锯齿" if is_chinese else "ANTI-ALIASING"
	volume_title.text = "音量" if is_chinese else "VOLUME"
	latency_title.text = "音画延迟" if is_chinese else "AUDIO DELAY"
	turn_key_label.text = "转向键" if is_chinese else "TURN KEY"
	turn_key_value_button.tooltip_text = "点击后按新键绑定" if is_chinese else "CLICK THEN PRESS A KEY TO REBIND"
	settings_note.text = "ESC 可关闭面板" if is_chinese else "PRESS ESC TO CLOSE"
	_update_selection_visual()
	_update_turn_key_button()

func _lock_selection() -> void:
	locked = true
	_recording_turn_key = false
	_skin_open = false
	_settings_open = false
	skin_panel_holder.visible = false
	settings_panel_holder.visible = false
	input_blocker.visible = false
	shade.visible = false
	_release_focus()
	for panel_tween: Tween in _panel_tweens.values():
		if panel_tween and panel_tween.is_valid():
			panel_tween.kill()
	_panel_tweens.clear()
	_closing_panel = null
	hide()
