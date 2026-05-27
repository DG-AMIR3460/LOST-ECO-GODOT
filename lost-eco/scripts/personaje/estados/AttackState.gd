extends PlayerState
## Pulso de Luz: Area2D knockback + consumo de Light Energy.


var _timer: float = 0.0
const DURATION: float = 0.24
var _fired: bool = false


func enter() -> void:
	_fired = player.perform_light_pulse()
	_timer = DURATION if _fired else 0.1


func physics_update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, PlayerController2D.FRICTION_GROUND * delta * 0.35)
	player.move_with_physics()
	if _timer <= 0.0:
		if player.is_on_floor():
			request_transition("Idle" if player.get_horizontal_input() == 0.0 else "Move")
		else:
			request_transition("Jump")
