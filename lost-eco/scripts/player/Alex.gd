extends CharacterBody2D

signal action_performed(action_name: String, intensity: float)

const BASE_SPEED: float = 90.0

@export var has_weapon: bool = true

# Nodos de la escena (seguimos referenciando para no romper el .tscn)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mud_particles: GPUParticles2D     = $MudParticles
@onready var interact_area: Area2D             = $InteractArea

var speed_multiplier: float  = 1.0
var facing_direction: Vector2 = Vector2.DOWN
var empathy_level: float     = 0.0
var can_move: bool           = true

# ── Visual del personaje ──────────────────────────────────────────────────────
var visual: Node2D   = null
var body_sprite: Sprite2D = null
var _walk_t: float   = 0.0

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	GameManager.player = self
	add_to_group("player")
	GameManager.empathy_changed.connect(_on_empathy_changed)

	# Ocultar el placeholder (icon.svg)
	if animated_sprite:
		animated_sprite.visible = false

	_build_character()

# ── Construcción del personaje ────────────────────────────────────────────────
func _build_character() -> void:
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)

	body_sprite = CharacterArt.make_sprite("alex")
	if body_sprite:
		body_sprite.name = "BodySprite"
		visual.add_child(body_sprite)
	else:
		_build_fallback_character()

	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-5, 0), Vector2(5, 0), Vector2(4, 2), Vector2(-4, 2),
	])
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.position = Vector2(0, 8)
	shadow.z_index = -1
	visual.add_child(shadow)
	visual.move_child(shadow, 0)


func _build_fallback_character() -> void:
	var SKIN := Color(0.93, 0.77, 0.61)
	var SHIRT := Color(0.22, 0.48, 0.82)
	var PANTS := Color(0.16, 0.24, 0.46)
	_r(visual, -4, -9, 8, 7, SKIN)
	_r(visual, -4, -2, 8, 6, SHIRT)
	_r(visual, -4, 5, 3, 5, PANTS)
	_r(visual, 1, 5, 3, 5, PANTS)


func _r(parent: Node2D, x: float, y: float, w: float, h: float, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)
	])
	p.color = color
	parent.add_child(p)
	return p

# ── Física y movimiento ───────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not can_move:
		return

	var input_dir = _get_input_direction()

	if input_dir != Vector2.ZERO:
		facing_direction = input_dir
		velocity = input_dir * BASE_SPEED * speed_multiplier
		_animate_walk(input_dir, delta)
		action_performed.emit("move", input_dir.x)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, BASE_SPEED * 4.0 * delta)
		_animate_idle(delta)

	move_and_slide()

func _get_input_direction() -> Vector2:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_right"): dir.x += 1
	if Input.is_action_pressed("move_left"):  dir.x -= 1
	if Input.is_action_pressed("move_down"):  dir.y += 1
	if Input.is_action_pressed("move_up"):    dir.y -= 1
	return dir.normalized()

# ── Animación de caminar ──────────────────────────────────────────────────────
func _animate_walk(dir: Vector2, delta: float) -> void:
	_walk_t += delta * 10.0
	if body_sprite == null:
		return
	if dir.x < -0.1:
		body_sprite.scale.x = -absf(body_sprite.scale.x)
	elif dir.x > 0.1:
		body_sprite.scale.x = absf(body_sprite.scale.x)
	var bob := sin(_walk_t) * 1.2
	body_sprite.position.y = bob
func _animate_idle(delta: float) -> void:
	_walk_t = 0.0
	if body_sprite:
		body_sprite.position.y = lerpf(body_sprite.position.y, 0.0, delta * 14.0)

# ── Input ─────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("attack") and has_weapon:
		action_performed.emit("attack", 1.0)
		_play_attack_animation()

	if event.is_action_pressed("drop_weapon") and has_weapon:
		_drop_weapon()

func _try_interact() -> void:
	if not interact_area: return
	for body in interact_area.get_overlapping_bodies():
		if body.has_method("interact"):
			body.interact()
			return
	for area in interact_area.get_overlapping_areas():
		if area.has_method("interact"):
			area.interact()
			return

func _drop_weapon() -> void:
	has_weapon = false
	action_performed.emit("drop_weapon", 0.0)
	# Animación: flash blanco (rendición)
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "modulate", Color(2.5, 2.5, 2.5), 0.08)
		tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.35)

func _play_attack_animation() -> void:
	if body_sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(body_sprite, "modulate", Color(2.0, 1.4, 0.5), 0.07)
	tween.tween_property(body_sprite, "modulate", Color.WHITE, 0.12)

# ── Daño recibido ─────────────────────────────────────────────────────────────
func take_hit(source_position: Vector2) -> void:
	# Retroceso (knockback)
	var knockback = (global_position - source_position).normalized() * 70.0
	velocity = knockback
	AudioManager.play_sfx("hurt")
	# Flash rojo
	if visual:
		visual.modulate = Color(2.2, 0.4, 0.4)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(visual):
			visual.modulate = Color(1.0, 1.0, 1.0)

# ── API pública ───────────────────────────────────────────────────────────────
func set_speed_multiplier(value: float) -> void:
	speed_multiplier = value

func has_weapon_equipped() -> bool:
	return has_weapon

func set_can_move(value: bool) -> void:
	can_move = value

# ── Empatía (cambia el color del personaje) ───────────────────────────────────
func _on_empathy_changed(value: float) -> void:
	empathy_level = value
	# El personaje se vuelve más cálido conforme crece la empatía
	var warmth = Color(1.0, 0.9 + value * 0.1, 0.8 + value * 0.2)
	if visual:
		visual.modulate = warmth
