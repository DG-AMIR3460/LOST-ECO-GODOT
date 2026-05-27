extends Node2D
## Cinemática de rescate: Alex encuentra a Mateo tras completar la Zona 4.

const UI_FONT_PATH := "res://PatrickHand-Regular.ttf"
const VIEWPORT_SIZE := Vector2i(320, 180)
const GROUND_Y := 142.0
const MENU_SCENE := "res://scenes/menu.tscn"

const DIALOGUE_LINES: Array[Dictionary] = [
	{
		"speaker": "Alex",
		"text": "Mateo... ¿estás ahí? No huyas, por favor.",
	},
	{
		"speaker": "Mateo",
		"text": "¡Aléjate! No sé si puedo confiar en ti...",
	},
	{
		"speaker": "Alex",
		"text": "Tiré el arma. Fui un cobarde. Lo siento mucho, perdóname.",
	},
	{
		"speaker": "Mateo",
		"text": "...Está bien, Alex. Solo quiero ir a casa.",
	},
]

var _ui_layer: CanvasLayer
var _world_root: Node2D
var _dialogue_label: RichTextLabel
var _dialogue_panel: Panel
var _continue_hint: Label
var _fade_rect: ColorRect
var _backdrop: ColorRect
var _vignette: ColorRect
var _title_label: Label
var _menu_layer: CanvasLayer

var _alex: Sprite2D
var _mateo: Sprite2D
var _dialogue_index: int = 0
var _dialogue_active: bool = false
var _sequence_done: bool = false
var _menu_shown: bool = false
var _exiting: bool = false
var _ui_font: Font


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameManager.player = null
	RenderingServer.set_default_clear_color(Color(0.05, 0.07, 0.11))
	_ui_font = load(UI_FONT_PATH) as Font
	_setup_camera()
	_build_world()
	_build_characters()
	_build_ui()
	await _play_intro_sequence()


func _exit_tree() -> void:
	_exiting = true


func _unhandled_input(event: InputEvent) -> void:
	if _menu_shown or not _dialogue_active:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_advance_dialogue()


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.position = Vector2(VIEWPORT_SIZE) * 0.5
	cam.position_smoothing_enabled = false
	add_child(cam)
	cam.make_current()


# =============================================================================
# Escena
# =============================================================================

func _build_world() -> void:
	_world_root = Node2D.new()
	_world_root.name = "World"
	add_child(_world_root)

	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -2
	add_child(bg_layer)

	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.color = Color(0.05, 0.07, 0.11, 1.0)
	bg_layer.add_child(_backdrop)

	var ground_layer := CanvasLayer.new()
	ground_layer.layer = -1
	add_child(ground_layer)

	var ground := ColorRect.new()
	ground.position = Vector2(0.0, 132.0)
	ground.size = Vector2(VIEWPORT_SIZE.x, 48.0)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.color = Color(0.08, 0.12, 0.09, 1.0)
	ground_layer.add_child(ground)

	var ground_line := ColorRect.new()
	ground_line.position = Vector2(0.0, 131.0)
	ground_line.size = Vector2(VIEWPORT_SIZE.x, 2.0)
	ground_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground_line.color = Color(0.18, 0.28, 0.20, 1.0)
	ground_layer.add_child(ground_line)

	for i in 6:
		var tree := ColorRect.new()
		tree.position = Vector2(12.0 + i * 52.0, 88.0)
		tree.size = Vector2(18.0, 44.0)
		tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tree.color = Color(0.04, 0.08, 0.05, 0.9)
		ground_layer.add_child(tree)

	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.color = Color(0.0, 0.0, 0.0, 0.45)
	bg_layer.add_child(_vignette)


func _build_characters() -> void:
	var chars := Node2D.new()
	chars.name = "Characters"
	_world_root.add_child(chars)

	_alex = CharacterArt.make_sprite("alex", 0.14)
	if _alex == null:
		_alex = _fallback_sprite("Alex", Color(0.55, 0.72, 0.95))
	_alex.name = "Alex"
	_alex.position = Vector2(-48.0, GROUND_Y)
	chars.add_child(_alex)

	_mateo = CharacterArt.make_sprite("mateo", 0.36)
	if _mateo == null:
		_mateo = _fallback_sprite("Mateo", Color(0.58, 0.74, 0.44))
	_mateo.name = "Mateo"
	_mateo.position = Vector2(268.0, GROUND_Y)
	_mateo.flip_h = true
	_mateo.modulate = Color(0.75, 0.78, 0.85, 1.0)
	chars.add_child(_mateo)


