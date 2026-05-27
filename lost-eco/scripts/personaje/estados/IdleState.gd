extends PlayerState


func physics_update(delta: float) -> void:
	if player.input_locked:
		return
	player.apply_gravity(delta)
	if player.try_jump():
		request_transition("Jump")
		return
	if Input.is_action_just_pressed("dash") and player.try_start_dash():
		request_transition("Dash")
		return
	if Input.is_action_just_pressed("attack"):
		request_transition("Attack")
		return
	var dir := player.get_horizontal_input()
	if dir != 0.0:
		request_transition("Move")
		return
	player.velocity.x = move_toward(player.velocity.x, 0.0, PlayerController2D.FRICTION_GROUND * delta)
	player.move_with_physics()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		player.buffer_jump()
