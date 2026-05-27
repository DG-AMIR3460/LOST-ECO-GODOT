extends Node
class_name GameSession
## Estado de partida inyectado por escena. Sin Autoload ni Singleton.

signal health_changed(current: int, maximum: int)
signal light_energy_changed(current: float, maximum: float)
signal score_changed(new_score: int)
signal player_died(last_phrase: String)
signal memory_collected(count: int)

@export var max_health: int = 3
@export var max_light_energy: float = 100.0
@export var light_pulse_cost: float = 28.0

var current_health: int = 3
var light_energy: float = 100.0
var score: int = 0
var memories_found: int = 0
var last_cyberbullying_phrase: String = "..."
var _death_emitted: bool = false


func _ready() -> void:
	reset_for_run()


func reset_for_run() -> void:
	_death_emitted = false
	current_health = max_health
	light_energy = max_light_energy
	_emit_all()


func take_damage(amount: int = 1, phrase: String = "") -> void:
	if amount <= 0 or current_health <= 0 or _death_emitted:
		return
	if not phrase.is_empty():
		last_cyberbullying_phrase = phrase
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		_emit_death_once()


func _emit_death_once() -> void:
	if _death_emitted:
		return
	_death_emitted = true
	player_died.emit(last_cyberbullying_phrase)


func heal(amount: int = 1) -> void:
	if _death_emitted:
		return
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func spend_light(cost: float) -> bool:
	if light_energy < cost:
		return false
	light_energy -= cost
	light_energy_changed.emit(light_energy, max_light_energy)
	return true


func restore_light(amount: float) -> void:
	light_energy = minf(max_light_energy, light_energy + amount)
	light_energy_changed.emit(light_energy, max_light_energy)


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func register_memory() -> void:
	memories_found += 1
	memory_collected.emit(memories_found)


func is_alive() -> bool:
	return current_health > 0 and not _death_emitted


func _emit_all() -> void:
	health_changed.emit(current_health, max_health)
	light_energy_changed.emit(light_energy, max_light_energy)
	score_changed.emit(score)
