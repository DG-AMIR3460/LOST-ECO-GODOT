extends Node2D
## El Pantano — demo V Gamer Fair: máxima dificultad, DI estricta, sin Singleton gameplay.

const TILE_SIZE: float = 16.0
const DIFFICULTY: float = 1.45
const WAVE_INTERVAL: float = 22.0

const MAP: Array = [
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

const MUD := Color(0.1, 0.13, 0.07)
const WALL := Color(0.05, 0.06, 0.03)
const MUD_HI := Color(0.14, 0.17, 0.09)
const PARALLAX_SCRIPT := preload("res://scripts/mapa/GothicParallaxLayers.gd")
const PLAYER_SCENE := preload("res://scenes/core/player_controller.tscn")
const NEXT_ZONE_SCENE := "res://scenes/world/Zone2_Swamp.tscn"

@onready var session: GameSession = $GameSession
@onready var enemy_factory: EnemyFactory = $EnemyFactory
@onready var level_generator: LevelProceduralObstacle = $LevelProceduralObstacle
@onready var accessibility: AccessibilityManager = $AccessibilityManager
@onready var death_director: DeathCinematicDirector = $DeathCinematicDirector
@onready var screen_shake: ScreenShake = $ScreenShake
@onready var skin_mapper: PlayerSkinMapper = $PlayerSkinMapper
@onready var gameplay_layer: Node2D = $Gameplay
@onready var hazards_layer: Node2D = $Hazards
@onready var echoes_layer: Node2D = $Echoes
@onready var enemies_layer: Node2D = $Enemies
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var vignette_layer: CanvasLayer = $VignetteLayer

var _player: PlayerController2D = null
var _floor_positions: Array[Vector2] = []
var _hud: GameHUD = null
var _minimap: FogOfWarMinimap = null
var _floors: Array[Rect2] = []
var _walls: Array[Rect2] = []
var _vignette_mat: ShaderMaterial = null
var _wave_timer: float = 35.0
var _pause_layer: CanvasLayer = null
var _is_paused: bool = false
var _enemy_positions: Array[Vector2] = []
var _exit_area: Area2D = null
var _exit_unlocked: bool = false
var _zone_transitioning: bool = false
var _atmosphere: GothicAtmosphere = null


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_clear_stale_game_over_layers()
	death_director.reset_state()
	RenderingServer.set_default_clear_color(Color(0.03, 0.04, 0.07))
	if canvas_modulate:
		canvas_modulate.color = Color(0.48, 0.44, 0.62, 1.0)
	_setup_vignette()
	_build_level()
	_configure_level_generator()
	level_generator.difficulty = DIFFICULTY
	level_generator.generate()
	_spawn_player()
	_wire_systems()
	_atmosphere = GothicAtmosphere.new()
	add_child(_atmosphere)
	_atmosphere.setup(self, _player, "swamp")
	_spawn_initial_enemies()
	_register_static_echoes()
	_show_intro()
	_spawn_ambient_motes()
	call_deferred("_unlock_exit")


func _setup_vignette() -> void:
	if vignette_layer == null:
		return
	var rect := ColorRect.new()
	rect.name = "VignetteRect"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = preload("res://shaders/vignette_screen.gdshader")
	rect.color = Color(1.0, 1.0, 1.0, 1.0)
	_vignette_mat.set_shader_parameter("intensity", 0.55)
	_vignette_mat.set_shader_parameter("aspect_ratio", 1.777)
	rect.material = _vignette_mat
	vignette_layer.add_child(rect)


func _build_level() -> void:
	for y in MAP.size():
		for x in MAP[y].length():
			var c: String = MAP[y][x]
			var pos := Vector2(x * TILE_SIZE, y * TILE_SIZE)
			match c:
				"#":
					_walls.append(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)))
					_add_wall(pos)
				"S", "E", "X", ".":
					_floors.append(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)))
					_floor_positions.append(pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5))
					_add_floor_body(pos)
					if c == "E":
						_spawn_static_echo(pos)
					if c == "X":
						_spawn_exit(pos)
	queue_redraw()


