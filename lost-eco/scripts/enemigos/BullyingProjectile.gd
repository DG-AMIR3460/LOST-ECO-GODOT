extends Area2D
class_name BullyingProjectile
## Proyectil de acoso — texto pixel + estela de partículas.

const SPEED: float = 200.0
const LIFETIME: float = 6.0
const PIXEL_FONT := "res://PatrickHand-Regular.ttf"

var _velocity: Vector2 = Vector2.ZERO
var _phrase: String = ""
var _target: PlayerController2D = null
var _label: Label = null
var _trail: GPUParticles2D = null
var _glow: PointLight2D = null


func _ready() -> void:
	add_to_group("bullying_projectile")
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	z_index = 30
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 16)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_glow = PointLight2D.new()
	_glow.color = Color(0.95, 0.15, 0.2)
	_glow.energy = 0.45
	_glow.texture_scale = 0.7
	LightTextureFactory.apply_crimson_eye(_glow, Vector2.ZERO, 0.45)
	add_child(_glow)
	_trail = GPUParticles2D.new()
	_trail.amount = 12
	_trail.lifetime = 0.5
	_trail.preprocess = 0.2
	_trail.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 18.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 22.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.2
	mat.scale_max = 0.55
	mat.color = Color(0.9, 0.2, 0.28, 0.55)
	_trail.process_material = mat
	add_child(_trail)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", Color(0.98, 0.22, 0.32))
	_label.add_theme_color_override("font_outline_color", Color(0.15, 0.02, 0.05))
	_label.add_theme_constant_override("outline_size", 2)
	_label.z_index = 20
	var font_res: Font = load(PIXEL_FONT) as Font
	if font_res:
		_label.add_theme_font_override("font", font_res)
	add_child(_label)
	var life := get_tree().create_timer(LIFETIME)
	life.timeout.connect(queue_free)


func launch(from: Vector2, direction: Vector2, phrase: String, target: PlayerController2D) -> void:
	global_position = from
	_velocity = direction.normalized() * SPEED
	_phrase = phrase
	_target = target
	_label.text = phrase
	rotation = _velocity.angle()
	if _trail and _trail.process_material is ParticleProcessMaterial:
		var pm := _trail.process_material as ParticleProcessMaterial
		pm.direction = Vector3(_velocity.normalized().x, _velocity.normalized().y, 0)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	if _label:
		_label.modulate = Color(1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.15, 0.9, 0.9)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController2D:
		var player := body as PlayerController2D
		if player.is_spawn_protected():
			queue_free()
			return
		player.take_damage_from(global_position, 1, _phrase)
		queue_free()
