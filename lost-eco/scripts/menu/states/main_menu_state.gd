extends MenuState
## Estado del menú principal (Jugar, Opciones, Salir).

const BUTTON_ACTIONS := {
	"jugar": "play",
	"play": "play",
	"opciones": "options",
	"options": "options",
	"salir": "quit",
	"quit": "quit",
	"exit": "quit",
}

var _connections: Array = []
var _machine: Node


func get_state_name() -> String:
	return "MainMenuState"


func enter(context: Control, machine: Node) -> void:
	_machine = machine
	MenuHelpers.apply_menu_entry_presentation()
	_connect_buttons(context)


func exit(context: Control, _machine: Node) -> void:
	MenuHelpers.disconnect_all(_connections)
	_machine = null


func _connect_buttons(context: Control) -> void:
	for button in MenuHelpers.find_buttons(context):
		MenuHelpers.prepare_menu_button(button)
		var key := MenuHelpers.normalize_key(button.name, button.text)
		if not BUTTON_ACTIONS.has(key):
			continue
		var action: String = BUTTON_ACTIONS[key]
		var callable := _on_button_action.bind(action)
		MenuHelpers.track_connection(_connections, button, "pressed", callable)


func _on_button_action(action: String) -> void:
	if _machine == null:
		return
	match action:
		"play":
			_machine.transition_to_game()
		"options":
			_machine.transition_to_options()
		"quit":
			_machine.quit_game()
