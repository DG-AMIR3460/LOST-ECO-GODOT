extends MenuState
## Estado del menú principal (Jugar, Opciones, Salir).

const BUTTON_ACTIONS := {
	"jugar": "play",
	"play": "play",
	"elpantano": "demo",
	"pantano": "demo",
	"demo": "demo",
	"opciones": "options",
	"options": "options",
	"salir": "quit",
	"quit": "quit",
	"exit": "quit",
}

var _connections: Array = []
var _machine: Node
var _context: Control
var _main_buttons: Control
var _play_panel: Control
var _difficulty_option: OptionButton


func get_state_name() -> String:
	return "MainMenuState"


func enter(context: Control, machine: Node) -> void:
	_context = context
	_machine = machine
	_cache_nodes(context)
	_setup_difficulty_options()
	_hide_play_setup()
	MenuHelpers.apply_menu_entry_presentation()
	_connect_buttons(context)
	_connect_play_panel()


func exit(_context: Control, _machine_ref: Node) -> void:
	MenuHelpers.disconnect_all(_connections)
	_hide_play_setup()
	_context = null
	_machine = null


func _cache_nodes(context: Control) -> void:
	_main_buttons = context.get_node_or_null("Buttons") as Control
	_play_panel = context.get_node_or_null("PlaySetupPanel") as Control
	_difficulty_option = context.get_node_or_null("%PlayDifficultyOption") as OptionButton


func _setup_difficulty_options() -> void:
	if _difficulty_option == null:
		return
	_difficulty_option.clear()
	_difficulty_option.add_item("Fácil", SettingsManager.Difficulty.FACIL)
	_difficulty_option.add_item("Normal", SettingsManager.Difficulty.NORMAL)
	_difficulty_option.add_item("Difícil", SettingsManager.Difficulty.DIFICIL)
	_difficulty_option.select(_get_difficulty_index(SettingsManager.difficulty_index))


func _connect_buttons(context: Control) -> void:
	for button in MenuHelpers.find_buttons(context):
		if _play_panel and _play_panel.is_ancestor_of(button):
			continue
		MenuHelpers.prepare_menu_button(button)
		var key := MenuHelpers.normalize_key(button.name, button.text)
		if not BUTTON_ACTIONS.has(key):
			continue
		var action: String = BUTTON_ACTIONS[key]
		var callable := _on_button_action.bind(action)
		MenuHelpers.track_connection(_connections, button, "pressed", callable)


func _connect_play_panel() -> void:
	var start_btn := _context.get_node_or_null("%PlayStartButton") as Button
	var back_btn := _context.get_node_or_null("%PlayBackButton") as Button
	if start_btn:
		MenuHelpers.prepare_menu_button(start_btn)
		MenuHelpers.track_connection(_connections, start_btn, "pressed", _on_play_start_pressed)
	if back_btn:
		MenuHelpers.prepare_menu_button(back_btn)
		MenuHelpers.track_connection(_connections, back_btn, "pressed", _on_play_back_pressed)


func _on_button_action(action: String) -> void:
	if _machine == null:
		return
	match action:
		"play":
			_show_play_setup()
		"demo":
			_machine.transition_to_demo_pantano()
		"options":
			_machine.transition_to_options()
		"quit":
			_machine.quit_game()


func _show_play_setup() -> void:
	if _play_panel:
		_play_panel.visible = true
	if _main_buttons:
		_main_buttons.visible = false
	if _difficulty_option:
		_difficulty_option.select(_get_difficulty_index(SettingsManager.difficulty_index))


func _hide_play_setup() -> void:
	if _play_panel:
		_play_panel.visible = false
	if _main_buttons:
		_main_buttons.visible = true


func _on_play_start_pressed() -> void:
	if _machine == null or _difficulty_option == null:
		return
	var selected := _difficulty_option.selected
	if selected < 0:
		selected = SettingsManager.Difficulty.NORMAL
	var difficulty_id := _difficulty_option.get_item_id(selected)
	_machine.begin_game_with_difficulty(difficulty_id)


func _on_play_back_pressed() -> void:
	_hide_play_setup()


func _get_difficulty_index(mode: int) -> int:
	if _difficulty_option == null:
		return SettingsManager.Difficulty.NORMAL
	for i in _difficulty_option.item_count:
		if _difficulty_option.get_item_id(i) == mode:
			return i
	return SettingsManager.Difficulty.NORMAL
