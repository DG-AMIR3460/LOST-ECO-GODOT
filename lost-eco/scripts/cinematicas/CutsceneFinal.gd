extends Node2D
## Cinemática final de Lost Eco — todo generado por código.
## Uso: crea un Node2D vacío, adjunta este script y pulsa Play.

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------

const MENU_SCENE := "res://MainMenu.tscn"
const FADE_DURATION := 2.0
const UI_FONT_PATH := "res://PatrickHand-Regular.ttf"

## Resolución lógica del juego (project.godot → display/window/size).
const VIEWPORT_SIZE := Vector2i(320, 180)

const DIALOGUE_LINES: Array[Dictionary] = [
	{
		"speaker": "Alex",
		"text": "Mateo, por favor no huyas... Fui un cobarde. Lo siento mucho, perdóname.",
	},
	{
		"speaker": "Mateo",
		"text": "...Está bien, Alex. Solo quiero ir a casa.",
	},
]

# Paleta compartida para el pixel art procedural.
const C_TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)
const C_SKIN := Color(0.93, 0.78, 0.62)
const C_SKIN_SHADOW := Color(0.78, 0.62, 0.48)
const C_HAIR := Color(0.28, 0.20, 0.14)
const C_EYE := Color(0.18, 0.14, 0.12)
const C_HOOD_BLUE := Color(0.20, 0.38, 0.78)
const C_HOOD_DARK := Color(0.12, 0.24, 0.55)
const C_JACKET := Color(0.24, 0.24, 0.30)
const C_PANTS := Color(0.16, 0.18, 0.24)
const C_SHOES := Color(0.34, 0.28, 0.22)
const C_MATEO_SHIRT := Color(0.58, 0.74, 0.44)
const C_MATEO_SHORTS := Color(0.42, 0.52, 0.68)
const C_MATEO_SCARF := Color(0.82, 0.62, 0.38)

# ---------------------------------------------------------------------------
# Referencias en runtime
# ---------------------------------------------------------------------------

var _ui_layer: CanvasLayer
var _dialogue_label: RichTextLabel
var _fade_rect: ColorRect

var _dialogue_index: int = 0
var _fade_started: bool = false
var _ui_font: Font


# =============================================================================
# Ciclo de vida
# =============================================================================

func _ready() -> void:
	_ui_font = load(UI_FONT_PATH) as Font
	_build_world()
	_build_ui()
	_show_dialogue_line(0)
	_dialogue_index = 1


func _unhandled_input(event: InputEvent) -> void:
	if _fade_started:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_advance_dialogue()


# =============================================================================
# Construcción de escena
# =============================================================================

