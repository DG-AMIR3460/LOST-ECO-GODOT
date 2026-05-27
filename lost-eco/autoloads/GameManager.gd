extends Node

signal empathy_changed(new_value: float)
signal score_changed(new_score: int)
signal health_changed(new_health: int)

const MENU_BUTTON_SCRIPT := preload("res://scripts/menu/menu_button.gd")
const UI_FONT_PATH := "res://PatrickHand-Regular.ttf"
const TITLE_FONT_PATH := "res://Fonts/AmaticSC-Bold.ttf"

# 0.0 = Alex agresivo | 1.0 = Alex empático
var empathy_level: float = 0.0

var player: CharacterBody2D = null

# ── Sistema de puntuación ────────────────────────────────────────────────────
var score: int = 0

# ── Sistema de vida ──────────────────────────────────────────────────────────
var max_health: int = 3
var current_health: int = 3
var _game_over_in_progress: bool = false

# ── Pausa / Game Over ────────────────────────────────────────────────────────
var _pause_layer: CanvasLayer
var _game_over_layer: CanvasLayer
var _pause_open: bool = false
var _returning_to_menu: bool = false
var _zone_transition_running: bool = false
var _ui_font: Font
var _title_font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_font = load(UI_FONT_PATH) as Font
	_title_font = load(TITLE_FONT_PATH) as Font


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			_try_debug_skip_current_zone()
			get_viewport().set_input_as_handled()
			return

	if not event.is_action_pressed("pause"):
		return
	if DialogueManager.is_zone_intro_active():
		return
	if ZoneCinematicDirector.is_playing():
		return
	if _game_over_in_progress or _returning_to_menu:
		return
	if _is_menu_scene() or _is_core_gameplay_scene():
		return
	if _pause_open:
		close_pause()
	else:
		open_pause()
	get_viewport().set_input_as_handled()


func open_pause() -> void:
	if _pause_open or _is_menu_scene():
		return
	_ensure_pause_layer()
	_pause_layer.visible = true
	_pause_open = true
	get_tree().paused = true
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)


func close_pause() -> void:
	if not _pause_open:
		return
	_pause_open = false
	get_tree().paused = false
	if _pause_layer:
		_pause_layer.visible = false
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)


func return_to_main_menu() -> void:
	if _returning_to_menu:
		return
	_returning_to_menu = true
	close_pause()
	close_game_over()
	_game_over_in_progress = false
	DialogueManager.clear_all()
	get_tree().paused = false
	player = null
	await SceneTransition.change_scene(SettingsManager.MENU_SCENE)
	_returning_to_menu = false


# ── Empatía ──────────────────────────────────────────────────────────────────
func update_empathy(delta: float) -> void:
	empathy_level = clamp(empathy_level + delta, 0.0, 1.0)
	empathy_changed.emit(empathy_level)


# ── Puntuación ───────────────────────────────────────────────────────────────
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


# ── Vida ─────────────────────────────────────────────────────────────────────
func take_damage() -> void:
	if _game_over_in_progress:
		return
	current_health = max(0, current_health - 1)
	health_changed.emit(current_health)
	if current_health <= 0:
		_game_over_in_progress = true
		_game_over()


func heal(amount: int = 1) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)


func restore_full_health() -> void:
	current_health = max_health
	health_changed.emit(current_health)


func on_zone_completed() -> void:
	restore_full_health()
	_game_over_in_progress = false


## Completa la zona y cambia de escena desde el autoload (evita crashes al liberar el mapa).
func request_zone_complete(
	completed_zone: int,
	next_scene: String,
	quest_id: String,
	score_points: int,
	empathy_delta: float
) -> void:
	if _zone_transition_running:
		return
	_zone_transition_running = true
	_run_zone_complete_async(completed_zone, next_scene, quest_id, score_points, empathy_delta)


func _run_zone_complete_async(
	completed_zone: int,
	next_scene: String,
	quest_id: String,
	score_points: int,
	empathy_delta: float
) -> void:
	on_zone_completed()
	close_pause()
	if player and is_instance_valid(player) and player.has_method("set_can_move"):
		player.set_can_move(false)
	QuestManager.advance_quest(quest_id)
	update_empathy(empathy_delta)
	add_score(score_points)
	var refl := StoryReflections.get_zone_complete(completed_zone)
	if not refl.is_empty():
		DialogueManager.show_reflection(
			refl.title, refl.body + "\n+%d pts" % score_points, refl.accent, 2.5
		)
		await get_tree().create_timer(2.5).timeout
	player = null
	await SceneTransition.play_bridge_and_change_scene(completed_zone, next_scene)
	_zone_transition_running = false


