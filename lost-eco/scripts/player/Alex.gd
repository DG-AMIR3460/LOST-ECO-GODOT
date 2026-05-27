extends CharacterBody2D

signal action_performed(action_name: String, intensity: float)

const BASE_SPEED: float = 90.0

@export var has_weapon: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mud_particles: GPUParticles2D = $MudParticles
@onready var interact_area: Area2D = $InteractArea

var speed_multiplier: float = 1.0
var facing_direction: Vector2 = Vector2.DOWN
var empathy_level: float = 0.0
var can_move: bool = true

var visual: Node2D = null
var leg_l: Polygon2D = null
var leg_r: Polygon2D = null
var arm_l: Polygon2D = null
var arm_r: Polygon2D = null
var _walk_t: float = 0.0
var _gothic_visual: GothicPlayerVisual = null


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	GameManager.player = self
	add_to_group("player")
	GameManager.empathy_changed.connect(_on_empathy_changed)
	z_index = 10

	if animated_sprite:
		animated_sprite.visible = false
	if mud_particles:
		mud_particles.emitting = false

	if CharacterArt.is_ready():
		_setup_gothic_sprite_visual()
	else:
		_build_character()


func _setup_gothic_sprite_visual() -> void:
	_hide_legacy_visual()
	_gothic_visual = get_node_or_null("GothicVisual") as GothicPlayerVisual
	if _gothic_visual == null:
		_gothic_visual = GothicPlayerVisual.new()
		_gothic_visual.name = "GothicVisual"
		add_child(_gothic_visual)
	var skin := "alex"
	if SettingsManager and not SettingsManager.player_skin.is_empty():
		skin = SettingsManager.player_skin
	_gothic_visual.setup(self, skin)


func _hide_legacy_visual() -> void:
	if visual:
		visual.visible = false
		visual.queue_free()
		visual = null
	leg_l = null
	leg_r = null
	arm_l = null
	arm_r = null


func _build_character() -> void:
	visual = Node2D.new()
	visual.name = "Visual"
	add_child(visual)

	var SKIN := Color(0.93, 0.77, 0.61)
	var HAIR := Color(0.25, 0.14, 0.05)
	var BROW := Color(0.18, 0.11, 0.03)
	var EYES := Color(0.08, 0.08, 0.25)
	var MOUTH := Color(0.75, 0.45, 0.45)
	var SHIRT := Color(0.22, 0.48, 0.82)
	var PANTS := Color(0.16, 0.24, 0.46)
	var BELT := Color(0.10, 0.10, 0.10)
	var SHOE := Color(0.10, 0.07, 0.04)

	_r(visual, -4, -9, 8, 7, SKIN)
	_r(visual, -4, -9, 8, 3, HAIR)
	_r(visual, -4, -8, 1, 3, HAIR)
	_r(visual, 3, -8, 1, 3, HAIR)
	_r(visual, -3, -5, 2, 1, BROW)
	_r(visual, 1, -5, 2, 1, BROW)
	_r(visual, -3, -4, 2, 2, EYES)
	_r(visual, 1, -4, 2, 2, EYES)
	_r(visual, -3, -4, 1, 1, Color(0.85, 0.90, 1.0))
	_r(visual, 1, -4, 1, 1, Color(0.85, 0.90, 1.0))
	_r(visual, 0, -2, 1, 1, Color(SKIN.r - 0.08, SKIN.g - 0.08, SKIN.b - 0.08))
	_r(visual, -2, -1, 4, 1, MOUTH)
	_r(visual, -1, -2, 2, 2, SKIN)
	_r(visual, -4, -2, 8, 6, SHIRT)
	_r(visual, 0, -1, 1, 1, Color(1, 1, 1, 0.4))
	_r(visual, 0, 1, 1, 1, Color(1, 1, 1, 0.4))
	_r(visual, -4, 4, 8, 1, BELT)
	_r(visual, -1, 4, 2, 1, Color(0.7, 0.6, 0.2))
	arm_l = _r(visual, -6, -2, 2, 5, SHIRT)
	arm_r = _r(visual, 4, -2, 2, 5, SHIRT)
	_r(visual, -6, 3, 2, 2, SKIN)
	_r(visual, 4, 3, 2, 2, SKIN)
	leg_l = _r(visual, -4, 5, 3, 5, PANTS)
	leg_r = _r(visual, 1, 5, 3, 5, PANTS)
	_r(visual, -4, 9, 4, 2, SHOE)
	_r(visual, 1, 9, 4, 2, SHOE)


