extends Control

const SETTINGS_PATH: String = "user://settings.cfg"
const UI_SECTION: String = "ui"
const PROGRESS_SECTION: String = "progress"
const UNLOCKED_STAGE_COUNT_KEY: String = "unlocked_stage_count"
const FULL_MODE_UNLOCKED_KEY: String = "full_mode_unlocked"
const STAGE_COUNT: int = 4
const FIN_SCENE_PATH: String = "res://[Scenes]/Fin/Fin.tscn"
const FIN_STAGE_ENTRY_META: StringName = &"fin_stage_entry"
const FULL_LEVEL_JUST_UNLOCKED_META: StringName = &"full_level_just_unlocked"
const STAGE_SCENE_PATHS: Array[String] = [
	FIN_SCENE_PATH,
	FIN_SCENE_PATH,
	FIN_SCENE_PATH,
	FIN_SCENE_PATH,
]

const STAGE_TITLES_ZH: Array[String] = ["初滞", "回声", "终章", "回声之境"]
const STAGE_TITLES_EN: Array[String] = ["FIRST DELAY", "THE ECHO", "GENTLE ARRIVAL", "ECHO REALM"]
const STAGE_SUBTITLES_ZH: Array[String] = ["暖黄峡谷", "灰蓝山谷", "镜面回廊", "完整关卡"]
const STAGE_SUBTITLES_EN: Array[String] = ["AMBER CANYON", "BLUE VALLEY", "MIRROR CORRIDOR", "FULL EXPERIENCE"]
const STAGE_DESCRIPTIONS_ZH: Array[String] = [
	"世界开始变慢，你还没意识到。",
	"那些你以为已经过去的，正在追上你。",
	"你以为已经抵达，但真正的答案还在更远处。",
	"迟到的温柔，终于抵达。",
]
const STAGE_DESCRIPTIONS_EN: Array[String] = [
	"The world begins to slow before you notice.",
	"What you thought was gone is catching up.",
	"You thought you had arrived, but the answer waits farther on.",
	"The tenderness that arrived late is finally here.",
]
const LATENCY_MIN: float = -5.0
const LATENCY_MAX: float = 5.0
const LATENCY_STEP: float = 0.01
const MENU_MUSIC_FADE_DURATION: float = 0.45
const INPUT_SECTION: String = "input"
const TURN_ACTION: StringName = &"turn"
const DEFAULT_TURN_KEY: Key = KEY_SPACE

