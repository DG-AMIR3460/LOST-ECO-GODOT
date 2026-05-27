extends Area2D
class_name LightPulseWave

const RADIUS: float = 78.0
const KNOCKBACK: float = 340.0
const LIFETIME: float = 0.38

var _owner_player: PlayerController2D = null
var _burst_light: PointLight2D = null


func _ready() -> void:
	collision_layer = 4
	collision_mask = 27
	monitoring = true
	monitorable = false
	z_index = 50
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(2.6, 2.6), LIFETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(self, "modulate:a", 0.0, LIFETIME)
	if _burst_light:
		tween.parallel().tween_property(_burst_light, "energy", 0.0, LIFETIME)
	tween.tween_callback(queue_free)


func activate(origin: Vector2, owner_player: PlayerController2D) -> void:
	global_position = origin
	_owner_player = owner_player
	modulate = Color(1.5, 1.7, 1.0, 0.9)
	_burst_light = PointLight2D.new()
	LightTextureFactory.apply_halo_to_light(_burst_light, Color(1.0, 0.95, 0.7), 2.2, 3.2)
	add_child(_burst_light)
	var ring := Polygon2D.new()
	ring.color = Color(1.0, 0.96, 0.75, 0.45)
	ring.polygon = _make_ring(32, RADIUS * 0.35, RADIUS)
	add_child(ring)
	var core := Polygon2D.new()
	core.color = Color(1.2, 1.3, 0.9, 0.7)
	core.polygon = _make_ring(16, 2.0, RADIUS * 0.4)
	add_child(core)


func _make_ring(segments: int, inner: float, outer: float) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in segments + 1:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * outer)
	for i in segments + 1:
		var a := TAU * float(segments - i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * inner)
	return pts


func _on_body_entered(body: Node2D) -> void:
	if body is EnemyAIBase:
		var enemy := body as EnemyAIBase
		var dir := (enemy.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		enemy.receive_light_pulse(dir, KNOCKBACK)
	if body.is_in_group("terrain_switch") and body.has_method("activate_switch"):
		body.activate_switch()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullying_projectile"):
		area.queue_free()
