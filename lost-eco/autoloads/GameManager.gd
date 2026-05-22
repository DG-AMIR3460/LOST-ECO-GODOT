extends Node

signal empathy_changed(new_value: float)
signal score_changed(new_score: int)
signal health_changed(new_health: int)

# 0.0 = Alex agresivo | 1.0 = Alex empático
var empathy_level: float = 0.0

var player: CharacterBody2D = null

# ── Sistema de puntuación ────────────────────────────────────────────────────
var score: int = 0

# ── Sistema de vida ──────────────────────────────────────────────────────────
var max_health: int = 3
var current_health: int = 3
var _game_over_in_progress: bool = false

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

func _game_over() -> void:
	if player:
		player.set_can_move(false)
	# Espera un momento y reinicia la escena actual
	await get_tree().create_timer(1.5).timeout
	current_health = max_health
	_game_over_in_progress = false
	get_tree().reload_current_scene()

# ── Interfaz ─────────────────────────────────────────────────────────────────
func show_interact_prompt(visible: bool) -> void:
	get_tree().call_group("hud", "set_interact_prompt_visible", visible)
