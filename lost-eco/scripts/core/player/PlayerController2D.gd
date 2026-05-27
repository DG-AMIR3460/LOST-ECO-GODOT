extends CharacterBody2D
class_name PlayerController2D
## Controlador Hollow Knight — input en física (no depende solo de _unhandled_input).

signal state_changed(state_name: String)
signal light_pulse_used(energy_left: float)
signal health_updated(current: int, maximum: int)
signal died
signal landed

const GRAVITY: float = 1350.0
const MAX_FALL_SPEED: float = 560.0
const MOVE_SPEED: float = 220.0
const ACCEL_GROUND: float = 2800.0
const ACCEL_AIR: float = 1900.0
const FRICTION_GROUND: float = 3200.0
const JUMP_VELOCITY: float = -355.0
const JUMP_CUT_MULT: float = 0.38
const COYOTE_TIME: float = 0.15
const JUMP_BUFFER_TIME: float = 0.14
const DASH_SPEED: float = 400.0
const DASH_TIME: float = 0.13
const DASH_COOLDOWN: float = 0.68
const LIGHT_PULSE_SCENE := preload("res://scenes/core/light_pulse_wave.tscn")

@export var facing_right: bool = true

var session: GameSession = null
var state_machine: PlayerStateMachine = null
var skin_mapper: PlayerSkinMapper = null
var death_director: DeathCinematicDirector = null

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: float = 1.0
var invulnerable: bool = false
var input_locked: bool = false
var controls_enabled: bool = true
var last_horizontal_input: float = 0.0
var _spawn_protect_timer: float = 0.0
var _was_on_floor: bool = false
var _halo_time: float = 0.0
var _jump_held: bool = false
var _gothic_visual: GothicPlayerVisual = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var halo_light: PointLight2D = $HaloLight
@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var spore_particles: GPUParticles2D = $SporeParticles
@onready var camera: Camera2D = $Camera2D
@onready var _visual_fallback: Polygon2D = $VisualFallback


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 8.0
	floor_max_angle = deg_to_rad(50.0)
	max_slides = 4
	add_to_group("player")
	z_index = 10
	_setup_halo_light()
	_setup_gothic_visual()
	_register_states()
	if _visual_fallback:
		_visual_fallback.visible = false
	call_deferred("_ensure_runtime_ready")


func _ensure_runtime_ready() -> void:
	var tree := get_tree()
	if tree:
		tree.paused = false
	if Engine.time_scale < 0.2:
		Engine.time_scale = 1.0
	controls_enabled = true
	if input_locked and session == null:
		input_locked = false


func inject_dependencies(
	p_session: GameSession,
	p_death_director: DeathCinematicDirector,
	p_skin_mapper: PlayerSkinMapper = null
) -> void:
	session = p_session
	death_director = p_death_director
	skin_mapper = p_skin_mapper
	input_locked = false
	controls_enabled = true
	if skin_mapper:
		skin_mapper.bind_player(self)
	else:
		_apply_default_sprite()
	if session:
		if session.health_changed.is_connected(_on_session_health_changed):
			session.health_changed.disconnect(_on_session_health_changed)
		if session.player_died.is_connected(_on_session_player_died):
			session.player_died.disconnect(_on_session_player_died)
		session.health_changed.connect(_on_session_health_changed)
		session.player_died.connect(_on_session_player_died)
		_on_session_health_changed(session.current_health, session.max_health)
	if state_machine and session.is_alive():
		state_machine.change_state("Idle")
	if camera:
		camera.make_current()


func _register_states() -> void:
	state_machine = PlayerStateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)
	state_machine.register_state("Idle", preload("res://scripts/core/player/states/IdleState.gd").new())
	state_machine.register_state("Move", preload("res://scripts/core/player/states/MoveState.gd").new())
	state_machine.register_state("Jump", preload("res://scripts/core/player/states/JumpState.gd").new())
	state_machine.register_state("Dash", preload("res://scripts/core/player/states/DashState.gd").new())
	state_machine.register_state("Attack", preload("res://scripts/core/player/states/AttackState.gd").new())
	state_machine.register_state("Hurt", preload("res://scripts/core/player/states/HurtState.gd").new())
	state_machine.register_state("Dead", preload("res://scripts/core/player/states/DeadState.gd").new())
	state_machine.state_changed.connect(func(_p, c): state_changed.emit(c))
	state_machine.change_state("Idle")


