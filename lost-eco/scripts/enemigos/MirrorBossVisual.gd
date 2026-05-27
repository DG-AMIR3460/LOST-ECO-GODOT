extends RefCounted
class_name MirrorBossVisual
## Jefe del espejo — sprite + marco de arena visible.


static func spawn(parent: Node2D, tile_pos: Vector2, tile_size: int) -> Dictionary:
	var center := tile_pos + Vector2(tile_size * 0.5, tile_size * 0.5)
	var root := Node2D.new()
	root.name = "MirrorBoss"
	root.global_position = center
	root.add_to_group("mirror_boss")
	parent.add_child(root)

	var platform := Polygon2D.new()
	platform.name = "Platform"
	platform.polygon = _ellipse_points(14, 6)
	platform.color = Color(0.12, 0.08, 0.18, 0.85)
	root.add_child(platform)

	var ring := Polygon2D.new()
	ring.name = "Ring"
	ring.polygon = _ellipse_points(18, 8)
	ring.color = Color(0.35, 0.22, 0.55, 0.35)
	root.add_child(ring)

	var sprite: CanvasItem = null
	if CharacterArt.is_ready():
		var sp := CharacterArt.make_sprite("medium", 0.13)
		if sp:
			sp.name = "BossSprite"
			sp.modulate = Color(0.55, 0.45, 0.75, 0.55)
			sp.z_index = 2
			root.add_child(sp)
			sprite = sp
	if sprite == null:
		var body := Polygon2D.new()
		body.name = "BossBody"
		body.polygon = PackedVector2Array([
			Vector2(0, -14), Vector2(11, -6), Vector2(9, 12),
			Vector2(-9, 12), Vector2(-11, -6),
		])
		body.color = Color(0.38, 0.14, 0.58)
		root.add_child(body)
		sprite = body

	var mirror := Polygon2D.new()
	mirror.name = "MirrorFrame"
	mirror.polygon = PackedVector2Array([
		Vector2(-10, -16), Vector2(10, -16), Vector2(12, 14),
		Vector2(-12, 14), Vector2(-10, -16),
	])
	mirror.color = Color(0.55, 0.75, 1.0, 0.25)
	mirror.z_index = 3
	root.add_child(mirror)

	var light := PointLight2D.new()
	light.name = "BossLight"
	light.color = Color(0.65, 0.45, 1.0)
	light.energy = 0.0
	light.texture_scale = 1.4
	root.add_child(light)

	var area := Area2D.new()
	area.name = "BossArea"
	area.global_position = center
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	parent.add_child(area)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22
	col.shape = shape
	area.add_child(col)

	return {
		"node": root,
		"sprite": sprite,
		"ring": ring,
		"light": light,
		"area": area,
		"center": center,
	}


static func play_locked_idle(sprite: CanvasItem) -> Tween:
	if sprite == null:
		return null
	sprite.modulate = Color(0.45, 0.38, 0.55, 0.65)
	return null


static func play_awaken(parent: Node, data: Dictionary) -> void:
	var root: Node2D = data.get("node")
	var sprite: CanvasItem = data.get("sprite")
	var ring: Polygon2D = data.get("ring")
	var light: PointLight2D = data.get("light")
	if root == null:
		return

	var tw := parent.create_tween()
	tw.set_parallel(true)
	if sprite:
		tw.tween_property(sprite, "modulate", Color(1.1, 0.95, 1.35), 0.5)
		tw.tween_property(root, "scale", Vector2(1.15, 1.15), 0.55).from(Vector2(0.85, 0.85))
	if ring:
		tw.tween_property(ring, "color", Color(0.75, 0.55, 1.0, 0.65), 0.6)
	if light:
		tw.tween_property(light, "energy", 1.35, 0.7)

	var pulse := parent.create_tween().set_loops()
	if sprite:
		pulse.tween_property(sprite, "modulate", Color(1.5, 1.0, 1.8), 0.9)
		pulse.tween_property(sprite, "modulate", Color(1.0, 0.92, 1.2), 0.9)
	data["pulse_tween"] = pulse


static func play_heal(parent: Node, data: Dictionary) -> void:
	var pulse: Tween = data.get("pulse_tween")
	if pulse:
		pulse.kill()
	var root: Node2D = data.get("node")
	var sprite: CanvasItem = data.get("sprite")
	var tw := parent.create_tween()
	if sprite:
		tw.tween_property(sprite, "modulate", Color(2.0, 1.7, 0.45), 2.0)
	if root:
		tw.tween_property(root, "scale", Vector2(0.05, 0.05), 1.4)


static func _ellipse_points(rx: float, ry: float, segments: int = 16) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts
