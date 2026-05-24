extends Node2D

# ── Niebla ───────────────────────────────────────────────────────────────────
var fog_material: ShaderMaterial

# ── Ecos de luz (coleccionables) ─────────────────────────────────────────────
var echoes_collected: int = 0
const TOTAL_ECHOES = 4

# ─────────────────────────────────────────────────────────────────────────────
# MAPA  (32 columnas × 20 filas — cada fila EXACTAMENTE 32 chars)
#
#   #  = Pared con colisión   (borde exterior siempre #)
#   .  = Suelo libre
#   S  = Posición inicial de Alex
#   E  = Eco de luz (coleccionable)
#   X  = Salida (se desbloquea al recoger los 4 ecos)
#
#  Las TRES filas de muros (5, 10, 15) tienen huecos en cols 10-11 y 21-22.
#  Esto garantiza un camino COMPLETAMENTE CONECTADO de S → todos los Ecos → X.
# ─────────────────────────────────────────────────────────────────────────────
const MAP = [
	"################################",  # R0  borde superior
	"#S.............................#",  # R1  AREA 1 (filas 1-4)  — inicio
	"#....E.........................#",  # R2  E1 en col 5
	"#..............................#",  # R3
	"#..............................#",  # R4
	"##########..#########..#########",  # R5  MURO con huecos en cols 10-11 y 21-22
	"#..............................#",  # R6  AREA 2 (filas 6-9)
	"#........................E.....#",  # R7  E2 en col 25
	"#..............................#",  # R8
	"#..............................#",  # R9
	"##########..#########..#########",  # R10 MURO
	"#..............................#",  # R11 AREA 3 (filas 11-14)
	"#.........E....................#",  # R12 E3 en col 10
	"#..............................#",  # R13
	"#..............................#",  # R14
	"##########..#########..#########",  # R15 MURO
	"#..............................#",  # R16 AREA 4 (filas 16-18)
	"#.....................E........#",  # R17 E4 en col 22
	"#.............................X#",  # R18 SALIDA X en col 30
	"################################",  # R19 borde inferior
]

const TS = 16
const WALL_COLOR        = Color(0.08, 0.07, 0.13)
const FLOOR_COLOR       = Color(0.15, 0.12, 0.22)
const ECHO_COLOR        = Color(0.9,  0.95, 0.5)
const EXIT_LOCKED_COLOR = Color(0.28, 0.28, 0.35)
const EXIT_OPEN_COLOR   = Color(0.15, 0.90, 0.45)
const ENEMY_BODY_COLOR  = Color(0.55, 0.08, 0.12)
const ENEMY_GLOW_COLOR  = Color(0.80, 0.20, 0.30, 0.35)

var walls:  Array = []
var floors: Array = []

# ── Salida ───────────────────────────────────────────────────────────────────
var exit_poly: Polygon2D = null
var exit_area: Area2D   = null
var exit_unlocked: bool  = false
var _transitioning: bool = false

# ── Enemigos (Sombras del Acoso) ──────────────────────────────────────────────
var enemies: Array = []   # [{node, area, speed}]

# Posiciones tile (col, fila) — 8 sombras repartidas por el mapa
const ENEMY_TILES = [
	Vector2i(15,  2),
	Vector2i(20,  4),
	Vector2i( 8,  3),
	Vector2i( 5,  7),
	Vector2i(20,  8),
	Vector2i(25, 12),
	Vector2i( 8, 13),
	Vector2i(10, 17),
]

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
var hud_layer: CanvasLayer = null
var lbl_score:  Label = null
var lbl_health: Label = null
var lbl_echo:   Label = null
var lbl_light:  Label = null
var minimap: ZoneMinimap = null

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.10))
	_generate_map()
	_setup_fog()
	_spawn_enemies()
	_setup_hud()
	GameManager.empathy_changed.connect(_on_empathy_changed)
	GameManager.health_changed.connect(func(_v): _update_hud())
	GameManager.score_changed.connect(func(_v): _update_hud())

	# Alex no lleva arma en zona 1 (el ataque = Pulso de Luz)
	if GameManager.player:
		GameManager.player.has_weapon = false

	await get_tree().create_timer(0.5).timeout
	DialogueManager.show_zone_intro(
		"ZONA 1 — Laberinto de Palabras",
		"Las Sombras del Acoso guardan este lugar.\nRecoge 4 Ecos de Luz para abrir la salida.",
		"Cada eco carga un Pulso de Luz [J] para repeler sombras.",
		Color(0.95, 0.90, 0.45)
	)

