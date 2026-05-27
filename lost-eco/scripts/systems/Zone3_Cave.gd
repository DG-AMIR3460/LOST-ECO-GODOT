extends Node2D

# ── Mapa (32 columnas × 20 filas) ────────────────────────────────────────────
# S = Inicio | E = Eco | B = Jefe espejo | # = Pared | . = Suelo de cueva
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
	"#................B.............#",
	"#..............................#",
	"################################",
]

const TS = 16
const FLOOR_COLOR       = Color(0.14, 0.13, 0.17)
const FLOOR_DARK_COLOR  = Color(0.09, 0.08, 0.11)
const WALL_COLOR        = Color(0.06, 0.05, 0.08)
const ECHO_COLOR        = Color(0.92, 0.82, 0.35)
const CRYSTAL_COLOR     = Color(0.58, 0.56, 0.52)
const ENEMY_BODY_COLOR  = Color(0.82, 0.68, 0.12)
const ENEMY_GLOW_COLOR  = Color(0.95, 0.85, 0.22, 0.38)

var floors: Array = []
var floor_shades: Array = []
var walls:  Array = []

var echoes_collected: int = 0
const TOTAL_ECHOES = 3
var boss_unlocked: bool = false
var boss_defeated: bool = false

var enemies: Array = []
const ENEMY_TILES = [
	Vector2i(14,  2),
	Vector2i( 8,  7),
	Vector2i(26,  8),
	Vector2i(10, 12),
	Vector2i(20, 16),
]

const ENEMY_MSGS = [
	"Tu reflejo te persigue...\n¿reconoces lo que hiciste?  -1 vida",
	"Los cristales guardan\nrecuerdos que evitaste.  -1 vida",
	"La oscuridad imita\ntus peores decisiones.  -1 vida",
	"Cada sombra es una palabra\nque no deberías haber dicho.  -1 vida",
	"El miedo reflejado\nvuelve hacia ti.  -1 vida",
]

var light_charges: int = 0
const MAX_CHARGES: int = 3
const PULSE_RADIUS: float = 62.0
const STUN_TIME: float = 1.8

var _transitioning: bool = false
var _event_timer: float = 22.0
var _boss_phase: int = 0
var _boss_node: Node2D = null
var _boss_sprite: CanvasItem = null
var _boss_area: Area2D = null
var _boss_tween: Tween = null

var hud_layer: PremiumZoneHUD = null
var minimap: ZoneMinimap = null
var _gothic_player: GothicPlayerVisual = null
var _atmosphere: GothicAtmosphere = null


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color(0.04, 0.03, 0.07))
	var fog_ui := get_node_or_null("CanvasLayer")
	if fog_ui:
		fog_ui.visible = false
	_generate_map()
	_spawn_enemies()
	_setup_gothic_player()
	_setup_hud()
	if GameManager.player:
		_atmosphere = GothicAtmosphere.new()
		add_child(_atmosphere)
		_atmosphere.setup(self, GameManager.player, "cave")
	GameManager.health_changed.connect(func(_v): _update_hud())

	if GameManager.player:
		GameManager.player.has_weapon = false

	await get_tree().create_timer(0.5).timeout
	DialogueManager.show_zone_intro(
		"ZONA 3 — Cueva del Espejo",
		"Los cristales reflejan tus miedos.\nRecoge 3 Ecos y enfrenta al jefe del espejo.",
		"No pelees: acércate sin arma [Q] para sanarlo.",
		Color(0.92, 0.82, 0.40)
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
					if randf() < 0.16:
						floor_shades.append(Rect2(pos, Vector2(TS, TS)))
					if GameManager.player:
						GameManager.player.global_position = pos + Vector2(8, 8)
				"E":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					if randf() < 0.16:
						floor_shades.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_echo(pos)
				"B":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					if randf() < 0.16:
						floor_shades.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_boss(pos)
				_:
					floors.append(Rect2(pos, Vector2(TS, TS)))
					if randf() < 0.16:
						floor_shades.append(Rect2(pos, Vector2(TS, TS)))
					if randf() < 0.10:
						_spawn_crystal(pos)
	queue_redraw()


func _draw() -> void:
	GothicTilePainter.draw_zone_map(self, floors, floor_shades, walls, "cave")


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
	poly.position = pos + Vector2(TS / 2.0, TS / 2.0)
	poly.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(3, -1), Vector2(2, 4),
		Vector2(-2, 4), Vector2(-3, -1)
	])
	poly.color = CRYSTAL_COLOR
	add_child(poly)


func _spawn_echo(pos: Vector2) -> void:
	EchoStarVisual.spawn(self, pos + Vector2(TS / 2.0, TS / 2.0), Callable(self, "_collect_echo"))


