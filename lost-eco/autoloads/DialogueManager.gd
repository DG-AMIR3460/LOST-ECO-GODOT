extends Node

signal dialogue_started
signal dialogue_finished

var dialogue_box: Control = null
var current_lines: Array[String] = []
var current_line_index: int = 0
var is_active: bool = false

# Referencia al nodo DialogueBox en el HUD
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

func show_floating_text(text: String, world_position: Vector2, color: Color = Color.WHITE) -> void:
	# Crear texto flotante en pantalla
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.z_index = 100
	get_tree().current_scene.add_child(label)
	label.global_position = world_position
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30, 2.0)
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free).set_delay(2.1)

func show_memory_fragment(fragment_id: int, text: String, color: Color) -> void:
	# Mostrar panel de fragmento de memoria
	if dialogue_box:
		dialogue_box.show_memory(fragment_id, text, color)

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
