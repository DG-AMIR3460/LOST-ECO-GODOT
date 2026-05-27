extends EnemyAIBase
class_name ShadowSwarmEnemy

const BASE_CONVERGE: float = 175.0
const LIGHT_ATTRACTION: float = 1.5

var _speed_mult: float = 1.0


func _ready() -> void:
	max_health = 1
	current_health = 1
	chase_speed = BASE_CONVERGE
	if sprite:
		sprite.self_modulate = Color(0.12, 0.02, 0.06)
		var art := CharacterArt.make_sprite("susurrantes", 0.11)
		if art:
			sprite.texture = art.texture
			sprite.scale = art.scale
	_setup_crimson_eyes()


func apply_difficulty(mult: float) -> void:
	_speed_mult = mult
	chase_speed = BASE_CONVERGE * mult


func _process_ai(_delta: float) -> void:
	var target := get_player_light_position()
	var dir := target - global_position
	if dir.length_squared() < 20.0:
		return
	dir = dir.normalized()
	var dist := global_position.distance_to(target)
	var rush := 1.0 + clampf(1.0 - dist / 120.0, 0.0, 0.8) * _speed_mult
	velocity = dir * chase_speed * LIGHT_ATTRACTION * rush
	if sprite and dir.x != 0.0:
		sprite.flip_h = dir.x < 0.0
	if eye_light:
		eye_light.energy = 0.9 + sin(Time.get_ticks_msec() * 0.008) * 0.25


func on_light_pulse() -> void:
	current_health = 0
	_die()