# ── Generación del mapa ───────────────────────────────────────────────────────
func _generate_map() -> void:
	for y in MAP.size():
		for x in MAP[y].length():
			var c  = MAP[y][x]
			var pos = Vector2(x * TS, y * TS)
			match c:
				"#":
					walls.append(Rect2(pos, Vector2(TS, TS)))
					_add_wall(pos)
				"S":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					if GameManager.player:
						GameManager.player.global_position = pos + Vector2(8, 8)
				"E":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_echo(pos)
				"X":
					floors.append(Rect2(pos, Vector2(TS, TS)))
					_spawn_exit(pos)
				_:
					floors.append(Rect2(pos, Vector2(TS, TS)))
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

# ── Ecos ──────────────────────────────────────────────────────────────────────
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
		Vector2(-5,-5), Vector2(5,-5), Vector2(5,5), Vector2(-5,5)
	])
	poly.color = ECHO_COLOR
	a.add_child(poly)
	# Pulso de brillo
	var tween = create_tween().set_loops()
	tween.tween_property(poly, "modulate", Color(2.0, 2.0, 0.5), 0.55)
	tween.tween_property(poly, "modulate", Color(1.0, 1.0, 1.0),  0.55)
	a.body_entered.connect(func(body):
		if body.is_in_group("player"): _collect_echo(a)
	)