func _collect_echo(node: Node) -> void:
	if minimap:
		minimap.mark_echo_collected_at(node.global_position, TS)
	echoes_collected += 1
	node.queue_free()
	GameManager.add_score(150)
	light_charges = min(light_charges + 1, MAX_CHARGES)
	_update_hud()
	var refl := StoryReflections.get_echo_reflection(3, echoes_collected)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body, refl.accent, 3.5)
	DialogueManager.show_corner_notice(
		"Eco %d/%d  +150 pts  ⚡+1" % [echoes_collected, TOTAL_ECHOES],
		Color(0.75, 0.55, 0.95), 2.0
	)
	if echoes_collected >= TOTAL_ECHOES:
		_unlock_boss()
	EnemyBehavior.trigger_rush_near(enemies, node.global_position, 2)


func _unlock_boss() -> void:
	boss_unlocked = true
	if _boss_sprite:
		_boss_sprite.modulate = Color(1.4, 1.0, 1.8)
		var tween = create_tween().set_loops()
		tween.tween_property(_boss_sprite, "modulate", Color(1.8, 0.8, 2.5), 0.45)
		tween.tween_property(_boss_sprite, "modulate", Color.WHITE, 0.45)
	if GameManager.player:
		DialogueManager.show_corner_notice(
			"Jefe despierto — acércate sin arma [Q].",
			Color(0.85, 0.65, 1.0), 3.5
		)


