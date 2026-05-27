extends StaticBody2D

var _activated: bool = false


func _ready() -> void:
	add_to_group("terrain_switch")


func activate_switch() -> void:
	if _activated:
		return
	_activated = true
	modulate = Color(0.5, 1.0, 0.6)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 24.0, 0.6)
