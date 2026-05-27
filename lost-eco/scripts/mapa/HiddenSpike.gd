extends Area2D

@onready var visual: Polygon2D = $Visual

var _armed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_armed = false
	if visual:
		visual.color = Color(0.45, 0.08, 0.12, 0.35)
		visual.polygon = PackedVector2Array([-7, 5, 0, -8, 7, 5, 0, 2])
	var tw := create_tween().set_loops()
	if visual:
		tw.tween_property(visual, "modulate", Color(1.4, 0.35, 0.3, 0.5), 0.35)
		tw.tween_property(visual, "modulate", Color(0.5, 0.1, 0.15, 0.2), 0.45)
	await get_tree().create_timer(0.6).timeout
	_armed = true


func _process(_delta: float) -> void:
	if visual == null:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p := players[0] as PlayerController2D
	if p == null:
		return
	var dist := global_position.distance_to(p.global_position)
	var alpha := clampf(1.0 - dist / 48.0, 0.06, 0.85)
	visual.modulate.a = alpha
	if dist < 14.0:
		visual.modulate = Color(1.2, 0.3, 0.25, alpha)


func _on_body_entered(body: Node2D) -> void:
	if not _armed:
		return
	if body is PlayerController2D:
		var player := body as PlayerController2D
		if player.is_spawn_protected():
			return
		player.take_damage_from(global_position, 1, "El pantano oculta sus espinas.")