func _build_world() -> void:
	# Fondo oscuro del claro final (capa inferior de UI para cubrir toda la pantalla).
	var bg_layer := CanvasLayer.new()
	bg_layer.name = "BackgroundLayer"
	bg_layer.layer = -1
	add_child(bg_layer)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.color = Color(0.05, 0.07, 0.11, 1.0)
	bg_layer.add_child(backdrop)

	# Suelo y línea de horizonte sencilla.
	var ground_layer := CanvasLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.layer = 0
	add_child(ground_layer)

	var ground := ColorRect.new()
	ground.name = "Ground"
	ground.position = Vector2(0.0, 132.0)
	ground.size = Vector2(VIEWPORT_SIZE.x, 48.0)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.color = Color(0.08, 0.12, 0.09, 1.0)
	ground_layer.add_child(ground)

	var ground_line := ColorRect.new()
	ground_line.name = "GroundLine"
	ground_line.position = Vector2(0.0, 131.0)
	ground_line.size = Vector2(VIEWPORT_SIZE.x, 2.0)
	ground_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground_line.color = Color(0.18, 0.28, 0.20, 1.0)
	ground_layer.add_child(ground_line)

	# Personajes frente a frente.
	var alex := _make_sprite_from_texture(_create_alex_texture(), "Alex")
	alex.position = Vector2(96.0, 118.0)
	alex.scale = Vector2(3.0, 3.0)
	add_child(alex)

	var mateo := _make_sprite_from_texture(_create_mateo_texture(), "Mateo")
	mateo.position = Vector2(224.0, 120.0)
	mateo.scale = Vector2(3.0, 3.0)
	mateo.flip_h = true
	add_child(mateo)


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "UILayer"
	_ui_layer.layer = 10
	add_child(_ui_layer)

	# Caja de diálogo inferior.
	var panel := Panel.new()
	panel.name = "DialoguePanel"
	panel.position = Vector2(8.0, 118.0)
	panel.size = Vector2(VIEWPORT_SIZE.x - 16.0, 54.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.05, 0.09, 0.94)
	panel_style.border_color = Color(0.72, 0.58, 0.28, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	_ui_layer.add_child(panel)

	_dialogue_label = RichTextLabel.new()
	_dialogue_label.name = "DialogueText"
	_dialogue_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogue_label.offset_left = 8.0
	_dialogue_label.offset_top = 6.0
	_dialogue_label.offset_right = -8.0
	_dialogue_label.offset_bottom = -6.0
	_dialogue_label.bbcode_enabled = true
	_dialogue_label.fit_content = false
	_dialogue_label.scroll_active = false
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_color_override("default_color", Color(0.92, 0.90, 0.82))
	_dialogue_label.add_theme_font_size_override("normal_font_size", 10)
	if _ui_font:
		_dialogue_label.add_theme_font_override("normal_font", _ui_font)
	panel.add_child(_dialogue_label)

	# Indicador para continuar.
	var hint := Label.new()
	hint.name = "ContinueHint"
	hint.text = "[ Enter / Espacio ]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.position = Vector2(VIEWPORT_SIZE.x - 108.0, 104.0)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.65, 0.62, 0.52, 0.85))
	if _ui_font:
		hint.add_theme_font_override("font", _ui_font)
	_ui_layer.add_child(hint)

	# Fade a negro (invisible al inicio, encima de todo).
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeToBlack"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_ui_layer.add_child(_fade_rect)


# =============================================================================
# Pixel art procedural
# =============================================================================

func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	if color.a <= 0.0:
		return
	img.fill_rect(rect, color)


func _make_sprite_from_texture(texture: Texture2D, sprite_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2(0.0, -texture.get_height() * 0.5)
	return sprite


func _create_alex_texture() -> ImageTexture:
	## Alex arrepentido: capucha azul, chaqueta oscura, postura inclinada hacia Mateo.
	var img := Image.create(20, 28, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)

	# Capucha y contorno de cabeza.
	_fill_rect(img, Rect2i(6, 1, 8, 3), C_HOOD_DARK)
	_fill_rect(img, Rect2i(5, 3, 10, 4), C_HOOD_BLUE)
	_fill_rect(img, Rect2i(6, 7, 8, 2), C_HOOD_BLUE)

	# Rostro bajo la capucha.
	_fill_rect(img, Rect2i(7, 7, 6, 5), C_SKIN)
	_fill_rect(img, Rect2i(8, 9, 1, 1), C_EYE)
	_fill_rect(img, Rect2i(11, 9, 1, 1), C_EYE)
	_fill_rect(img, Rect2i(9, 11, 2, 1), C_SKIN_SHADOW)

	# Cuerpo y brazos (postura algo encorvada / arrepentida).
	_fill_rect(img, Rect2i(6, 12, 8, 8), C_JACKET)
	_fill_rect(img, Rect2i(4, 13, 2, 6), C_JACKET)
	_fill_rect(img, Rect2i(14, 14, 2, 5), C_JACKET)
	_fill_rect(img, Rect2i(3, 19, 2, 2), C_SKIN)
	_fill_rect(img, Rect2i(15, 18, 2, 2), C_SKIN)

	# Piernas y zapatos.
	_fill_rect(img, Rect2i(7, 20, 3, 5), C_PANTS)
	_fill_rect(img, Rect2i(11, 20, 3, 5), C_PANTS)
	_fill_rect(img, Rect2i(6, 25, 4, 2), C_SHOES)
	_fill_rect(img, Rect2i(11, 25, 4, 2), C_SHOES)

	return ImageTexture.create_from_image(img)


func _create_mateo_texture() -> ImageTexture:
	## Mateo, niño perdido: ropa verde, más bajo que Alex, expresión contenida.
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)

	# Pelo corto.
	_fill_rect(img, Rect2i(4, 1, 8, 3), C_HAIR)
	_fill_rect(img, Rect2i(5, 0, 6, 1), C_HAIR)

	# Cara.
	_fill_rect(img, Rect2i(5, 4, 6, 5), C_SKIN)
	_fill_rect(img, Rect2i(6, 6, 1, 1), C_EYE)
	_fill_rect(img, Rect2i(9, 6, 1, 1), C_EYE)
	_fill_rect(img, Rect2i(7, 8, 2, 1), C_SKIN_SHADOW)

	# Bufanda / detalle cálido.
	_fill_rect(img, Rect2i(4, 9, 8, 2), C_MATEO_SCARF)

	# Camiseta y brazos.
	_fill_rect(img, Rect2i(4, 11, 8, 6), C_MATEO_SHIRT)
	_fill_rect(img, Rect2i(2, 12, 2, 4), C_MATEO_SHIRT)
	_fill_rect(img, Rect2i(12, 12, 2, 4), C_MATEO_SHIRT)
	_fill_rect(img, Rect2i(1, 16, 2, 2), C_SKIN)
	_fill_rect(img, Rect2i(13, 16, 2, 2), C_SKIN)

	# Pantalón corto.
	_fill_rect(img, Rect2i(5, 17, 6, 3), C_MATEO_SHORTS)

	# Piernas y zapatillas.
	_fill_rect(img, Rect2i(5, 20, 2, 3), C_SKIN_SHADOW)
	_fill_rect(img, Rect2i(9, 20, 2, 3), C_SKIN_SHADOW)
	_fill_rect(img, Rect2i(4, 22, 3, 2), C_SHOES)
	_fill_rect(img, Rect2i(9, 22, 3, 2), C_SHOES)

	return ImageTexture.create_from_image(img)


# =============================================================================
# Diálogo
# =============================================================================

func _show_dialogue_line(index: int) -> void:
	if index < 0 or index >= DIALOGUE_LINES.size():
		return

	var line: Dictionary = DIALOGUE_LINES[index]
	var speaker: String = line.get("speaker", "")
	var body: String = line.get("text", "")

	var speaker_color := Color(0.95, 0.82, 0.42) if speaker == "Alex" else Color(0.62, 0.88, 0.72)
	_dialogue_label.text = (
		"[color=#%s][b]%s:[/b][/color] %s"
		% [speaker_color.to_html(false), speaker, body]
	)


func _advance_dialogue() -> void:
	if _dialogue_index < DIALOGUE_LINES.size():
		_show_dialogue_line(_dialogue_index)
		_dialogue_index += 1
		return

	_start_fade_to_black()


# =============================================================================
# Transición final
# =============================================================================

func _start_fade_to_black() -> void:
	if _fade_started:
		return
	_fade_started = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished

	get_tree().change_scene_to_file(MENU_SCENE)
