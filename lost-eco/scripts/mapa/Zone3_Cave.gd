extends Node2D

# ── Mapa (32 columnas × 20 filas) ────────────────────────────────────────────
# S = Inicio | E = Eco | B = Jefe | Cristales y sellos en tiles fijos
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
var memories_read: int = 0
const TOTAL_MEMORIES = 3
var seals_lit: int = 0
const TOTAL_SEALS = 3
const SEAL_PULSE_RADIUS := 42.0

var boss_unlocked: bool = false
var boss_defeated: bool = false

var memories: Array = []
var seals: Array = []
var _near_memory: Dictionary = {}
var _near_seal: Dictionary = {}
var _hint_cooldown: float = 0.0
var _boss_hint_cd: float = 0.0

const MEMORY_TILES = [
	Vector2i(7, 2),
	Vector2i(5, 12),
	Vector2i(24, 16),
]
const SEAL_TILES = [
	Vector2i(18, 4),
	Vector2i(10, 8),
	Vector2i(16, 14),
]

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
var _boss_data: Dictionary = {}
var _boss_arena_active: bool = false
var _boss_sequence_running: bool = false
var _arena_overlay: CanvasLayer = null

var hud_layer: PremiumZoneHUD = null
var minimap: ZoneMinimap = null
var _gothic_player: GothicPlayerVisual = null
var _atmosphere: GothicAtmosphere = null


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color(0.09, 0.08, 0.14))
	var fog_ui := get_node_or_null("CanvasLayer")
	if fog_ui:
		fog_ui.visible = false
	_generate_map()
	_spawn_memories()
	_spawn_seals()
	_spawn_enemies()
	_setup_hud()
	GameManager.health_changed.connect(func(_v): _update_hud())
	call_deferred("_finish_player_setup")

	await get_tree().create_timer(0.5).timeout
	ZoneMissionBriefs.show_for_zone(3)


func _finish_player_setup() -> void:
	var setup := ZoneVisualBootstrap.finish_player_setup(self, MAP, TS, "cave_bright")
	_gothic_player = setup.get("gothic") as GothicPlayerVisual
	_atmosphere = setup.get("atmosphere") as GothicAtmosphere
	if GameManager.player:
		GameManager.player.has_weapon = false
		if not GameManager.player.action_performed.is_connected(_on_player_peace_action):
			GameManager.player.action_performed.connect(_on_player_peace_action)


func _on_player_peace_action(action_name: String, _intensity: float) -> void:
	if action_name == "drop_weapon":
		_try_heal_boss()


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


func _spawn_memories() -> void:
	for i in MEMORY_TILES.size():
		var pos := Vector2(MEMORY_TILES[i].x * TS, MEMORY_TILES[i].y * TS)
		_spawn_memory(pos, i + 1)


func _spawn_memory(pos: Vector2, index: int) -> void:
	var center := pos + Vector2(TS / 2.0, TS / 2.0)
	var node := Node2D.new()
	node.global_position = center
	add_child(node)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(4, -1), Vector2(3, 5),
		Vector2(-3, 5), Vector2(-4, -1)
	])
	poly.color = Color(0.35, 0.65, 1.0)
	node.add_child(poly)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-2, -8), Vector2(6, -3), Vector2(5, 7),
		Vector2(-5, 7), Vector2(-6, -3)
	])
	glow.color = Color(0.55, 0.85, 1.0, 0.45)
	node.add_child(glow)
	var pl := PointLight2D.new()
	pl.energy = 0.55
	pl.texture_scale = 0.9
	pl.color = Color(0.55, 0.82, 1.0)
	node.add_child(pl)
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
	memories.append({"node": node, "poly": poly, "area": area, "index": index, "done": false})


func _spawn_seals() -> void:
	for i in SEAL_TILES.size():
		var pos := Vector2(SEAL_TILES[i].x * TS, SEAL_TILES[i].y * TS)
		_spawn_seal(pos)


