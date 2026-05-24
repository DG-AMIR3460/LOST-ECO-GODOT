extends Node

signal dialogue_started
signal dialogue_finished

const FONT_PATH := "res://PatrickHand-Regular.ttf"
const TITLE_FONT_PATH := "res://Fonts/AmaticSC-Bold.ttf"

var dialogue_box: Control = null
var current_lines: Array[String] = []
var current_line_index: int = 0
var is_active: bool = false

var _message_layer: CanvasLayer
var _active_banner: Control
var _ui_font: Font
var _title_font: Font


func _ready() -> void:
	_ui_font = load(FONT_PATH) as Font
	_title_font = load(TITLE_FONT_PATH) as Font


func register_dialogue_box(box: Control) -> void:
	dialogue_box = box


func start_dialogue(dialogue_key: String, _caller: Node = null) -> void:
	var lines = _get_dialogue_lines(dialogue_key)
	if lines.is_empty():
		return
	current_lines = lines
	current_line_index = 0
	is_active = true
	dialogue_started.emit()
	_show_current_line()


func advance() -> void:
	if not is_active:
		return
	current_line_index += 1
	if current_line_index >= current_lines.size():
		_end_dialogue()
	else:
		_show_current_line()


func _show_current_line() -> void:
	if dialogue_box and current_line_index < current_lines.size():
		dialogue_box.show_line(current_lines[current_line_index])


func _end_dialogue() -> void:
	is_active = false
	if dialogue_box:
		dialogue_box.hide()
	dialogue_finished.emit()


func show_zone_intro(title: String, objective: String, hint: String, accent: Color = Color(0.95, 0.88, 0.45)) -> void:
	_ensure_message_layer()
	if _active_banner and is_instance_valid(_active_banner):
		_active_banner.queue_free()

	var banner := _build_intro_banner(title, objective, hint, accent)
	_message_layer.add_child(banner)
	_active_banner = banner

	banner.modulate.a = 0.0
	banner.scale = Vector2(0.94, 0.94)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(6.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.45)
	tween.tween_callback(banner.queue_free)


func show_floating_text(text: String, world_position: Vector2, color: Color = Color.WHITE, duration: float = 2.8) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var bubble := _build_world_bubble(text, color)
	scene.add_child(bubble)
	bubble.reset_size()
	bubble.global_position = world_position + Vector2(-bubble.size.x * 0.5, -bubble.size.y - 6)

	bubble.modulate.a = 0.0
	bubble.scale = Vector2(0.88, 0.88)
	var tween := bubble.create_tween()
	tween.tween_property(bubble, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(bubble, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(maxf(0.8, duration - 0.8))
	tween.tween_property(bubble, "position:y", bubble.position.y - 16, 0.55)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.55)
	tween.tween_callback(bubble.queue_free)


func show_memory_fragment(fragment_id: int, text: String, color: Color) -> void:
	if dialogue_box:
		dialogue_box.show_memory(fragment_id, text, color)


func _ensure_message_layer() -> void:
	if _message_layer and is_instance_valid(_message_layer):
		return
	_message_layer = CanvasLayer.new()
	_message_layer.layer = 90
	_message_layer.name = "MessageLayer"
	add_child(_message_layer)


func _build_intro_banner(title: String, objective: String, hint: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 10.0
	panel.offset_top = 6.0
	panel.offset_right = -10.0
	panel.offset_bottom = 72.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.92)
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var title_label := _make_ui_label(title, accent, 15, _title_font, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title_label)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(accent.r, accent.g, accent.b, 0.35)
	box.add_child(sep)

	var objective_label := _make_ui_label(objective, Color(0.96, 0.94, 0.88), 11, _ui_font, HORIZONTAL_ALIGNMENT_CENTER)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(objective_label)

	var hint_label := _make_ui_label(hint, Color(0.75, 0.88, 1.0), 10, _ui_font, HORIZONTAL_ALIGNMENT_CENTER)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint_label)

	return panel


func _build_world_bubble(text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.06, 0.88)
	style.border_color = Color(color.r, color.g, color.b, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

	var label := _make_ui_label(text, color, 10, _ui_font, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(120, 0)
	panel.add_child(label)
	panel.reset_size()
	return panel


func _make_ui_label(text: String, color: Color, size: int, font: Font, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", size)
	if font:
		label.add_theme_font_override("font", font)
	return label


func _get_dialogue_lines(key: String) -> Array[String]:
	var dialogues: Dictionary = {
		"la_voz_stage_0": [
			"La Voz: ...¿Escuchas los árboles?",
			"La Voz: Llevan siglos absorbiendo las palabras que la gente lanza.",
			"La Voz: Palabras que duelen como cuchillos... o como las tuyas."
		],
		"la_voz_stage_1": [
			"La Voz: La luz no borra lo que dijiste, niño.",
			"La Voz: Pero sí te ayuda a ver lo que causaste."
		],
		"la_voz_stage_2": [
			"La Voz: El laberinto ha terminado.",
			"La Voz: Recuerda: cada eco que encontraste era la voz de alguien que intentaba ser escuchado."
		],
		"climax_base": [
			"Alex: Mateo... espera.",
			"Alex: No voy a hacerte nada. Tiré el arma.",
			"Alex: Estos días en el bosque... sentí lo que tú sentías en la escuela.",
			"Alex: El miedo. La soledad. No poder escapar.",
			"Alex: Fui un cobarde. Y lo siento."
		],
		"climax_full": [
			"Alex: Mateo... encontré tus cosas por el bosque.",
			"Alex: Tu mochila rota. Tu cuaderno con tachones. El teléfono.",
			"Alex: Leí tu carta. La que nunca enviaste.",
			"Alex: ...",
			"Alex: Lo siento. De verdad. No tenía idea de cuánto te hacíamos daño.",
			"Alex: ¿Puedes perdonarme?"
		],
	}
	return dialogues.get(key, [])
