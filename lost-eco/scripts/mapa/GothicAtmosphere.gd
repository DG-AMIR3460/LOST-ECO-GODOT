extends Node
class_name GothicAtmosphere
## Viñeta, penumbra global, parallax y niebla que sigue al jugador.

const VIGNETTE_SHADER := preload("res://shaders/vignette_screen.gdshader")
const FOG_SHADER := preload("res://assets/shaders/fog_shader.gdshader")
const PARALLAX_SCRIPT := preload("res://scripts/mapa/GothicParallaxLayers.gd")

var _zone_root: Node2D = null
var _player: Node2D = null
var _vignette_layer: CanvasLayer = null
var _fog_layer: CanvasLayer = null
var _fog_mat: ShaderMaterial = null
var _modulate: CanvasModulate = null
var _theme: String = "cave"
var _light_radius_base: float = 0.22
var _light_radius_pulse: float = 0.02
var _vignette_rect: ColorRect = null


func setup(zone: Node2D, player: Node2D, theme: String = "cave") -> void:
	_zone_root = zone
	_player = player
	_theme = theme
	name = "GothicAtmosphere"
	_attach_modulate()
	_attach_vignette()
	_attach_parallax()
	_attach_fog()
	_apply_theme_defaults()
	set_process(true)


func _apply_theme_defaults() -> void:
	match _theme:
		"cave_bright":
			_light_radius_base = 0.46
			_light_radius_pulse = 0.025
		"labyrinth":
			_light_radius_base = 0.44
		"swamp":
			_light_radius_base = 0.30
		_:
			_light_radius_base = 0.22


func _attach_modulate() -> void:
	_modulate = _zone_root.get_node_or_null("CanvasModulate") as CanvasModulate
	if _modulate == null:
		_modulate = CanvasModulate.new()
		_modulate.name = "CanvasModulate"
		_zone_root.add_child(_modulate)
		_zone_root.move_child(_modulate, 0)
	match _theme:
		"swamp":
			_modulate.color = Color(0.32, 0.34, 0.48, 1.0)
		"river":
			_modulate.color = Color(0.18, 0.28, 0.42, 1.0)
		"cave_bright":
			_modulate.color = Color(0.44, 0.42, 0.54, 1.0)
		"labyrinth":
			_modulate.color = Color(0.38, 0.36, 0.48, 1.0)
		"cave":
			_modulate.color = Color(0.22, 0.2, 0.32, 1.0)
		_:
			_modulate.color = Color(0.28, 0.26, 0.38, 1.0)


func _attach_vignette() -> void:
	var old := _zone_root.get_node_or_null("GothicVignette")
	if old:
		old.queue_free()
	_vignette_layer = CanvasLayer.new()
	_vignette_layer.name = "GothicVignette"
	_vignette_layer.layer = 92
	_zone_root.add_child(_vignette_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE_SHADER
	mat.set_shader_parameter("intensity", 0.78)
	mat.set_shader_parameter("softness", 0.48)
	mat.set_shader_parameter("tint", Color(0.008, 0.006, 0.028, 1.0))
	rect.material = mat
	rect.color = Color.WHITE
	_vignette_layer.add_child(rect)
	_vignette_rect = rect
	if _theme == "cave_bright":
		mat.set_shader_parameter("intensity", 0.40)
		mat.set_shader_parameter("softness", 0.58)


func _attach_parallax() -> void:
	var old := _zone_root.get_node_or_null("GothicParallax")
	if old:
		old.queue_free()
	var para := ParallaxBackground.new()
	para.name = "GothicParallax"
	para.set_script(PARALLAX_SCRIPT)
	_zone_root.add_child(para)
	_zone_root.move_child(para, 0)
	if para.has_method("build"):
		para.build(_player, _theme)


func _attach_fog() -> void:
	var old := _zone_root.get_node_or_null("GothicFogLayer")
	if old:
		old.queue_free()
	_fog_layer = CanvasLayer.new()
	_fog_layer.name = "GothicFogLayer"
	_fog_layer.layer = 88
	_zone_root.add_child(_fog_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = FOG_SHADER
	if _theme == "cave_bright":
		_fog_mat.set_shader_parameter("light_radius", 0.46)
		_fog_mat.set_shader_parameter("edge_softness", 0.24)
		_fog_mat.set_shader_parameter("fog_color", Color(0.05, 0.04, 0.10, 0.52))
	elif _theme == "labyrinth":
		_fog_mat.set_shader_parameter("light_radius", 0.44)
		_fog_mat.set_shader_parameter("edge_softness", 0.20)
		_fog_mat.set_shader_parameter("fog_color", Color(0.06, 0.05, 0.12, 0.62))
	else:
		_fog_mat.set_shader_parameter("light_radius", 0.22)
		_fog_mat.set_shader_parameter("edge_softness", 0.14)
		_fog_mat.set_shader_parameter("fog_color", Color(0.04, 0.03, 0.08, 0.88))
	rect.material = _fog_mat
	rect.color = Color.WHITE
	_fog_layer.add_child(rect)


func _process(_delta: float) -> void:
	if _fog_mat == null or _player == null or not is_instance_valid(_player):
		return
	var vp := get_viewport()
	if vp == null:
		return
	var cam := vp.get_camera_2d()
	if cam == null:
		return
	var screen := vp.get_visible_rect().size
	if screen.x < 1.0:
		return
	var xf := vp.get_canvas_transform()
	var screen_pos := xf * _player.global_position
	var uv := screen_pos / screen
	uv = uv.clamp(Vector2(0.05, 0.05), Vector2(0.95, 0.95))
	_fog_mat.set_shader_parameter("player_pos", uv)
	var radius := _light_radius_base + sin(Time.get_ticks_msec() * 0.001) * _light_radius_pulse
	_fog_mat.set_shader_parameter("light_radius", radius)
