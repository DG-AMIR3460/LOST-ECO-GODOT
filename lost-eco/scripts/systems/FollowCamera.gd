extends Camera2D

@export var follow_speed: float = 8.0
var target: Node2D = null

func _ready() -> void:
	zoom = Vector2(2, 2)
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed

func _process(_delta: float) -> void:
	if target == null and GameManager.player != null:
		target = GameManager.player
	if target:
		global_position = target.global_position
