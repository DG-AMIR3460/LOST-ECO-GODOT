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
	if dir == 0.0 and player.is_on_floor():
		request_transition("Idle")
		return
	var target := dir * PlayerController2D.MOVE_SPEED
	var accel := PlayerController2D.ACCEL_GROUND if player.is_on_floor() else PlayerController2D.ACCEL_AIR
	player.velocity.x = move_toward(player.velocity.x, target, accel * delta)
	player.move_with_physics()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		player.buffer_jump()
	if event.is_action_released("jump"):
		player.cut_jump()
