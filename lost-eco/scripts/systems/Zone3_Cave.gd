extends Node2D

const MAP = [
	"################################",
	"#..............................#",
	"#.############################.#",
	"#.#..........................#.#",
	"#.#.########################.#.#",
	"#.#.#....................#...#.#",
	"#.#.#.##################.#.#.#.#",
	"#.#.#.#S.................#.#.#.#",
	"#.#.#.##################.#.#.#.#",
	"#.#.#....................#.#.#.#.",
	"#.#.########################.#.#",
	"#.#..........................#.#",
	"#.############################.#",
	"#..............................#",
	"#.######.##################.####",
	"#.#....#.#................#...##",
	"#.#.##.#.#.############.###.####",
	"#.#.##.#.#.#..........B.#.......",
	"#...##...#.############.########",
	"################################",
]

const TS = 16
const FLOOR_COLOR   = Color(0.08, 0.06, 0.15)
const WALL_COLOR    = Color(0.05, 0.03, 0.12)
const CRYSTAL_COLOR = Color(0.25, 0.15, 0.45)

var floors: Array = []
var walls:  Array = []

# ── HUD ──────────────────────────────────────────────────────────────────────
var hud_layer: CanvasLayer = null
var lbl_score: Label = null
var lbl_health: Label = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.03, 0.02, 0.08))
	_generate_map()
	_setup_hud()
	DialogueManager.show_floating_text(
		"Los cristales reflejan tu imagen...\nEsta cueva guarda un secreto.",
		Vector2(80, 20), Color(0.7, 0.5, 0.9)
	)

func _generate_map() -> void:
	for y in MAP.size():
		for x in MAP[y].length():
			var c = MAP[y][x]
			var pos = Vector2(x * TS, y * TS)
			match c:
				"#":
					walls.append(Rect2(pos, Vector2(TS, TS)))
					_add_wall(pos)
				"S":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					if GameManager.player:
						GameManager.player.global_position = pos + Vector2(8, 8)
				"B":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_boss(pos)
				_:
					floors.append(Rect2(pos, Vector2(TS, TS)))
					if randf() < 0.1:
						_spawn_crystal(pos)
	queue_redraw()

func _draw() -> void:
	for r in floors: draw_rect(r, FLOOR_COLOR)
	for r in walls:  draw_rect(r, WALL_COLOR)

func _add_wall(pos: Vector2) -> void:
	var b = StaticBody2D.new()
	b.global_position = pos + Vector2(TS / 2.0, TS / 2.0)
	add_child(b)
	var c = CollisionShape2D.new()
	var s = RectangleShape2D.new()
	s.size = Vector2(TS, TS)
	c.shape = s
	b.add_child(c)

func _spawn_crystal(pos: Vector2) -> void:
	var poly = Polygon2D.new()
	var cx = pos.x + TS / 2.0
	var cy = pos.y + TS / 2.0
	poly.position = Vector2(cx, cy)
	poly.polygon = PackedVector2Array([
		Vector2(0,-5), Vector2(3,-1), Vector2(2,4),
		Vector2(-2,4), Vector2(-3,-1)
	])
	poly.color = CRYSTAL_COLOR
	add_child(poly)

