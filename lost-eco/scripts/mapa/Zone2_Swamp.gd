extends Node2D

# ── Mapa (32 columnas × 20 filas) ────────────────────────────────────────────
# S = Inicio | E = Eco | P = Pilar (mantén [E] para activar) | X = Salida
const MAP = [
	"################################",
	"#S.............................#",
	"#....E....P....................#",
	"#..............................#",
	"#..............................#",
	"##########..#########..#########",
	"#..............................#",
	"#........................E.....#",
	"#..............................#",
	"#..............................#",
	"##########..#########..#########",
	"#..............................#",
	"#.........E....P...............#",
	"#..............................#",
	"#..............................#",
	"##########..#########..#########",
	"#..............................#",
	"#...................P..........#",
	"#.............................X#",
	"################################",
]

const TS = 16
const MUD_COLOR         = Color(0.20, 0.22, 0.12)
const WALL_COLOR        = Color(0.10, 0.12, 0.06)
const ECHO_COLOR        = Color(0.6, 0.85, 0.45)
const EXIT_LOCKED_COLOR = Color(0.28, 0.32, 0.18)
const EXIT_OPEN_COLOR   = Color(0.35, 0.90, 0.40)
const ENEMY_BODY_COLOR  = Color(0.58, 0.10, 0.48)
const ENEMY_GLOW_COLOR  = Color(0.95, 0.42, 0.78, 0.72)

var floors: Array = []
var walls:  Array = []

var echoes_collected: int = 0
const TOTAL_ECHOES = 3
var pillars_activated: int = 0
const TOTAL_PILLARS = 3
const PILLAR_HOLD_TIME := 0.8

var pillars: Array = []
var _near_pillar: Dictionary = {}
var _pillar_hold: float = 0.0

var exit_poly: Polygon2D = null
var exit_area: Area2D = null
var exit_unlocked: bool = false
var _transitioning: bool = false
var _event_timer: float = 20.0
var _mud_slow_timer: float = 0.0

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
const PULSE_RADIUS: float = 62.0
const STUN_TIME: float = 1.8

var hud_layer: PremiumZoneHUD = null
var minimap: ZoneMinimap = null
var _gothic_player: GothicPlayerVisual = null


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color(0.10, 0.13, 0.06))
	_generate_map()
	_spawn_enemies()
	_setup_hud()
	GameManager.health_changed.connect(func(_v): _update_hud())
	GameManager.score_changed.connect(func(_v): _update_hud())
	call_deferred("_finish_player_setup")

	await get_tree().create_timer(0.5).timeout
	ZoneMissionBriefs.show_for_zone(2)


func _finish_player_setup() -> void:
	var setup := ZoneVisualBootstrap.finish_player_setup(self, MAP, TS, "swamp")
	_gothic_player = setup.get("gothic") as GothicPlayerVisual
	if GameManager.player:
		GameManager.player.has_weapon = false
		GameManager.player.set_speed_multiplier(0.65)


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
				"E":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_mud_zone(pos)
					_spawn_echo(pos)
				"P":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_mud_zone(pos)
					_spawn_pillar(pos)
				"X":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_mud_zone(pos)
					_spawn_exit(pos)
				_:
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_add_mud_zone(pos)
	queue_redraw()


func _draw() -> void:
	GothicTilePainter.draw_zone_map(self, floors, [], walls, "swamp")


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
	EchoStarVisual.spawn(self, pos + Vector2(TS / 2.0, TS / 2.0), Callable(self, "_collect_echo"))


func _collect_echo(node: Node) -> void:
	if minimap:
		minimap.mark_echo_collected_at(node.global_position, TS)
	echoes_collected += 1
	node.queue_free()
	GameManager.add_score(120)
	light_charges = min(light_charges + 1, MAX_CHARGES)
	_update_hud()
	var refl := StoryReflections.get_echo_reflection(2, echoes_collected)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body, refl.accent, 3.5)
	DialogueManager.show_corner_notice(
		"Eco %d/%d  +120 pts  ⚡+1" % [echoes_collected, TOTAL_ECHOES],
		Color(0.6, 0.95, 0.5), 2.0
	)
	if echoes_collected >= TOTAL_ECHOES and pillars_activated >= TOTAL_PILLARS:
		_unlock_exit()
	EnemyBehavior.trigger_rush_near(enemies, node.global_position, 2)
	_update_hud_status()


