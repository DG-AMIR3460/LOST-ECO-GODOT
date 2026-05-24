extends Node2D

# ── Mapa (32 columnas × 20 filas) ────────────────────────────────────────────
# S = Inicio | E = Eco | X = Salida | # = Pared | . = Pantano
const MAP = [
	"################################",
	"#S.............................#",
	"#....E.........................#",
	"#..............................#",
	"#..............................#",
	"##########..#########..#########",
	"#..............................#",
	"#........................E.....#",
	"#..............................#",
	"#..............................#",
	"##########..#########..#########",
	"#..............................#",
	"#.........E....................#",
	"#..............................#",
	"#..............................#",
	"##########..#########..#########",
	"#..............................#",
	"#..............................#",
	"#.............................X#",
	"################################",
]

const TS = 16
const MUD_COLOR         = Color(0.20, 0.22, 0.12)
const WALL_COLOR        = Color(0.10, 0.12, 0.06)
const ECHO_COLOR        = Color(0.6, 0.85, 0.45)
const EXIT_LOCKED_COLOR = Color(0.28, 0.32, 0.18)
const EXIT_OPEN_COLOR   = Color(0.35, 0.90, 0.40)
const ENEMY_BODY_COLOR  = Color(0.12, 0.28, 0.10)
const ENEMY_GLOW_COLOR  = Color(0.35, 0.55, 0.20, 0.35)

var floors: Array = []
var walls:  Array = []

var echoes_collected: int = 0
const TOTAL_ECHOES = 3

var exit_poly: Polygon2D = null
var exit_area: Area2D = null
var exit_unlocked: bool = false
var _transitioning: bool = false

var enemies: Array = []
const ENEMY_TILES = [
	Vector2i(12,  2),
	Vector2i(24,  4),
	Vector2i( 8,  7),
	Vector2i(22, 12),
	Vector2i(14, 17),
]

const ENEMY_MSGS = [
	"El fango te arrastra...\ncomo el remordimiento.  -1 vida",
	"Cada paso pesado recuerda\nlo que ignoraste.  -1 vida",
	"La paciencia también duele\n cuando la necesitas.  -1 vida",
	"El pantano no perdona\nla impulsividad.  -1 vida",
	"Resistir el barro es aprender\na escuchar.  -1 vida",
]

var light_charges: int = 0
const MAX_CHARGES: int = 3
const PULSE_RADIUS: float = 50.0
const STUN_TIME: float = 1.8

var hud_layer: CanvasLayer = null
var lbl_score: Label = null
var lbl_health: Label = null
var lbl_echo: Label = null
var lbl_light: Label = null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.10, 0.13, 0.06))
	_generate_map()
	_spawn_enemies()
	_setup_hud()
	GameManager.health_changed.connect(func(_v): _update_hud())
	GameManager.score_changed.connect(func(_v): _update_hud())

	if GameManager.player:
		GameManager.player.has_weapon = false

	await get_tree().create_timer(0.5).timeout
	DialogueManager.show_zone_intro(
		"ZONA 2 — El Pantano",
		"El fango te frena a cada paso.\nRecoge 3 Ecos de Luz para abrir la salida.",
		"Usa [J] para repeler sombras. La paciencia es tu camino.",
		Color(0.65, 0.95, 0.50)
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
					_add_mud_zone(pos)
					if GameManager.player:
						GameManager.player.global_position = pos + Vector2(8, 8)
						GameManager.player.set_speed_multiplier(0.65)
				"E":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_mud_zone(pos)
					_spawn_echo(pos)
				"X":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_mud_zone(pos)
					_spawn_exit(pos)
				_:
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
			body.set_speed_multiplier(0.42)
	)
	area.body_exited.connect(func(body):
		if body.is_in_group("player"):
			body.set_speed_multiplier(0.65)
	)


func _spawn_echo(pos: Vector2) -> void:
	var a = Area2D.new()
	a.global_position = pos + Vector2(TS / 2.0, TS / 2.0)
	a.add_to_group("echo_of_light")
	add_child(a)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 7
	c.shape = s
	a.add_child(c)
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
	])
	poly.color = ECHO_COLOR
	a.add_child(poly)
	var tween = create_tween().set_loops()
	tween.tween_property(poly, "modulate", Color(1.6, 2.0, 0.8), 0.55)
	tween.tween_property(poly, "modulate", Color(1.0, 1.0, 1.0), 0.55)
	a.body_entered.connect(func(body):
		if body.is_in_group("player"):
			_collect_echo(a)
	)


