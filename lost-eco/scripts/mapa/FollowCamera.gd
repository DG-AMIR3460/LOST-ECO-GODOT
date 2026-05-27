extends Camera2D

@export var follow_speed: float = 8.0

var target: Node2D = null
var _focus_pos: Vector2 = Vector2.INF
var _focus_blend: float = 0.0


func _ready() -> void:
	zoom = Vector2(2, 2)
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed


func focus_on(world_pos: Vector2, hold_seconds: float = 1.4) -> void:
	_focus_pos = world_pos
	_focus_blend = 1.0
	await get_tree().create_timer(hold_seconds).timeout
	_focus_blend = 0.0


func _process(delta: float) -> void:
	if _focus_blend > 0.0 and _focus_pos != Vector2.INF:
		var blend_speed := 4.0 * delta
		_focus_blend = maxf(0.0, _focus_blend - blend_speed)
		var weight := 1.0 - _focus_blend
		var focus_target := _focus_pos
		if target and _focus_blend < 0.85:
			focus_target = focus_target.lerp(target.global_position, weight)
		global_position = global_position.lerp(focus_target, minf(1.0, 6.0 * delta))
		return

	if target == null and GameManager.player != null:
		target = GameManager.player
	if target:
		global_position = target.global_position
