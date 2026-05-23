extends RefCounted
class_name MenuState
## Clase base del patrón State para todos los menús del juego.


func get_state_name() -> String:
	return "MenuState"


## Se invoca al activar este estado sobre un contexto visual (escena/panel).
func enter(_context: Control, _machine: Node) -> void:
	pass


## Se invoca al salir del estado; libera señales y referencias.
func exit(_context: Control, _machine: Node) -> void:
	pass