func _spawn_boss(pos: Vector2) -> void:
	var boss_node = Node2D.new()
	boss_node.global_position = pos + Vector2(TS / 2.0, TS / 2.0)
	boss_node.add_to_group("mirror_boss")
	add_child(boss_node)

	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0,-10), Vector2(8,-4), Vector2(6,8),
		Vector2(-6,8),  Vector2(-8,-4)
	])
	poly.color = Color(0.3, 0.1, 0.5)
	boss_node.add_child(poly)

	# Pulso de brillo inicial
	var tween_idle = create_tween().set_loops()
	tween_idle.tween_property(poly, "modulate", Color(1.4, 0.6, 2.0), 1.0)
	tween_idle.tween_property(poly, "modulate", Color(1.0, 1.0, 1.0), 1.0)

	var area = Area2D.new()
	area.global_position = pos + Vector2(TS / 2.0, TS / 2.0)
	add_child(area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 20
	c.shape = s
	area.add_child(c)

	var phase = 0
	area.body_entered.connect(func(body):
		if not body.is_in_group("player"): return
		phase += 1
		match phase:
			1:
				tween_idle.kill()
				DialogueManager.show_floating_text(
					"El monstruo imita cada uno de tus movimientos.\n¡No ataques! Acércate sin arma.",
					body.global_position + Vector2(0,-30), Color(0.8, 0.5, 1.0)
				)
				_boss_pulse(boss_node, poly)
			2:
				DialogueManager.show_floating_text(
					"Se detiene... está confundido.\nAcércate y cúralo sin arma.",
					body.global_position + Vector2(0,-30), Color(0.9, 0.7, 1.0)
				)
			3:
				if not GameManager.player.has_weapon_equipped():
					_heal_boss(boss_node, poly, body)
				else:
					DialogueManager.show_floating_text(
						"Debes soltar el arma primero.\nPresiona Q para soltarla.",
						body.global_position + Vector2(0,-30), Color(1.0, 0.5, 0.3)
					)
					phase = 2  # Permite volver a intentarlo
	)

func _boss_pulse(boss: Node2D, poly: Polygon2D) -> void:
	var tween = create_tween().set_loops(8)
	tween.tween_property(poly, "modulate", Color(1.8, 0.3, 2.0), 0.25)
	tween.tween_property(poly, "modulate", Color(1.0, 1.0, 1.0),  0.25)

func _heal_boss(boss: Node2D, poly: Polygon2D, player: Node) -> void:
	DialogueManager.show_floating_text(
		"El cristal se calienta...\nla oscuridad se disipa.",
		boss.global_position + Vector2(0,-20), Color(1.0, 0.85, 0.2)
	)
	var tween = create_tween()
	tween.tween_property(poly, "modulate", Color(2.0, 1.7, 0.3), 2.0)
	tween.tween_property(boss, "scale", Vector2(0.1, 0.1), 1.5)
	tween.tween_callback(func():
		boss.queue_free()
		_zone_complete()
	)

func _zone_complete() -> void:
	set_process(false)
	QuestManager.advance_quest("zone3")
	GameManager.update_empathy(0.34)
	GameManager.add_score(700)
	_update_hud()
	DialogueManager.show_floating_text(
		"El monstruo era tu propio miedo reflejado.\nHas elegido la empatía.\n+700 puntos",
		GameManager.player.global_position + Vector2(0,-30), Color(1.0, 0.85, 0.3)
	)
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file("res://scenes/world/Clearing.tscn")

# ── HUD ───────────────────────────────────────────────────────────────────────
func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	lbl_score = Label.new()
	lbl_score.position = Vector2(4, 2)
	lbl_score.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	lbl_score.add_theme_font_size_override("font_size", 9)
	hud_layer.add_child(lbl_score)

	lbl_health = Label.new()
	lbl_health.position = Vector2(4, 13)
	lbl_health.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	lbl_health.add_theme_font_size_override("font_size", 9)
	hud_layer.add_child(lbl_health)

	var lbl_zone = Label.new()
	lbl_zone.position = Vector2(4, 24)
	lbl_zone.text = "ZONA 3: La Cueva del Espejo"
	lbl_zone.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	lbl_zone.add_theme_font_size_override("font_size", 9)
	hud_layer.add_child(lbl_zone)

	GameManager.health_changed.connect(func(_v): _update_hud())
	GameManager.score_changed.connect(func(_v): _update_hud())
	_update_hud()

func _update_hud() -> void:
	if lbl_score:
		lbl_score.text = "PTS: %d" % GameManager.score
	if lbl_health:
		var h = ""
		for _i in GameManager.current_health:
			h += "♥"
		for _i in (GameManager.max_health - GameManager.current_health):
			h += "♡"
		lbl_health.text = "VIDA: " + h