func _spawn_boss(pos: Vector2) -> void:
	var center = pos + Vector2(TS / 2.0, TS / 2.0)
	_boss_node = Node2D.new()
	_boss_node.global_position = center
	_boss_node.add_to_group("mirror_boss")
	add_child(_boss_node)

	var boss_poly := Polygon2D.new()
	boss_poly.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(10, -5), Vector2(8, 10),
		Vector2(-8, 10), Vector2(-10, -5)
	])
	boss_poly.color = Color(0.45, 0.15, 0.65)
	_boss_node.add_child(boss_poly)
	_boss_sprite = boss_poly

	for ox in [-4, 2]:
		var eye := Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(ox, -5), Vector2(ox + 2, -5), Vector2(ox + 2, -3), Vector2(ox, -3)
		])
		eye.color = Color(1.0, 0.85, 1.0)
		_boss_node.add_child(eye)

	if _boss_sprite:
		_boss_tween = create_tween().set_loops()
		_boss_tween.tween_property(_boss_sprite, "modulate", Color(1.2, 0.5, 1.8), 1.0)
		_boss_tween.tween_property(_boss_sprite, "modulate", Color.WHITE, 1.0)

	_boss_area = Area2D.new()
	_boss_area.global_position = center
	add_child(_boss_area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 20
	c.shape = s
	_boss_area.add_child(c)
	_boss_area.body_entered.connect(_on_boss_body_entered)


func _on_boss_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or boss_defeated:
		return
	if not boss_unlocked:
		DialogueManager.show_corner_notice(
			"Jefe dormido — faltan %d ecos." % (TOTAL_ECHOES - echoes_collected),
			Color(0.6, 0.5, 0.9), 2.0
		)
		return

	_boss_phase += 1
	match _boss_phase:
		1:
			if _boss_tween:
				_boss_tween.kill()
			DialogueManager.show_corner_notice(
				"¡No ataques! Acércate sin arma.",
				Color(0.8, 0.5, 1.0), 3.0
			)
			_boss_pulse()
		2:
			DialogueManager.show_corner_notice(
				"Está confundido — acércate y presiona [E].",
				Color(0.9, 0.7, 1.0), 3.0
			)
		3:
			if not GameManager.player.has_weapon_equipped():
				_heal_boss(body)
			else:
				DialogueManager.show_corner_notice(
					"Suelta el arma con [Q] primero.",
					Color(1.0, 0.5, 0.3), 2.5
				)
				_boss_phase = 2


func _boss_pulse() -> void:
	var tween = create_tween().set_loops(8)
	tween.tween_property(_boss_sprite, "modulate", Color(1.8, 0.3, 2.0), 0.25)
	tween.tween_property(_boss_sprite, "modulate", Color.WHITE, 0.25)


func _heal_boss(_player: Node) -> void:
	if boss_defeated:
		return
	boss_defeated = true
	DialogueManager.show_reflection(
		"Sanación",
		"El cristal se calienta... la oscuridad se disipa.",
		Color(1.0, 0.85, 0.2), 3.0
	)
	var tween = create_tween()
	tween.tween_property(_boss_sprite, "modulate", Color(2.0, 1.7, 0.3), 2.0)
	tween.tween_property(_boss_node, "scale", Vector2(0.1, 0.1), 1.5)
	tween.tween_callback(_zone_complete)


func _spawn_enemies() -> void:
	for i in ENEMY_TILES.size():
		var tile = ENEMY_TILES[i]
		var world_pos = Vector2(tile.x * TS, tile.y * TS) + Vector2(TS / 2.0, TS / 2.0)
		_create_enemy(world_pos, i)


func _create_enemy(world_pos: Vector2, idx: int) -> void:
	var enemy := ShadowEnemyVisual.create(self, world_pos, {
		"body": Color(0.08, 0.05, 0.12),
		"glow": Color(0.35, 0.04, 0.1, 0.5),
		"pulse": Color(1.4, 0.2, 0.35),
		"eyes": Color(1.0, 0.12, 0.18),
		"wisp": Color(0.2, 0.03, 0.08, 0.7),
		"sprite": "espectro",
		"scale": 0.92,
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
		"speed": 18.0 + idx * 2.0,
	})
	EnemyBehavior.init_entry(enemies[-1], world_pos)


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
	tween_flash.tween_property(GameManager.player, "modulate", Color(2.5, 1.5, 3.0), 0.08)
	tween_flash.tween_property(GameManager.player, "modulate", Color(1.0, 1.0, 1.0), 0.25)

	for ed in enemies:
		var en: Node2D = ed["node"]
		if not is_instance_valid(en):
			continue
		if en.global_position.distance_to(player_pos) <= PULSE_RADIUS:
			var push_dir = (en.global_position - player_pos).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.RIGHT
			en.global_position += push_dir * 55.0
			en.set_meta("stunned", STUN_TIME)
			var ar: Area2D = ed["area"]
			if is_instance_valid(ar):
				ar.global_position = en.global_position

	DialogueManager.show_corner_notice("¡Pulso de Luz!", Color(0.9, 0.7, 1.0), 1.5)

	await get_tree().create_timer(8.0).timeout
	if not _transitioning:
		light_charges = min(light_charges + 1, MAX_CHARGES)
		_update_hud()


func _setup_gothic_player() -> void:
	if GameManager.player:
		_gothic_player = ZoneVisualBootstrap.setup_gothic_alex(GameManager.player)


func _process(delta: float) -> void:
	if GameManager.player and GameManager.player.has_meta("enemy_cd"):
		var cd = maxf(0.0, GameManager.player.get_meta("enemy_cd") - delta)
		GameManager.player.set_meta("enemy_cd", cd)

	if not GameManager.player:
		return
	if _gothic_player:
		var vel := GameManager.player.velocity
		_gothic_player.update_motion(vel, true, false, false)
	var player_pos = GameManager.player.global_position

	_event_timer -= delta
	if _event_timer <= 0.0:
		_event_timer = randf_range(20.0, 28.0)
		_trigger_cave_echo()

	for ed in enemies:
		EnemyBehavior.tick(ed, player_pos, delta)

	_update_minimap()


func _trigger_cave_echo() -> void:
	if _transitioning or enemies.is_empty():
		return
	EnemyBehavior.trigger_surge(enemies, 3.5)
	DialogueManager.show_corner_notice("Los ecos de la cueva despiertan — ¡emboscada!", Color(0.85, 0.72, 1.0), 2.5)
	queue_redraw()


func _setup_hud() -> void:
	hud_layer = PremiumZoneHUD.new()
	hud_layer.setup("ZONA 3 — Cueva del Espejo", GameManager.max_health, MAX_CHARGES)
	add_child(hud_layer)
	minimap = ZoneMinimap.new()
	minimap.setup(MAP, {
		"floor": FLOOR_COLOR,
		"wall": WALL_COLOR,
		"echo": ECHO_COLOR,
		"exit": Color(0.85, 0.72, 0.25),
		"enemy": Color(0.92, 0.18, 0.28),
		"border": Color(0.72, 0.58, 0.22, 0.9),
	})
	minimap.position = Vector2(208, 88)
	minimap.enable_fog_of_war()
	hud_layer.add_child(minimap)
	_update_hud()


func _update_hud() -> void:
	if hud_layer:
		hud_layer.update_echoes(echoes_collected, TOTAL_ECHOES)
		hud_layer.update_light_charges(light_charges, MAX_CHARGES)


func _update_minimap() -> void:
	if minimap == null or GameManager.player == null:
		return
	minimap.set_player_world_pos(GameManager.player.global_position, TS)
	minimap.set_echoes_remaining(TOTAL_ECHOES - echoes_collected)
	minimap.set_exit_open(boss_unlocked)
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
	set_process(false)
	GameManager.close_pause()
	if GameManager.player:
		GameManager.player.set_can_move(false)
	QuestManager.advance_quest("zone3")
	GameManager.update_empathy(0.34)
	GameManager.add_score(700)
	_update_hud()
	DialogueManager.show_corner_notice("¡Zona completada! Pasando al Río...", Color(0.92, 0.85, 0.45), 3.0)
	var refl := StoryReflections.get_zone_complete(3)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body + "\n+700 pts", refl.accent, 3.5)
	await get_tree().create_timer(3.5).timeout
	await SceneTransition.change_scene("res://scenes/world/Zone4_Rio.tscn")