@onready var backdrop: Control = $Backdrop
@onready var home_screen: Control = $SafeMargin/Layout/ScreenArea/HomeScreen
@onready var chapter_screen: Control = $SafeMargin/Layout/ScreenArea/ChapterScreen
@onready var home_content: VBoxContainer = $SafeMargin/Layout/ScreenArea/HomeScreen/HomeContent
@onready var chapter_content: VBoxContainer = $SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent
@onready var chapters_button: Button = $SafeMargin/Layout/TopBar/ChaptersButton
@onready var language_button: Button = $SafeMargin/Layout/TopBar/LanguageButton
@onready var settings_button: Button = $SafeMargin/Layout/TopBar/SettingsButton
@onready var explore_button: Button = $SafeMargin/Layout/ScreenArea/HomeScreen/HomeContent/Actions/ExploreButton
@onready var quick_start_button: Button = $SafeMargin/Layout/ScreenArea/HomeScreen/HomeContent/Actions/QuickStartButton
@onready var back_button: Button = $SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/HeadingRow/BackButton
@onready var launch_button: Button = $SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/SelectionPanel/SelectionMargin/SelectionRow/LaunchButton
@onready var selected_index_label: Label = $SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/SelectionPanel/SelectionMargin/SelectionRow/Copy/SelectedIndex
@onready var selected_title_label: Label = $SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/SelectionPanel/SelectionMargin/SelectionRow/Copy/SelectedTitle
@onready var selected_description_label: Label = $SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/SelectionPanel/SelectionMargin/SelectionRow/Copy/SelectedDescription
@onready var carousel: Control = $SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/MirrorCarousel
@onready var settings_shade: ColorRect = $SettingsShade
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_title: Label = $SettingsPanel/PanelMargin/SettingsContent/Header/SettingsTitle
@onready var settings_close_button: Button = $SettingsPanel/PanelMargin/SettingsContent/Header/CloseButton
@onready var settings_intro: Label = $SettingsPanel/PanelMargin/SettingsContent/SettingsIntro
@onready var language_value_button: Button = $SettingsPanel/PanelMargin/SettingsContent/LanguageRow/LanguageValue
@onready var antialiasing_label: Label = $SettingsPanel/PanelMargin/SettingsContent/AntiAliasingRow/AntiAliasingLabel
@onready var antialiasing_option: OptionButton = $SettingsPanel/PanelMargin/SettingsContent/AntiAliasingRow/AntiAliasingOption
@onready var volume_title: Label = $SettingsPanel/PanelMargin/SettingsContent/VolumeBlock/VolumeHeader/VolumeTitle
@onready var volume_value: Label = $SettingsPanel/PanelMargin/SettingsContent/VolumeBlock/VolumeHeader/VolumeValue
@onready var volume_slider: HSlider = $SettingsPanel/PanelMargin/SettingsContent/VolumeBlock/VolumeSlider
@onready var latency_title: Label = $SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyHeader/LatencyTitle
@onready var latency_value: Label = $SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyHeader/LatencyValue
@onready var latency_arrow_left: Button = $SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyControls/LatencyArrowLeft
@onready var latency_arrow_right: Button = $SettingsPanel/PanelMargin/SettingsContent/LatencyBlock/LatencyControls/LatencyArrowRight
@onready var turn_key_label: Label = $SettingsPanel/PanelMargin/SettingsContent/TurnKeyRow/TurnKeyLabel
@onready var turn_key_value_button: Button = $SettingsPanel/PanelMargin/SettingsContent/TurnKeyRow/TurnKeyValue
@onready var turn_key_remove_button: Button = $SettingsPanel/PanelMargin/SettingsContent/TurnKeyRow/TurnKeyRemove
@onready var settings_note: Label = $SettingsPanel/PanelMargin/SettingsContent/SettingsNote
@onready var transition_layer: ColorRect = $TransitionLayer
@onready var status_label: Label = $StatusLabel
@onready var menu_music: AudioStreamPlayer = $MenuMusic

var _is_chinese: bool = true
var _selected_stage: int = 0
var _music_delay: float = 0.0
var _music_volume: float = 1.0
var _settings_open: bool = false
var _launching: bool = false
var _unlocked_stage_count: int = 1
var _full_mode_unlocked: bool = false
var _music_tween: Tween
var _music_request: int = 0
var _recording_turn_key: bool = false
var _turn_keys: Array[int] = [DEFAULT_TURN_KEY]
var _turn_buttons: Array[int] = [MOUSE_BUTTON_LEFT]

func _ready() -> void:
	_load_preferences()
	_connect_controls()
	_populate_options()
	_apply_language()
	var full_level_just_unlocked: bool = get_tree().root.has_meta(FULL_LEVEL_JUST_UNLOCKED_META)
	if full_level_just_unlocked:
		get_tree().root.remove_meta(FULL_LEVEL_JUST_UNLOCKED_META)
	carousel.call("set_full_mode_unlocked", _is_stage_unlocked(STAGE_COUNT - 1) and not full_level_just_unlocked)
	_select_stage(0)
	chapter_screen.visible = false
	settings_shade.visible = false
	settings_panel.visible = false
	transition_layer.visible = false
	status_label.visible = false
	await get_tree().process_frame
	_animate_intro()
	if full_level_just_unlocked:
		await _play_full_level_unlock()

