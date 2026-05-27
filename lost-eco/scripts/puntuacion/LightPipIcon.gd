extends Control

var _lit: bool = false
var _pulse: float = 0.0


func set_lit(on: bool) -> void:
	_lit = on
	queue_redraw()


func _process(delta: float) -> void:
	if _lit:
		_pulse += delta * 5.0
		queue_redraw()


func _draw() -> void:
	var sz := size
	var center := sz * 0.5
	var r := minf(sz.x, sz.y) * 0.38
	var c := Color(0.95, 0.82, 0.28) if _lit else Color(0.15, 0.12, 0.18)
	if _lit:
		c = c.lerp(Color(1.0, 0.95, 0.6), sin(_pulse) * 0.2 + 0.2)
	draw_circle(center, r, c)
	draw_arc(center, r + 0.6, 0.0, TAU, 12, Color(0.4, 0.32, 0.12, 0.6), 1.0)
