extends RefCounted
class_name EnemyBehavior
## IA: persigue al jugador, respeta paredes y puede ser eliminada con Pulso de Luz.


const RUSH_DIST := 48.0


static func init_entry(ed: Dictionary, home: Vector2) -> void:
	ed["home"] = home
	ed["speed_mult"] = 1.0
	ed["surge_timer"] = 0.0
	ed["rush_timer"] = 0.0


static func tick(ed: Dictionary, player_pos: Vector2, delta: float) -> void:
	var en: Node2D = ed.get("node")
	if not is_instance_valid(en):
		return
	if en.has_meta("eliminating"):
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

	var speed: float = float(ed.get("speed", 0.0))
	if float(ed.get("surge_timer", 0.0)) > 0.0:
		ed["surge_timer"] = float(ed.get("surge_timer", 0.0)) - delta
		speed *= 1.75
	if float(ed.get("rush_timer", 0.0)) > 0.0:
		ed["rush_timer"] = float(ed.get("rush_timer", 0.0)) - delta
		speed *= 1.45

	var dist: float = en.global_position.distance_to(player_pos)
	var chase_speed: float = speed * (1.35 if dist > 120.0 else 1.0)
	_move_toward(ed, en, player_pos, chase_speed, delta)
	_sync_area(ed, en)


static func eliminate_in_radius(enemies: Array, player_pos: Vector2, radius: float) -> int:
	var removed: int = 0
	var pending: Array = []
	for ed in enemies:
		var en: Node2D = ed.get("node")
		if not is_instance_valid(en):
			pending.append(ed)
			continue
		if en.has_meta("eliminating"):
			continue
		if en.global_position.distance_to(player_pos) > radius:
			continue
		eliminate_entry(ed, en.get_parent())
		pending.append(ed)
		removed += 1
	for ed in pending:
		enemies.erase(ed)
	return removed


static func eliminate_entry(ed: Dictionary, tween_host: Node) -> void:
	var en: Node2D = ed.get("node")
	var ar: Area2D = ed.get("area")
	if is_instance_valid(en):
		en.set_meta("eliminating", true)
	if is_instance_valid(ar):
		ar.monitoring = false
		ar.monitorable = false
	if not is_instance_valid(en):
		if is_instance_valid(ar):
			ar.queue_free()
		return
	var host: Node = tween_host if is_instance_valid(tween_host) else en
	var tw: Tween = host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(en, "modulate:a", 0.0, 0.38)
	tw.tween_property(en, "scale", en.scale * 0.25, 0.38)
	tw.chain().tween_callback(func():
		if is_instance_valid(en):
			en.queue_free()
		if is_instance_valid(ar):
			ar.queue_free()
	)


static func trigger_surge(enemies: Array, duration: float = 4.5) -> void:
	for ed in enemies:
		if ed.has("node") and is_instance_valid(ed["node"]):
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


static func _move_toward(_ed: Dictionary, en: Node2D, target: Vector2, speed: float, delta: float) -> void:
	GridMapPhysics.move_node(en, target, speed, delta)
	var dx: float = target.x - en.global_position.x
	_face(en, dx)


static func _face(en: Node2D, dx: float) -> void:
	if absf(dx) < 0.05:
		return
	en.scale.x = absf(en.scale.x) * (-1.0 if dx < 0.0 else 1.0)


static func _sync_area(ed: Dictionary, en: Node2D) -> void:
	var ar: Area2D = ed.get("area")
	if is_instance_valid(ar):
		ar.global_position = en.global_position
