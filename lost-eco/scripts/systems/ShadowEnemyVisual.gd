extends RefCounted
class_name ShadowEnemyVisual
## Sombras enemigas visibles: silueta roja + ojos brillantes + halo.


static func create(parent: Node, world_pos: Vector2, palette: Dictionary) -> Node2D:
	var sprite_key: String = palette.get("sprite", "")
	if not sprite_key.is_empty() and CharacterArt.is_ready():
		return _create_hybrid_enemy(parent, world_pos, palette, sprite_key)
	return _create_polygon_enemy(parent, world_pos, palette)


static func _create_hybrid_enemy(parent: Node, world_pos: Vector2, palette: Dictionary, sprite_key: String) -> Node2D:
	var enemy := _create_polygon_enemy(parent, world_pos, palette)
	var sprite := CharacterArt.make_sprite(sprite_key, 0.10)
	if sprite:
		sprite.modulate = Color(0.55, 0.55, 0.65, 0.85)
		sprite.z_index = -1
		enemy.add_child(sprite)
		enemy.move_child(sprite, 0)
	return enemy


static func _create_polygon_enemy(parent: Node, world_pos: Vector2, palette: Dictionary) -> Node2D:
	var body_color: Color = palette.get("body", Color(0.78, 0.10, 0.16))
	var glow_color: Color = palette.get("glow", Color(0.95, 0.28, 0.38, 0.55))
	var pulse_color: Color = palette.get("pulse", Color(1.8, 0.45, 0.50))
	var eye_color: Color = palette.get("eyes", Color(1.0, 0.95, 0.90))
	var wisp_color: Color = palette.get("wisp", Color(0.45, 0.08, 0.14, 0.75))

	var enemy := Node2D.new()
	enemy.global_position = world_pos
	enemy.z_index = 8
	parent.add_child(enemy)

	var aura := Polygon2D.new()
	aura.name = "Aura"
	aura.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(12, -7), Vector2(11, 12),
		Vector2(0, 16), Vector2(-11, 12), Vector2(-12, -7),
	])
	aura.color = glow_color
	enemy.add_child(aura)

	for i in 3:
		var wisp := Polygon2D.new()
		var side := -1.0 if i == 0 else (1.0 if i == 2 else 0.0)
		wisp.polygon = PackedVector2Array([
			Vector2(-2 + side * 3, 6), Vector2(2 + side * 3, 6),
			Vector2(1 + side * 4, 12), Vector2(-1 + side * 4, 12),
		])
		wisp.color = wisp_color
		enemy.add_child(wisp)

	var body := Polygon2D.new()
	body.name = "Body"
	body.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(8, -6), Vector2(7, 5),
		Vector2(3, 10), Vector2(-3, 10), Vector2(-7, 5), Vector2(-8, -6),
	])
	body.color = body_color
	enemy.add_child(body)

	for ox in [-5, 3]:
		var eye_glow := Polygon2D.new()
		eye_glow.polygon = PackedVector2Array([
			Vector2(ox - 1, -6), Vector2(ox + 3, -6),
			Vector2(ox + 3, -2), Vector2(ox - 1, -2),
		])
		eye_glow.color = Color(eye_color.r, eye_color.g, eye_color.b, 0.5)
		enemy.add_child(eye_glow)

		var eye := Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(ox, -5), Vector2(ox + 2, -5),
			Vector2(ox + 2, -3), Vector2(ox, -3),
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

	var eye_light := PointLight2D.new()
	eye_light.color = Color(0.98, 0.08, 0.12)
	eye_light.energy = 1.15
	eye_light.texture_scale = 0.55
	LightTextureFactory.apply_crimson_eye(eye_light, Vector2.ZERO, 1.15)
	enemy.add_child(eye_light)

	var smoke := GPUParticles2D.new()
	smoke.amount = 10
	smoke.lifetime = 1.2
	smoke.preprocess = 0.4
	var sm := ParticleProcessMaterial.new()
	sm.direction = Vector3(0, -1, 0)
	sm.spread = 140.0
	sm.initial_velocity_min = 2.0
	sm.initial_velocity_max = 8.0
	sm.gravity = Vector3(0, -12, 0)
	sm.scale_min = 0.4
	sm.scale_max = 1.1
	sm.color = Color(0.12, 0.02, 0.06, 0.45)
	smoke.process_material = sm
	enemy.add_child(smoke)

	var scale_factor: float = palette.get("scale", 0.85)
	enemy.scale = Vector2(scale_factor, scale_factor)
	enemy.modulate = Color(0.35, 0.32, 0.4, 0.95)

	return enemy
