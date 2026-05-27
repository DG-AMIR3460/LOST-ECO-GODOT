extends CanvasLayer
## Transiciones suaves tipo fade entre escenas del juego.

const DEFAULT_FADE_DURATION := 0.55

var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_overlay()


func _build_fade_overlay() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeOverlay"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0.02, 0.02, 0.05, 0.0)
	add_child(_fade_rect)


func change_scene(scene_path: String, fade_duration: float = DEFAULT_FADE_DURATION) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	DialogueManager.clear_all()

	await fade_out(fade_duration)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneTransition: no se pudo cargar %s (error %s)" % [scene_path, error])
	await get_tree().process_frame
	await fade_in(fade_duration)

	_is_transitioning = false


func fade_out(duration: float = DEFAULT_FADE_DURATION) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func fade_in(duration: float = DEFAULT_FADE_DURATION) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
