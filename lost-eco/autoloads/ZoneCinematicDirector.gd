extends Node
## Cinemáticas entre niveles — centradas en cualquier resolución / aspect ratio.

signal cinematic_finished(cinematic_id: String)

const UI_FONT := "res://PatrickHand-Regular.ttf"
const TITLE_FONT := "res://Fonts/AmaticSC-Bold.ttf"
const PANEL_MIN := Vector2(260, 100)
const PANEL_MAX := Vector2(300, 140)

const CINEMATICS: Dictionary = {
	"intro_campaign": {
		"bg": Color(0.06, 0.05, 0.12, 1.0),
		"accent": Color(0.95, 0.88, 0.42),
		"skip_next_intro": false,
		"slides": [
			{"kind": "title", "title": "LOST ECO", "subtitle": "Un bosque de palabras", "duration": 2.5},
			{"kind": "quote", "speaker": "La Voz", "body": "Alex... el bosque guarda lo que dijiste\ny lo que no viste en los ojos de Mateo.", "duration": 3.2},
			{"kind": "chapter", "title": "ZONA 1", "subtitle": "El Río", "body": "3 ecos en la corriente.\n[E] interactuar  [J] pulso de luz", "duration": 3.0},
		],
	},
	"bridge_1_2": {
		"bg": Color(0.05, 0.08, 0.06, 1.0),
		"accent": Color(0.65, 0.95, 0.50),
		"skip_next_intro": false,
		"slides": [
			{"kind": "title", "title": "Zona superada", "subtitle": "El Río", "duration": 2.2},
			{"kind": "quote", "speaker": "La Voz", "body": "Cruzaste la corriente.\nEl laberinto te espera.", "duration": 3.0},
			{"kind": "chapter", "title": "ZONA 2", "subtitle": "Laberinto de Palabras", "body": "Recoge 4 ecos de luz.", "duration": 2.8},
		],
	},
	"bridge_2_3": {
		"bg": Color(0.04, 0.04, 0.10, 1.0),
		"accent": Color(0.85, 0.70, 1.0),
		"skip_next_intro": false,
		"slides": [
			{"kind": "title", "title": "Zona superada", "subtitle": "Laberinto de Palabras", "duration": 2.2},
			{"kind": "quote", "speaker": "La Voz", "body": "Escuchaste ecos ajenos.\nEl pantano te espera.", "duration": 3.0},
			{"kind": "chapter", "title": "ZONA 3", "subtitle": "El Pantano", "body": "Pilares [E] + 3 ecos.", "duration": 2.8},
		],
	},
	"bridge_3_4": {
		"bg": Color(0.03, 0.06, 0.12, 1.0),
		"accent": Color(0.50, 0.88, 0.82),
		"skip_next_intro": false,
		"slides": [
			{"kind": "title", "title": "Zona superada", "subtitle": "El Pantano", "duration": 2.2},
			{"kind": "quote", "speaker": "La Voz", "body": "La paciencia abrió camino.\nMira tu reflejo en la cueva.", "duration": 3.0},
			{"kind": "chapter", "title": "ZONA 4", "subtitle": "Cueva del Espejo", "body": "Cristales [E]. Derrota al jefe con [J].", "duration": 2.8},
		],
	},
	"bridge_4_clearing": {
		"bg": Color(0.05, 0.07, 0.10, 1.0),
		"accent": Color(0.55, 0.92, 0.70),
		"skip_next_intro": false,
		"slides": [
			{"kind": "title", "title": "Zona superada", "subtitle": "Cueva del Espejo", "duration": 2.2},
			{"kind": "quote", "speaker": "La Voz", "body": "Elegiste empatía.\nAlex encuentra a Mateo en el claro.", "duration": 3.2},
			{"kind": "chapter", "title": "EL CLARO", "subtitle": "Final", "body": "Palabras honestas. Sin violencia.", "duration": 2.8},
		],
	},
}

var _layer: CanvasLayer = null
var _root: Control = null
var _center: CenterContainer = null
var _frame: PanelContainer = null
var _content: MarginContainer = null
var _skip_btn: Button = null
var _playing: bool = false
var _slide_timer: float = 0.0
var _ui_font: Font
var _title_font: Font
var _skip_next_zone_intro: bool = false
var _current_data: Dictionary = {}
var _slide_index: int = 0
var _slides: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_font = load(UI_FONT) as Font
	_title_font = load(TITLE_FONT) as Font


func _process(delta: float) -> void:
	if not _playing:
		return
	_slide_timer -= delta
	if _slide_timer <= 0.0:
		_advance_slide()
		return
	if _wants_skip():
		_end_playback()


func is_playing() -> bool:
	return _playing


func consume_skip_zone_intro() -> bool:
	var v := _skip_next_zone_intro
	_skip_next_zone_intro = false
	return v


func get_bridge_key(completed_zone: int) -> String:
	match completed_zone:
		1: return "bridge_1_2"
		2: return "bridge_2_3"
		3: return "bridge_3_4"
		4: return "bridge_4_clearing"
		_: return ""


