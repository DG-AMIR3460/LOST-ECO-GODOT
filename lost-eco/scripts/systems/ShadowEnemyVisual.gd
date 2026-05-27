extends RefCounted
class_name ShadowEnemyVisual
## Enemigos con sprite del sheet o silueta procedural como respaldo.


static func create(parent: Node, world_pos: Vector2, palette: Dictionary) -> Node2D:
	var sprite_key: String = palette.get("sprite", "")
	if not sprite_key.is_empty():
		return _create_sprite_enemy(parent, world_pos, palette, sprite_key)
	return _create_polygon_enemy(parent, world_pos, palette)


static func _create_sprite_enemy(parent: Node, world_pos: Vector2, palette: Dictionary, sprite_key: String) -> Node2D:
	var enemy := Node2D.new()
	enemy.global_position = world_pos
	parent.add_child(enemy)

	var sprite := CharacterArt.make_sprite(sprite_key, -1.0)
	if sprite == null:
		enemy.queue_free()
		return _create_polygon_enemy(parent, world_pos, palette)

	var scale_factor: float = palette.get("scale", 1.0)
	sprite.scale *= scale_factor
	sprite.offset.y *= scale_factor
	enemy.add_child(sprite)

	var glow := Polygon2D.new()
	glow.name = "Glow"
	glow.polygon = PackedVector2Array([
		Vector2(-10, -8), Vector2(10, -8), Vector2(10, 8), Vector2(-10, 8),
	])
	var glow_color: Color = palette.get("glow", Color(0.5, 0.2, 0.3, 0.25))
	glow.color = glow_color
	glow.z_index = -1
	enemy.add_child(glow)
	enemy.move_child(glow, 0)

	var float_tween := parent.create_tween().set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(enemy, "position:y", enemy.position.y - 2.0, 0.8)
	float_tween.tween_property(enemy, "position:y", enemy.position.y + 2.0, 0.8)

	var pulse_tween := parent.create_tween().set_loops()
	var pulse_color: Color = palette.get("pulse", Color(1.4, 1.2, 1.3))
	pulse_tween.tween_property(sprite, "modulate", pulse_color, 0.7)
	pulse_tween.tween_property(sprite, "modulate", Color.WHITE, 0.7)

	var glow_tween := parent.create_tween().set_loops()
	glow_tween.tween_property(glow, "modulate:a", 0.35, 0.85)
	glow_tween.tween_property(glow, "modulate:a", 0.75, 0.85)

	return enemy


static func _create_polygon_enemy(parent: Node, world_pos: Vector2, palette: Dictionary) -> Node2D:
	var body_color: Color = palette.get("body", Color(0.45, 0.06, 0.14))
	var glow_color: Color = palette.get("glow", Color(0.85, 0.18, 0.28, 0.42))
	var pulse_color: Color = palette.get("pulse", Color(1.6, 0.35, 0.45))
	var eye_color: Color = palette.get("eyes", Color(1.0, 0.22, 0.18))
	var wisp_color: Color = palette.get("wisp", Color(0.25, 0.04, 0.10, 0.65))

	var enemy := Node2D.new()
	enemy.global_position = world_pos
	parent.add_child(enemy)

	var aura := Polygon2D.new()
	aura.name = "Aura"
	aura.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(10, -6), Vector2(9, 10),
		Vector2(0, 14), Vector2(-9, 10), Vector2(-10, -6),
	])
	aura.color = glow_color
	enemy.add_child(aura)

	for i in 3:
		var wisp := Polygon2D.new()
		var side := -1.0 if i == 0 else (1.0 if i == 2 else 0.0)
		wisp.polygon = PackedVector2Array([
			Vector2(-2 + side * 3, 6), Vector2(2 + side * 3, 6),
			Vector2(1 + side * 4, 11), Vector2(-1 + side * 4, 11),
		])
		wisp.color = wisp_color
		enemy.add_child(wisp)

	var body := Polygon2D.new()
	body.name = "Body"
	body.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(7, -5), Vector2(6, 4),
		Vector2(3, 9), Vector2(-3, 9), Vector2(-6, 4), Vector2(-7, -5),
	])
	body.color = body_color
	enemy.add_child(body)

	var core := Polygon2D.new()
	core.name = "Core"
	core.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(3, -2), Vector2(2, 3),
		Vector2(-2, 3), Vector2(-3, -2),
	])
	core.color = Color(body_color.r + 0.12, body_color.g + 0.02, body_color.b + 0.08, 0.85)
	enemy.add_child(core)

	for ox in [-4, 2]:
		var eye_glow := Polygon2D.new()
		eye_glow.polygon = PackedVector2Array([
			Vector2(ox - 1, -5), Vector2(ox + 3, -5),
			Vector2(ox + 3, -1), Vector2(ox - 1, -1),
		])
		eye_glow.color = Color(eye_color.r, eye_color.g, eye_color.b, 0.35)
		enemy.add_child(eye_glow)

		var eye := Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(ox, -4), Vector2(ox + 2, -4),
			Vector2(ox + 2, -2), Vector2(ox, -2),
		])
		eye.color = eye_color
		eye.name = "Eye"
		enemy.add_child(eye)

	var float_tween := parent.create_tween().set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(enemy, "position:y", enemy.position.y - 2.5, 0.75)
	float_tween.tween_property(enemy, "position:y", enemy.position.y + 2.5, 0.75)

	var pulse_tween := parent.create_tween().set_loops()
	pulse_tween.tween_property(body, "modulate", pulse_color, 0.65)
	pulse_tween.tween_property(body, "modulate", Color(1.0, 1.0, 1.0), 0.65)

	var aura_tween := parent.create_tween().set_loops()
	aura_tween.tween_property(aura, "modulate:a", 0.55, 0.9)
	aura_tween.tween_property(aura, "modulate:a", 1.0, 0.9)

	var spin_tween := parent.create_tween().set_loops()
	spin_tween.tween_property(aura, "rotation", TAU, 5.5).from(0.0)

	var scale_factor: float = palette.get("scale", 0.68)
	enemy.scale = Vector2(scale_factor, scale_factor)

	return enemy
