extends Node2D

# ── Niebla ───────────────────────────────────────────────────────────────────
var fog_material: ShaderMaterial

# ── Ecos de luz (coleccionables) ─────────────────────────────────────────────
var echoes_collected: int = 0
const TOTAL_ECHOES = 4

# ── Mapa generado (laberinto real 49×33) ─────────────────────────────────────
var MAP: Array = []
var _spawn_tile: Vector2i = Vector2i(1, 1)

const TS = 16
const WALL_COLOR        = Color(0.08, 0.07, 0.13)
const FLOOR_COLOR       = Color(0.15, 0.12, 0.22)
const ECHO_COLOR        = Color(0.9,  0.95, 0.5)
const EXIT_LOCKED_COLOR = Color(0.28, 0.28, 0.35)
const EXIT_OPEN_COLOR   = Color(0.15, 0.90, 0.45)
const ENEMY_BODY_COLOR  = Color(0.82, 0.12, 0.18)
const ENEMY_GLOW_COLOR  = Color(0.95, 0.30, 0.40, 0.55)

var walls:  Array = []
var floors: Array = []

# ── Salida ───────────────────────────────────────────────────────────────────
var exit_poly: Polygon2D = null
var exit_area: Area2D   = null
var exit_unlocked: bool  = false
var _transitioning: bool = false
var _event_timer: float = 18.0

# ── Enemigos (Sombras del Acoso) ──────────────────────────────────────────────
var enemies: Array = []   # [{node, area, speed}]

# Posiciones tile — se calculan tras generar el laberinto
var _enemy_tiles: Array[Vector2i] = []

const ENEMY_MSGS = [
	"Una palabra puede doler\npor años enteros.  -1 vida",
	"El miedo que causas\nte perseguirá siempre.  -1 vida",
	"Ignorar el daño hecho\nte hace cómplice.  -1 vida",
	"Las cicatrices del bullying\nno se ven... pero duelen.  -1 vida",
	"Cada insulto deja\nuna marca invisible.  -1 vida",
	"El silencio cómplice\ntambién hace daño.  -1 vida",
	"Burlarse no es juego,\nes una herida lenta.  -1 vida",
	"Nadie merece sentirse\ninvisible o asustado.  -1 vida",
]

# ── Pulso de Luz (defensa) ────────────────────────────────────────────────────
var light_charges: int   = 1    # Empieza con 1 carga para aprender el Pulso de Luz
const MAX_CHARGES: int   = 3
const PULSE_RADIUS: float = 68.0
const STUN_TIME: float    = 2.2

# ── HUD ──────────────────────────────────────────────────────────────────────
var hud_layer: PremiumZoneHUD = null
var minimap: ZoneMinimap = null
var _gothic_player: GothicPlayerVisual = null

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color(0.14, 0.12, 0.20))
	call_deferred("_build_level")
	GameManager.empathy_changed.connect(_on_empathy_changed)
	GameManager.health_changed.connect(func(_v): _update_hud())
	GameManager.score_changed.connect(func(_v): _update_hud())


func _build_level() -> void:
	MAP = MazeGenerator.build_zone1_labyrinth()
	if MAP.is_empty():
		push_error("Zone1: no se pudo generar el mapa")
		return
	_cache_spawn_tile()
	_enemy_tiles = DifficultySettings.pick_enemy_tiles(
		MAP, DifficultySettings.get_enemy_count(8, 1), _spawn_tile, 80.0
	)
	_generate_map()
	_spawn_enemies()
	_setup_hud()
	_configure_camera_limits()
	_finish_player_setup()
	await get_tree().create_timer(0.5).timeout
	ZoneMissionBriefs.show_for_zone(1)


func _finish_player_setup() -> void:
	var setup := ZoneVisualBootstrap.finish_player_setup(self, MAP, TS, "labyrinth")
	_gothic_player = setup.get("gothic") as GothicPlayerVisual
	var atm := setup.get("atmosphere") as GothicAtmosphere
	if atm:
		fog_material = atm.get_fog_material()
	if GameManager.player:
		GameManager.player.has_weapon = false
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam and GameManager.player:
		cam.global_position = GameManager.player.global_position
	queue_redraw()


func _cache_spawn_tile() -> void:
	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			if row[x] == "S":
				_spawn_tile = Vector2i(x, y)
				return


func _configure_camera_limits() -> void:
	var cam := get_node_or_null("Camera2D")
	if cam and cam.has_method("set_map_limits"):
		cam.set_map_limits(MAP[0].length() * TS, MAP.size() * TS)


# ── Generación del mapa ───────────────────────────────────────────────────────
func _generate_map() -> void:
	for y in MAP.size():
		for x in MAP[y].length():
			var c  = MAP[y][x]
			var pos = Vector2(x * TS, y * TS)
			match c:
				"#":
					walls.append(Rect2(pos, Vector2(TS, TS)))
				"S":
					floors.append(Rect2(pos, Vector2(TS, TS)))
				"E":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_echo(pos)
				"X":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_exit(pos)
				_:
					floors.append(Rect2(pos, Vector2(TS, TS)))
	ZoneMapCollider.build(self, walls)
	queue_redraw()

