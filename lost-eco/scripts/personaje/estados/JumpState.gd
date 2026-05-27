extends PlayerState


func physics_update(delta: float) -> void:
	if player.input_locked:
		return
	player.apply_gravity(delta)
	if player.is_on_floor() and player.try_jump():
		pass
	elif Input.is_action_just_pressed("dash") and player.try_start_dash():
		request_transition("Dash")
		return
	elif Input.is_action_just_pressed("attack"):
		request_transition("Attack")
		return
	var dir := player.get_horizontal_input()
	var target := dir * PlayerController2D.MOVE_SPEED
	player.velocity.x = move_toward(player.velocity.x, target, PlayerController2D.ACCEL_AIR * delta)
	if player.is_on_floor():
		if dir != 0.0:
			request_transition("Move")
		else:
			request_transition("Idle")
	player.move_with_physics()


func handle_input(event: InputEvent) -> void:
	if event.is_action_released("jump"):
		player.cut_jump()
	if event.is_action_pressed("jump"):
		player.buffer_jump()
