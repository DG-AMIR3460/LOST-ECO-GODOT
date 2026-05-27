extends MenuState
## Estado reservado para el menú de pausa in-game (listo para escalar sin tocar el flujo actual).

var _connections: Array = []
var _machine: Node


func get_state_name() -> String:
	return "PauseMenuState"


func enter(context: Control, machine: Node) -> void:
	_machine = machine
	# Punto de extensión: conectar botones de pausa cuando exista la escena/panel.
	MenuHelpers.apply_menu_entry_presentation()


func exit(_context: Control, machine_ref: Node) -> void:
	MenuHelpers.disconnect_all(_connections)
	_machine = null


func resume_game() -> void:
	if _machine:
		_machine.transition_to_game()
