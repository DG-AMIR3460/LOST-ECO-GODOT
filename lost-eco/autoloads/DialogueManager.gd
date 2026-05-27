extends Node

signal dialogue_started
signal dialogue_finished

const FONT_PATH := "res://PatrickHand-Regular.ttf"
const TITLE_FONT_PATH := "res://Fonts/AmaticSC-Bold.ttf"
const CORNER_WIDTH := 148.0

var dialogue_box: Control = null
var current_lines: Array[String] = []
var current_line_index: int = 0
var is_active: bool = false

var _message_layer: CanvasLayer
var _active_banner: Control
var _corner_panel: PanelContainer
var _corner_tween: Tween
var _intro_tween: Tween
var _ui_font: Font
var _title_font: Font


func _ready() -> void:
	_ui_font = load(FONT_PATH) as Font
	_title_font = load(TITLE_FONT_PATH) as Font


func clear_all() -> void:
	is_active = false
	current_lines.clear()
	current_line_index = 0
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	if _corner_tween and _corner_tween.is_valid():
		_corner_tween.kill()
	_corner_tween = null
	_unbind_intro_dismiss_on_move()
	_active_banner = null
	_corner_panel = null
	if dialogue_box and is_instance_valid(dialogue_box):
		dialogue_box.hide()
	if _message_layer and is_instance_valid(_message_layer):
		for child in _message_layer.get_children():
			child.queue_free()


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
	dismiss_zone_intro()

	var banner := _build_compact_panel(title, objective, hint, accent, 11, 9)
	banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
	banner.offset_left = 4.0
	banner.offset_top = 52.0
	banner.offset_right = 4.0 + CORNER_WIDTH
	_message_layer.add_child(banner)
	_active_banner = banner

	banner.modulate.a = 0.0
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = create_tween()
	_intro_tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	_intro_tween.tween_interval(3.0)
	_intro_tween.tween_property(banner, "modulate:a", 0.0, 0.25)
	_intro_tween.tween_callback(func() -> void:
		_active_banner = null
		_unbind_intro_dismiss_on_move()
		if is_instance_valid(banner):
			banner.queue_free()
	)
	_bind_intro_dismiss_on_move()


func dismiss_zone_intro() -> void:
	if not _active_banner or not is_instance_valid(_active_banner):
		return
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	var banner := _active_banner
	_active_banner = null
	_unbind_intro_dismiss_on_move()
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 0.0, 0.12)
	tween.tween_callback(banner.queue_free)


func show_corner_notice(text: String, color: Color = Color(0.92, 0.90, 0.82), duration: float = 3.0) -> void:
	_show_corner_panel("", text, color, duration, 9, false)


func show_reflection(title: String, body: String, accent: Color, duration: float = 4.5) -> void:
	_show_corner_panel(title, body, accent, duration, 9, true)


func show_floating_text(text: String, _world_position: Vector2 = Vector2.ZERO, color: Color = Color.WHITE, duration: float = 2.8) -> void:
	show_corner_notice(text, color, duration)


func show_memory_fragment(fragment_id: int, text: String, color: Color) -> void:
	if dialogue_box:
		dialogue_box.show_memory(fragment_id, text, color)


func _show_corner_panel(title: String, body: String, accent: Color, duration: float, font_size: int, is_reflection: bool) -> void:
	_ensure_message_layer()
	if _corner_panel and is_instance_valid(_corner_panel):
		_corner_panel.queue_free()
	if _corner_tween and _corner_tween.is_valid():
		_corner_tween.kill()

	var panel := _build_compact_panel(title, body, "", accent, font_size + 1 if is_reflection else font_size, font_size, is_reflection)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 4.0
	panel.offset_bottom = -4.0
	panel.offset_right = 4.0 + CORNER_WIDTH
	panel.offset_top = -52.0 if is_reflection else -38.0
	_message_layer.add_child(panel)
	_corner_panel = panel

	panel.modulate.a = 0.0
	_corner_tween = create_tween()
	_corner_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	_corner_tween.tween_interval(duration)
	_corner_tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	_corner_tween.tween_callback(func() -> void:
		if _corner_panel == panel:
			_corner_panel = null
		if is_instance_valid(panel):
			panel.queue_free()
	)


func _bind_intro_dismiss_on_move() -> void:
	if GameManager.player == null:
		call_deferred("_bind_intro_dismiss_on_move")
		return
	if not GameManager.player.action_performed.is_connected(_on_player_action_dismiss_intro):
		GameManager.player.action_performed.connect(_on_player_action_dismiss_intro)


func _unbind_intro_dismiss_on_move() -> void:
	if GameManager.player and GameManager.player.action_performed.is_connected(_on_player_action_dismiss_intro):
		GameManager.player.action_performed.disconnect(_on_player_action_dismiss_intro)


func _on_player_action_dismiss_intro(action_name: String, _intensity: float) -> void:
	if action_name == "move":
		dismiss_zone_intro()


func _ensure_message_layer() -> void:
	if _message_layer and is_instance_valid(_message_layer):
		return
	_message_layer = CanvasLayer.new()
	_message_layer.layer = 90
	_message_layer.name = "MessageLayer"
	add_child(_message_layer)


func _build_compact_panel(
	title: String,
	body: String,
	hint: String,
	accent: Color,
	title_size: int,
	body_size: int,
	is_reflection: bool = false
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CORNER_WIDTH, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.07, 0.94)
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 3
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	if not title.is_empty():
		var prefix := "◆ " if is_reflection else ""
		var title_label := _make_ui_label(prefix + title, accent, title_size, _title_font, HORIZONTAL_ALIGNMENT_LEFT)
		box.add_child(title_label)

	if not body.is_empty():
		var body_label := _make_ui_label(body, Color(0.94, 0.92, 0.86), body_size, _ui_font, HORIZONTAL_ALIGNMENT_LEFT)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(body_label)

	if not hint.is_empty():
		var hint_label := _make_ui_label(hint, Color(0.72, 0.85, 1.0), body_size - 1, _ui_font, HORIZONTAL_ALIGNMENT_LEFT)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint_label)

	return panel


func _make_ui_label(text: String, color: Color, size: int, font: Font, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
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
