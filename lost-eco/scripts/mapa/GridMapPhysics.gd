extends RefCounted
class_name GridMapPhysics
## Movimiento con colisión por tiles (# = pared) para laberintos en grilla.

static var current_map: Array = []
static var tile_size: int = 16


static func set_map(map: Array, ts: int = 16) -> void:
	current_map = map
	tile_size = ts


static func clear_map() -> void:
	current_map = []
	tile_size = 16


static func is_walkable(world_pos: Vector2, radius: float = 4.0) -> bool:
	if current_map.is_empty():
		return true
	for offset in [
		Vector2.ZERO,
		Vector2(radius, 0), Vector2(-radius, 0),
		Vector2(0, radius), Vector2(0, -radius),
	]:
		if not _is_floor(world_pos + offset):
			return false
	return true


static func move_body(body: CharacterBody2D, velocity: Vector2, delta: float) -> void:
	if body == null:
		return
	if current_map.is_empty():
		body.velocity = velocity
		body.move_and_slide()
		return

	var pos: Vector2 = body.global_position
	var next_x: Vector2 = pos + Vector2(velocity.x * delta, 0.0)
	if is_walkable(next_x):
		pos.x = next_x.x
	else:
		velocity.x = 0.0

	var next_y: Vector2 = pos + Vector2(0.0, velocity.y * delta)
	if is_walkable(next_y):
		pos.y = next_y.y
	else:
		velocity.y = 0.0

	body.global_position = pos
	body.velocity = velocity
	_clamp_to_bounds(body)


static func move_node(node: Node2D, target: Vector2, speed: float, delta: float) -> void:
	if node == null:
		return
	var dir: Vector2 = target - node.global_position
	if dir.length() <= 2.0:
		return
	var step: Vector2 = dir.normalized() * speed * delta
	var next: Vector2 = node.global_position + step
	if current_map.is_empty() or is_walkable(next, 3.0):
		node.global_position = next
	else:
		var slide_x: Vector2 = node.global_position + Vector2(step.x, 0.0)
		if is_walkable(slide_x, 3.0):
			node.global_position = slide_x
		var slide_y: Vector2 = node.global_position + Vector2(0.0, step.y)
		if is_walkable(slide_y, 3.0):
			node.global_position = slide_y


static func _clamp_to_bounds(body: CharacterBody2D) -> void:
	if current_map.is_empty():
		return
	var ts: float = float(tile_size)
	var margin: float = ts * 0.45
	var first_row: String = str(current_map[0])
	var map_w: int = first_row.length()
	var map_h: int = current_map.size()
	var max_x: float = float(map_w - 1) * ts + ts * 0.5
	var max_y: float = float(map_h - 1) * ts + ts * 0.5
	body.global_position = Vector2(
		clampf(body.global_position.x, margin, max_x - margin),
		clampf(body.global_position.y, margin, max_y - margin)
	)


static func _is_floor(world_pos: Vector2) -> bool:
	var tx: int = int(floor(world_pos.x / float(tile_size)))
	var ty: int = int(floor(world_pos.y / float(tile_size)))
	if ty < 0 or ty >= current_map.size():
		return false
	var row: String = str(current_map[ty])
	if tx < 0 or tx >= row.length():
		return false
	return row[tx] != "#"
