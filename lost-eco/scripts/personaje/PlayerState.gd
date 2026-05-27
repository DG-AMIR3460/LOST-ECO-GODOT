extends Node
class_name PlayerState
## Estado base del patrón State. Cada subclase encapsula su propio ciclo de vida.

var machine: PlayerStateMachine = null
var player: PlayerController2D = null


func bind(p_machine: PlayerStateMachine, p_player: PlayerController2D) -> void:
	machine = p_machine
	player = p_player


func enter() -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func request_transition(state_name: String) -> void:
	if machine:
		machine.change_state(state_name)
