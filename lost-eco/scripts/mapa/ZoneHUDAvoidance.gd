extends RefCounted
class_name ZoneHUDAvoidance
## Desplaza paneles de HUD cuando el jugador queda debajo.


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


static func slide_panel(
	current: Vector2,
	rest: Vector2,
	panel_size: Vector2,
	player_rect: Rect2,
	vp_size: Vector2,
	delta: float,
	anchor: int = Anchor.TOP_LEFT,
	speed: float = 18.0
) -> Vector2:
	if panel_size.x < 1.0 or panel_size.y < 1.0:
		return rest
	var panel_rect := Rect2(current, panel_size)
	var target: Vector2 = rest
	if panel_rect.intersects(player_rect):
		target = _find_clear_position(rest, panel_size, player_rect, vp_size, anchor)
	var blend: float = clampf(delta * speed, 0.0, 1.0)
	return current.lerp(target, blend)


static func _find_clear_position(
	rest: Vector2,
	panel_size: Vector2,
	player_rect: Rect2,
	vp_size: Vector2,
	anchor: int
) -> Vector2:
	var pc: Vector2 = player_rect.get_center()
	var margin: float = 12.0
	var opts: Array[Vector2] = []
	match anchor:
		Anchor.TOP_LEFT:
			opts = [
				Vector2(pc.x + player_rect.size.x * 0.5 + margin, rest.y),
				Vector2(rest.x, pc.y + player_rect.size.y * 0.5 + margin),
				Vector2(vp_size.x - panel_size.x - 4.0, 4.0),
				Vector2(4.0, vp_size.y - panel_size.y - 4.0),
			]
		Anchor.BOTTOM_RIGHT:
			opts = [
				Vector2(pc.x - panel_size.x - margin, rest.y),
				Vector2(rest.x, pc.y - panel_size.y - margin),
				Vector2(4.0, vp_size.y - panel_size.y - 4.0),
				Vector2(vp_size.x - panel_size.x - 4.0, 4.0),
			]
		_:
			opts = [rest]
	for opt: Vector2 in opts:
		var pos: Vector2 = _clamp_pos(opt, panel_size, vp_size)
		if not Rect2(pos, panel_size).intersects(player_rect):
			return pos
	return _clamp_pos(
		rest + Vector2(margin, margin) if anchor == Anchor.TOP_LEFT else rest - Vector2(margin, margin),
		panel_size,
		vp_size
	)


static func _clamp_pos(pos: Vector2, panel_size: Vector2, vp_size: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, 2.0, maxf(2.0, vp_size.x - panel_size.x - 2.0)),
		clampf(pos.y, 2.0, maxf(2.0, vp_size.y - panel_size.y - 2.0))
	)
