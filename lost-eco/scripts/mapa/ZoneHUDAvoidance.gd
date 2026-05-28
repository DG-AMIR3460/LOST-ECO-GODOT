extends RefCounted
class_name ZoneHUDAvoidance
## Evita que el HUD tape al jugador: salta a la esquina opuesta o se oculta.


enum Anchor { TOP_LEFT, BOTTOM_RIGHT }


static func world_to_canvas(node: Node2D) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2.ZERO
	return node.get_global_transform_with_canvas().origin


static func viewport_size(node: Node) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2(320, 180)
	return node.get_viewport().get_visible_rect().size


static func player_screen_rect(player: Node2D) -> Rect2:
	var center: Vector2 = world_to_canvas(player)
	return Rect2(center - Vector2(7.0, 11.0), Vector2(14.0, 22.0))


static func update_panel(
	current: Vector2,
	rest: Vector2,
	panel_size: Vector2,
	player_rect: Rect2,
	vp_size: Vector2,
	delta: float,
	anchor: int = Anchor.TOP_LEFT
) -> Dictionary:
	if panel_size.x < 1.0 or panel_size.y < 1.0:
		return {"position": rest, "visible": true}

	var dodge: Vector2 = _dodge_position(panel_size, vp_size, anchor)
	var home_rect: Rect2 = Rect2(rest, panel_size).grow(10.0)
	var dodge_rect: Rect2 = Rect2(dodge, panel_size)

	if home_rect.intersects(player_rect):
		if dodge_rect.intersects(player_rect):
			return {"position": dodge, "visible": false}
		return {"position": dodge, "visible": true}

	if current.distance_squared_to(rest) > 0.5:
		var blend: float = clampf(delta * 9.0, 0.0, 1.0)
		return {"position": current.lerp(rest, blend), "visible": true}

	return {"position": rest, "visible": true}


static func _dodge_position(panel_size: Vector2, vp_size: Vector2, anchor: int) -> Vector2:
	match anchor:
		Anchor.TOP_LEFT:
			return Vector2(
				vp_size.x - panel_size.x - 4.0,
				4.0
			)
		Anchor.BOTTOM_RIGHT:
			return Vector2(
				4.0,
				vp_size.y - panel_size.y - 4.0
			)
		_:
			return Vector2(4.0, 4.0)
