extends Node

signal dialogue_started
signal dialogue_finished

const FONT_PATH := "res://PatrickHand-Regular.ttf"
const TITLE_FONT_PATH := "res://Fonts/AmaticSC-Bold.ttf"
const CORNER_WIDTH := 76.0
const INTRO_WIDTH := 220.0

var dialogue_box: Control = null
var current_lines: Array[String] = []
var current_line_index: int = 0
var is_active: bool = false

var _message_layer: CanvasLayer
var _active_banner: Control
var _intro_overlay: ColorRect
var _intro_root: Control
var _intro_active: bool = false
var _corner_panel: PanelContainer
var _corner_tween: Tween
var _ui_font: Font
var _title_font: Font


func _ready() -> void:
	_ui_font = load(FONT_PATH) as Font
	_title_font = load(TITLE_FONT_PATH) as Font


func clear_all() -> void:
	is_active = false
	current_lines.clear()
	current_line_index = 0
	if _corner_tween and _corner_tween.is_valid():
		_corner_tween.kill()
	_corner_tween = null
	dismiss_zone_intro()
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


## placement: "center" (modal + [E]) o "top_right" (esquina, también [E])
func show_zone_intro(
	title: String,
	objective: String,
	hint: String,
	accent: Color = Color(0.95, 0.88, 0.45),
	placement: String = "center"
) -> void:
	_ensure_message_layer()
	dismiss_zone_intro()
	_intro_active = true

	if GameManager.player and GameManager.player.has_method("set_can_move"):
		GameManager.player.set_can_move(false)

	_intro_overlay = ColorRect.new()
	_intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro_overlay.color = Color(0.02, 0.02, 0.06, 0.62)
	_intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_message_layer.add_child(_intro_overlay)

	var panel := _build_intro_panel(title, objective, hint, accent)
	_active_banner = panel

	if placement == "top_right":
		panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		panel.offset_left = -(INTRO_WIDTH + 6.0)
		panel.offset_top = 8.0
		panel.offset_right = -6.0
		_message_layer.add_child(panel)
	else:
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_message_layer.add_child(center)
		center.add_child(panel)
		_intro_root = center

	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.22)


func dismiss_zone_intro() -> void:
	if not _intro_active and _active_banner == null and _intro_overlay == null:
		return
	_intro_active = false

	if _intro_overlay and is_instance_valid(_intro_overlay):
		_intro_overlay.queue_free()
	_intro_overlay = null

	if _intro_root and is_instance_valid(_intro_root):
		_intro_root.queue_free()
		_intro_root = null
		_active_banner = null
	elif _active_banner and is_instance_valid(_active_banner):
		_active_banner.queue_free()
	_active_banner = null

	if GameManager.player and is_instance_valid(GameManager.player):
		if GameManager.player.has_method("set_can_move") and not get_tree().paused:
			GameManager.player.set_can_move(true)


func _unhandled_input(event: InputEvent) -> void:
	if not _intro_active:
		return
	if _intro_continue_pressed(event):
		dismiss_zone_intro()
		get_viewport().set_input_as_handled()


func _intro_continue_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	return false


func show_corner_notice(text: String, color: Color = Color(0.96, 0.94, 0.88), duration: float = 2.2) -> void:
	_show_corner_panel("", text, color, duration, 7, false)


func show_reflection(title: String, body: String, accent: Color, duration: float = 3.5) -> void:
	_show_corner_panel(title, body, accent, duration, 8, true)


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
	panel.offset_top = -30.0 if is_reflection else -22.0
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


func _build_intro_panel(
	title: String,
	objective: String,
	hint: String,
	accent: Color
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(INTRO_WIDTH, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.12, 0.98)
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	if not title.is_empty():
		var title_lbl := _make_ui_label(title, accent, 11, _title_font, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(title_lbl)

	if not objective.is_empty():
		var obj_lbl := _make_ui_label(objective, Color(0.98, 0.96, 0.90), 9, _ui_font, HORIZONTAL_ALIGNMENT_CENTER)
		obj_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(obj_lbl)

	if not hint.is_empty():
		var hint_lbl := _make_ui_label(hint, Color(0.72, 0.85, 1.0), 8, _ui_font, HORIZONTAL_ALIGNMENT_CENTER)
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint_lbl)

	var sep := HSeparator.new()
	box.add_child(sep)

	var continue_lbl := _make_ui_label(
		"[E] Continuar",
		Color(0.55, 0.95, 0.50),
		9,
		_ui_font,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	box.add_child(continue_lbl)

	return panel


func _ensure_message_layer() -> void:
	if _message_layer and is_instance_valid(_message_layer):
		return
	_message_layer = CanvasLayer.new()
	_message_layer.layer = 110
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
	style.bg_color = Color(0.08, 0.06, 0.12, 0.96)
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	if not title.is_empty():
		var prefix := "◆ " if is_reflection else ""
		var title_label := _make_ui_label(prefix + title, accent, title_size, _title_font, HORIZONTAL_ALIGNMENT_LEFT)
		box.add_child(title_label)

	if not body.is_empty():
		var body_label := _make_ui_label(body, Color(0.98, 0.96, 0.90), body_size, _ui_font, HORIZONTAL_ALIGNMENT_LEFT)
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
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
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