func _spawn_pillar(pos: Vector2) -> void:
	var center := pos + Vector2(TS / 2.0, TS / 2.0)
	var node := Node2D.new()
	node.global_position = center
	add_child(node)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-4, 4), Vector2(0, -6), Vector2(4, 4), Vector2(0, 2)
	])
	poly.color = Color(0.35, 0.55, 0.28)
	node.add_child(poly)
	var area := Area2D.new()
	area.global_position = center
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	add_child(area)
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 11
	c.shape = s
	area.add_child(c)
	pillars.append({"node": node, "poly": poly, "area": area, "done": false, "pos": center})


func _update_hud_status() -> void:
	if hud_layer:
		hud_layer.update_status(
			"ECOS %d/%d  PILARES %d/%d → SALIDA X" % [
				echoes_collected, TOTAL_ECHOES, pillars_activated, TOTAL_PILLARS
			]
		)


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
	if exit_unlocked:
		return
	if pillars_activated < TOTAL_PILLARS or echoes_collected < TOTAL_ECHOES:
		return
	exit_unlocked = true
	if exit_poly:
		exit_poly.color = EXIT_OPEN_COLOR
		var tween = create_tween().set_loops()
		tween.tween_property(exit_poly, "modulate", Color(1.6, 2.2, 1.4), 0.45)
		tween.tween_property(exit_poly, "modulate", Color(1.0, 1.0, 1.0), 0.45)
	if GameManager.player:
		DialogueManager.show_corner_notice("¡Salida abierta! → abajo derecha.", Color(0.35, 1.0, 0.45), 3.0)


func _spawn_enemies() -> void:
	for i in ENEMY_TILES.size():
		var tile = ENEMY_TILES[i]
		var world_pos = Vector2(tile.x * TS, tile.y * TS) + Vector2(TS / 2.0, TS / 2.0)
		_create_enemy(world_pos, i)


func _create_enemy(world_pos: Vector2, idx: int) -> void:
	var enemy := ShadowEnemyVisual.create(self, world_pos, {
		"body": ENEMY_BODY_COLOR,
		"glow": ENEMY_GLOW_COLOR,
		"pulse": Color(1.5, 0.55, 1.25),
		"eyes": Color(1.0, 0.92, 0.35),
		"wisp": Color(0.75, 0.22, 0.55, 0.65),
		"modulate": Color(0.92, 0.82, 1.0, 1.0),
		"scale": 0.95,
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
		"speed": 14.0 + idx * 1.5,
	})
	EnemyBehavior.init_entry(enemies[-1], world_pos)


