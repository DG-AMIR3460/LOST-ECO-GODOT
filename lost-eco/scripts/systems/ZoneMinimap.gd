extends Control
class_name ZoneMinimap
## Minimapa mejorado: panel, leyenda, ecos recolectados y enemigos.


const TILE_PX := 2.6
const PADDING := 4.0
const HEADER_H := 10.0
const LEGEND_H := 9.0

var _map: Array = []
var _cols: int = 0
var _rows: int = 0
var _echo_tiles: Array[Vector2i] = []
var _collected_echoes: Array[Vector2i] = []
var _enemy_tiles: Array[Vector2i] = []
var _exit_tile: Vector2i = Vector2i(-1, -1)
var _boss_tile: Vector2i = Vector2i(-1, -1)

var _floor_color: Color = Color(0.18, 0.15, 0.22)
var _wall_color: Color = Color(0.08, 0.07, 0.12)
var _player_color: Color = Color(0.40, 0.82, 1.0)
var _echo_color: Color = Color(0.98, 0.92, 0.38)
var _exit_color: Color = Color(0.28, 0.92, 0.48)
var _enemy_color: Color = Color(0.92, 0.28, 0.32)
var _border_color: Color = Color(0.85, 0.72, 0.28, 0.85)

var _player_tile: Vector2i = Vector2i(-1, -1)
var _display_player: Vector2 = Vector2.ZERO
var _echoes_left: int = 0
var _exit_open: bool = false
var _pulse: float = 0.0
var _map_origin: Vector2 = Vector2.ZERO
var _map_size: Vector2 = Vector2.ZERO
var _fog_enabled: bool = false
var _discovered: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func setup(map: Array, colors: Dictionary = {}) -> void:
	_map = map
	_rows = map.size()
	_cols = map[0].length() if _rows > 0 else 0
	_floor_color = colors.get("floor", _floor_color)
	_wall_color = colors.get("wall", _wall_color)
	_player_color = colors.get("player", _player_color)
	_echo_color = colors.get("echo", _echo_color)
	_exit_color = colors.get("exit", _exit_color)
	_enemy_color = colors.get("enemy", _enemy_color)
	_border_color = colors.get("border", _border_color)

	_echo_tiles.clear()
	_collected_echoes.clear()
	_enemy_tiles.clear()
	for y in _rows:
		for x in _cols:
			match map[y][x]:
				"E":
					_echo_tiles.append(Vector2i(x, y))
				"X":
					_exit_tile = Vector2i(x, y)
				"B":
					_boss_tile = Vector2i(x, y)

	_map_size = Vector2(_cols * TILE_PX, _rows * TILE_PX)
	_map_origin = Vector2(PADDING, PADDING + HEADER_H)
	var total_w := _map_size.x + PADDING * 2.0
	var total_h := HEADER_H + _map_size.y + LEGEND_H + PADDING * 2.0
	custom_minimum_size = Vector2(total_w, total_h)
	size = custom_minimum_size
	queue_redraw()


func enable_fog_of_war() -> void:
	_fog_enabled = true
	_discovered.clear()


func reveal_near(tile: Vector2i, radius: int = 3) -> void:
	if not _fog_enabled:
		return
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var t := Vector2i(tile.x + dx, tile.y + dy)
			_discovered[str(t)] = true


func set_player_world_pos(world_pos: Vector2, tile_size: float) -> void:
	if tile_size <= 0.0:
		return
	_player_tile = Vector2i(
		int(floor(world_pos.x / tile_size)),
		int(floor(world_pos.y / tile_size))
	)
	if _fog_enabled:
		reveal_near(_player_tile, 3)
	var target := _map_origin + Vector2(
		(_player_tile.x + 0.5) * TILE_PX,
		(_player_tile.y + 0.5) * TILE_PX
	)
	if _display_player == Vector2.ZERO:
		_display_player = target
	queue_redraw()


func set_echoes_remaining(count: int) -> void:
	_echoes_left = count
	queue_redraw()


func set_exit_open(open: bool) -> void:
	_exit_open = open
	queue_redraw()


func mark_echo_collected_at(world_pos: Vector2, tile_size: float) -> void:
	if tile_size <= 0.0:
		return
	var tile := Vector2i(
		int(floor(world_pos.x / tile_size)),
		int(floor(world_pos.y / tile_size))
	)
	if tile not in _collected_echoes:
		_collected_echoes.append(tile)
	queue_redraw()


func set_enemy_tiles(tiles: Array[Vector2i]) -> void:
	_enemy_tiles = tiles
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 3.5
	if _player_tile.x >= 0:
		var target := _map_origin + Vector2(
			(_player_tile.x + 0.5) * TILE_PX,
			(_player_tile.y + 0.5) * TILE_PX
		)
		_display_player = _display_player.lerp(target, minf(1.0, delta * 14.0))
		queue_redraw()