func _game_over() -> void:
	close_pause()
	DialogueManager.clear_all()
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	_ensure_game_over_layer()
	_game_over_layer.visible = true
	get_tree().paused = true


func close_game_over() -> void:
	if _game_over_layer and is_instance_valid(_game_over_layer):
		_game_over_layer.visible = false
	get_tree().paused = false


func _game_over_continue() -> void:
	close_game_over()
	restore_full_health()
	_game_over_in_progress = false
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)
	get_tree().reload_current_scene()


func _game_over_exit() -> void:
	close_game_over()
	restore_full_health()
	_game_over_in_progress = false
	return_to_main_menu()


# ── Interfaz ─────────────────────────────────────────────────────────────────
func show_interact_prompt(visible: bool) -> void:
	get_tree().call_group("hud", "set_interact_prompt_visible", visible)


func _is_menu_scene() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return true
	var path: String = current.scene_file_path
	return path == SettingsManager.MENU_SCENE or path == SettingsManager.OPTIONS_SCENE


func _is_core_gameplay_scene() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return false
	var path: String = current.scene_file_path
	return path.contains("/core/") or path.contains("pantano_world")


func _is_campaign_zone_scene() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return false
	var path: String = current.scene_file_path
	return path.contains("/world/Zone")


func is_zone_transition_running() -> bool:
	return _zone_transition_running


func _try_debug_skip_current_zone() -> void:
	if _is_menu_scene() or _is_core_gameplay_scene():
		return
	if not _is_campaign_zone_scene():
		return
	if _zone_transition_running:
		return
	if ZoneCinematicDirector.is_playing():
		return
	if _game_over_in_progress or _returning_to_menu:
		return
	var current := get_tree().current_scene
	if current == null or not current.has_method("_zone_complete"):
		return
	DialogueManager.clear_all()
	close_pause()
	DialogueManager.show_corner_notice("Zona saltada — [L]", Color(0.95, 0.82, 0.42), 1.2)
	current.call("_zone_complete")


func _ensure_pause_layer() -> void:
	if _pause_layer and is_instance_valid(_pause_layer):
		return

	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 120
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.05, 0.72)
	_pause_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 96)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.10, 0.95)
	style.border_color = Color(0.95, 0.78, 0.28, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 5
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.88, 0.45))
	title.add_theme_font_size_override("font_size", 18)
	if _title_font:
		title.add_theme_font_override("font", _title_font)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "[ESC] Continuar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	hint.add_theme_font_size_override("font_size", 9)
	if _ui_font:
		hint.add_theme_font_override("font", _ui_font)
	box.add_child(hint)

	var resume_btn := _make_pause_button("Continuar")
	resume_btn.pressed.connect(close_pause)
	box.add_child(resume_btn)

	var menu_btn := _make_pause_button("Menú principal")
	menu_btn.pressed.connect(func(): return_to_main_menu())
	box.add_child(menu_btn)

	_pause_layer.visible = false


func _make_pause_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 22)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 12)
	if _ui_font:
		button.add_theme_font_override("font", _ui_font)
	button.set_script(MENU_BUTTON_SCRIPT)
	if button.has_method("_ready"):
		button._ready()
	return button


func _ensure_game_over_layer() -> void:
	if _game_over_layer and is_instance_valid(_game_over_layer):
		return

	_game_over_layer = CanvasLayer.new()
	_game_over_layer.layer = 125
	_game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_game_over_layer)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.01, 0.08, 0.82)
	_game_over_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 120)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.10, 0.98)
	style.border_color = Color(0.95, 0.25, 0.30, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	title.add_theme_font_size_override("font_size", 20)
	if _title_font:
		title.add_theme_font_override("font", _title_font)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Te quedaste sin vidas."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color(0.88, 0.84, 0.78))
	subtitle.add_theme_font_size_override("font_size", 10)
	if _ui_font:
		subtitle.add_theme_font_override("font", _ui_font)
	box.add_child(subtitle)

	var continue_btn := _make_pause_button("Seguir jugando")
	continue_btn.pressed.connect(_game_over_continue)
	box.add_child(continue_btn)

	var menu_btn := _make_pause_button("Salir al menú")
	menu_btn.pressed.connect(_game_over_exit)
	box.add_child(menu_btn)

	_game_over_layer.visible = false