func _r(parent: Node2D, x: float, y: float, w: float, h: float, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)
	])
	p.color = color
	parent.add_child(p)
	return p


func _physics_process(delta: float) -> void:
	if not can_move:
		return

	var input_dir := _get_input_direction()
	if input_dir != Vector2.ZERO:
		facing_direction = input_dir
		velocity = input_dir * BASE_SPEED * speed_multiplier
		if _gothic_visual:
			_gothic_visual.update_motion(velocity, true, false, false)
		else:
			_animate_walk(input_dir, delta)
		action_performed.emit("move", input_dir.x)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, BASE_SPEED * 4.0 * delta)
		if _gothic_visual:
			_gothic_visual.update_motion(velocity, true, false, false)
		else:
			_animate_idle(delta)

	move_and_slide()


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	return dir.normalized()


func _animate_walk(dir: Vector2, delta: float) -> void:
	_walk_t += delta * 10.0
	if visual == null:
		return
	if dir.x < -0.1:
		visual.scale.x = -1.0
	elif dir.x > 0.1:
		visual.scale.x = 1.0
	var swing := sin(_walk_t) * 2.8
	if leg_l:
		leg_l.position.y = swing
	if leg_r:
		leg_r.position.y = -swing
	if arm_l:
		arm_l.position.y = -swing * 0.7
	if arm_r:
		arm_r.position.y = swing * 0.7


func _animate_idle(delta: float) -> void:
	_walk_t = 0.0
	if visual == null:
		return
	var s := delta * 14.0
	if leg_l:
		leg_l.position.y = lerpf(leg_l.position.y, 0.0, s)
	if leg_r:
		leg_r.position.y = lerpf(leg_r.position.y, 0.0, s)
	if arm_l:
		arm_l.position.y = lerpf(arm_l.position.y, 0.0, s)
	if arm_r:
		arm_r.position.y = lerpf(arm_r.position.y, 0.0, s)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("attack") and has_weapon:
		action_performed.emit("attack", 1.0)
		_play_attack_animation()
	if event.is_action_pressed("drop_weapon") and has_weapon:
		_drop_weapon()


func _try_interact() -> void:
	if not interact_area:
		return
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
	if _gothic_visual:
		_gothic_visual.flash_attack()
	elif visual:
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color(2.5, 2.5, 2.5), 0.08)
		tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.35)


func _play_attack_animation() -> void:
	if _gothic_visual:
		_gothic_visual.flash_attack()
		return
	if arm_r and visual:
		var orig_x := arm_r.position.x
		var tween := create_tween()
		tween.tween_property(arm_r, "position:x", orig_x + 4.0, 0.07)
		tween.tween_property(arm_r, "position:x", orig_x, 0.12)


func take_hit(source_position: Vector2) -> void:
	var knockback := (global_position - source_position).normalized() * 70.0
	velocity = knockback
	AudioManager.play_sfx("hurt")
	if _gothic_visual and _gothic_visual.get_node_or_null("BodyAnim"):
		var anim := _gothic_visual.get_node("BodyAnim") as AnimatedSprite2D
		anim.modulate = Color(2.2, 0.4, 0.4)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(anim):
			anim.modulate = Color.WHITE
	elif visual:
		visual.modulate = Color(2.2, 0.4, 0.4)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(visual):
			visual.modulate = Color(1.0, 1.0, 1.0)


func set_speed_multiplier(value: float) -> void:
	speed_multiplier = value


func has_weapon_equipped() -> bool:
	return has_weapon


func set_can_move(value: bool) -> void:
	can_move = value


func _on_empathy_changed(value: float) -> void:
	empathy_level = value
	if _gothic_visual:
		return
	var warmth := Color(1.0, 0.9 + value * 0.1, 0.8 + value * 0.2)
	if visual:
		visual.modulate = warmth