func _collect_echo(node: Node) -> void:
	echoes_collected += 1
	node.queue_free()
	GameManager.add_score(120)
	light_charges = min(light_charges + 1, MAX_CHARGES)
	_update_hud()
	if GameManager.player:
		DialogueManager.show_floating_text(
			"Eco %d/%d recogido  +120 pts  ⚡+1" % [echoes_collected, TOTAL_ECHOES],
			GameManager.player.global_position + Vector2(0, -22), Color(0.6, 0.95, 0.5)
		)
	if echoes_collected >= TOTAL_ECHOES:
		_unlock_exit()


func _spawn_exit(pos: Vector2) -> void:
	var center = pos + Vector2(TS / 2.0, TS / 2.0)
	var exit_node = Node2D.new()
	exit_node.global_position = center
	add_child(exit_node)

	exit_poly = Polygon2D.new()
	exit_poly.polygon = PackedVector2Array([
		Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7)
	])
	exit_poly.color = EXIT_LOCKED_COLOR
	exit_node.add_child(exit_poly)

	exit_area = Area2D.new()
	exit_area.global_position = center
	add_child(exit_area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 12
	c.shape = s
	exit_area.add_child(c)
	exit_area.body_entered.connect(func(body):
		if not body.is_in_group("player"):
			return
		if exit_unlocked:
			_zone_complete()
		else:
			DialogueManager.show_floating_text(
				"Salida bloqueada...\nRecoge los %d ecos primero." % TOTAL_ECHOES,
				body.global_position + Vector2(0, -25), Color(0.6, 0.8, 0.5)
			)
	)


func _unlock_exit() -> void:
	exit_unlocked = true
	if exit_poly:
		exit_poly.color = EXIT_OPEN_COLOR
		var tween = create_tween().set_loops()
		tween.tween_property(exit_poly, "modulate", Color(1.6, 2.2, 1.4), 0.45)
		tween.tween_property(exit_poly, "modulate", Color(1.0, 1.0, 1.0), 0.45)
	if GameManager.player:
		DialogueManager.show_floating_text(
			"¡La salida se abrió!\nPortal verde → esquina inferior derecha.",
			GameManager.player.global_position + Vector2(0, -30), Color(0.3, 1.0, 0.45)
		)


func _spawn_enemies() -> void:
	for i in ENEMY_TILES.size():
		var tile = ENEMY_TILES[i]
		var world_pos = Vector2(tile.x * TS, tile.y * TS) + Vector2(TS / 2.0, TS / 2.0)
		_create_enemy(world_pos, i)


func _create_enemy(world_pos: Vector2, idx: int) -> void:
	var enemy := ShadowEnemyVisual.create(self, world_pos, {
		"body": ENEMY_BODY_COLOR,
		"glow": ENEMY_GLOW_COLOR,
		"pulse": Color(0.55, 1.35, 0.45),
		"eyes": Color(0.85, 1.0, 0.35),
		"wisp": Color(0.10, 0.22, 0.06, 0.75),
	})

	var area = Area2D.new()
	area.global_position = world_pos
	add_child(area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 8
	c.shape = s
	area.add_child(c)

	var msg = ENEMY_MSGS[idx % ENEMY_MSGS.size()]
	area.body_entered.connect(func(body_hit):
		if body_hit.is_in_group("player"):
			_enemy_hit_player(body_hit, msg, enemy.global_position)
	)

	enemies.append({
		"node": enemy,
		"area": area,
		"speed": 14.0 + idx * 1.5,
	})


func _enemy_hit_player(p: Node, message: String, source_pos: Vector2) -> void:
	if p.has_meta("enemy_cd") and p.get_meta("enemy_cd") > 0.0:
		return
	p.set_meta("enemy_cd", 1.6)
	GameManager.take_damage()
	if is_instance_valid(p):
		p.take_hit(source_pos)
		DialogueManager.show_floating_text(
			message, p.global_position + Vector2(0, -28), Color(0.7, 1.0, 0.45)
		)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and light_charges > 0 and GameManager.player:
		_use_light_pulse()
		get_viewport().set_input_as_handled()


func _use_light_pulse() -> void:
	light_charges -= 1
	_update_hud()
	var player_pos = GameManager.player.global_position

	var tween_flash = create_tween()
	tween_flash.tween_property(GameManager.player, "modulate", Color(2.0, 3.0, 1.0), 0.08)
	tween_flash.tween_property(GameManager.player, "modulate", Color(1.0, 1.0, 1.0), 0.25)

	for ed in enemies:
		var en: Node2D = ed["node"]
		if not is_instance_valid(en):
			continue
		if en.global_position.distance_to(player_pos) <= PULSE_RADIUS:
			var push_dir = (en.global_position - player_pos).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.RIGHT
			en.global_position += push_dir * 50.0
			en.set_meta("stunned", STUN_TIME)
			var ar: Area2D = ed["area"]
			if is_instance_valid(ar):
				ar.global_position = en.global_position

	DialogueManager.show_floating_text(
		"¡Pulso de Luz!", player_pos + Vector2(0, -25), Color(0.8, 1.0, 0.4)
	)

	await get_tree().create_timer(8.0).timeout
	if not _transitioning:
		light_charges = min(light_charges + 1, MAX_CHARGES)
		_update_hud()


func _process(delta: float) -> void:
	if GameManager.player and GameManager.player.has_meta("enemy_cd"):
		var cd = maxf(0.0, GameManager.player.get_meta("enemy_cd") - delta)
		GameManager.player.set_meta("enemy_cd", cd)

	if not GameManager.player:
		return
	var player_pos = GameManager.player.global_position

	for ed in enemies:
		var en: Node2D = ed["node"]
		if not is_instance_valid(en):
			continue

		if en.has_meta("stunned"):
			var t = en.get_meta("stunned") - delta
			if t <= 0.0:
				en.remove_meta("stunned")
				var b = en.get_node_or_null("Body")
				if b:
					b.modulate = Color(1, 1, 1)
			else:
				en.set_meta("stunned", t)
				var b = en.get_node_or_null("Body")
				if b:
					b.modulate = Color(0.5, 1.0, 0.6)
				continue

		var dir = player_pos - en.global_position
		if dir.length() > 4.0:
			en.global_position += dir.normalized() * ed["speed"] * delta
		var ar: Area2D = ed["area"]
		if is_instance_valid(ar):
			ar.global_position = en.global_position


func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	lbl_score = _make_label(Vector2(4, 2), Color(1.0, 0.9, 0.3))
	lbl_health = _make_label(Vector2(4, 13), Color(1.0, 0.35, 0.35))
	lbl_echo = _make_label(Vector2(4, 24), Color(0.6, 0.95, 0.5))
	lbl_light = _make_label(Vector2(4, 35), Color(0.5, 0.9, 0.6))

	var lbl_zone = _make_label(Vector2(4, 46), Color(0.5, 0.8, 0.5))
	lbl_zone.text = "ZONA 2: El Pantano"

	var lbl_hint = _make_label(Vector2(4, 57), Color(0.55, 0.65, 0.45))
	lbl_hint.text = "[J] Pulso de Luz"

	_update_hud()


func _make_label(pos: Vector2, color: Color) -> Label:
	var lbl = Label.new()
	lbl.position = pos
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 9)
	hud_layer.add_child(lbl)
	return lbl


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
	if lbl_echo:
		lbl_echo.text = "ECOS: %d/%d" % [echoes_collected, TOTAL_ECHOES]
	if lbl_light:
		var li = ""
		for _i in light_charges:
			li += "●"
		for _i in (MAX_CHARGES - light_charges):
			li += "○"
		lbl_light.text = "LUZ:  " + li


func _zone_complete() -> void:
	if _transitioning:
		return
	_transitioning = true
	set_process(false)
	QuestManager.advance_quest("zone2")
	GameManager.update_empathy(0.33)
	GameManager.add_score(400)
	if GameManager.player:
		GameManager.player.set_speed_multiplier(1.0)
		DialogueManager.show_floating_text(
			"Aprendiste a construir puentes, no muros.\n+400 puntos — ¡Zona 2 completada!",
			GameManager.player.global_position + Vector2(0, -30), Color(0.5, 0.9, 0.5)
		)
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/world/Zone3_Cave.tscn")
