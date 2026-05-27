extends Node2D
class_name GothicPlayerVisual
## Capa visual gótica: AnimatedSprite2D, luz orgánica, estela de dash.

@export var skin_key: String = "exploradora"

var _anim: AnimatedSprite2D = null
var _halo: PointLight2D = null
var _dash_trail: GPUParticles2D = null
var _breath_t: float = 0.0
var _last_state: String = "idle"
var _host: CharacterBody2D = null


func setup(host: CharacterBody2D, skin: String = "") -> void:
	_host = host
	if not skin.is_empty():
		skin_key = skin
	_build_nodes()
	z_index = 12


func _build_nodes() -> void:
	for c in get_children():
		c.queue_free()
	_halo = PointLight2D.new()
	_halo.name = "OrganicHalo"
	_halo.z_index = -2
	_halo.energy = 0.38
	_halo.color = Color(0.85, 0.78, 0.95)
	_halo.texture_scale = 1.1
	LightTextureFactory.apply_halo_to_light(_halo, Color(0.82, 0.78, 1.0), 0.38, 1.1)
	add_child(_halo)
	_anim = AnimatedSprite2D.new()
	_anim.name = "BodyAnim"
	_anim.z_index = 2
	_anim.sprite_frames = PlayerAnimationFactory.build_from_skin(skin_key)
	_anim.centered = true
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_sprite_layout()
	if _anim.sprite_frames.has_animation("idle"):
		_anim.play("idle")
	add_child(_anim)
	_dash_trail = GPUParticles2D.new()
	_dash_trail.name = "DashTrail"
	_dash_trail.emitting = false
	_dash_trail.amount = 14
	_dash_trail.lifetime = 0.35
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 28.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 55.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.25
	mat.scale_max = 0.7
	mat.color = Color(0.75, 0.82, 1.0, 0.55)
	_dash_trail.process_material = mat
	add_child(_dash_trail)


func apply_skin(skin: String) -> void:
	skin_key = skin
	if _anim:
		_anim.sprite_frames = PlayerAnimationFactory.build_from_skin(skin_key)
		_apply_sprite_layout()
		_anim.play("idle")


func _apply_sprite_layout() -> void:
	if _anim == null:
		return
	var scale_val := CharacterArt.get_sprite_scale(skin_key)
	_anim.scale = Vector2(scale_val, scale_val)
	var frame_h := _frame_pixel_height()
	if frame_h > 0.0:
		_anim.offset = Vector2(0, -frame_h * scale_val * 0.30)
	else:
		_anim.offset = Vector2(0, -10)


func _frame_pixel_height() -> float:
	if _anim == null or _anim.sprite_frames == null:
		return 0.0
	for anim_name in ["idle", "run", "jump"]:
		if _anim.sprite_frames.has_animation(anim_name) and _anim.sprite_frames.get_frame_count(anim_name) > 0:
			var tex := _anim.sprite_frames.get_frame_texture(anim_name, 0)
			if tex:
				return float(tex.get_height())
	return 0.0


func update_motion(velocity: Vector2, on_floor: bool, attacking: bool = false, dashing: bool = false) -> void:
	if _anim == null:
		return
	var state := "idle"
	if attacking:
		state = "attack_pulse"
	elif dashing:
		state = "dash"
	elif not on_floor:
		state = "jump"
	elif velocity.length() > 40.0:
		state = "run"
	if state != _last_state and _anim.sprite_frames.has_animation(state):
		_anim.play(state)
		_last_state = state
	if _dash_trail:
		_dash_trail.emitting = dashing
	if velocity.x != 0.0:
		_anim.flip_h = velocity.x < 0.0
	_breath_t += get_process_delta_time()
	var bob := sin(_breath_t * 3.2) * (1.2 if state == "idle" else 2.5)
	_anim.position.y = bob
	if _halo:
		_halo.energy = 0.32 + sin(_breath_t * 2.1) * 0.05


func flash_attack() -> void:
	if _anim == null:
		return
	if _anim.sprite_frames.has_animation("attack_pulse"):
		_anim.play("attack_pulse")
	_last_state = "attack_pulse"
	var tw := create_tween()
	tw.tween_property(_anim, "modulate", Color(2.0, 2.3, 1.5), 0.06)
	tw.tween_property(_anim, "modulate", Color.WHITE, 0.22)