func _enemy_hit_player(p: Node, message: String, source_pos: Vector2) -> void:
	if p.has_meta("enemy_cd") and p.get_meta("enemy_cd") > 0.0:
		return
	p.set_meta("enemy_cd", 1.6)
	GameManager.take_damage()
	if is_instance_valid(p):
		p.take_hit(source_pos)
		var hit := StoryReflections.get_enemy_hit()
		DialogueManager.show_reflection(hit.title, message + "\n" + hit.body, hit.accent, 3.0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and light_charges > 0 and GameManager.player:
		_use_light_pulse()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact"):
		_try_pillar_interact()


func _try_pillar_interact() -> void:
	_update_near_pillar()
	if _near_pillar.is_empty() or _near_pillar.get("done", true):
		return
	_pillar_hold = 0.0
	DialogueManager.show_corner_notice("Mantén [E] para activar el Pilar...", Color(0.75, 0.98, 0.5), 1.0)


func _activate_pillar(pillar: Dictionary) -> void:
	if pillar.get("done", false):
		return
	pillar["done"] = true
	pillars_activated += 1
	var poly: Polygon2D = pillar.get("poly")
	if poly:
		poly.color = Color(0.55, 0.95, 0.45)
	if minimap:
		minimap.mark_pillar_activated_at(pillar.get("pos", Vector2.ZERO), TS)
	GameManager.add_score(80)
	DialogueManager.show_corner_notice(
		"Pilar activado (%d/%d) — la paciencia abre caminos." % [pillars_activated, TOTAL_PILLARS],
		Color(0.5, 0.95, 0.55), 1.8
	)
	_update_hud_status()
	if echoes_collected >= TOTAL_ECHOES and pillars_activated >= TOTAL_PILLARS:
		_unlock_exit()


func _update_near_pillar() -> void:
	_near_pillar = {}
	if GameManager.player == null:
		return
	var player_pos := GameManager.player.global_position
	for p in pillars:
		if p.get("done", false):
			continue
		var pillar_pos: Vector2 = p.get("pos", Vector2(-99999, -99999))
		if player_pos.distance_to(pillar_pos) <= 20.0:
			_near_pillar = p
			return


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

	DialogueManager.show_corner_notice("¡Pulso de Luz!", Color(0.8, 1.0, 0.4), 1.5)

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

	_event_timer -= delta
	if _mud_slow_timer > 0.0:
		_mud_slow_timer -= delta
		if _mud_slow_timer <= 0.0 and GameManager.player:
			GameManager.player.set_speed_multiplier(0.65)
	if _event_timer <= 0.0:
		_event_timer = randf_range(18.0, 26.0)
		_trigger_mud_surge()

	for ed in enemies:
		EnemyBehavior.tick(ed, player_pos, delta)

	_update_minimap()
	_check_exit_overlap()
	_update_near_pillar()
	if not _near_pillar.is_empty() and not _near_pillar.get("done", true):
		if Input.is_action_pressed("interact"):
			var prev := _pillar_hold
			_pillar_hold += delta
			if _pillar_hold >= PILLAR_HOLD_TIME:
				_activate_pillar(_near_pillar)
				_pillar_hold = 0.0
			else:
				var pct := int(_pillar_hold / PILLAR_HOLD_TIME * 100.0)
				var prev_pct := int(prev / PILLAR_HOLD_TIME * 100.0)
				if pct / 25 != prev_pct / 25:
					DialogueManager.show_corner_notice(
						"Activando Pilar... %d%%" % pct,
						Color(0.7, 1.0, 0.45), 0.5
					)
		else:
			_pillar_hold = 0.0
	else:
		_pillar_hold = 0.0


func _trigger_mud_surge() -> void:
	if _transitioning or enemies.is_empty():
		return
	EnemyBehavior.trigger_surge(enemies, 4.5)
	DialogueManager.show_corner_notice("El pantano se agita — ¡las sombras embisten!", Color(0.45, 0.95, 0.55), 2.5)
	if GameManager.player:
		GameManager.player.set_speed_multiplier(0.32)
		_mud_slow_timer = 2.5


func _try_use_exit(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if exit_unlocked:
		_zone_complete()
	else:
		var msg := "Faltan ecos (%d/%d)" % [echoes_collected, TOTAL_ECHOES]
		if pillars_activated < TOTAL_PILLARS:
			msg = "Pilares %d/%d y ecos %d/%d" % [pillars_activated, TOTAL_PILLARS, echoes_collected, TOTAL_ECHOES]
		DialogueManager.show_corner_notice(msg, Color(0.6, 0.85, 0.5), 1.5)


func _check_exit_overlap() -> void:
	if not exit_unlocked or _transitioning or exit_area == null or GameManager.player == null:
		return
	if exit_area.overlaps_body(GameManager.player):
		_zone_complete()


func _setup_hud() -> void:
	hud_layer = ZoneUIBootstrap.attach_hud(self, "Z2 Pantano", MAX_CHARGES)
	minimap = ZoneUIBootstrap.attach_minimap(self, MAP, {
		"floor": MUD_COLOR,
		"wall": WALL_COLOR,
		"echo": ECHO_COLOR,
		"exit": EXIT_OPEN_COLOR,
		"enemy": Color(0.95, 0.45, 0.82),
	}, true, 4)
	_update_hud_status()


func _update_hud() -> void:
	_update_hud_status()
	if hud_layer:
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
	QuestManager.advance_quest("zone2")
	GameManager.update_empathy(0.33)
	GameManager.add_score(400)
	var refl := StoryReflections.get_zone_complete(2)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body + "\n+400 pts", refl.accent, 2.5)
		await get_tree().create_timer(2.5).timeout
	await SceneTransition.play_bridge_and_change_scene(2, "res://scenes/world/Zone3_Cave.tscn")