func _play_full_level_unlock() -> void:
	chapter_screen.visible = true
	home_screen.visible = false
	_selected_stage = STAGE_COUNT - 1
	if backdrop.has_method("set_stage"):
		backdrop.call("set_stage", _selected_stage)
	carousel.call("set_selected", _selected_stage, false)
	_update_selected_stage_copy()
	_sync_menu_music(true)
	await carousel.call("play_unlock")
	_update_carousel_copy()
	_update_selected_stage_copy()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _recording_turn_key:
			_recording_turn_key = false
			_update_turn_key_button()
			_release_settings_focus()
			return
		if _settings_open:
			_close_settings()
		elif chapter_screen.visible:
			_show_home()
		return
	if _recording_turn_key:
		if event is InputEventKey and event.pressed and not event.echo:
			_apply_turn_key(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
		elif event is InputEventMouseButton and event.pressed:
			_apply_turn_key_mouse(event.button_index)

func _connect_controls() -> void:
	chapters_button.pressed.connect(_show_chapters)
	language_button.pressed.connect(_toggle_language)
	settings_button.pressed.connect(_open_settings)
	explore_button.pressed.connect(_show_chapters)
	quick_start_button.pressed.connect(_launch_latest_unlocked_stage)
	back_button.pressed.connect(_show_home)
	launch_button.pressed.connect(_launch_selected_stage)
	settings_close_button.pressed.connect(_close_settings)
	settings_shade.gui_input.connect(_on_settings_shade_input)
	language_value_button.pressed.connect(_toggle_language)
	antialiasing_option.item_selected.connect(_on_antialiasing_selected)
	volume_slider.value_changed.connect(_on_volume_changed)
	latency_arrow_left.pressed.connect(_on_latency_decrease)
	latency_arrow_right.pressed.connect(_on_latency_increase)
	turn_key_value_button.pressed.connect(_on_turn_key_button_pressed)
	turn_key_remove_button.pressed.connect(_on_turn_key_remove_pressed)
	carousel.connect("stage_selected", _select_stage)
	_apply_turn_key_binding()
	_set_settings_buttons_focus_none()

func _load_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	_is_chinese = str(config.get_value(UI_SECTION, "language", "zh")) != "en"
	_full_mode_unlocked = bool(config.get_value(PROGRESS_SECTION, FULL_MODE_UNLOCKED_KEY, false))
	_unlocked_stage_count = clampi(int(config.get_value(
		PROGRESS_SECTION,
		UNLOCKED_STAGE_COUNT_KEY,
		1
	)), 1, STAGE_COUNT)
	var audio_settings: Dictionary = SetLatency.load_settings()
	_music_delay = float(audio_settings.get("delay", 0.0))
	_music_volume = float(audio_settings.get("volume", 1.0))
	volume_slider.set_value_no_signal(_music_volume)

func _save_language() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(UI_SECTION, "language", "zh" if _is_chinese else "en")
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("MainMenu.gd: failed to save language (%s)" % error_string(error))

func _populate_options() -> void:
	antialiasing_option.clear()
	for index: int in range(4):
		antialiasing_option.add_item(GraphicsQuality.ANTIALIASING_LABELS[index], index)
	antialiasing_option.select(GraphicsQuality.antialiasing)

func _toggle_language() -> void:
	_is_chinese = not _is_chinese
	_save_language()
	_apply_language()

func _apply_language() -> void:
	$SafeMargin/Layout/TopBar/Brand/BrandTitle.text = "弄影" if _is_chinese else "AFTERIMAGE"
	chapters_button.text = "章节" if _is_chinese else "CHAPTERS"
	language_button.text = "EN" if _is_chinese else "中文"
	settings_button.text = "设置" if _is_chinese else "SETTINGS"
	$SafeMargin/Layout/ScreenArea/HomeScreen/HomeContent/Kicker.text = "一段关于时间、记忆与错过的旅程" if _is_chinese else "A JOURNEY THROUGH TIME, MEMORY, AND WHAT WE MISS"
	$SafeMargin/Layout/ScreenArea/HomeScreen/HomeContent/Title.text = "追上那个\n迟到的自己" if _is_chinese else "CATCH UP WITH\nTHE SELF BEHIND YOU"
	explore_button.text = "选择章节" if _is_chinese else "SELECT CHAPTER"
	quick_start_button.text = "继续你的回响" if _is_chinese else "CONTINUE YOUR ECHO"
	back_button.text = "返回" if _is_chinese else "BACK"
	$SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/HeadingRow/HeadingCopy/ChapterKicker.text = "四段尚未抵达的路" if _is_chinese else "FOUR ROADS NOT YET ARRIVED"
	$SafeMargin/Layout/ScreenArea/ChapterScreen/ChapterContent/HeadingRow/HeadingCopy/ChapterTitle.text = "选择你要进入的回声" if _is_chinese else "CHOOSE THE ECHO TO ENTER"
	settings_title.text = "设置" if _is_chinese else "SETTINGS"
	settings_close_button.text = "关闭" if _is_chinese else "CLOSE"
	settings_intro.text = "调整音画同步。改动会立即保存。" if _is_chinese else "TUNE AUDIO SYNC. CHANGES SAVE IMMEDIATELY."
	$SettingsPanel/PanelMargin/SettingsContent/LanguageRow/LanguageLabel.text = "语言" if _is_chinese else "LANGUAGE"
	language_value_button.text = "中文" if _is_chinese else "ENGLISH"
	antialiasing_label.text = "抗锯齿" if _is_chinese else "ANTI-ALIASING"
	volume_title.text = "音量" if _is_chinese else "VOLUME"
	latency_title.text = "音画延迟" if _is_chinese else "AUDIO DELAY"
	turn_key_label.text = "转向键" if _is_chinese else "TURN KEY"
	turn_key_value_button.tooltip_text = "点击后按新键绑定" if _is_chinese else "CLICK THEN PRESS A KEY TO REBIND"
	settings_note.text = "ESC 可关闭面板" if _is_chinese else "PRESS ESC TO CLOSE"
	_update_carousel_copy()
	_update_selected_stage_copy()
	_update_setting_values()
	_update_turn_key_button()

func _animate_intro() -> void:
	home_content.modulate.a = 0.0
	home_content.position.y += 24.0
	$SafeMargin/Layout/TopBar.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(home_content, "modulate:a", 1.0, 0.7).set_delay(0.12)
	tween.tween_property(home_content, "position:y", home_content.position.y - 24.0, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($SafeMargin/Layout/TopBar, "modulate:a", 1.0, 0.45)

func _show_home() -> void:
	if _launching or home_screen.visible:
		return
	_switch_screen(chapter_screen, home_screen, home_content)

func _show_chapters() -> void:
	if _launching or chapter_screen.visible:
		return
	_switch_screen(home_screen, chapter_screen, chapter_content)

func _switch_screen(from_screen: Control, to_screen: Control, _to_content: Control) -> void:
	var fade_out: Tween = create_tween()
	fade_out.tween_property(from_screen, "modulate:a", 0.0, 0.18)
	await fade_out.finished
	from_screen.visible = false
	from_screen.modulate.a = 1.0
	to_screen.visible = true
	to_screen.modulate.a = 0.0
	var fade_in: Tween = create_tween()
	fade_in.tween_property(to_screen, "modulate:a", 1.0, 0.3)

func _select_stage(index: int) -> void:
	_selected_stage = clampi(index, 0, STAGE_COUNT - 1)
	if backdrop.has_method("set_stage"):
		backdrop.call("set_stage", _selected_stage)
	carousel.call("set_selected", _selected_stage)
	_update_selected_stage_copy()
	_sync_menu_music()

func _sync_menu_music(force_unlock_music: bool = false) -> void:
	var target_stream: AudioStream = preload("res://[Scenes]/Begin.ogg")
	if force_unlock_music or (_selected_stage == STAGE_COUNT - 1 and _is_stage_unlocked(_selected_stage)):
		target_stream = preload("res://[Scenes]/Unlock.ogg")
	_music_request += 1
	_play_menu_music(target_stream, _music_request)

func _play_menu_music(target_stream: AudioStream, request: int) -> void:
	if menu_music.stream == target_stream and menu_music.playing:
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	if menu_music.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(menu_music, "volume_db", linear_to_db(0.001), MENU_MUSIC_FADE_DURATION)
		await _music_tween.finished
		if request != _music_request:
			return
	menu_music.stop()
	menu_music.stream = target_stream
	if target_stream is AudioStreamOggVorbis:
		(target_stream as AudioStreamOggVorbis).loop = true
	menu_music.volume_db = linear_to_db(0.001)
	menu_music.play()
	_music_tween = create_tween()
	_music_tween.tween_property(menu_music, "volume_db", linear_to_db(max(_music_volume, 0.001)), MENU_MUSIC_FADE_DURATION)

func _fade_out_menu_music() -> void:
	if not menu_music.playing:
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(menu_music, "volume_db", linear_to_db(0.001), MENU_MUSIC_FADE_DURATION)

func _update_carousel_copy() -> void:
	var titles: Array[String] = STAGE_TITLES_ZH if _is_chinese else STAGE_TITLES_EN
	var subtitles: Array[String] = STAGE_SUBTITLES_ZH if _is_chinese else STAGE_SUBTITLES_EN
	var statuses: Array[String] = []
	for index: int in range(STAGE_COUNT):
		var status: String = "可进入" if _is_chinese else "PLAYABLE"
		if not _is_stage_unlocked(index):
			status = "通过上一段解锁" if _is_chinese else "COMPLETE THE PREVIOUS PART"
		elif index == STAGE_COUNT - 1:
			if _full_mode_unlocked:
				status = "完整内容已解锁" if _is_chinese else "FULL EXPERIENCE UNLOCKED"
			else:
				status = "回声之境已解锁" if _is_chinese else "ECHO REALM UNLOCKED"
		statuses.append(status)
	carousel.call("configure_copy", titles, subtitles, statuses)

func _update_selected_stage_copy() -> void:
	var titles: Array[String] = STAGE_TITLES_ZH if _is_chinese else STAGE_TITLES_EN
	var descriptions: Array[String] = STAGE_DESCRIPTIONS_ZH if _is_chinese else STAGE_DESCRIPTIONS_EN
	selected_index_label.text = ("回响 %02d" if _is_chinese else "ECHO %02d") % (_selected_stage + 1)
	selected_title_label.text = titles[_selected_stage]
	selected_description_label.text = descriptions[_selected_stage]
	var scene_path: String = _get_stage_scene_path(_selected_stage)
	var scene_available: bool = not scene_path.is_empty()
	var stage_unlocked: bool = _is_stage_unlocked(_selected_stage)
	launch_button.disabled = not scene_available or not stage_unlocked
	if scene_available and stage_unlocked:
		launch_button.text = "进入场景" if _is_chinese else "ENTER SCENE"
	elif not stage_unlocked:
		launch_button.text = "尚未解锁" if _is_chinese else "LOCKED"
	else:
		launch_button.text = "制作中" if _is_chinese else "COMING SOON"

func _open_settings() -> void:
	if _settings_open or _launching:
		return
	_settings_open = true
	settings_shade.visible = true
	settings_panel.visible = true
	settings_shade.modulate.a = 0.0
	settings_panel.modulate.a = 0.0
	_release_settings_focus()
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(settings_shade, "modulate:a", 1.0, 0.22)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.28)

func _close_settings() -> void:
	if not _settings_open:
		return
	_settings_open = false
	_release_settings_focus()
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(settings_shade, "modulate:a", 0.0, 0.2)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	settings_shade.visible = false
	settings_panel.visible = false

func _on_settings_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_settings()

func _on_antialiasing_selected(index: int) -> void:
	GraphicsQuality.antialiasing = index
	GraphicsQuality.apply_antialiasing(get_viewport())
	GraphicsQuality.save_settings()

func _on_volume_changed(value: float) -> void:
	_music_volume = value
	SetLatency.save_settings(_music_delay, _music_volume)
	if menu_music.playing:
		menu_music.volume_db = linear_to_db(max(_music_volume, 0.001))
	_update_setting_values()

func _on_latency_decrease() -> void:
	_set_music_delay(_music_delay - LATENCY_STEP)

func _on_latency_increase() -> void:
	_set_music_delay(_music_delay + LATENCY_STEP)

func _set_music_delay(value: float) -> void:
	_music_delay = clampf(value, LATENCY_MIN, LATENCY_MAX)
	SetLatency.save_settings(_music_delay, _music_volume)
	_update_setting_values()

func _update_setting_values() -> void:
	volume_value.text = "%d%%" % roundi(_music_volume * 100.0)
	latency_value.text = "%+d ms" % roundi(_music_delay * 1000.0)

# === turn 键位 ===

func _on_turn_key_button_pressed() -> void:
	if _recording_turn_key:
		return
	_recording_turn_key = true
	turn_key_value_button.text = _get_recording_hint()

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
	_release_settings_focus()

func _apply_turn_key(key: int) -> void:
	_recording_turn_key = false
	if not _turn_keys.has(key):
		_turn_keys.append(key)
		_write_turn_key_to_input_map()
		_save_turn_key()
	_update_turn_key_button()
	_release_settings_focus()

func _apply_turn_key_mouse(button: int) -> void:
	if button == MOUSE_BUTTON_NONE:
		return
	_recording_turn_key = false
	if not _turn_buttons.has(button):
		_turn_buttons.append(button)
		_write_turn_key_to_input_map()
		_save_turn_key()
	_update_turn_key_button()
	_release_settings_focus()

func _set_settings_buttons_focus_none() -> void:
	for child: Node in settings_panel.find_children("*", "Button", true, false):
		var button: Button = child as Button
		if button:
			button.focus_mode = Control.FOCUS_NONE

func _release_settings_focus() -> void:
	if settings_panel.has_focus():
		settings_panel.release_focus()
	get_viewport().gui_release_focus()

func _write_turn_key_to_input_map() -> void:
	if not InputMap.has_action(TURN_ACTION):
		InputMap.add_action(TURN_ACTION)
	for existing: InputEvent in InputMap.action_get_events(TURN_ACTION):
		InputMap.action_erase_event(TURN_ACTION, existing)
	for keycode: int in _turn_keys:
		if keycode > 0:
			var key_event: InputEventKey = InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(TURN_ACTION, key_event)
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
	var keys_str: String = str(config.get_value(INPUT_SECTION, "turn_keys", ""))
	if not keys_str.is_empty():
		for part: String in keys_str.split(",", false):
			var code: int = int(part)
			if code > 0 and not _turn_keys.has(code):
				_turn_keys.append(code)
	var mouse_str: String = str(config.get_value(INPUT_SECTION, "turn_mouse", ""))
	if not mouse_str.is_empty():
		for part: String in mouse_str.split(",", false):
			var idx: int = int(part)
			if idx > 0 and not _turn_buttons.has(idx):
				_turn_buttons.append(idx)
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
		push_error("MainMenu.gd: failed to save turn key (%s)" % error_string(error))

func _update_turn_key_button() -> void:
	if _recording_turn_key:
		turn_key_value_button.text = _get_recording_hint()
		return
	turn_key_value_button.text = _get_turn_key_display_name()

func _get_recording_hint() -> String:
	return "按任意键…" if _is_chinese else "PRESS ANY KEY…"

func _get_turn_key_display_name() -> String:
	var names: PackedStringArray = []
	for keycode: int in _turn_keys:
		var name: String = OS.get_keycode_string(keycode)
		if not name.is_empty():
			names.append(name)
	for button_index: int in _turn_buttons:
		match button_index:
			MOUSE_BUTTON_LEFT:
				names.append("鼠标左键" if _is_chinese else "LMB")
			MOUSE_BUTTON_RIGHT:
				names.append("鼠标右键" if _is_chinese else "RMB")
			MOUSE_BUTTON_MIDDLE:
				names.append("鼠标中键" if _is_chinese else "MMB")
			_:
				names.append("M%d" % button_index)
	if names.is_empty():
		return "未绑定" if _is_chinese else "UNBOUND"
	return " / ".join(names)

func _launch_selected_stage() -> void:
	_launch_stage(_selected_stage)

func _launch_latest_unlocked_stage() -> void:
	_launch_stage(_unlocked_stage_count - 1)

func _is_stage_unlocked(index: int) -> bool:
	return index >= 0 and index < _unlocked_stage_count

func _get_stage_scene_path(index: int) -> String:
	if index < 0 or index >= STAGE_SCENE_PATHS.size():
		return ""
	return STAGE_SCENE_PATHS[index]

func _launch_stage(index: int) -> void:
	if _launching or index < 0 or index >= STAGE_SCENE_PATHS.size() or not _is_stage_unlocked(index):
		return
	var scene_path: String = _get_stage_scene_path(index)
	if scene_path.is_empty():
		return
	_launching = true
	carousel.call("set_focus", true)
	_fade_out_menu_music()
	status_label.text = "正在进入回声…" if _is_chinese else "ENTERING THE ECHO..."
	status_label.visible = true
	status_label.modulate.a = 0.0
	transition_layer.visible = true
	transition_layer.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(status_label, "modulate:a", 1.0, 0.25).set_delay(0.2)
	tween.tween_property(transition_layer, "modulate:a", 1.0, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	get_tree().root.set_meta("menu_launch_pending", true)
	get_tree().root.set_meta(FIN_STAGE_ENTRY_META, index)
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		get_tree().root.remove_meta("menu_launch_pending")
		get_tree().root.remove_meta(FIN_STAGE_ENTRY_META)
		_launching = false
		transition_layer.visible = false
		status_label.text = "场景加载失败：%s" % error_string(error) if _is_chinese else "SCENE LOAD FAILED: %s" % error_string(error)