func _add_wall(pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.global_position = pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	gameplay_layer.add_child(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	col.shape = shape
	body.add_child(col)


func _add_floor_body(pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.global_position = pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	gameplay_layer.add_child(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	col.shape = shape
	body.add_child(col)


func _spawn_static_echo(pos: Vector2) -> void:
	var echo_scene := preload("res://scenes/core/level/memory_echo.tscn")
	var echo := echo_scene.instantiate()
	echoes_layer.add_child(echo)
	echo.global_position = pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5 - 4.0)
	if echo.has_signal("collected"):
		echo.collected.connect(_on_echo_collected.bind(echo))


func _register_static_echoes() -> void:
	pass


func _on_echo_collected(echo: Node) -> void:
	if _minimap and echo:
		var cell := Vector2i(
			int(floor(echo.global_position.x / TILE_SIZE)),
			int(floor(echo.global_position.y / TILE_SIZE))
		)
		_minimap.mark_echo_collected(cell)
	if session and session.memories_found >= 2:
		_unlock_exit()


func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate() as PlayerController2D
	gameplay_layer.add_child(_player)
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] == "S":
				_player.global_position = Vector2(
					x * TILE_SIZE + TILE_SIZE * 0.5 + 24.0,
					y * TILE_SIZE - 7.0
				)
				break
	call_deferred("_snap_player_to_floor")


func _configure_level_generator() -> void:
	var spawn_excludes: Array[Vector2] = []
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] == "S":
				spawn_excludes.append(Vector2(x * TILE_SIZE + 8.0, y * TILE_SIZE + 8.0))
	level_generator.configure(echoes_layer, hazards_layer, _floor_positions, spawn_excludes, 96.0)
	level_generator.spike_count = 8


func _wire_systems() -> void:
	session.max_health = 3
	session.reset_for_run()
	session.max_light_energy = 100.0
	session.light_energy = 100.0
	session.light_pulse_cost = 26.0
	death_director.configure(session, screen_shake)
	accessibility.bind_viewport_root(self)
	_player.inject_dependencies(session, death_director, skin_mapper)
	_player.grant_spawn_protection(4.0)
	gameplay_layer.z_index = 5
	call_deferred("_ensure_camera_current")
	if skin_mapper and SettingsManager.player_skin:
		skin_mapper.apply_skin(SettingsManager.player_skin)
	enemy_factory.configure(enemies_layer, _player, DIFFICULTY)
	enemy_factory.enemy_spawned.connect(_on_enemy_spawned)
	enemy_factory.enemy_spawned.connect(func(_e, _t): _refresh_enemy_minimap())
	screen_shake.bind_camera(_player.camera)
	_hud = GameHUD.new()
	add_child(_hud)
	_hud.bind_session(session)
	_minimap = FogOfWarMinimap.new()
	_minimap.position = Vector2(208, 92)
	_hud.add_child(_minimap)
	_minimap.setup_from_grid(MAP, {"floor": MUD, "wall": WALL, "echo": Color(1.0, 0.9, 0.4)})
	call_deferred("_build_parallax")


func _snap_player_to_floor() -> void:
	if _player == null:
		return
	await get_tree().physics_frame
	for _i in 8:
		if _player.is_on_floor():
			break
		_player.velocity = Vector2(_player.velocity.x, 120.0)
		_player.move_and_slide()


func _build_parallax() -> void:
	if _player == null:
		return
	var existing := get_node_or_null("ParallaxBackground")
	if existing:
		existing.queue_free()
	var para := ParallaxBackground.new()
	para.name = "ParallaxBackground"
	para.set_script(PARALLAX_SCRIPT)
	add_child(para)
	move_child(para, 0)
	if para.has_method("build"):
		para.build(_player, "swamp")


func _spawn_exit(pos: Vector2) -> void:
	var center := pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5 - 2.0)
	_exit_area = Area2D.new()
	_exit_area.name = "ExitArea"
	_exit_area.collision_layer = 0
	_exit_area.collision_mask = 1
	_exit_area.monitoring = true
	_exit_area.global_position = center
	gameplay_layer.add_child(_exit_area)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	_exit_area.add_child(shape)
	var marker := Polygon2D.new()
	marker.color = Color(0.2, 0.85, 0.45, 0.85)
	marker.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6),
	])
	_exit_area.add_child(marker)
	_exit_area.body_entered.connect(_on_exit_body_entered)


func _on_exit_body_entered(body: Node2D) -> void:
	if _zone_transitioning or not _exit_unlocked:
		return
	if body is PlayerController2D:
		_complete_pantano_demo()


func _unlock_exit() -> void:
	_exit_unlocked = true
	if _exit_area:
		for child in _exit_area.get_children():
			if child is Polygon2D:
				(child as Polygon2D).color = Color(0.15, 0.95, 0.5, 1.0)