func _draw() -> void:
	var total := size
	draw_rect(Rect2(Vector2.ZERO, total), Color(0.03, 0.025, 0.06, 0.92))
	draw_rect(Rect2(Vector2(0.5, 0.5), total - Vector2(1, 1)), _border_color, false, 1.0)

	_draw_label(Vector2(PADDING, 2.0), "MAPA", Color(0.92, 0.84, 0.45), 8)

	for y in _rows:
		for x in _cols:
			var tile := Vector2i(x, y)
			var pos := _map_origin + Vector2(x * TILE_PX, y * TILE_PX)
			var rect := Rect2(pos, Vector2(TILE_PX, TILE_PX))
			var known := not _fog_enabled or _discovered.has(str(tile))
			if not known:
				draw_rect(rect, Color(0.02, 0.02, 0.04, 0.92))
				continue
			if _map[y][x] == "#":
				_draw_wall_tile(rect)
			else:
				_draw_floor_tile(rect)

	for t in _enemy_tiles:
		_draw_enemy_marker(_tile_center(t))

	for t in _echo_tiles:
		if t in _collected_echoes:
			continue
		var pulse_a := 0.65 + sin(_pulse + t.x * 0.4 + t.y * 0.3) * 0.35
		_draw_echo_marker(_tile_center(t), Color(_echo_color.r, _echo_color.g, _echo_color.b, pulse_a))

	if _exit_tile.x >= 0:
		var exit_c := _exit_color if _exit_open else Color(0.32, 0.32, 0.38)
		if _exit_open:
			exit_c = exit_c.lightened(sin(_pulse) * 0.12)
		draw_rect(
			Rect2(_map_origin + Vector2(_exit_tile.x * TILE_PX, _exit_tile.y * TILE_PX), Vector2(TILE_PX, TILE_PX)),
			exit_c
		)
	elif _boss_tile.x >= 0:
		var boss_c := _exit_color if _exit_open else Color(0.38, 0.18, 0.52)
		if _exit_open:
			boss_c = boss_c.lightened(sin(_pulse) * 0.15)
		draw_rect(
			Rect2(_map_origin + Vector2(_boss_tile.x * TILE_PX, _boss_tile.y * TILE_PX), Vector2(TILE_PX, TILE_PX)),
			boss_c
		)

	if _display_player != Vector2.ZERO:
		var tri := PackedVector2Array([
			_display_player + Vector2(0, -4), _display_player + Vector2(3.5, 3),
			_display_player + Vector2(-3.5, 3),
		])
		draw_colored_polygon(tri, Color(1, 1, 1, 0.25))
		draw_colored_polygon(tri, _player_color)
		draw_circle(_display_player, 1.2, Color(0.95, 0.95, 1.0))

	var legend_y := _map_origin.y + _map_size.y + 2.0
	_draw_legend(Vector2(PADDING, legend_y))


func _tile_center(tile: Vector2i) -> Vector2:
	return _map_origin + Vector2((tile.x + 0.5) * TILE_PX, (tile.y + 0.5) * TILE_PX)


func _draw_echo_marker(center: Vector2, color: Color) -> void:
	var star := PackedVector2Array()
	for i in 5:
		var a := TAU * float(i) / 5.0 - PI * 0.5
		var r := TILE_PX * 0.38 if i % 2 == 0 else TILE_PX * 0.16
		star.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(star, Color(color.r, color.g, color.b, color.a * 0.35))
	draw_colored_polygon(star, color)


func _draw_floor_tile(rect: Rect2) -> void:
	draw_rect(rect, _floor_color.darkened(0.08))
	draw_rect(rect.grow(-0.6), _floor_color.lightened(0.06))


func _draw_wall_tile(rect: Rect2) -> void:
	draw_rect(rect, _wall_color)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), _wall_color.lightened(0.12), 1.0)


func _draw_enemy_marker(center: Vector2) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -3.2), center + Vector2(2.8, 2.2), center + Vector2(-2.8, 2.2),
	])
	draw_colored_polygon(pts, Color(_enemy_color.r, _enemy_color.g, _enemy_color.b, 0.85))
	draw_circle(center + Vector2(0, -0.5), 1.0, Color(1.0, 0.2, 0.25))


func _draw_legend(origin: Vector2) -> void:
	var items: Array = [
		[_player_color, "Tú"],
		[_echo_color, "Eco"],
		[_exit_color, "Fin"],
		[_enemy_color, "Enm"],
	]
	var x := origin.x
	for item in items:
		draw_circle(Vector2(x + 2.0, origin.y + 4.5), 1.8, item[0])
		_draw_label(Vector2(x + 5.0, origin.y), item[1], Color(0.68, 0.68, 0.74), 6)
		x += 20.0


func _draw_label(pos: Vector2, text: String, color: Color, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
