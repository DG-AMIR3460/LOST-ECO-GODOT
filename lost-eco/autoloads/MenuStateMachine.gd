extends Node
## Máquina de estados del menú (State Pattern).
## Coordina transiciones entre MainMenu, Options y Pause sin acoplar las escenas.

enum StateId { NONE, MAIN, OPTIONS, PAUSE }

const MainMenuState := preload("res://scripts/menu/states/main_menu_state.gd")
const OptionsMenuState := preload("res://scripts/menu/states/options_menu_state.gd")
const PauseMenuState := preload("res://scripts/menu/states/pause_menu_state.gd")

var _states: Dictionary = {}
var _current_id: StateId = StateId.NONE
var _current_state: MenuState
var _context: Control
var _is_transitioning: bool = false


func _ready() -> void:
	_states[StateId.MAIN] = MainMenuState.new()
	_states[StateId.OPTIONS] = OptionsMenuState.new()
	_states[StateId.PAUSE] = PauseMenuState.new()


func get_current_state_id() -> StateId:
	return _current_id


func get_current_state_name() -> String:
	if _current_state:
		return _current_state.get_state_name()
	return "None"


func activate_main_menu(context: Control) -> void:
	_activate_state(StateId.MAIN, context)


func activate_options_menu(context: Control) -> void:
	_activate_state(StateId.OPTIONS, context)


func activate_pause_menu(context: Control) -> void:
	_activate_state(StateId.PAUSE, context)


func release_context(context: Control) -> void:
	if _context != context:
		return
	_deactivate_current_state()
	_context = null


func transition_to_main() -> void:
	await _change_menu_scene(SettingsManager.MENU_SCENE)


func transition_to_options() -> void:
	await _change_menu_scene(SettingsManager.OPTIONS_SCENE)


func transition_to_game() -> void:
	await _start_gameplay_scene(SettingsManager.GAME_SCENE)


func transition_to_demo_pantano() -> void:
	await _start_gameplay_scene(SettingsManager.DEMO_PANTANO_SCENE)


func _start_gameplay_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	_deactivate_current_state()
	_context = null
	_current_id = StateId.NONE
	_current_state = null

	GameManager.score = 0
	GameManager.current_health = GameManager.max_health
	GameManager.empathy_level = 0.0
	GameManager.player = null
	GameManager.close_pause()
	GameManager.empathy_changed.emit(GameManager.empathy_level)
	GameManager.health_changed.emit(GameManager.current_health)
	GameManager.score_changed.emit(GameManager.score)

	AudioManager.stop_menu_music(0.6)
	get_tree().paused = false
	Engine.time_scale = 1.0
	if scene_path == SettingsManager.GAME_SCENE:
		await SceneTransition.change_scene_with_cinematic("intro_campaign", scene_path)
	else:
		await SceneTransition.change_scene(scene_path)
	_is_transitioning = false


func quit_game() -> void:
	get_tree().quit()


func _activate_state(state_id: StateId, context: Control) -> void:
	if _context != context:
		_deactivate_current_state()
		_context = context

	_current_id = state_id
	_current_state = _states[state_id] as MenuState
	_current_state.enter(_context, self)


func _deactivate_current_state() -> void:
	if _current_state and _context:
		_current_state.exit(_context, self)
	_current_state = null
	_current_id = StateId.NONE


func _change_menu_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	_deactivate_current_state()
	_context = null

	await SceneTransition.change_scene(scene_path)
	_is_transitioning = false
