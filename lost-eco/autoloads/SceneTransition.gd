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
	await _run_scene_change(scene_path, "", fade_duration)


func change_scene_with_cinematic(cinematic_id: String, scene_path: String, fade_duration: float = DEFAULT_FADE_DURATION) -> void:
	await _run_scene_change(scene_path, cinematic_id, fade_duration)


func play_bridge_and_change_scene(completed_zone: int, scene_path: String, fade_duration: float = DEFAULT_FADE_DURATION) -> void:
	var key := ZoneCinematicDirector.get_bridge_key(completed_zone)
	if key.is_empty():
		await change_scene(scene_path, fade_duration)
		return
	await _run_scene_change(scene_path, key, fade_duration)


func force_reset() -> void:
	_is_transitioning = false


func _run_scene_change(scene_path: String, cinematic_id: String, fade_duration: float) -> void:
	if _is_transitioning:
		push_warning("SceneTransition: reiniciando transición bloqueada")
		_is_transitioning = false
	_is_transitioning = true
	DialogueManager.clear_all()
	GameManager.close_pause()

	if not cinematic_id.is_empty():
		await ZoneCinematicDirector.play(cinematic_id)

	await fade_out(fade_duration)
	get_tree().paused = false
	Engine.time_scale = 1.0
	DialogueManager.clear_all()
	if GameManager.player != null:
		GameManager.player = null
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneTransition: no se pudo cargar %s (error %s)" % [scene_path, error])
		var menu_err := get_tree().change_scene_to_file(SettingsManager.MENU_SCENE)
		if menu_err != OK:
			push_error("SceneTransition: tampoco se pudo cargar el menú (error %s)" % menu_err)
		await get_tree().process_frame
		await fade_in(fade_duration)
		_is_transitioning = false
		return
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
