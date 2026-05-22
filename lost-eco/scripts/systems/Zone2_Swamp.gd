extends Node2D

# Cada fila del MAP debe tener EXACTAMENTE 32 caracteres.
# S=Inicio | B=Bloqueador sombra | E=Salida | #=Pared | .=Pantano (barro)
const MAP = [
	"################################",
	"#S.............................#",
	"#..............................#",
	"#..............................#",
	"#...........B..................#",
	"#..............................#",
	"#..............................#",
	"###########################.####",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#....####....####....####......#",
	"#..............................#",
	"#.........####.....####........#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#.............................E#",
	"################################",
]

const TS = 16
const MUD_COLOR    = Color(0.20, 0.22, 0.12)
const WALL_COLOR   = Color(0.10, 0.12, 0.06)
const SHADOW_COLOR = Color(0.8, 0.8, 0.9, 0.5)

var floors: Array = []
var walls:  Array = []

# ── HUD ──────────────────────────────────────────────────────────────────────
var hud_layer: CanvasLayer = null
var lbl_score: Label = null
var lbl_health: Label = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.10, 0.13, 0.06))
	_generate_map()
	_setup_hud()
	DialogueManager.show_floating_text(
		"Sientes el fango jalarte...\nLa paciencia es el único camino.",
		Vector2(100, 30), Color(0.8, 0.9, 0.7)
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
						GameManager.player.set_speed_multiplier(0.6)
				"B":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_shadow_blocker(pos)
				"E":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_exit(pos)
				".":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_mud_zone(pos)
	queue_redraw()

func _draw() -> void:
	for r in floors: draw_rect(r, MUD_COLOR)
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

func _add_mud_zone(pos: Vector2) -> void:
	var area = Area2D.new()
	area.global_position = pos
	add_child(area)
	var c = CollisionShape2D.new()
	var s = RectangleShape2D.new()
	s.size = Vector2(TS, TS)
	c.shape = s
	area.add_child(c)
	area.body_entered.connect(func(body):
		if body.is_in_group("player"):
			body.set_speed_multiplier(0.4)
	)
	area.body_exited.connect(func(body):
		if body.is_in_group("player"):
			body.set_speed_multiplier(1.0)
	)

func _spawn_shadow_blocker(pos: Vector2) -> void:
	var b = StaticBody2D.new()
	b.global_position = pos + Vector2(TS / 2.0, TS / 2.0)
	b.add_to_group("shadow_blocker")
	add_child(b)
	var c = CollisionShape2D.new()
	var s = RectangleShape2D.new()
	s.size = Vector2(TS - 2, TS - 2)
	c.shape = s
	b.add_child(c)
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-7,-7), Vector2(7,-7), Vector2(7,7), Vector2(-7,7)
	])
	poly.color = SHADOW_COLOR
	b.add_child(poly)
	DialogueManager.show_floating_text(
		"Una sombra bloquea el camino...\nActúa con cuidado.",
		b.global_position + Vector2(0, -20), Color(0.9, 0.9, 1.0)
	)

func _spawn_exit(pos: Vector2) -> void:
	var area = Area2D.new()
	area.global_position = pos + Vector2(TS / 2.0, TS / 2.0)
	add_child(area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 10
	c.shape = s
	area.add_child(c)

	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-8,-8), Vector2(8,-8), Vector2(8,8), Vector2(-8,8)
	])
	poly.color = Color(0.4, 0.8, 0.4)
	area.add_child(poly)

	# Pulso en el portal de salida
	var tween = create_tween().set_loops()
	tween.tween_property(poly, "modulate", Color(1.8, 1.8, 0.5), 0.7)
	tween.tween_property(poly, "modulate", Color(1.0, 1.0, 1.0),  0.7)

	area.body_entered.connect(func(body):
		if body.is_in_group("player"):
			_zone_complete()
	)

func _zone_complete() -> void:
	set_process(false)
	QuestManager.advance_quest("zone2")
	GameManager.update_empathy(0.33)
	GameManager.add_score(400)
	if GameManager.player:
		GameManager.player.set_speed_multiplier(1.0)
	DialogueManager.show_floating_text(
		"Aprendiste a construir puentes, no muros.\n+400 puntos",
		GameManager.player.global_position + Vector2(0, -30), Color(0.5, 0.9, 0.5)
	)
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/world/Zone3_Cave.tscn")

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
	lbl_zone.text = "ZONA 2: El Pantano"
	lbl_zone.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
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
