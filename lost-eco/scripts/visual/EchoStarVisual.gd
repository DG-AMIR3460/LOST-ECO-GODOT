extends RefCounted
class_name EchoStarVisual
## Eco de memoria: estrella dorada brillante con luz.


static func spawn(parent: Node, world_pos: Vector2, on_collect: Callable) -> Area2D:
	var area := Area2D.new()
	area.global_position = world_pos
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.add_to_group("echo_of_light")
	parent.add_child(area)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	area.add_child(shape)
	var glow := PointLight2D.new()
	glow.color = Color(1.0, 0.88, 0.45)
	glow.energy = 0.95
	glow.texture_scale = 1.1
	LightTextureFactory.apply_halo_to_light(glow, Color(1.0, 0.9, 0.5), 0.95, 1.1)
	area.add_child(glow)
	var core := Polygon2D.new()
	core.color = Color(1.0, 0.92, 0.35, 0.95)
	core.polygon = _star_poly(8.0)
	area.add_child(core)
	var ring := Polygon2D.new()
	ring.color = Color(1.2, 1.1, 0.5, 0.35)
	ring.polygon = _star_poly(12.0)
	area.add_child(ring)
	ring.z_index = -1
	var tw := area.create_tween().set_loops()
	tw.tween_property(core, "modulate", Color(2.0, 1.8, 0.8), 0.55)
	tw.tween_property(core, "modulate", Color(1.0, 1.0, 1.0), 0.55)
	tw.parallel().tween_property(area, "rotation", TAU, 4.0).from(0.0)
	area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			on_collect.call(area)
	)
	return area


static func _star_poly(radius: float) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in 8:
		var a := TAU * float(i) / 8.0 - PI * 0.5
		var r := radius if i % 2 == 0 else radius * 0.42
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts
