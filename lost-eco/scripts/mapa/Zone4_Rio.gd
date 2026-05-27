extends Node2D

# ── Mapa (32 columnas × 20 filas) ────────────────────────────────────────────
# S = Inicio | E = Eco | X = Salida | # = Orilla tropical | . = Agua del río
const MAP = [
	"################################",
	"#S.............................#",
	"#....E.........................#",
	"#..............................#",
	"#..........####................#",
	"#..........#..#................#",
	"#..........#..#................#",
	"#........................E.....#",
	"#..........####................#",
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
const WATER_COLOR         = Color(0.18, 0.42, 0.72)
const WATER_DARK_COLOR    = Color(0.12, 0.32, 0.58)
const WALL_COLOR          = Color(0.12, 0.48, 0.22)
const WALL_DARK_COLOR     = Color(0.08, 0.32, 0.14)
const ECHO_COLOR          = Color(0.55, 0.92, 0.85)
const EXIT_LOCKED_COLOR   = Color(0.15, 0.38, 0.55)
const EXIT_OPEN_COLOR     = Color(0.35, 0.85, 0.95)
const ENEMY_BODY_COLOR    = Color(0.12, 0.28, 0.62)
const ENEMY_GLOW_COLOR    = Color(0.25, 0.55, 0.92, 0.38)

var floors: Array = []
var water_shades: Array = []
var walls:  Array = []

var echoes_collected: int = 0
const TOTAL_ECHOES = 3

var exit_poly: Polygon2D = null
var exit_area: Area2D = null
var exit_unlocked: bool = false
var _transitioning: bool = false

var enemies: Array = []
const ENEMY_TILES = [
	Vector2i(10,  2),
	Vector2i(26,  4),
	Vector2i( 6,  8),
	Vector2i(20, 12),
	Vector2i(16, 17),
]

const ENEMY_MSGS = [
	"La corriente te arrastra...\nhacia lo que evitaste.  -1 vida",
	"El agua fría recuerda\nel silencio que guardaste.  -1 vida",
	"Cada ola repite una palabra\nque no pediste perdón.  -1 vida",
	"El río no juzga,\npero tampoco perdona.  -1 vida",
	"Nadar contra la culpa\nagota más que el cuerpo.  -1 vida",
]

var light_charges: int = 0
const MAX_CHARGES: int = 3
const PULSE_RADIUS: float = 62.0
const STUN_TIME: float = 1.8

var hud_layer: PremiumZoneHUD = null
var minimap: ZoneMinimap = null
var _gothic_player: GothicPlayerVisual = null


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color(0.08, 0.22, 0.38))
	_generate_map()
	_spawn_enemies()
	_setup_hud()
	GameManager.health_changed.connect(func(_v): _update_hud())
	GameManager.score_changed.connect(func(_v): _update_hud())
	call_deferred("_finish_player_setup")

	await get_tree().create_timer(0.5).timeout
	ZoneMissionBriefs.show_for_zone(4)


func _finish_player_setup() -> void:
	var setup := ZoneVisualBootstrap.finish_player_setup(self, MAP, TS, "river")
	_gothic_player = setup.get("gothic") as GothicPlayerVisual
	if GameManager.player:
		GameManager.player.has_weapon = false
		GameManager.player.set_speed_multiplier(0.70)


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
					_add_water_zone(pos)
				"E":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_water_zone(pos)
					_spawn_echo(pos)
				"X":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_water_zone(pos)
					_spawn_exit(pos)
				_:
					floors.append(Rect2(pos, Vector2(TS, TS)))
					if randf() < 0.14:
						water_shades.append(Rect2(pos, Vector2(TS, TS)))
					_add_water_zone(pos)
	queue_redraw()


func _draw() -> void:
	GothicTilePainter.draw_zone_map(self, floors, water_shades, walls, "river")


