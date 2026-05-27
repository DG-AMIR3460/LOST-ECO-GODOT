extends Node
class_name DeathCinematicDirector

const DEATH_SHADER := preload("res://shaders/death_bleed.gdshader")
const MENU_SCENE := "res://scenes/menu.tscn"
const RETRY_SCENE := "res://scenes/core/pantano_world.tscn"
const UI_FONT := "res://PatrickHand-Regular.ttf"

var _session: GameSession = null
var _screen_shake: ScreenShake = null
var _playing: bool = false
var _overlay_layer: CanvasLayer = null
var _game_over_layer: CanvasLayer = null


func configure(session: GameSession, screen_shake: ScreenShake) -> void:
	_session = session
	_screen_shake = screen_shake
	reset_state()


func reset_state() -> void:
	_playing = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	_cleanup_layers()


func _cleanup_layers() -> void:
	if _overlay_layer and is_instance_valid(_overlay_layer):
		_overlay_layer.queue_free()
		_overlay_layer = null
	if _game_over_layer and is_instance_valid(_game_over_layer):
		_game_over_layer.queue_free()
		_game_over_layer = null


func play(player: PlayerController2D) -> void:
	if _playing:
		return
	if _session and _session.is_alive():
		return
	if player == null or not is_instance_valid(player):
		return
	_playing = true
	player.input_locked = true
	var phrase := _session.last_cyberbullying_phrase if _session else "..."
	var tree := player.get_tree()
	tree.paused = false
	Engine.time_scale = 0.15
	if _screen_shake and player.camera:
		_screen_shake.bind_camera(player.camera)
		_screen_shake.shake(14.0, 0.85)
	await _zoom_camera(player)
	await _run_death_shader(player)
	Engine.time_scale = 1.0
	_show_game_over_ui(phrase)


func _zoom_camera(player: PlayerController2D) -> void:
	if player.camera == null:
		await get_tree().create_timer(0.5).timeout
		return
	var cam := player.camera
	cam.make_current()
	var tw := player.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(cam, "zoom", Vector2(2.4, 2.4), 0.9).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func _run_death_shader(player: PlayerController2D) -> void:
	_cleanup_layers()
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 200
	_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_overlay_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = DEATH_SHADER
	mat.set_shader_parameter("bleed", 0.0)
	rect.material = mat
	_overlay_layer.add_child(rect)
	var tw := rect.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(func(v: float): mat.set_shader_parameter("bleed", v), 0.0, 1.0, 1.0)
	await tw.finished


func _show_game_over_ui(phrase: String) -> void:
	_cleanup_layers()
	_game_over_layer = CanvasLayer.new()
	_game_over_layer.layer = 210
	_game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_game_over_layer)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.01, 0.03, 0.92)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_over_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_layer.add_child(center)

	var panel := PanelContainer.new()
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.05, 0.04, 0.09, 0.95)
	pstyle.border_color = Color(0.85, 0.68, 0.28, 0.9)
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", pstyle)
	panel.custom_minimum_size = Vector2(240, 130)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var font_res: Font = load(UI_FONT) as Font
	var title := Label.new()
	title.text = "LOST ECO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42))
	if font_res:
		title.add_theme_font_override("font", font_res)
	box.add_child(title)

	var sub := Label.new()
	sub.text = "\"%s\"" % phrase
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 200.0
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.82, 0.32, 0.36))
	if font_res:
		sub.add_theme_font_override("font", font_res)
	box.add_child(sub)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	box.add_child(btn_row)

	var retry := _make_button("Reintentar", font_res)
	var menu := _make_button("Menú principal", font_res)
	btn_row.add_child(retry)
	btn_row.add_child(menu)

	retry.pressed.connect(_on_retry_pressed)
	menu.pressed.connect(_on_menu_pressed)


func _on_retry_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_playing = false
	_cleanup_layers()
	get_tree().change_scene_to_file(RETRY_SCENE)


func _on_menu_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_playing = false
	_cleanup_layers()
	get_tree().change_scene_to_file(MENU_SCENE)


func _make_button(text: String, font_res: Font) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(100, 28)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.12, 0.2)
	style.border_color = Color(0.75, 0.58, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.22, 0.18, 0.28)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65))
	b.add_theme_font_size_override("font_size", 11)
	if font_res:
		b.add_theme_font_override("font", font_res)
	return b