func _draw() -> void:
	GothicTilePainter.draw_zone_map(self, floors, [], walls, "labyrinth")

# ── Ecos ──────────────────────────────────────────────────────────────────────
func _spawn_echo(pos: Vector2) -> void:
	EchoStarVisual.spawn(self, pos + Vector2(TS / 2.0, TS / 2.0), Callable(self, "_collect_echo"))

func _collect_echo(node: Node) -> void:
	if minimap:
		minimap.mark_echo_collected_at(node.global_position, TS)
	echoes_collected += 1
	node.queue_free()
	GameManager.add_score(100)
	# Aumentar radio de visión en la niebla
	if fog_material:
		var r = 0.44 + echoes_collected * 0.04
		create_tween().tween_method(
			func(v): fog_material.set_shader_parameter("light_radius", v),
			fog_material.get_shader_parameter("light_radius"), r, 1.5
		)
	# +1 carga de luz
	light_charges = min(light_charges + 1, MAX_CHARGES)
	_update_hud()
	var refl := StoryReflections.get_echo_reflection(1, echoes_collected)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body, refl.accent, 3.5)
	DialogueManager.show_corner_notice(
		"Eco %d/%d  +100 pts  ⚡+1" % [echoes_collected, TOTAL_ECHOES],
		Color(0.9, 0.95, 0.5), 2.0
	)
	if echoes_collected >= TOTAL_ECHOES:
		_unlock_exit()
	EnemyBehavior.trigger_rush_near(enemies, node.global_position, 2)

# ── Salida ────────────────────────────────────────────────────────────────────
func _spawn_exit(pos: Vector2) -> void:
	var center = pos + Vector2(TS / 2.0, TS / 2.0)
	var exit_node = Node2D.new()
	exit_node.global_position = center
	add_child(exit_node)

	exit_poly = Polygon2D.new()
	exit_poly.polygon = PackedVector2Array([
		Vector2(-7,-7), Vector2(7,-7), Vector2(7,7), Vector2(-7,7)
	])
	exit_poly.color = EXIT_LOCKED_COLOR
	exit_node.add_child(exit_poly)

	# Símbolo candado
	var lock = Polygon2D.new()
	lock.polygon = PackedVector2Array([
		Vector2(-3,-3), Vector2(-1,-3), Vector2(0,-1),
		Vector2(1,-3),  Vector2(3,-3),  Vector2(1,0),
		Vector2(3,3),   Vector2(1,3),   Vector2(0,1),
		Vector2(-1,3),  Vector2(-3,3),  Vector2(-1,0)
	])
	lock.color = Color(0.5, 0.4, 0.1)
	exit_node.add_child(lock)

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
		# Pulso infinito hasta que el jugador lo usa
		var tween = create_tween().set_loops()
		tween.tween_property(exit_poly, "modulate", Color(1.8, 2.2, 1.8), 0.45)
		tween.tween_property(exit_poly, "modulate", Color(1.0, 1.0, 1.0),  0.45)
	if GameManager.player:
		DialogueManager.show_corner_notice("¡Salida abierta! → abajo derecha.", Color(0.25, 1.0, 0.50), 3.0)

# ── Enemigos (Sombras del Acoso) ──────────────────────────────────────────────
func _spawn_enemies() -> void:
	for i in _enemy_tiles.size():
		var tile = _enemy_tiles[i]
		var world_pos = Vector2(tile.x * TS, tile.y * TS) + Vector2(TS / 2.0, TS / 2.0)
		_create_enemy(world_pos, i)

func _create_enemy(world_pos: Vector2, idx: int) -> void:
	var enemy := ShadowEnemyVisual.create(self, world_pos, {
		"body": ENEMY_BODY_COLOR,
		"glow": ENEMY_GLOW_COLOR,
		"pulse": Color(1.8, 0.45, 0.50),
		"eyes": Color(1.0, 0.95, 0.90),
		"wisp": Color(0.45, 0.08, 0.14, 0.75),
		"scale": 0.90,
	})

	# Área de daño
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
		"node":  enemy,
		"area":  area,
		"speed": (12.0 + idx * 1.2) * DifficultySettings.get_speed_mult(),
	})
	EnemyBehavior.init_entry(enemies[-1], world_pos)

func _enemy_hit_player(p: Node, message: String, source_pos: Vector2) -> void:
	if p.has_meta("enemy_cd") and p.get_meta("enemy_cd") > 0.0:
		return
	p.set_meta("enemy_cd", DifficultySettings.get_hit_cooldown(2.2))
	GameManager.take_damage()
	if is_instance_valid(p):
		p.take_hit(source_pos)
		var hit := StoryReflections.get_enemy_hit()
		DialogueManager.show_reflection(hit.title, message + "\n" + hit.body, hit.accent, 3.0)