func _add_wall(pos: Vector2) -> void:
	var b = StaticBody2D.new()
	b.global_position = pos + Vector2(TS / 2.0, TS / 2.0)
	add_child(b)
	var c = CollisionShape2D.new()
	var s = RectangleShape2D.new()
	s.size = Vector2(TS, TS)
	c.shape = s
	b.add_child(c)


func _add_water_zone(pos: Vector2) -> void:
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
			body.set_speed_multiplier(0.48)
	)
	area.body_exited.connect(func(body):
		if body.is_in_group("player"):
			body.set_speed_multiplier(0.70)
	)


func _spawn_echo(pos: Vector2) -> void:
	EchoStarVisual.spawn(self, pos + Vector2(TS / 2.0, TS / 2.0), Callable(self, "_collect_echo"))


func _collect_echo(node: Node) -> void:
	if minimap:
		minimap.mark_echo_collected_at(node.global_position, TS)
	echoes_collected += 1
	node.queue_free()
	GameManager.add_score(130)
	light_charges = min(light_charges + 1, MAX_CHARGES)
	_update_hud()
	var refl := StoryReflections.get_echo_reflection(4, echoes_collected)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body, refl.accent, 3.5)
	DialogueManager.show_corner_notice(
		"Eco %d/%d  +130 pts  ⚡+1" % [echoes_collected, TOTAL_ECHOES],
		Color(0.50, 0.92, 0.85), 2.0
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
	exit_area.monitoring = true
	exit_area.collision_mask = 1
	add_child(exit_area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 16
	c.shape = s
	exit_area.add_child(c)
	exit_area.body_entered.connect(func(body):
		_try_use_exit(body)
	)


func _unlock_exit() -> void:
	exit_unlocked = true
	if exit_poly:
		exit_poly.color = EXIT_OPEN_COLOR
		var tween = create_tween().set_loops()
		tween.tween_property(exit_poly, "modulate", Color(1.2, 2.0, 2.2), 0.45)
		tween.tween_property(exit_poly, "modulate", Color(1.0, 1.0, 1.0), 0.45)
	if GameManager.player:
		DialogueManager.show_corner_notice("¡Salida abierta! → abajo derecha.", Color(0.40, 0.95, 0.90), 3.0)


func _spawn_enemies() -> void:
	for i in ENEMY_TILES.size():
		var tile = ENEMY_TILES[i]
		var world_pos = Vector2(tile.x * TS, tile.y * TS) + Vector2(TS / 2.0, TS / 2.0)
		_create_enemy(world_pos, i)


func _create_enemy(world_pos: Vector2, idx: int) -> void:
	var enemy := ShadowEnemyVisual.create(self, world_pos, {
		"body": ENEMY_BODY_COLOR,
		"glow": ENEMY_GLOW_COLOR,
		"pulse": Color(0.45, 0.85, 1.55),
		"eyes": Color(0.55, 0.85, 1.0),
		"wisp": Color(0.08, 0.18, 0.38, 0.75),
		"scale": 0.68,
	})

	var area = Area2D.new()
	area.global_position = world_pos
	add_child(area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 6
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
		"speed": 16.0 + idx * 1.5,
	})


func _enemy_hit_player(p: Node, message: String, source_pos: Vector2) -> void:
	if p.has_meta("enemy_cd") and p.get_meta("enemy_cd") > 0.0:
		return
	p.set_meta("enemy_cd", 1.5)
	GameManager.take_damage()
	if is_instance_valid(p):
		p.take_hit(source_pos)
		var hit := StoryReflections.get_enemy_hit()
		DialogueManager.show_reflection(hit.title, message + "\n" + hit.body, hit.accent, 3.0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and light_charges > 0 and GameManager.player:
		_use_light_pulse()
		get_viewport().set_input_as_handled()


func _use_light_pulse() -> void:
	light_charges -= 1
	_update_hud()
	var player_pos = GameManager.player.global_position

	var tween_flash = create_tween()
	tween_flash.tween_property(GameManager.player, "modulate", Color(1.2, 2.2, 2.5), 0.08)
	tween_flash.tween_property(GameManager.player, "modulate", Color(1.0, 1.0, 1.0), 0.25)

	for ed in enemies:
		var en: Node2D = ed["node"]
		if not is_instance_valid(en):
			continue
		if en.global_position.distance_to(player_pos) <= PULSE_RADIUS:
			var push_dir = (en.global_position - player_pos).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.RIGHT
			en.global_position += push_dir * 52.0
			en.set_meta("stunned", STUN_TIME)
			var ar: Area2D = ed["area"]
			if is_instance_valid(ar):
				ar.global_position = en.global_position

	DialogueManager.show_corner_notice("¡Pulso de Luz!", Color(0.55, 0.90, 1.0), 1.5)

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
	if _gothic_player:
		_gothic_player.update_motion(GameManager.player.velocity, true)
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
					b.modulate = Color(0.45, 0.75, 1.2)
				continue

		var dir = player_pos - en.global_position
		if dir.length() > 4.0:
			en.global_position += dir.normalized() * ed["speed"] * delta
		var ar: Area2D = ed["area"]
		if is_instance_valid(ar):
			ar.global_position = en.global_position

	_update_minimap()
	_check_exit_overlap()


func _try_use_exit(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if exit_unlocked:
		_zone_complete()
	else:
		DialogueManager.show_corner_notice(
			"Salida bloqueada — faltan %d ecos." % (TOTAL_ECHOES - echoes_collected),
			Color(0.50, 0.85, 0.90), 2.0
		)


func _check_exit_overlap() -> void:
	if not exit_unlocked or _transitioning or exit_area == null or GameManager.player == null:
		return
	if exit_area.overlaps_body(GameManager.player):
		_zone_complete()


func _setup_hud() -> void:
	hud_layer = ZoneUIBootstrap.attach_hud(self, "Z4 Río", MAX_CHARGES)
	minimap = ZoneUIBootstrap.attach_minimap(self, MAP, {
		"floor": WATER_COLOR,
		"wall": WALL_COLOR,
		"echo": ECHO_COLOR,
		"exit": EXIT_OPEN_COLOR,
		"enemy": Color(0.92, 0.18, 0.28),
	}, true, 4)
	_update_hud()


func _update_hud() -> void:
	if hud_layer:
		hud_layer.update_status(
			"ECOS %d/%d — con %d abre SALIDA (X)" % [echoes_collected, TOTAL_ECHOES, TOTAL_ECHOES]
		)
		hud_layer.update_light_charges(light_charges, MAX_CHARGES)


func _update_minimap() -> void:
	if minimap == null or GameManager.player == null:
		return
	minimap.set_player_world_pos(GameManager.player.global_position, TS)
	minimap.set_echoes_remaining(TOTAL_ECHOES - echoes_collected)
	minimap.set_exit_open(exit_unlocked)
	minimap.set_enemy_tiles(_get_enemy_minimap_tiles())


func _get_enemy_minimap_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for ed in enemies:
		var en: Node2D = ed["node"]
		if is_instance_valid(en):
			tiles.append(Vector2i(
				int(floor(en.global_position.x / TS)),
				int(floor(en.global_position.y / TS))
			))
	return tiles


func _zone_complete() -> void:
	if _transitioning:
		return
	_transitioning = true
	GameManager.on_zone_completed()
	set_process(false)
	GameManager.close_pause()
	if GameManager.player:
		GameManager.player.set_can_move(false)
		GameManager.player.set_speed_multiplier(1.0)
	QuestManager.advance_quest("zone4")
	GameManager.update_empathy(0.33)
	GameManager.add_score(500)
	var refl := StoryReflections.get_zone_complete(4)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body + "\n+500 pts", refl.accent, 2.5)
		await get_tree().create_timer(2.5).timeout
	await SceneTransition.play_bridge_and_change_scene(4, "res://scenes/world/Clearing.tscn")
