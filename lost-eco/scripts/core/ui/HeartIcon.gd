extends Control

var _filled: bool = true
var _active: bool = true
var _pulse: float = 0.0


func set_filled(filled: bool, active: bool) -> void:
	_filled = filled
	_active = active
	queue_redraw()


func _process(delta: float) -> void:
	if _filled:
		_pulse += delta * 4.0
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var col := Color(0.9, 0.2, 0.25) if _filled else Color(0.25, 0.12, 0.15)
	if _filled:
		col = col.lerp(Color(1.0, 0.5, 0.45), sin(_pulse) * 0.15 + 0.15)
	var pts := PackedVector2Array([
		Vector2(5, 2), Vector2(8, 0), Vector2(10, 3),
		Vector2(5, 9), Vector2(0, 3), Vector2(2, 0),
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, Color(0.15, 0.05, 0.08), 1.0, true)
