extends CharacterBody2D
class_name EnemyAIBase
## IA base: knockback, hit-flash, gravedad y ojos carmesí con PointLight2D.

signal enemy_defeated(enemy: EnemyAIBase)
signal enemy_damaged(enemy: EnemyAIBase, amount: int)

@export var max_health: int = 2
@export var chase_speed: float = 90.0
@export var knockback_resistance: float = 0.55

var current_health: int = 2
var target_player: PlayerController2D = null
var _stun_timer: float = 0.0
var _contact_cooldown: float = 0.0
var _flash_tween: Tween = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var eye_light: PointLight2D = $EyeLight


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	floor_stop_on_slope = true
	_setup_crimson_eyes()


func inject_player(player: PlayerController2D) -> void:
	target_player = player


func _setup_crimson_eyes() -> void:
	if eye_light:
		LightTextureFactory.apply_crimson_eye(eye_light, Vector2.ZERO, 1.1)
	if sprite:
		sprite.self_modulate = Color(0.85, 0.75, 0.78)
		sprite.visible = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + 950.0 * delta, 460.0)
	if _contact_cooldown > 0.0:
		_contact_cooldown = maxf(0.0, _contact_cooldown - delta)
	if _stun_timer > 0.0:
		_stun_timer -= delta
		move_and_slide()
		_try_contact_damage()
		return
	_process_ai(delta)
	move_and_slide()
	_try_contact_damage()


func _try_contact_damage() -> void:
	if _contact_cooldown > 0.0 or target_player == null or not is_instance_valid(target_player):
		return
	if target_player.is_spawn_protected() or target_player.invulnerable:
		return
	if global_position.distance_to(target_player.global_position) > 14.0:
		return
	_contact_cooldown = 0.9
	target_player.take_damage_from(global_position, 1, "La sombra te alcanza.")


func _process_ai(_delta: float) -> void:
	pass


func receive_light_pulse(direction: Vector2, force: float) -> void:
	_stun_timer = 0.55
	velocity = direction * force * (1.0 - knockback_resistance)
	_play_hit_flash(Color(1.9, 2.4, 1.3))
	on_light_pulse()


func on_light_pulse() -> void:
	pass


func take_damage(amount: int, source: Vector2 = Vector2.ZERO) -> void:
	current_health -= amount
	enemy_damaged.emit(self, amount)
	if source != Vector2.ZERO:
		var dir := (global_position - source).normalized()
		velocity = dir * 160.0
	_play_hit_flash(Color(2.4, 0.35, 0.3))
	if current_health <= 0:
		_die()


func _die() -> void:
	if eye_light:
		var tw := create_tween()
		tw.tween_property(eye_light, "energy", 0.0, 0.25)
	enemy_defeated.emit(self)
	queue_free()


func _play_hit_flash(color: Color) -> void:
	if sprite == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", color, 0.05)
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func track_player_position() -> Vector2:
	if target_player and is_instance_valid(target_player):
		return target_player.global_position
	return global_position


func get_player_light_position() -> Vector2:
	if target_player and is_instance_valid(target_player):
		if target_player.halo_light:
			return target_player.halo_light.global_position
		return target_player.global_position
	return global_position