func _fallback_sprite(sprite_name: String, tint: Color) -> Sprite2D:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(tint)
	var tex := ImageTexture.create_from_image(img)
	var s := Sprite2D.new()
	s.name = sprite_name
	s.texture = tex
	s.centered = true
	s.scale = Vector2(2.5, 2.5)
	return s


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)

	_title_label = Label.new()
	_title_label.text = "EL CLARO"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector2(0.0, 18.0)
	_title_label.size = Vector2(VIEWPORT_SIZE.x, 24.0)
	_title_label.modulate.a = 0.0
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42))
	if _ui_font:
		_title_label.add_theme_font_override("font", _ui_font)
	_ui_layer.add_child(_title_label)

	_dialogue_panel = Panel.new()
	_dialogue_panel.position = Vector2(8.0, 118.0)
	_dialogue_panel.size = Vector2(VIEWPORT_SIZE.x - 16.0, 54.0)
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.modulate.a = 0.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.05, 0.09, 0.94)
	panel_style.border_color = Color(0.72, 0.58, 0.28, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(8)
	_dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	_ui_layer.add_child(_dialogue_panel)

	_dialogue_label = RichTextLabel.new()
	_dialogue_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogue_label.offset_left = 8.0
	_dialogue_label.offset_top = 6.0
	_dialogue_label.offset_right = -8.0
	_dialogue_label.offset_bottom = -6.0
	_dialogue_label.bbcode_enabled = false
	_dialogue_label.scroll_active = false
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_color_override("default_color", Color(0.92, 0.90, 0.82))
	_dialogue_label.add_theme_font_size_override("normal_font_size", 10)
	if _ui_font:
		_dialogue_label.add_theme_font_override("normal_font", _ui_font)
	_dialogue_panel.add_child(_dialogue_label)

	_continue_hint = Label.new()
	_continue_hint.text = "[ Enter / Espacio ]"
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_hint.position = Vector2(VIEWPORT_SIZE.x - 108.0, 104.0)
	_continue_hint.modulate.a = 0.0
	_continue_hint.add_theme_font_size_override("font_size", 8)
	_continue_hint.add_theme_color_override("font_color", Color(0.65, 0.62, 0.52, 0.85))
	if _ui_font:
		_continue_hint.add_theme_font_override("font", _ui_font)
	_ui_layer.add_child(_continue_hint)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 1.0
	_ui_layer.add_child(_fade_rect)


# =============================================================================
# Animación
# =============================================================================

func _play_intro_sequence() -> void:
	if _exiting:
		return

	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "modulate:a", 0.0, 1.2)
	await fade_in.finished
	if _exiting:
		return

	var title_tw := create_tween()
	title_tw.tween_property(_title_label, "modulate:a", 1.0, 0.8)
	await get_tree().create_timer(1.4).timeout
	if _exiting:
		return
	title_tw = create_tween()
	title_tw.tween_property(_title_label, "modulate:a", 0.0, 0.6)
	await title_tw.finished
	if _exiting:
		return

	_start_idle_bob(_mateo, 3.0, 1.2)
	var mateo_base_x := _mateo.position.x
	var mateo_shake := create_tween().set_loops(8)
	mateo_shake.tween_property(_mateo, "position:x", mateo_base_x + 2.0, 0.08)
	mateo_shake.tween_property(_mateo, "position:x", mateo_base_x - 2.0, 0.08)

	_start_walk_bob(_alex)
	var walk := create_tween()
	walk.set_trans(Tween.TRANS_SINE)
	walk.set_ease(Tween.EASE_IN_OUT)
	walk.tween_property(_alex, "position", Vector2(108.0, GROUND_Y), 2.8)
	await walk.finished
	if _exiting:
		return
	_stop_walk_bob(_alex)
	_start_idle_bob(_alex, 2.0, 1.5)

	await get_tree().create_timer(0.4).timeout
	if _exiting:
		return
	if mateo_shake.is_valid():
		mateo_shake.kill()
	_mateo.position.x = mateo_base_x

	await _start_dialogue()


func _start_idle_bob(sprite: Sprite2D, amplitude: float, period: float) -> void:
	if sprite == null:
		return
	sprite.set_meta("bob_amp", amplitude)
	sprite.set_meta("bob_period", period)
	if not sprite.has_meta("bob_base_y"):
		sprite.set_meta("bob_base_y", sprite.position.y)


