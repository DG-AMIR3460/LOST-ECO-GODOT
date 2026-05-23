extends Control
## Punto de entrada visual del menú principal.
## La lógica vive en MainMenuState (MenuStateMachine).


func _ready() -> void:
	MenuStateMachine.activate_main_menu(self)


func _exit_tree() -> void:
	MenuStateMachine.release_context(self)
