extends PlayerState


func enter() -> void:
	player.input_locked = true
	player.velocity = Vector2.ZERO
	player.set_collision_layer_value(1, false)
	player.died.emit()
	if player.sprite:
		var tw := player.create_tween()
		tw.tween_property(player.sprite, "rotation", deg_to_rad(90.0 if player.facing_right else -90.0), 0.35)
		tw.parallel().tween_property(player.sprite, "modulate", Color(0.4, 0.35, 0.45), 0.35)
	if player.death_director and player.session and not player.session.is_alive():
		player.death_director.play(player)


func physics_update(_delta: float) -> void:
	pass