func _start_walk_bob(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.set_meta("walking", true)
	_start_idle_bob(sprite, 4.0, 0.22)


func _stop_walk_bob(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.set_meta("walking", false)


func _process(_delta: float) -> void:
	if _exiting:
		return
	for sprite in [_alex, _mateo]:
		if sprite == null or not is_instance_valid(sprite) or not sprite.has_meta("bob_base_y"):
			continue
		var base_y: float = sprite.get_meta("bob_base_y")
		var amp: float = sprite.get_meta("bob_amp", 0.0)
		var period: float = sprite.get_meta("bob_period", 1.0)
		if amp <= 0.0 or period <= 0.0:
			continue
		var t := Time.get_ticks_msec() / 1000.0
		var factor := 1.0 if sprite.get_meta("walking", false) else 0.35
		sprite.position.y = base_y + sin(t * TAU / period) * amp * factor


func _start_dialogue() -> void:
	if _exiting:
		return
	_dialogue_active = true
	_dialogue_index = 0

	var panel_in := create_tween()
	panel_in.tween_property(_dialogue_panel, "modulate:a", 1.0, 0.5)
	panel_in.parallel().tween_property(_continue_hint, "modulate:a", 1.0, 0.5)
	await panel_in.finished
	if _exiting:
		return

	_show_dialogue_line(0)
	_dialogue_index = 1


func _show_dialogue_line(index: int) -> void:
	if index < 0 or index >= DIALOGUE_LINES.size() or _dialogue_label == null:
		return
	var line: Dictionary = DIALOGUE_LINES[index]
	var speaker: String = line.get("speaker", "")
	var body: String = line.get("text", "")
	_dialogue_label.text = "%s: %s" % [speaker, body]
	_pulse_speaker(speaker)


func _pulse_speaker(speaker: String) -> void:
	var target := _alex if speaker == "Alex" else _mateo
	if target == null or not is_instance_valid(target):
		return
	if not target.has_meta("base_scale"):
		target.set_meta("base_scale", target.scale)
	var base_scale: Vector2 = target.get_meta("base_scale")
	var tw := create_tween()
	tw.tween_property(target, "scale", base_scale * 1.06, 0.12)
	tw.tween_property(target, "scale", base_scale, 0.18)


func _advance_dialogue() -> void:
	if not _dialogue_active or _sequence_done or _exiting:
		return
	if _dialogue_index < DIALOGUE_LINES.size():
		_show_dialogue_line(_dialogue_index)
		_dialogue_index += 1
		return
	_dialogue_active = false
	await _play_reconciliation()


func _play_reconciliation() -> void:
	if _exiting:
		return
	_sequence_done = true

	var hide_ui := create_tween()
	hide_ui.tween_property(_dialogue_panel, "modulate:a", 0.0, 0.4)
	hide_ui.parallel().tween_property(_continue_hint, "modulate:a", 0.0, 0.4)
	await hide_ui.finished
	if _exiting:
		return

	var dawn := create_tween()
	dawn.tween_method(_apply_dawn_color, 0.0, 1.0, 3.0)
	dawn.parallel().tween_property(_vignette, "modulate:a", 0.15, 3.0)
	if _mateo:
		dawn.parallel().tween_property(_mateo, "modulate", Color.WHITE, 2.5)
	await dawn.finished
	if _exiting:
		return

	if _mateo:
		_mateo.flip_h = false
		_start_walk_bob(_mateo)
		var reunite := create_tween()
		reunite.set_trans(Tween.TRANS_SINE)
		reunite.set_ease(Tween.EASE_IN_OUT)
		reunite.tween_property(_mateo, "position", Vector2(148.0, GROUND_Y), 2.2)
		await reunite.finished
		_stop_walk_bob(_mateo)
	if _exiting:
		return

	_title_label.text = "Ambos caminaron hacia casa.\nFin."
	_title_label.add_theme_font_size_override("font_size", 11)
	var end_title := create_tween()
	end_title.tween_property(_title_label, "modulate:a", 1.0, 1.0)
	await get_tree().create_timer(2.5).timeout
	if _exiting:
		return
	end_title = create_tween()
	end_title.tween_property(_title_label, "modulate:a", 0.0, 0.8)
	await end_title.finished
	if _exiting:
		return

	_show_main_menu_button()


func _apply_dawn_color(t: float) -> void:
	var c := Color(0.05, 0.07, 0.11).lerp(Color(0.55, 0.42, 0.28), t)
	if _backdrop:
		_backdrop.color = c
	RenderingServer.set_default_clear_color(c)


func _show_main_menu_button() -> void:
	if _menu_shown or _exiting:
		return
	_menu_shown = true

	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 20
	add_child(_menu_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_layer.add_child(center)

	var btn := _make_menu_button("Volver al menú principal")
	center.add_child(btn)
	btn.pressed.connect(_on_menu_pressed)

	btn.modulate.a = 0.0
	var btn_in := create_tween()
	btn_in.tween_property(btn, "modulate:a", 1.0, 0.6)


func _make_menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 32)
	b.focus_mode = Control.FOCUS_ALL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.12, 0.2)
	style.border_color = Color(0.75, 0.58, 0.22)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.22, 0.18, 0.28)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65))
	b.add_theme_font_size_override("font_size", 12)
	if _ui_font:
		b.add_theme_font_override("font", _ui_font)
	return b


func _on_menu_pressed() -> void:
	if _exiting:
		return
	_exiting = true
	if _menu_layer:
		_menu_layer.visible = false
	await GameManager.return_to_main_menu()
