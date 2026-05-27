extends StaticBody2D

var _triggered: bool = false
var _fall_timer: float = 0.28
var _difficulty: float = 1.0


func set_difficulty(mult: float) -> void:
	_difficulty = mult
	_fall_timer = maxf(0.12, 0.35 - mult * 0.08)


func _ready() -> void:
	var detector := get_node_or_null("Detector") as Area2D
	if detector:
		detector.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body is PlayerController2D:
		_triggered = true
		_collapse()


func _collapse() -> void:
	modulate = Color(1.2, 0.9, 0.6)
	await get_tree().create_timer(_fall_timer).timeout
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 90.0, 0.45 / _difficulty)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func(): set_deferred("collision_layer", 0))
