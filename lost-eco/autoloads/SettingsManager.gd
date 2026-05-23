extends Node
## Gestor global de configuración: audio, pantalla y filtros de daltonismo.
## Persiste los ajustes en user://settings.cfg y los aplica al iniciar.

signal settings_changed

enum ColorblindMode { NORMAL, PROTANOPIA, DEUTERANOPIA, TRITANOPIA }

const SETTINGS_PATH := "user://settings.cfg"
const GAME_SCENE := "res://scenes/world/Zone1_Labyrinth.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const OPTIONS_SCENE := "res://scenes/opciones.tscn"

## Resolución interna del juego (viewport lógico). La ventana escala encima de esto.
const BASE_VIEWPORT := Vector2i(320, 180)

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(640, 360),
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false
var resolution_index: int = 2
var colorblind_mode: ColorblindMode = ColorblindMode.NORMAL

var _filter_layer: CanvasLayer
var _filter_rect: ColorRect
var _filter_material: ShaderMaterial


func _ready() -> void:
	_setup_audio_buses()
	_setup_colorblind_overlay()
	_load_settings()
	apply_audio_volumes()
	apply_colorblind_filter()
	# La ventana principal aún no está lista en el primer frame del autoload.
	call_deferred("apply_display_settings")


func _setup_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _setup_colorblind_overlay() -> void:
	_filter_layer = CanvasLayer.new()
	_filter_layer.layer = 128
	_filter_layer.name = "ColorblindFilterLayer"
	add_child(_filter_layer)

	var back_buffer := BackBufferCopy.new()
	back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	_filter_layer.add_child(back_buffer)

	_filter_rect = ColorRect.new()
	_filter_rect.name = "ColorblindFilter"
	_filter_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_filter_rect.color = Color(1, 1, 1, 1)
	_filter_layer.add_child(_filter_rect)

	var shader := load("res://shaders/colorblind_filter.gdshader") as Shader
	_filter_material = ShaderMaterial.new()
	_filter_material.shader = shader
	_filter_material.set_shader_parameter("mode", ColorblindMode.NORMAL)
	_filter_rect.material = _filter_material
	_filter_rect.visible = false


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	master_volume = config.get_value("audio", "master", master_volume)
	music_volume = config.get_value("audio", "music", music_volume)
	sfx_volume = config.get_value("audio", "sfx", sfx_volume)
	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	resolution_index = config.get_value("display", "resolution_index", resolution_index)
	colorblind_mode = config.get_value("accessibility", "colorblind_mode", colorblind_mode)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "resolution_index", resolution_index)
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	config.save(SETTINGS_PATH)
	settings_changed.emit()


func apply_all_settings() -> void:
	apply_audio_volumes()
	apply_display_settings()
	apply_colorblind_filter()


func apply_audio_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	var music_index := AudioServer.get_bus_index("Music")
	if music_index != -1:
		AudioServer.set_bus_volume_db(music_index, linear_to_db(music_volume))
	var sfx_index := AudioServer.get_bus_index("SFX")
	if sfx_index != -1:
		AudioServer.set_bus_volume_db(sfx_index, linear_to_db(sfx_volume))


func apply_display_settings() -> void:
	if not is_inside_tree():
		return
	_apply_display_settings_now()
	call_deferred("_verify_window_size_next_frame")


func get_current_resolution() -> Vector2i:
	if resolution_index >= 0 and resolution_index < RESOLUTIONS.size():
		return RESOLUTIONS[resolution_index]
	return Vector2i(1280, 720)


func _get_main_window() -> Window:
	return get_tree().root as Window


func _apply_display_settings_now() -> void:
	var window := _get_main_window()
	var target_size := get_current_resolution()

	# Configura el escalado interno (320x180) y deja que la ventana controle el tamaño físico.
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_size = BASE_VIEWPORT
	window.unresizable = false
	window.min_size = Vector2i(320, 180)
	window.max_size = Vector2i(7680, 4320)

	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return

	# Modo ventana: aplicar tamaño real de inmediato por ambas vías (Window + DisplayServer).
	window.mode = Window.MODE_WINDOWED
	window.borderless = false

	ProjectSettings.set_setting("display/window/size/window_width_override", target_size.x)
	ProjectSettings.set_setting("display/window/size/window_height_override", target_size.y)

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(target_size)
	window.size = target_size
	_center_window_on_screen(window, target_size)


func _verify_window_size_next_frame() -> void:
	if not is_inside_tree() or fullscreen:
		return

	await get_tree().process_frame

	var window := _get_main_window()
	var target_size := get_current_resolution()
	var current_size := DisplayServer.window_get_size()

	if current_size != target_size:
		DisplayServer.window_set_size(target_size)
		window.size = target_size
		_center_window_on_screen(window, target_size)


func _center_window_on_screen(window: Window, size: Vector2i) -> void:
	var screen_index := window.current_screen
	var screen_position := DisplayServer.screen_get_position(screen_index)
	var screen_size := DisplayServer.screen_get_size(screen_index)
	var centered := screen_position + (screen_size - size) / 2
	DisplayServer.window_set_position(centered)
	window.position = centered


func apply_colorblind_filter() -> void:
	if _filter_material == null:
		return

	_filter_material.set_shader_parameter("mode", colorblind_mode)
	_filter_rect.visible = colorblind_mode != ColorblindMode.NORMAL


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio_volumes()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_audio_volumes()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio_volumes()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_display_settings()


func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	apply_display_settings()


func set_colorblind_mode(mode: ColorblindMode) -> void:
	colorblind_mode = mode
	apply_colorblind_filter()


func get_resolution_label(index: int) -> String:
	if index < 0 or index >= RESOLUTIONS.size():
		return "Desconocida"
	var size := RESOLUTIONS[index]
	return "%dx%d" % [size.x, size.y]
