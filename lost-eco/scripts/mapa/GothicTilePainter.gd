extends RefCounted
class_name GothicTilePainter
## Dibujo de suelos/paredes con textura procedural gótica (sin placeholders grises).


static func draw_zone_map(
	canvas: CanvasItem,
	floors: Array,
	floor_shades: Array,
	walls: Array,
	theme: String = "cave"
) -> void:
	var pal: Dictionary = _palette(theme)
	for r in floors:
		_draw_floor_tile(canvas, r, pal, false)
	for r in floor_shades:
		_draw_floor_tile(canvas, r, pal, true)
	for r in walls:
		_draw_wall_tile(canvas, r, pal)


static func _color(pal: Dictionary, key: String) -> Color:
	return pal[key] as Color


static func _palette(theme: String) -> Dictionary:
	if theme == "labyrinth":
		return {
			"floor": Color(0.28, 0.24, 0.34),
			"floor_hi": Color(0.38, 0.34, 0.46),
			"floor_lo": Color(0.20, 0.18, 0.26),
			"wall": Color(0.12, 0.10, 0.16),
			"moss": Color(0.34, 0.38, 0.28, 0.35),
			"crack": Color(0.08, 0.06, 0.12, 0.45),
		}
	if theme == "river":
		return {
			"floor": Color(0.16, 0.30, 0.44),
			"floor_hi": Color(0.24, 0.40, 0.56),
			"floor_lo": Color(0.10, 0.22, 0.34),
			"wall": Color(0.10, 0.24, 0.16),
			"moss": Color(0.28, 0.55, 0.42, 0.35),
			"crack": Color(0.06, 0.10, 0.14, 0.45),
		}
	if theme == "swamp":
		return {
			"floor": Color(0.22, 0.28, 0.16),
			"floor_hi": Color(0.30, 0.36, 0.22),
			"floor_lo": Color(0.16, 0.20, 0.12),
			"wall": Color(0.12, 0.14, 0.10),
			"moss": Color(0.34, 0.44, 0.22, 0.40),
			"crack": Color(0.08, 0.08, 0.10, 0.45),
		}
	return {
		"floor": Color(0.24, 0.22, 0.28),
		"floor_hi": Color(0.34, 0.32, 0.40),
		"floor_lo": Color(0.16, 0.14, 0.20),
		"wall": Color(0.12, 0.10, 0.14),
		"moss": Color(0.28, 0.30, 0.38, 0.30),
		"crack": Color(0.08, 0.06, 0.12, 0.45),
	}


static func _draw_floor_tile(canvas: CanvasItem, rect: Rect2, pal: Dictionary, shaded: bool) -> void:
	var base: Color
	var inner_fill: Color
	if shaded:
		base = _color(pal, "floor_lo")
		inner_fill = _color(pal, "floor")
	else:
		base = _color(pal, "floor")
		inner_fill = _color(pal, "floor_hi")
	canvas.draw_rect(rect, base)
	var inner := rect.grow(-2.0)
	canvas.draw_rect(inner, inner_fill)
	var seed := int(rect.position.x * 0.7 + rect.position.y * 1.3)
	if seed % 5 == 0:
		canvas.draw_rect(Rect2(inner.position + Vector2(2, 2), Vector2(3, 2)), _color(pal, "moss"))
	if seed % 7 == 0:
		canvas.draw_line(
			inner.position + Vector2(4, inner.size.y - 3),
			inner.position + Vector2(inner.size.x - 3, 2),
			_color(pal, "crack"),
			1.0
		)


static func _draw_wall_tile(canvas: CanvasItem, rect: Rect2, pal: Dictionary) -> void:
	var wall: Color = _color(pal, "wall")
	canvas.draw_rect(rect, wall)
	var hi := rect.grow(-3.0)
	canvas.draw_rect(hi, wall.lightened(0.08))
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 2.0), wall.darkened(0.15))
	var seed := int(rect.position.x + rect.position.y * 2.0)
	if seed % 4 == 0:
		canvas.draw_rect(Rect2(hi.position + Vector2(1, hi.size.y - 4), Vector2(hi.size.x - 2, 2)), _color(pal, "crack"))
