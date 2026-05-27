extends Node
class_name AccessibilityManager
## Alto contraste: ShaderMaterial + BackBufferCopy (sin built-ins de shader en GDScript).

signal high_contrast_toggled(enabled: bool)

@export var edge_shader: Shader = preload("res://shaders/edge_detect_high_contrast.gdshader")

var _enabled: bool = false
var _overlay: ColorRect = null
var _shader_mat: ShaderMaterial = null
var _viewport_root: Node = null
var _filter_layer: CanvasLayer = null


func bind_viewport_root(root: Node) -> void:
	_viewport_root = root
	_build_overlay()


func _build_overlay() -> void:
	if _viewport_root == null:
		return
	if _filter_layer and is_instance_valid(_filter_layer):
		_filter_layer.queue_free()

	_filter_layer = CanvasLayer.new()
	_filter_layer.name = "HighContrastLayer"
	_filter_layer.layer = 100
	_filter_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_viewport_root.add_child(_filter_layer)

	var back_buffer := BackBufferCopy.new()
	back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	back_buffer.name = "HighContrastBackBuffer"
	_filter_layer.add_child(back_buffer)

	_overlay = ColorRect.new()
	_overlay.name = "HighContrastOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	_overlay.color = Color(1.0, 1.0, 1.0, 1.0)

	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = edge_shader
	_shader_mat.set_shader_parameter("edge_strength", 3.2)
	_shader_mat.set_shader_parameter("threshold", 0.07)
	_overlay.material = _shader_mat

	_filter_layer.add_child(_overlay)


func toggle_high_contrast() -> void:
	_enabled = not _enabled
	if _overlay:
		_overlay.visible = _enabled
	_apply_sprite_fallback(_enabled)
	high_contrast_toggled.emit(_enabled)


func set_high_contrast(enabled: bool) -> void:
	if _enabled != enabled:
		toggle_high_contrast()


func is_high_contrast() -> bool:
	return _enabled


func _apply_sprite_fallback(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node is PlayerController2D and node.sprite:
			node.sprite.self_modulate = Color(0.98, 0.92, 0.18) if enabled else Color.WHITE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyAIBase and enemy.sprite:
			enemy.sprite.self_modulate = Color(0.95, 0.15, 0.22) if enabled else Color(0.85, 0.75, 0.78)
