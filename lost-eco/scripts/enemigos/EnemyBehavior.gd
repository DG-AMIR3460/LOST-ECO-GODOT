extends RefCounted
class_name EnemyBehavior
## IA ligera: patrulla, persecución con embestida y oleadas.


const PATROL_RADIUS := 52.0
const RUSH_DIST := 58.0
const CHASE_DIST := 140.0


static func init_entry(ed: Dictionary, home: Vector2) -> void:
	ed["home"] = home
	ed["speed_mult"] = 1.0
	ed["surge_timer"] = 0.0
	ed["rush_timer"] = 0.0
	_pick_patrol_target(ed)


static func tick(ed: Dictionary, player_pos: Vector2, delta: float) -> void:
	var en: Node2D = ed.get("node")
	if not is_instance_valid(en):
		return

	if en.has_meta("stunned"):
		var t: float = en.get_meta("stunned") - delta
		if t <= 0.0:
			en.remove_meta("stunned")
			en.modulate = Color.WHITE
		else:
			en.set_meta("stunned", t)
			en.modulate = Color(0.55, 0.65, 1.5)
		return

	var speed: float = ed["speed"]
	if ed.get("surge_timer", 0.0) > 0.0:
		ed["surge_timer"] -= delta
		speed *= 1.75
	if ed.get("rush_timer", 0.0) > 0.0:
		ed["rush_timer"] -= delta
		speed *= 1.45

	var dist := en.global_position.distance_to(player_pos)

	if dist > CHASE_DIST:
		_patrol(ed, en, speed, delta)
	elif dist > RUSH_DIST:
		_move_toward(ed, en, ed.get("patrol_target", ed["home"]), speed * 0.65, delta)
	else:
		_move_toward(ed, en, player_pos, speed, delta)

	_sync_area(ed, en)


static func trigger_surge(enemies: Array, duration: float = 4.5) -> void:
	for ed in enemies:
		ed["surge_timer"] = duration


static func trigger_rush_near(enemies: Array, origin: Vector2, count: int = 2) -> void:
	var sorted: Array = enemies.duplicate()
	sorted.sort_custom(func(a, b):
		var na: Node2D = a.get("node")
		var nb: Node2D = b.get("node")
		if not is_instance_valid(na):
			return false
		if not is_instance_valid(nb):
			return true
		return na.global_position.distance_to(origin) < nb.global_position.distance_to(origin)
	)
	for i in mini(count, sorted.size()):
		sorted[i]["rush_timer"] = 2.8


static func _patrol(ed: Dictionary, en: Node2D, speed: float, delta: float) -> void:
	var target: Vector2 = ed.get("patrol_target", ed["home"])
	if en.global_position.distance_to(target) < 10.0:
		_pick_patrol_target(ed)
		target = ed["patrol_target"]
	_move_toward(ed, en, target, speed * 0.5, delta)


static func _move_toward(ed: Dictionary, en: Node2D, target: Vector2, speed: float, delta: float) -> void:
	var dir := target - en.global_position
	if dir.length() <= 4.0:
		return
	en.global_position += dir.normalized() * speed * delta
	_face(en, dir.x)


static func _face(en: Node2D, dx: float) -> void:
	if absf(dx) < 0.05:
		return
	var sprite: Sprite2D = en.get_node_or_null("Sprite")
	if sprite:
		sprite.scale.x = absf(sprite.scale.x) * (-1.0 if dx < 0.0 else 1.0)


static func _pick_patrol_target(ed: Dictionary) -> void:
	var home: Vector2 = ed.get("home", Vector2.ZERO)
	ed["patrol_target"] = home + Vector2(
		randf_range(-PATROL_RADIUS, PATROL_RADIUS),
		randf_range(-PATROL_RADIUS, PATROL_RADIUS)
	)


static func _sync_area(ed: Dictionary, en: Node2D) -> void:
	var ar: Area2D = ed.get("area")
	if is_instance_valid(ar):
		ar.global_position = en.global_position