func play(cinematic_id: String) -> void:
	var data: Dictionary = CINEMATICS.get(cinematic_id, {})
	if data.is_empty():
		push_warning("ZoneCinematicDirector: cinemática '%s' no existe" % cinematic_id)
		return
	if _playing:
		await cinematic_finished
		return

	get_tree().paused = false
	Engine.time_scale = 1.0
	_playing = true
	_current_data = data
	_skip_next_zone_intro = data.get("skip_next_intro", false)
	DialogueManager.clear_all()
	GameManager.close_pause()

	_build_ui(data)
	_slide_index = 0
	_slides = data.get("slides", [])
	_show_current_slide()
	_sync_root_to_viewport()

	while _playing:
		await get_tree().process_frame

	_teardown()
	_playing = false
	_current_data = {}
	cinematic_finished.emit(cinematic_id)


func _sync_root_to_viewport() -> void:
	if _root == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var size := vp.get_visible_rect().size
	_root.set_size(size)
	_root.position = Vector2.ZERO


func _show_current_slide() -> void:
	if _slide_index >= _slides.size():
		_end_playback()
		return
	var slide: Dictionary = _slides[_slide_index]
	if _content == null:
		return
	for c in _content.get_children():
		c.queue_free()

	var accent: Color = _current_data.get("accent", Color(0.9, 0.85, 0.45))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	_content.add_child(box)

	match slide.get("kind", "title"):
		"quote":
			_build_quote(box, slide, accent)
		"chapter":
			_build_chapter(box, slide, accent)
		_:
			_build_title(box, slide, accent)

	_slide_timer = slide.get("duration", 2.5)


func _advance_slide() -> void:
	_slide_index += 1
	if _slide_index >= _slides.size():
		_end_playback()
	else:
		_show_current_slide()


func _end_playback() -> void:
	if not _playing:
		return
	_playing = false
	_slide_timer = 0.0


func _wants_skip() -> bool:
	return (
		Input.is_action_just_pressed("interact")
		or Input.is_action_just_pressed("pause")
		or Input.is_action_just_pressed("attack")
	)


func _build_ui(data: Dictionary) -> void:
	_teardown()
	_layer = CanvasLayer.new()
	_layer.layer = 128
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_root)

	var vp := get_viewport()
	if vp:
		vp.size_changed.connect(_sync_root_to_viewport)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = data.get("bg", Color(0.05, 0.04, 0.10))
	_root.add_child(bg)

	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_center)

	_frame = PanelContainer.new()
	_frame.custom_minimum_size = PANEL_MIN
	_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.14, 0.94)
	style.border_color = data.get("accent", Color(0.9, 0.85, 0.4))
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_frame.add_theme_stylebox_override("panel", style)
	_center.add_child(_frame)

	_content = MarginContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_frame.add_child(_content)

	var skip_row := CenterContainer.new()
	skip_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	skip_row.offset_top = -26.0
	skip_row.offset_bottom = -4.0
	_root.add_child(skip_row)

	_skip_btn = Button.new()
	_skip_btn.text = "Continuar  [E]"
	_skip_btn.custom_minimum_size = Vector2(120, 18)
	if _ui_font:
		_skip_btn.add_theme_font_override("font", _ui_font)
	_skip_btn.add_theme_font_size_override("font_size", 9)
	_skip_btn.pressed.connect(_end_playback)
	skip_row.add_child(_skip_btn)


func _build_title(box: VBoxContainer, slide: Dictionary, accent: Color) -> void:
	_add_lbl(box, slide.get("title", ""), 18, accent, true)
	if slide.has("subtitle"):
		_add_lbl(box, slide.get("subtitle", ""), 9, Color(0.88, 0.86, 0.78), false)


func _build_chapter(box: VBoxContainer, slide: Dictionary, accent: Color) -> void:
	_add_lbl(box, "Siguiente zona", 8, Color(0.6, 0.65, 0.75), false)
	_add_lbl(box, slide.get("title", ""), 16, accent, true)
	_add_lbl(box, slide.get("subtitle", ""), 10, Color(0.92, 0.88, 0.72), true)
	if slide.has("body"):
		_add_lbl(box, slide.get("body", ""), 8, Color(0.9, 0.9, 0.85), false)


func _build_quote(box: VBoxContainer, slide: Dictionary, accent: Color) -> void:
	_add_lbl(box, slide.get("speaker", "La Voz"), 9, accent, true)
	_add_lbl(box, '"%s"' % slide.get("body", ""), 8, Color(0.95, 0.93, 0.88), false)


func _add_lbl(parent: Node, text: String, size: int, color: Color, title_font: bool) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	var f: Font = _title_font if title_font and _title_font else _ui_font
	if f:
		lbl.add_theme_font_override("font", f)
	parent.add_child(lbl)


func _teardown() -> void:
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_sync_root_to_viewport):
		vp.size_changed.disconnect(_sync_root_to_viewport)
	if _layer and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_root = null
	_center = null
	_frame = null
	_content = null
	_skip_btn = null


func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		_end_playback()
		get_viewport().set_input_as_handled()
