extends Control
## Punto de entrada visual del menú de opciones.
## La lógica vive en OptionsMenuState (MenuStateMachine).


func _ready() -> void:
	MenuStateMachine.activate_options_menu(self)


func _exit_tree() -> void:
	MenuStateMachine.release_context(self)