func _complete_pantano_demo() -> void:
	if _zone_transitioning:
		return
	_zone_transitioning = true
	if _player:
		_player.input_locked = true
	DialogueManager.show_corner_notice("¡Pantano superado! Zona 2...", Color(0.55, 0.9, 0.5), 2.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = false
	Engine.time_scale = 1.0
	await SceneTransition.change_scene(NEXT_ZONE_SCENE)


func _spawn_initial_enemies() -> void:
	var spawns: Array[Vector2] = [
		Vector2(12 * TILE_SIZE, 2 * TILE_SIZE),
		Vector2(24 * TILE_SIZE, 4 * TILE_SIZE),
		Vector2(8 * TILE_SIZE, 7 * TILE_SIZE),
		Vector2(18 * TILE_SIZE, 11 * TILE_SIZE),
		Vector2(6 * TILE_SIZE, 14 * TILE_SIZE),
	]
	for i in mini(3, spawns.size()):
		enemy_factory.spawn_shadow_swarm(spawns[i] + Vector2(8, 6))
	enemy_factory.spawn_swamp_stalker(Vector2(22 * TILE_SIZE, 12 * TILE_SIZE))
	_refresh_enemy_minimap()


func _on_enemy_spawned(enemy: EnemyAIBase, _type: String) -> void:
	if enemy:
		_enemy_positions.append(enemy.global_position)


func _refresh_enemy_minimap() -> void:
	if _minimap == null:
		return
	var live: Array[Vector2] = []
	for node in enemies_layer.get_children():
		if node is EnemyAIBase and is_instance_valid(node):
			live.append(node.global_position)
	_minimap.set_enemy_world_positions(live, TILE_SIZE)


func _process(delta: float) -> void:
	if _player and _minimap:
		_minimap.reveal_at_world(_player.global_position, TILE_SIZE, 3)
	_refresh_enemy_minimap()
	_wave_timer -= delta
	if _wave_timer <= 0.0 and _player and session.is_alive():
		_wave_timer = WAVE_INTERVAL
		enemy_factory.spawn_jury_encounter(_player.global_position + Vector2(randf_range(-30.0, 30.0), -20.0))
	if _vignette_mat and _player:
		var stress := 1.0 - float(session.current_health) / float(session.max_health)
		_vignette_mat.set_shader_parameter("intensity", 0.72 + stress * 0.15)


func _draw() -> void:
	GothicTilePainter.draw_zone_map(self, _floors, [], _walls, "swamp")


func _spawn_ambient_motes() -> void:
	var motes := GPUParticles2D.new()
	motes.name = "AmbientMotes"
	motes.amount = 24
	motes.lifetime = 3.5
	motes.preprocess = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 160.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -6, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.9
	mat.color = Color(0.65, 0.7, 0.45, 0.35)
	motes.process_material = mat
	motes.position = Vector2(160, 90)
	add_child(motes)


func _show_intro() -> void:
	var intro_layer := CanvasLayer.new()
	intro_layer.layer = 50
	intro_layer.name = "IntroLayer"
	add_child(intro_layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 52)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.88)
	style.border_color = Color(0.55, 0.75, 0.4)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	intro_layer.add_child(panel)
	var lbl := Label.new()
	lbl.text = "EL PANTANO\n[A/D] Mover  [Espacio] Salto  [Shift] Dash  [J] Pulso\n[F1] Alto contraste  [ESC] Pausa"
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(0.62, 0.88, 0.52))
	panel.add_child(lbl)
	var timer := get_tree().create_timer(3.5)
	timer.timeout.connect(func():
		if is_instance_valid(intro_layer):
			intro_layer.queue_free()
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		accessibility.toggle_high_contrast()


func _toggle_pause() -> void:
	_is_paused = not _is_paused
	if _player:
		_player.input_locked = _is_paused
	if _is_paused:
		_show_pause_overlay()
	else:
		_hide_pause_overlay()


func _show_pause_overlay() -> void:
	if _pause_layer:
		return
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 80
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.05, 0.7)
	_pause_layer.add_child(bg)
	var lbl := Label.new()
	lbl.text = "PAUSA — ESC continuar"
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.82, 0.45))
	_pause_layer.add_child(lbl)


func _hide_pause_overlay() -> void:
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	_is_paused = false
	if _player:
		_player.input_locked = false


func _clear_stale_game_over_layers() -> void:
	for child in get_tree().root.get_children():
		if child is CanvasLayer and child.layer >= 200:
			child.queue_free()


func _ensure_camera_current() -> void:
	if _player and _player.camera:
		_player.camera.make_current()
