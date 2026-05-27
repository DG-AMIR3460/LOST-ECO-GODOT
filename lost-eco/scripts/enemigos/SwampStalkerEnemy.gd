extends EnemyAIBase
class_name SwampStalkerEnemy

const PREFERRED_DIST: float = 130.0
const RETREAT_DIST: float = 68.0
const BASE_FIRE_COOLDOWN: float = 2.1

const PROJECTILE_SCENE := preload("res://scenes/core/enemies/bullying_projectile.tscn")

var _fire_timer: float = 4.5
var _phrase_pool: Array[String] = []
var _fire_cooldown: float = BASE_FIRE_COOLDOWN
var _speed_mult: float = 1.0


func _ready() -> void:
	max_health = 4
	current_health = 4
	chase_speed = 78.0
	if _phrase_pool.is_empty():
		_phrase_pool = ["No vales nada", "Loser", "You suck!"]
	if sprite:
		var art := CharacterArt.make_sprite("espectro", 0.12)
		if art:
			sprite.texture = art.texture
			sprite.scale = art.scale
	_setup_crimson_eyes()


func apply_difficulty(mult: float) -> void:
	_speed_mult = mult
	_fire_cooldown = maxf(0.85, BASE_FIRE_COOLDOWN / mult)
	chase_speed = 78.0 * mult
	max_health = int(4.0 * mult)
	current_health = max_health


func set_phrase_pool(pool: Array[String]) -> void:
	_phrase_pool = pool


func _process_ai(_delta: float) -> void:
	_fire_timer -= _delta
	var player_pos := track_player_position()
	var offset := player_pos - global_position
	var dist := offset.length()
	if dist < RETREAT_DIST:
		velocity = -offset.normalized() * chase_speed * 1.5 * _speed_mult
	elif dist > PREFERRED_DIST:
		velocity = offset.normalized() * chase_speed * 0.75 * _speed_mult
	else:
		velocity = Vector2.ZERO
		if _fire_timer <= 0.0:
			_fire_projectile(offset.normalized())
			_fire_timer = _fire_cooldown
	if sprite and offset.x != 0.0:
		sprite.flip_h = offset.x < 0.0


func _fire_projectile(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	var proj := PROJECTILE_SCENE.instantiate() as BullyingProjectile
	get_tree().current_scene.add_child(proj)
	var phrase: String = _phrase_pool[randi() % _phrase_pool.size()]
	proj.launch(global_position + direction * 14.0, direction, phrase, target_player)
