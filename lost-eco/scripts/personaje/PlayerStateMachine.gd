extends Node
class_name PlayerStateMachine
## Máquina de estados OO pura — sin match/switch para lógica de estados.

signal state_changed(previous: String, current: String)

var _states: Dictionary = {}
var _current: PlayerState = null
var _current_name: String = ""


func register_state(state_name: String, state: PlayerState) -> void:
	_states[state_name] = state
	add_child(state)
	state.bind(self, get_parent() as PlayerController2D)


func change_state(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("PlayerStateMachine: estado desconocido '%s'" % state_name)
		return
	if _current_name == state_name:
		return
	var previous := _current_name
	if _current:
		_current.exit()
	_current = _states[state_name]
	_current_name = state_name
	_current.enter()
	state_changed.emit(previous, state_name)


func get_current_name() -> String:
	return _current_name


func handle_input(event: InputEvent) -> void:
	if _current:
		_current.handle_input(event)


func physics_update(delta: float) -> void:
	if _current:
		_current.physics_update(delta)
