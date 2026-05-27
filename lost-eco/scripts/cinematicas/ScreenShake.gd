extends Node
class_name ScreenShake

var _camera: Camera2D = null
var _strength: float = 0.0
var _duration: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO
var _original_zoom: Vector2 = Vector2.ONE


func bind_camera(camera: Camera2D) -> void:
	_camera = camera
	if _camera:
		_original_offset = _camera.offset
		_original_zoom = _camera.zoom


func shake(strength: float = 8.0, duration: float = 0.4) -> void:
	_strength = maxf(_strength, strength)
	_duration = maxf(_duration, duration)


func _process(delta: float) -> void:
	if _camera == null:
		return
	if _duration <= 0.0:
		_camera.offset = _original_offset
		return
	_duration -= delta
	var decay := _duration / 0.4
	var s := _strength * decay
	_camera.offset = _original_offset + Vector2(
		randf_range(-s, s),
		randf_range(-s, s)
	)
	if _duration <= 0.0:
		_camera.offset = _original_offset
		_strength = 0.0