func _spawn_seal(pos: Vector2) -> void:
	var center := pos + Vector2(TS / 2.0, TS / 2.0)
	var node := Node2D.new()
	node.global_position = center
	add_child(node)
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([
		Vector2(-7, 0), Vector2(0, -7), Vector2(7, 0),
		Vector2(0, 7), Vector2(-7, 0)
	])
	outer.color = Color(0.85, 0.65, 0.15, 0.35)
	node.add_child(outer)
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array([
		Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0),
		Vector2(0, 5), Vector2(-5, 0)
	])
	ring.color = Color(0.75, 0.55, 0.12)
	node.add_child(ring)
	var area := Area2D.new()
	area.global_position = center
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	add_child(area)
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 12
	c.shape = s
	area.add_child(c)
	seals.append({"node": node, "ring": ring, "outer": outer, "area": area, "pos": center, "done": false})


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
	_try_unlock_boss()
	EnemyBehavior.trigger_rush_near(enemies, node.global_position, 2)
	_update_hud_status()


func _try_unlock_boss() -> void:
	if boss_unlocked:
		return
	if echoes_collected < TOTAL_ECHOES or memories_read < TOTAL_MEMORIES or seals_lit < TOTAL_SEALS:
		return
	_unlock_boss()


func _unlock_boss() -> void:
	if boss_unlocked or _boss_sequence_running:
		return
	boss_unlocked = true
	_run_boss_arena_sequence()


func _run_boss_arena_sequence() -> void:
	if _boss_sequence_running:
		return
	_boss_sequence_running = true
	_event_timer = 99.0

	if GameManager.player:
		GameManager.player.set_can_move(false)

	_dismiss_zone_enemies()
	_show_arena_overlay()

	DialogueManager.show_reflection(
		"La Sala del Espejo",
		"Las sombras retroceden...\nEl reflejo del miedo te espera.",
		Color(0.82, 0.68, 1.0),
		2.8
	)
	await get_tree().create_timer(1.0).timeout

	var boss_center: Vector2 = _boss_data.get("center", Vector2.ZERO)
	var cam := get_node_or_null("Camera2D")
	if cam and cam.has_method("focus_on") and boss_center != Vector2.ZERO:
		await cam.focus_on(boss_center, 1.6)

	MirrorBossVisual.play_awaken(self, _boss_data)
	_boss_arena_active = true

	await get_tree().create_timer(1.2).timeout

	if GameManager.player and boss_center != Vector2.ZERO:
		var safe := boss_center + Vector2(0, 28)
		GameManager.player.global_position = safe

	await get_tree().create_timer(0.4).timeout

	if GameManager.player:
		GameManager.player.set_can_move(true)

	DialogueManager.show_corner_notice(
		"Sala del Espejo — [E] o [Q] para sanar al jefe.",
		Color(0.9, 0.78, 1.0),
		4.0
	)
	_boss_sequence_running = false
	_event_timer = 18.0


func _dismiss_zone_enemies() -> void:
	for ed in enemies:
		var en: Node2D = ed.get("node")
		if is_instance_valid(en):
			en.set_meta("stunned", 999.0)
			var tw := create_tween()
			tw.tween_property(en, "modulate:a", 0.0, 0.7)
		var ar: Area2D = ed.get("area")
		if is_instance_valid(ar):
			ar.monitoring = false


func _show_arena_overlay() -> void:
	if _arena_overlay:
		_arena_overlay.queue_free()
	_arena_overlay = CanvasLayer.new()
	_arena_overlay.layer = 90
	add_child(_arena_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.06, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena_overlay.add_child(dim)


func _spawn_boss(pos: Vector2) -> void:
	_boss_data = MirrorBossVisual.spawn(self, pos, TS)
	var area: Area2D = _boss_data.get("area")
	if area:
		area.body_entered.connect(_on_boss_body_entered)
	var sprite: CanvasItem = _boss_data.get("sprite")
	if sprite:
		MirrorBossVisual.play_locked_idle(sprite)


func _on_boss_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or boss_defeated:
		return
	if not boss_unlocked:
		DialogueManager.show_corner_notice(_boss_lock_message(), Color(0.6, 0.5, 0.9), 2.5)
		return
	_boss_pulse()
	DialogueManager.show_corner_notice(
		"Jefe del espejo — [E] o [Q] para sanar (sin violencia).",
		Color(0.88, 0.72, 1.0),
		3.5
	)


func _boss_area() -> Area2D:
	var a: Area2D = _boss_data.get("area")
	return a if is_instance_valid(a) else null


func _is_player_near_boss() -> bool:
	var area := _boss_area()
	return (
		area != null
		and GameManager.player != null
		and area.overlaps_body(GameManager.player)
	)


func _try_heal_boss() -> void:
	if boss_defeated:
		return
	if not boss_unlocked:
		if _is_player_near_boss():
			DialogueManager.show_corner_notice(_boss_lock_message(), Color(0.6, 0.5, 0.9), 2.5)
		return
	if not _is_player_near_boss():
		DialogueManager.show_corner_notice(
			"Entra a la Sala del Espejo (centro-abajo) y pulsa [E].",
			Color(0.75, 0.65, 0.95),
			2.5
		)
		return
	_heal_boss(GameManager.player)


func _boss_pulse() -> void:
	var sprite: CanvasItem = _boss_data.get("sprite")
	if sprite == null:
		return
	var tween = create_tween().set_loops(8)
	tween.tween_property(sprite, "modulate", Color(1.8, 0.3, 2.0), 0.25)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.92, 1.2), 0.25)