# ── Pulso de Luz ──────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and light_charges > 0 and GameManager.player:
		_use_light_pulse()
		get_viewport().set_input_as_handled()

func _use_light_pulse() -> void:
	light_charges -= 1
	_update_hud()
	var player_pos = GameManager.player.global_position

	# Flash visual en el jugador
	var tween_flash = create_tween()
	tween_flash.tween_property(GameManager.player, "modulate", Color(3.0, 3.0, 0.5), 0.08)
	tween_flash.tween_property(GameManager.player, "modulate", Color(1.0, 1.0, 1.0), 0.25)

	# Empujar y eliminar enemigos en radio
	var removed := EnemyBehavior.eliminate_in_radius(enemies, player_pos, PULSE_RADIUS)
	if removed > 0:
		GameManager.add_score(removed * 50)
		DialogueManager.show_corner_notice(
			"¡%d sombra(s) disipada(s)! +%d pts" % [removed, removed * 50],
			Color(1.0, 0.95, 0.45), 2.0
		)

	DialogueManager.show_corner_notice("¡Pulso de Luz!", Color(1.0, 1.0, 0.35), 1.5)

	# Recarga automática a los 8 segundos
	await get_tree().create_timer(8.0).timeout
	if not _transitioning:
		light_charges = min(light_charges + 1, MAX_CHARGES)
		_update_hud()

# ── Process: mover enemigos ───────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Cooldown de daño del jugador
	if GameManager.player and GameManager.player.has_meta("enemy_cd"):
		var cd = maxf(0.0, GameManager.player.get_meta("enemy_cd") - delta)
		GameManager.player.set_meta("enemy_cd", cd)

	if not GameManager.player:
		return
	var player_pos = GameManager.player.global_position

	_event_timer -= delta
	if _event_timer <= 0.0:
		var wait := DifficultySettings.get_surge_wait(16.0, 24.0)
		_event_timer = randf_range(wait.x, wait.y)
		_trigger_shadow_surge()

	for ed in enemies:
		EnemyBehavior.tick(ed, player_pos, delta)

	_update_minimap()
	_check_exit_overlap()


func _trigger_shadow_surge() -> void:
	if _transitioning or enemies.is_empty():
		return
	EnemyBehavior.trigger_surge(enemies, 4.0)
	DialogueManager.show_corner_notice("¡Oleada de susurros! — corren más rápido", Color(0.95, 0.45, 0.55), 2.5)
	if fog_material:
		var tween := create_tween()
		tween.tween_method(func(v): fog_material.set_shader_parameter("light_radius", v), 0.16, 0.10, 0.4)
		tween.tween_method(func(v): fog_material.set_shader_parameter("light_radius", v), 0.10, 0.16, 1.2)


func _try_use_exit(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if exit_unlocked:
		_zone_complete()
	else:
		DialogueManager.show_corner_notice(
			"Salida bloqueada — faltan %d ecos." % (TOTAL_ECHOES - echoes_collected),
			Color(0.65, 0.70, 0.95), 2.0
		)


func _check_exit_overlap() -> void:
	if not exit_unlocked or _transitioning or exit_area == null or GameManager.player == null:
		return
	if exit_area.overlaps_body(GameManager.player):
		_zone_complete()

# ── Niebla ───────────────────────────────────────────────────────────────────
func _setup_fog() -> void:
	var fog = get_node_or_null("CanvasLayer/FogOverlay")
	if fog == null: return
	fog.get_parent().visible = true
	if fog.material:
		fog_material = fog.material as ShaderMaterial
		if fog_material:
			fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			fog_material.set_shader_parameter("player_pos",  Vector2(0.5, 0.5))
			fog_material.set_shader_parameter("light_radius", 0.44)

# ── HUD ───────────────────────────────────────────────────────────────────────
var _map_layer: CanvasLayer = null

func _setup_hud() -> void:
	hud_layer = ZoneUIBootstrap.attach_hud(self, "Z1 Laberinto", MAX_CHARGES)
	minimap = ZoneUIBootstrap.attach_minimap(self, MAP, {
		"floor": FLOOR_COLOR.lightened(0.15),
		"wall": WALL_COLOR.lightened(0.12),
		"echo": ECHO_COLOR,
		"exit": EXIT_OPEN_COLOR,
		"enemy": Color(0.95, 0.32, 0.38),
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
	set_process(false)
	GameManager.request_zone_complete(
		1, "res://scenes/world/Zone2_Swamp.tscn", "zone1", 500, 0.33
	)

func _on_empathy_changed(v: float) -> void:
	modulate = Color(0.5 + v * 0.5, 0.5 + v * 0.5, 0.6 + v * 0.4)
