extends PlayerState

var _timer: float = 0.0
const STUN: float = 0.35


func enter() -> void:
	_timer = STUN
	player.invulnerable = true
	if player.sprite:
		var tw := player.create_tween()
		tw.tween_property(player.sprite, "modulate", Color(2.0, 0.35, 0.35), 0.06)
		tw.tween_property(player.sprite, "modulate", Color.WHITE, 0.2)


func exit() -> void:
	if not player.is_spawn_protected():
		player.invulnerable = false


func physics_update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, PlayerController2D.FRICTION_GROUND * delta)
	player.move_with_physics()
	if _timer <= 0.0:
		if player.session and not player.session.is_alive():
			request_transition("Dead")
		elif player.is_on_floor():
			request_transition("Idle")
		else:
			request_transition("Jump")