func _collect_echo(node: Node) -> void:
	echoes_collected += 1
	node.queue_free()
	GameManager.add_score(100)
	# Aumentar radio de visión en la niebla
	if fog_material:
		var r = 0.12 + echoes_collected * 0.05
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
	add_child(exit_area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 12
	c.shape = s
	exit_area.add_child(c)
	exit_area.body_entered.connect(func(body):
		if not body.is_in_group("player"): return
		if exit_unlocked:
			_zone_complete()
		else:
			DialogueManager.show_corner_notice(
				"Salida bloqueada — faltan %d ecos." % (TOTAL_ECHOES - echoes_collected),
				Color(0.65, 0.70, 0.95), 2.0
			)
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
	for i in ENEMY_TILES.size():
		var tile     = ENEMY_TILES[i]
		var world_pos = Vector2(tile.x * TS, tile.y * TS) + Vector2(TS / 2.0, TS / 2.0)
		_create_enemy(world_pos, i)

func _create_enemy(world_pos: Vector2, idx: int) -> void:
	var enemy := ShadowEnemyVisual.create(self, world_pos, {
		"body": ENEMY_BODY_COLOR,
		"glow": ENEMY_GLOW_COLOR,
		"pulse": Color(1.55, 0.35, 0.40),
		"eyes": Color(1.0, 0.20, 0.18),
		"wisp": Color(0.30, 0.05, 0.12, 0.70),
		"scale": 0.68,
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
		"speed": 12.0 + idx * 1.0,
	})

func _enemy_hit_player(p: Node, message: String, source_pos: Vector2) -> void:
	if p.has_meta("enemy_cd") and p.get_meta("enemy_cd") > 0.0:
		return
	p.set_meta("enemy_cd", 2.2)
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

	# Empujar y aturdir enemigos en radio
	for ed in enemies:
		var en: Node2D = ed["node"]
		if not is_instance_valid(en): continue
		var dist = en.global_position.distance_to(player_pos)
		if dist <= PULSE_RADIUS:
			var push_dir = (en.global_position - player_pos).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.RIGHT
			en.global_position += push_dir * 62.0
			en.set_meta("stunned", STUN_TIME)
			var ar: Area2D = ed["area"]
			if is_instance_valid(ar):
				ar.global_position = en.global_position

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

	if not GameManager.player: return
	var player_pos = GameManager.player.global_position

	for ed in enemies:
		var en: Node2D = ed["node"]
		if not is_instance_valid(en): continue

		# Gestión de aturdimiento
		if en.has_meta("stunned"):
			var t = en.get_meta("stunned") - delta
			if t <= 0.0:
				en.remove_meta("stunned")
				# Restaurar color
				var b = en.get_node_or_null("Body")
				if b: b.modulate = Color(1, 1, 1)
			else:
				en.set_meta("stunned", t)
				# Color azulado mientras está aturdido
				var b = en.get_node_or_null("Body")
				if b: b.modulate = Color(0.5, 0.5, 1.5)
				continue  # No se mueve mientras esté aturdido

		# Movimiento normal
		var dir = player_pos - en.global_position
		if dir.length() > 4.0:
			en.global_position += dir.normalized() * ed["speed"] * delta
		# Mantener área sincronizada
		var ar: Area2D = ed["area"]
		if is_instance_valid(ar):
			ar.global_position = en.global_position

	_update_minimap()

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
			fog_material.set_shader_parameter("light_radius", 0.16)

# ── HUD ───────────────────────────────────────────────────────────────────────
func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	lbl_score = _make_label(Vector2(4, 2),  Color(1.0, 0.9, 0.3))
	lbl_health = _make_label(Vector2(4, 13), Color(1.0, 0.35, 0.35))
	lbl_echo   = _make_label(Vector2(4, 24), Color(0.9, 0.95, 0.5))
	lbl_light  = _make_label(Vector2(4, 35), Color(0.4, 0.8, 1.0))

	var lbl_hint = _make_label(Vector2(4, 46), Color(0.6, 0.6, 0.7))
	lbl_hint.text = "[J] Pulso  [ESC] Menú"

	minimap = ZoneMinimap.new()
	minimap.setup(MAP, {
		"floor": FLOOR_COLOR,
		"wall": WALL_COLOR,
		"echo": ECHO_COLOR,
		"exit": EXIT_OPEN_COLOR,
	})
	minimap.position = Vector2(252, 130)
	hud_layer.add_child(minimap)
	var lbl_map = _make_label(Vector2(252, 122), Color(0.55, 0.55, 0.65))
	lbl_map.text = "MAPA"

	GameManager.health_changed.connect(func(_v): _update_hud())
	GameManager.score_changed.connect(func(_v): _update_hud())
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
		for _i in GameManager.current_health:   h += "♥"
		for _i in (GameManager.max_health - GameManager.current_health): h += "♡"
		lbl_health.text = "VIDA: " + h
	if lbl_echo:
		lbl_echo.text = "ECOS: %d/%d" % [echoes_collected, TOTAL_ECHOES]
	if lbl_light:
		var li = ""
		for _i in light_charges:               li += "●"
		for _i in (MAX_CHARGES - light_charges): li += "○"
		lbl_light.text = "LUZ:  " + li


func _update_minimap() -> void:
	if minimap == null or GameManager.player == null:
		return
	minimap.set_player_world_pos(GameManager.player.global_position, TS)
	minimap.set_echoes_remaining(TOTAL_ECHOES - echoes_collected)
	minimap.set_exit_open(exit_unlocked)


func _zone_complete() -> void:
	if _transitioning: return
	_transitioning = true
	set_process(false)
	QuestManager.advance_quest("zone1")
	GameManager.update_empathy(0.33)
	GameManager.add_score(500)
	var refl := StoryReflections.get_zone_complete(1)
	if not refl.is_empty():
		DialogueManager.show_reflection(refl.title, refl.body + "\n+500 pts", refl.accent, 5.0)
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/world/Zone2_Swamp.tscn")

func _on_empathy_changed(v: float) -> void:
	modulate = Color(0.5 + v * 0.5, 0.5 + v * 0.5, 0.6 + v * 0.4)