func _heal_boss(_player: Node) -> void:
	if boss_defeated:
		return
	boss_defeated = true
	DialogueManager.show_reflection(
		"Sanación",
		"El cristal se calienta... la oscuridad se disipa.",
		Color(1.0, 0.85, 0.2), 3.0
	)
	if _arena_overlay:
		_arena_overlay.queue_free()
		_arena_overlay = null
	MirrorBossVisual.play_heal(self, _boss_data)
	await get_tree().create_timer(2.2).timeout
	_zone_complete()


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


func _boss_lock_message() -> String:
	return "Faltan: CRIST %d/%d  LUCES %d/%d  ECOS %d/%d" % [
		memories_read, TOTAL_MEMORIES,
		seals_lit, TOTAL_SEALS,
		echoes_collected, TOTAL_ECHOES
	]


func _update_hud_status() -> void:
	if hud_layer:
		hud_layer.update_status(
			"CRIST %d/%d  LUCES %d/%d  ECOS %d/%d  → JEFE" % [
				memories_read, TOTAL_MEMORIES,
				seals_lit, TOTAL_SEALS,
				echoes_collected, TOTAL_ECHOES
			]
		)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and light_charges > 0 and GameManager.player:
		_use_light_pulse()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("drop_weapon"):
		if GameManager.player and GameManager.player.has_method("peace_gesture"):
			GameManager.player.peace_gesture()
		_try_heal_boss()
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

	_try_light_seals(player_pos)

	DialogueManager.show_corner_notice("¡Pulso! Empuja enemigos (los círculos dorados usan [E]).", Color(0.9, 0.7, 1.0), 2.0)

	await get_tree().create_timer(8.0).timeout
	if not _transitioning:
		light_charges = min(light_charges + 1, MAX_CHARGES)
		_update_hud()


func _try_light_seals(player_pos: Vector2) -> void:
	for seal in seals:
		if seal.get("done", false):
			continue
		var center: Vector2 = seal.get("pos", Vector2.ZERO)
		if center.distance_to(player_pos) <= SEAL_PULSE_RADIUS:
			_light_seal(seal)


func _light_seal(seal: Dictionary) -> void:
	if seal.get("done", false):
		return
	seal["done"] = true
	seals_lit += 1
	var ring: Polygon2D = seal.get("ring")
	var outer: Polygon2D = seal.get("outer")
	if ring:
		ring.color = Color(1.0, 0.92, 0.45)
	if outer:
		outer.color = Color(1.0, 0.85, 0.35, 0.7)
	var seal_node: Node2D = seal.get("node")
	if seal_node and not seal_node.has_node("SealLight"):
		var pl := PointLight2D.new()
		pl.name = "SealLight"
		pl.energy = 0.7
		pl.texture_scale = 1.1
		pl.color = Color(1.0, 0.88, 0.4)
		seal_node.add_child(pl)
	GameManager.add_score(70)
	DialogueManager.show_corner_notice(
		"Luz encendida (%d/%d)" % [seals_lit, TOTAL_SEALS],
		Color(0.92, 0.78, 0.40), 1.6
	)
	_update_hud_status()
	_try_unlock_boss()


