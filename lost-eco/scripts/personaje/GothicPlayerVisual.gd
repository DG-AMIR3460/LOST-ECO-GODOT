extends Node2D
class_name GothicPlayerVisual
## Capa visual gótica: AnimatedSprite2D, luz orgánica, estela de dash.

@export var skin_key: String = "alex"

var _anim: AnimatedSprite2D = null
var _outline: AnimatedSprite2D = null
var _shadow: Polygon2D = null
var _halo: PointLight2D = null
var _dash_trail: GPUParticles2D = null
var _breath_t: float = 0.0
var _last_state: String = "idle"
var _facing_x: float = 1.0
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
	_halo.energy = 0.52
	_halo.color = Color(0.95, 0.90, 1.0)
	_halo.texture_scale = 1.05
	LightTextureFactory.apply_halo_to_light(_halo, Color(0.92, 0.88, 1.0), 0.52, 1.05)
	add_child(_halo)
	_shadow = Polygon2D.new()
	_shadow.name = "GroundShadow"
	_shadow.z_index = -3
	_shadow.color = Color(0.02, 0.02, 0.05, 0.55)
	_shadow.polygon = PackedVector2Array([
		Vector2(-5, 4), Vector2(0, 7), Vector2(5, 4), Vector2(0, 2)
	])
	add_child(_shadow)
	_outline = AnimatedSprite2D.new()
	_outline.name = "BodyOutline"
	_outline.z_index = 1
	_outline.centered = true
	_outline.modulate = Color(0.05, 0.05, 0.08, 0.95)
	_outline.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_outline)
	_anim = AnimatedSprite2D.new()
	_anim.name = "BodyAnim"
	_anim.z_index = 2
	_anim.modulate = Color(1.18, 1.16, 1.22)
	_anim.sprite_frames = PlayerAnimationFactory.build_from_skin(skin_key)
	_anim.centered = true
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _outline:
		_outline.sprite_frames = _anim.sprite_frames
		_outline.scale = Vector2(1.06, 1.06)
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
		if _outline:
			_outline.sprite_frames = _anim.sprite_frames
		_apply_sprite_layout()
		_anim.play("idle")


func _apply_sprite_layout() -> void:
	if _anim == null:
		return
	var scale_val := CharacterArt.get_sprite_scale(skin_key)
	_anim.scale = Vector2(scale_val, scale_val)
	var frame_h := _frame_pixel_height()
	if frame_h > 0.0:
		_anim.offset = Vector2(0, -frame_h * scale_val * 0.22)
	else:
		_anim.offset = Vector2(0, -6)
	if _outline:
		_outline.scale = Vector2(scale_val * 1.06, scale_val * 1.06)
		_outline.offset = _anim.offset


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
	elif velocity.length() > 10.0:
		state = "run"
	if state != _last_state and _anim.sprite_frames.has_animation(state):
		_anim.play(state)
		if _outline and _outline.sprite_frames.has_animation(state):
			_outline.play(state)
		_last_state = state
	if state == "run" and _anim.sprite_frames.get_frame_count("run") > 1:
		var speed_scale := clampf(velocity.length() / 90.0, 0.85, 1.35)
		_anim.speed_scale = speed_scale
		if _outline:
			_outline.speed_scale = speed_scale
	else:
		_anim.speed_scale = 1.0
		if _outline:
			_outline.speed_scale = 1.0
	if _dash_trail:
		_dash_trail.emitting = dashing
	if absf(velocity.x) > 0.5:
		_facing_x = signf(velocity.x)
	var faces_left := CharacterArt.sprite_faces_left(skin_key)
	_anim.flip_h = (_facing_x > 0.0) if faces_left else (_facing_x < 0.0)
	_breath_t += get_process_delta_time()
	var bob_amp := 1.0 if state == "idle" else 4.0
	var bob_speed := 3.0 if state == "idle" else TAU / 0.22
	var bob := sin(_breath_t * bob_speed) * bob_amp
	if state == "idle":
		bob *= 0.35
	_anim.position.y = bob
	if _outline:
		_outline.position.y = bob
		_outline.flip_h = _anim.flip_h
	if _halo:
		_halo.energy = 0.55 + sin(_breath_t * 2.1) * 0.08


func flash_attack() -> void:
	if _anim == null:
		return
	if _anim.sprite_frames.has_animation("attack_pulse"):
		_anim.play("attack_pulse")
	_last_state = "attack_pulse"
	var tw := create_tween()
	tw.tween_property(_anim, "modulate", Color(2.0, 2.3, 1.5), 0.06)
	tw.tween_property(_anim, "modulate", Color.WHITE, 0.22)