func _physics_process(delta: float) -> void:
	if state_machine == null:
		return
	if not controls_enabled:
		controls_enabled = true
	_poll_input_edges()
	_update_timers(delta)
	_update_halo_pulse(delta)
	if not input_locked:
		state_machine.physics_update(delta)
	_apply_input_fallback(delta)
	_update_gothic_visual()
	_check_landing()
	_update_particles()


func _setup_gothic_visual() -> void:
	_gothic_visual = get_node_or_null("GothicVisual") as GothicPlayerVisual
	if _gothic_visual == null:
		_gothic_visual = GothicPlayerVisual.new()
		_gothic_visual.name = "GothicVisual"
		add_child(_gothic_visual)
	var skin := SettingsManager.player_skin if SettingsManager else "exploradora"
	_gothic_visual.setup(self, skin)
	if sprite:
		sprite.visible = false
	if halo_light:
		halo_light.visible = false


func _update_gothic_visual() -> void:
	if _gothic_visual == null or state_machine == null:
		return
	var attacking := state_machine.get_current_name() == "Attack"
	var dashing := is_dashing or state_machine.get_current_name() == "Dash"
	_gothic_visual.update_motion(velocity, is_on_floor(), attacking, dashing)


func _apply_input_fallback(_delta: float) -> void:
	if input_locked or state_machine == null:
		return
	var state_name := state_machine.get_current_name()
	if state_name not in ["Idle", "Move", "Jump"]:
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		return
	last_horizontal_input = dir
	facing_right = dir > 0.0
	if _gothic_visual:
		if sprite:
			sprite.visible = false
	elif sprite:
		sprite.flip_h = not facing_right
		sprite.visible = true
	if _visual_fallback:
		_visual_fallback.visible = false
	if state_name == "Idle" and is_on_floor():
		state_machine.change_state("Move")


func set_can_move(enabled: bool) -> void:
	input_locked = not enabled
	controls_enabled = true


func _poll_input_edges() -> void:
	if input_locked or not controls_enabled:
		return
	if Input.is_action_just_pressed("jump"):
		buffer_jump()
	if Input.is_action_just_released("jump"):
		cut_jump()
	_jump_held = Input.is_action_pressed("jump")


func _unhandled_input(event: InputEvent) -> void:
	if input_locked or state_machine == null or not controls_enabled:
		return
	state_machine.handle_input(event)
	# Dash/salto/ataque también por física; esto cubre ventana sin foco de ratón.
	if event.is_action_pressed("dash") and not input_locked:
		if state_machine.get_current_name() in ["Idle", "Move", "Jump"] and try_start_dash():
			state_machine.change_state("Dash")
	elif event.is_action_pressed("attack") and not input_locked:
		if state_machine.get_current_name() in ["Idle", "Move", "Jump", "Dash"]:
			state_machine.change_state("Attack")


func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	if _spawn_protect_timer > 0.0:
		_spawn_protect_timer = maxf(0.0, _spawn_protect_timer - delta)
	elif invulnerable and state_machine and state_machine.get_current_name() not in ["Dash", "Hurt", "Dead"]:
		invulnerable = false
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false


func _update_halo_pulse(delta: float) -> void:
	if halo_light == null:
		return
	_halo_time += delta
	var base_energy := 0.55
	if session:
		var ratio := session.light_energy / maxf(session.max_light_energy, 1.0)
		base_energy = 0.4 + ratio * 0.35
	halo_light.energy = clampf(base_energy + sin(_halo_time * 2.4) * 0.06, 0.3, 0.75)


func _check_landing() -> void:
	if is_on_floor() and not _was_on_floor:
		landed.emit()
	_was_on_floor = is_on_floor()


func _update_particles() -> void:
	if dust_particles:
		dust_particles.emitting = is_on_floor() and absf(velocity.x) > 55.0
	if spore_particles:
		spore_particles.emitting = true


