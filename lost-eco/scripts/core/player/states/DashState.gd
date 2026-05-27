extends PlayerState
## Dash: gravedad congelada durante frames activos (is_dashing en PlayerController2D).


func enter() -> void:
	player.invulnerable = true
	if player.sprite:
		player.sprite.modulate = Color(1.3, 1.4, 1.8)


func exit() -> void:
	if not player.is_spawn_protected():
		player.invulnerable = false
	player.is_dashing = false
	if player.sprite:
		player.sprite.modulate = Color.WHITE


func physics_update(_delta: float) -> void:
	player.apply_gravity(0.0)
	if not player.is_dashing:
		if player.is_on_floor():
			request_transition("Idle" if player.get_horizontal_input() == 0.0 else "Move")
		else:
			request_transition("Jump")
		return
	player.velocity.y = 0.0
	player.velocity.x = player.dash_direction * PlayerController2D.DASH_SPEED
	player.move_with_physics()


func handle_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("attack"):
		request_transition("Attack")
