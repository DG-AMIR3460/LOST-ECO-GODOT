extends MenuState
## Estado del menú de opciones (audio, pantalla, accesibilidad).

var _connections: Array = []
var _machine: Node
var _context: Control

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton
var _resolution_option: OptionButton
var _apply_resolution_button: Button
var _colorblind_option: OptionButton
var _back_button: Button


func get_state_name() -> String:
	return "OptionsMenuState"


func enter(context: Control, machine: Node) -> void:
	_context = context
	_machine = machine
	_cache_nodes(context)
	_setup_resolution_options()
	_setup_colorblind_options()
	_load_current_values()
	_connect_signals()
	MenuHelpers.prepare_menu_button(_back_button)
	MenuHelpers.prepare_menu_button(_apply_resolution_button)
	MenuHelpers.apply_menu_entry_presentation()


func exit(_context: Control, _machine: Node) -> void:
	MenuHelpers.disconnect_all(_connections)
	_context = null
	_machine = null


func _cache_nodes(context: Control) -> void:
	_master_slider = context.get_node("%MasterSlider") as HSlider
	_music_slider = context.get_node("%MusicSlider") as HSlider
	_sfx_slider = context.get_node("%SfxSlider") as HSlider
	_fullscreen_check = context.get_node("%FullscreenCheck") as CheckButton
	_resolution_option = context.get_node("%ResolutionOption") as OptionButton
	_apply_resolution_button = context.get_node("%ApplyResolutionButton") as Button
	_colorblind_option = context.get_node("%ColorblindOption") as OptionButton
	_back_button = context.get_node("%BackButton") as Button


func _setup_resolution_options() -> void:
	_resolution_option.clear()
	for i in SettingsManager.RESOLUTIONS.size():
		_resolution_option.add_item(SettingsManager.get_resolution_label(i), i)


func _setup_colorblind_options() -> void:
	_colorblind_option.clear()
	_colorblind_option.add_item("Normal", SettingsManager.ColorblindMode.NORMAL)
	_colorblind_option.add_item("Protanopia", SettingsManager.ColorblindMode.PROTANOPIA)
	_colorblind_option.add_item("Deuteranopia", SettingsManager.ColorblindMode.DEUTERANOPIA)
	_colorblind_option.add_item("Tritanopia", SettingsManager.ColorblindMode.TRITANOPIA)


func _load_current_values() -> void:
	_master_slider.value = SettingsManager.master_volume
	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value = SettingsManager.sfx_volume
	_fullscreen_check.button_pressed = SettingsManager.fullscreen
	_resolution_option.select(SettingsManager.resolution_index)
	_colorblind_option.select(_get_colorblind_index(SettingsManager.colorblind_mode))
	_update_resolution_control_state()


func _update_resolution_control_state() -> void:
	var windowed := not SettingsManager.fullscreen
	_resolution_option.disabled = not windowed
	_apply_resolution_button.disabled = not windowed


func _connect_signals() -> void:
	MenuHelpers.track_connection(_connections, _master_slider, "value_changed", _on_master_changed)
	MenuHelpers.track_connection(_connections, _music_slider, "value_changed", _on_music_changed)
	MenuHelpers.track_connection(_connections, _sfx_slider, "value_changed", _on_sfx_changed)
	MenuHelpers.track_connection(_connections, _fullscreen_check, "toggled", _on_fullscreen_toggled)
	MenuHelpers.track_connection(_connections, _apply_resolution_button, "pressed", _on_apply_resolution_pressed)
	MenuHelpers.track_connection(_connections, _colorblind_option, "item_selected", _on_colorblind_selected)
	MenuHelpers.track_connection(_connections, _back_button, "pressed", _on_back_pressed)


func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	SettingsManager.save_settings()


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	SettingsManager.save_settings()


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	SettingsManager.save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)
	SettingsManager.save_settings()
	_sync_fullscreen_ui()


func _sync_fullscreen_ui() -> void:
	_fullscreen_check.set_block_signals(true)
	_fullscreen_check.button_pressed = SettingsManager.fullscreen
	_fullscreen_check.set_block_signals(false)
	_update_resolution_control_state()


func _on_apply_resolution_pressed() -> void:
	if SettingsManager.fullscreen:
		return

	var selected_index := _resolution_option.get_selected_id()
	if selected_index < 0:
		selected_index = _resolution_option.selected

	SettingsManager.set_resolution_index(selected_index)
	SettingsManager.save_settings()


func _on_colorblind_selected(index: int) -> void:
	var mode_id := _colorblind_option.get_item_id(index)
	SettingsManager.set_colorblind_mode(mode_id)
	SettingsManager.save_settings()


func _on_back_pressed() -> void:
	if _machine:
		_machine.transition_to_main()


func _get_colorblind_index(mode: SettingsManager.ColorblindMode) -> int:
	for i in _colorblind_option.item_count:
		if _colorblind_option.get_item_id(i) == mode:
			return i
	return 0