func _try_interact() -> void:
	_update_near_memory()
	_update_near_seal()
	if not _near_memory.is_empty() and not _near_memory.get("done", true):
		_read_memory(_near_memory)
		return
	if not _near_seal.is_empty() and not _near_seal.get("done", true):
		_light_seal(_near_seal)
		return
	_try_heal_boss()


func _update_near_seal() -> void:
	_near_seal = {}
	if GameManager.player == null:
		return
	for seal in seals:
		if seal.get("done", false):
			continue
		var area: Area2D = seal.get("area")
		if is_instance_valid(area) and area.overlaps_body(GameManager.player):
			_near_seal = seal
			return


func _read_memory(mem: Dictionary) -> void:
	if mem.get("done", false):
		return
	mem["done"] = true
	memories_read += 1
	var idx: int = mem.get("index", 1)
	var poly: Polygon2D = mem.get("poly")
	if poly:
		poly.color = Color(0.85, 0.95, 1.0)
	GameManager.add_score(90)
	var refl := StoryReflections.get_crystal_memory(idx)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body, refl.accent, 3.0)
	DialogueManager.show_corner_notice(
		"Cristal leído (%d/%d) — busca más cristales azules" % [memories_read, TOTAL_MEMORIES],
		Color(0.72, 0.88, 1.0), 1.6
	)
	_update_hud_status()
	_try_unlock_boss()


func _update_near_memory() -> void:
	_near_memory = {}
	if GameManager.player == null:
		return
	for m in memories:
		if m.get("done", false):
			continue
		var area: Area2D = m.get("area")
		if is_instance_valid(area) and area.overlaps_body(GameManager.player):
			_near_memory = m
			return


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

	if not _boss_arena_active:
		for ed in enemies:
			EnemyBehavior.tick(ed, player_pos, delta)

	_update_minimap()
	_update_near_memory()
	_update_near_seal()
	_update_proximity_hints(delta)
	_update_boss_hint(delta)


func _update_boss_hint(delta: float) -> void:
	_boss_hint_cd = maxf(0.0, _boss_hint_cd - delta)
	if _boss_hint_cd > 0.0 or not boss_unlocked or boss_defeated:
		return
	if _is_player_near_boss():
		_boss_hint_cd = 5.0
		DialogueManager.show_corner_notice(
			"¡Aquí! Pulsa [E] o [Q] para sanar al jefe.",
			Color(0.9, 0.78, 1.0),
			2.2
		)


func _update_proximity_hints(delta: float) -> void:
	_hint_cooldown = maxf(0.0, _hint_cooldown - delta)
	if _hint_cooldown > 0.0 or _transitioning:
		return
	if not _near_memory.is_empty() and not _near_memory.get("done", true):
		_hint_cooldown = 5.0
		DialogueManager.show_corner_notice("Cristal azul → pulsa [E]", Color(0.55, 0.88, 1.0), 2.0)
		return
	if not _near_seal.is_empty() and not _near_seal.get("done", true):
		_hint_cooldown = 5.0
		DialogueManager.show_corner_notice("Círculo dorado → pulsa [E] para encender", Color(0.95, 0.82, 0.40), 2.0)


func _trigger_cave_echo() -> void:
	if _transitioning or _boss_arena_active or enemies.is_empty():
		return
	EnemyBehavior.trigger_surge(enemies, 3.5)
	DialogueManager.show_corner_notice("Los ecos de la cueva despiertan — ¡emboscada!", Color(0.85, 0.72, 1.0), 2.5)
	queue_redraw()


func _setup_hud() -> void:
	hud_layer = ZoneUIBootstrap.attach_hud(self, "Z3 Cueva", MAX_CHARGES)
	minimap = ZoneUIBootstrap.attach_minimap(self, MAP, {
		"floor": FLOOR_COLOR,
		"wall": WALL_COLOR,
		"echo": ECHO_COLOR,
		"exit": Color(0.85, 0.72, 0.25),
		"enemy": Color(0.92, 0.18, 0.28),
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
	_update_hud()
	GameManager.request_zone_complete(
		3, "res://scenes/world/Zone4_Rio.tscn", "zone3", 700, 0.34
	)