func apply_gravity(delta: float) -> void:
	if is_dashing:
		velocity.y = 0.0
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)


func move_with_physics() -> void:
	move_and_slide()


func get_horizontal_input() -> float:
	if input_locked:
		return 0.0
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		last_horizontal_input = dir
		facing_right = dir > 0.0
		if sprite:
			sprite.flip_h = not facing_right
			sprite.visible = true
		if _visual_fallback:
			_visual_fallback.visible = false
	return dir


func can_coyote_jump() -> bool:
	return coyote_timer > 0.0


func buffer_jump() -> void:
	jump_buffer_timer = JUMP_BUFFER_TIME


func wants_jump() -> bool:
	return jump_buffer_timer > 0.0 or Input.is_action_just_pressed("jump")


func consume_jump() -> void:
	jump_buffer_timer = 0.0
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0


func try_jump() -> bool:
	if is_on_floor() or can_coyote_jump():
		if wants_jump() or Input.is_action_just_pressed("jump"):
			consume_jump()
			return true
	if jump_buffer_timer > 0.0 and (is_on_floor() or can_coyote_jump()):
		consume_jump()
		return true
	return false


func try_start_dash() -> bool:
	if dash_cooldown_timer > 0.0 or is_dashing:
		return false
	var dir := get_horizontal_input()
	if dir == 0.0:
		dir = 1.0 if facing_right else -1.0
	dash_direction = signf(dir)
	is_dashing = true
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN
	velocity.y = 0.0
	velocity.x = dash_direction * DASH_SPEED
	return true


func cut_jump() -> void:
	if velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULT


func perform_light_pulse() -> bool:
	if session == null or not session.spend_light(session.light_pulse_cost):
		return false
	if _gothic_visual:
		_gothic_visual.flash_attack()
	var wave := LIGHT_PULSE_SCENE.instantiate()
	var root := get_tree().current_scene
	if root:
		root.add_child(wave)
	if wave.has_method("activate"):
		wave.activate(global_position, self)
	_pulse_attack_flash()
	light_pulse_used.emit(session.light_energy)
	return true


func _pulse_attack_flash() -> void:
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color(2.2, 2.5, 1.4), 0.05)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func grant_spawn_protection(duration: float = 2.5) -> void:
	_spawn_protect_timer = duration
	invulnerable = true


func is_spawn_protected() -> bool:
	return _spawn_protect_timer > 0.0


func take_damage_from(source: Vector2, amount: int = 1, phrase: String = "") -> void:
	if invulnerable or is_spawn_protected() or state_machine.get_current_name() == "Dead":
		return
	if session and not session.is_alive():
		return
	if session:
		session.take_damage(amount, phrase)
		if not session.is_alive():
			state_machine.change_state("Dead")
			return
	var knock := (global_position - source).normalized()
	if knock == Vector2.ZERO:
		knock = Vector2.LEFT if facing_right else Vector2.RIGHT
	velocity = knock * 200.0 + Vector2(0.0, -140.0)
	state_machine.change_state("Hurt")


func _on_session_health_changed(current: int, maximum: int) -> void:
	health_updated.emit(current, maximum)


func _on_session_player_died(_phrase: String) -> void:
	if session and not session.is_alive() and state_machine.get_current_name() != "Dead":
		state_machine.change_state("Dead")


func _apply_default_sprite() -> void:
	if _gothic_visual or sprite == null:
		return
	var art := CharacterArt.make_sprite("exploradora")
	if art:
		sprite.texture = art.texture
		sprite.scale = art.scale
		sprite.visible = true
		if _visual_fallback:
			_visual_fallback.visible = false
	else:
		_use_fallback_visual()


func _use_fallback_visual() -> void:
	if sprite:
		sprite.visible = false
	if _visual_fallback:
		_visual_fallback.visible = true


func _setup_halo_light() -> void:
	if halo_light:
		LightTextureFactory.apply_halo_to_light(halo_light, Color(1.0, 0.9, 0.68), 0.55, 1.35)
