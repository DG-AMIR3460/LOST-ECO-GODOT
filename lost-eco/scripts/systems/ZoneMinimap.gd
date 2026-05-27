extends Control
class_name ZoneMinimap
## Minimapa compacto con niebla de exploración (se descubre al caminar).


const TILE_PX := 2.0
const PADDING := 1.0
const HEADER_H := 5.0
const LEGEND_H := 12.0

var _map: Array = []
var _cols: int = 0
var _rows: int = 0
var _echo_tiles: Array[Vector2i] = []
var _collected_echoes: Array[Vector2i] = []
var _enemy_tiles: Array[Vector2i] = []
var _pillar_tiles: Array[Vector2i] = []
var _activated_pillars: Array[Vector2i] = []
var _exit_tile: Vector2i = Vector2i(-1, -1)
var _boss_tile: Vector2i = Vector2i(-1, -1)

var _floor_color: Color = Color(0.22, 0.18, 0.28)
var _wall_color: Color = Color(0.10, 0.08, 0.14)
var _player_color: Color = Color(0.45, 0.88, 1.0)
var _echo_color: Color = Color(0.98, 0.92, 0.38)
var _exit_color: Color = Color(0.28, 0.92, 0.48)
var _enemy_color: Color = Color(0.95, 0.32, 0.38)
var _pillar_color: Color = Color(0.90, 0.62, 0.22)
var _border_color: Color = Color(0.90, 0.78, 0.35, 0.95)
var _fog_undiscovered: Color = Color(0.04, 0.03, 0.07, 0.95)

var _player_tile: Vector2i = Vector2i(-1, -1)
var _display_player: Vector2 = Vector2.ZERO
var _echoes_left: int = 0
var _exit_open: bool = false
var _pulse: float = 0.0
var _map_origin: Vector2 = Vector2.ZERO
var _map_size: Vector2 = Vector2.ZERO
var _fog_enabled: bool = false
var _discovered: Dictionary = {}
var _reveal_radius: int = 4


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func setup(map: Array, colors: Dictionary = {}, _compact: bool = true) -> void:
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
	_pillar_tiles.clear()
	_activated_pillars.clear()
	for y in _rows:
		for x in _cols:
			match map[y][x]:
				"E":
					_echo_tiles.append(Vector2i(x, y))
				"X":
					_exit_tile = Vector2i(x, y)
				"B":
					_boss_tile = Vector2i(x, y)
				"P":
					_pillar_tiles.append(Vector2i(x, y))

	_recalc_size()
	queue_redraw()


func _recalc_size() -> void:
	_map_size = Vector2(_cols * TILE_PX, _rows * TILE_PX)
	_map_origin = Vector2(PADDING, PADDING + HEADER_H)
	var total_w := _map_size.x + PADDING * 2.0
	var total_h := HEADER_H + _map_size.y + LEGEND_H + PADDING * 2.0
	custom_minimum_size = Vector2(total_w, total_h)
	size = custom_minimum_size


func enable_fog_of_war(reveal_radius: int = 4) -> void:
	_fog_enabled = true
	_reveal_radius = reveal_radius
	_discovered.clear()
	for y in _rows:
		for x in _cols:
			if _map[y][x] == "S":
				reveal_near(Vector2i(x, y), reveal_radius + 1)
				return


func reveal_near(tile: Vector2i, radius: int = -1) -> void:
	if not _fog_enabled:
		return
	var r := radius if radius >= 0 else _reveal_radius
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if Vector2(dx, dy).length() > float(r) + 0.5:
				continue
			var t := Vector2i(tile.x + dx, tile.y + dy)
			if t.x < 0 or t.y < 0 or t.x >= _cols or t.y >= _rows:
				continue
			_discovered[_tile_key(t)] = true


func set_player_world_pos(world_pos: Vector2, tile_size: float) -> void:
	if tile_size <= 0.0:
		return
	_player_tile = Vector2i(
		int(floor(world_pos.x / tile_size)),
		int(floor(world_pos.y / tile_size))
	)
	if _fog_enabled:
		reveal_near(_player_tile, _reveal_radius)
	var target := _tile_center(_player_tile)
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


func mark_pillar_activated_at(world_pos: Vector2, tile_size: float) -> void:
	if tile_size <= 0.0:
		return
	var tile := Vector2i(
		int(floor(world_pos.x / tile_size)),
		int(floor(world_pos.y / tile_size))
	)
	if tile not in _activated_pillars:
		_activated_pillars.append(tile)
	queue_redraw()


func set_enemy_tiles(tiles: Array[Vector2i]) -> void:
	_enemy_tiles = tiles
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 3.5
	if _player_tile.x >= 0:
		var target := _tile_center(_player_tile)
		_display_player = _display_player.lerp(target, minf(1.0, delta * 14.0))
		queue_redraw()


func _draw() -> void:
	var total := size
	draw_rect(Rect2(Vector2.ZERO, total), Color(0.07, 0.06, 0.11, 0.96))
	draw_rect(Rect2(Vector2(0.5, 0.5), total - Vector2(1, 1)), _border_color, false, 1.0)
	_draw_label(Vector2(PADDING, 0.0), "M", Color(0.88, 0.82, 0.45), 5)

	for y in _rows:
		for x in _cols:
			var tile := Vector2i(x, y)
			var pos := _map_origin + Vector2(x * TILE_PX, y * TILE_PX)
			var rect := Rect2(pos, Vector2(TILE_PX, TILE_PX))
			if not _is_discovered(tile):
				draw_rect(rect, _fog_undiscovered)
				continue
			if _map[y][x] == "#":
				_draw_wall_tile(rect)
			else:
				_draw_floor_tile(rect)

	for t in _enemy_tiles:
		if _is_discovered(t):
			_draw_enemy_marker(_tile_center(t))

	for t in _echo_tiles:
		if t in _collected_echoes or not _is_discovered(t):
			continue
		var pulse_a := 0.65 + sin(_pulse + t.x * 0.4 + t.y * 0.3) * 0.35
		_draw_echo_marker(_tile_center(t), Color(_echo_color.r, _echo_color.g, _echo_color.b, pulse_a))

	for t in _pillar_tiles:
		if not _is_discovered(t):
			continue
		var pc := _pillar_color.lightened(0.35) if t in _activated_pillars else _pillar_color
		var pa := 0.55 if t in _activated_pillars else (0.55 + sin(_pulse * 1.2 + t.x + t.y) * 0.35)
		var center_p := _tile_center(t)
		draw_circle(center_p, TILE_PX * 0.52, Color(pc.r, pc.g, pc.b, pa * 0.45))
		draw_circle(center_p, TILE_PX * 0.30, Color(pc.r, pc.g, pc.b, pa))

	if _exit_tile.x >= 0 and (_is_discovered(_exit_tile) or _exit_open):
		var exit_c := _exit_color if _exit_open else Color(0.38, 0.38, 0.45)
		if _exit_open:
			exit_c = exit_c.lightened(sin(_pulse) * 0.12)
		draw_rect(
			Rect2(_map_origin + Vector2(_exit_tile.x * TILE_PX, _exit_tile.y * TILE_PX), Vector2(TILE_PX, TILE_PX)),
			exit_c
		)
	elif _boss_tile.x >= 0 and (_is_discovered(_boss_tile) or _exit_open):
		var boss_c := _exit_color if _exit_open else Color(0.42, 0.20, 0.55)
		draw_rect(
			Rect2(_map_origin + Vector2(_boss_tile.x * TILE_PX, _boss_tile.y * TILE_PX), Vector2(TILE_PX, TILE_PX)),
			boss_c
		)

	if _display_player != Vector2.ZERO:
		var s := 2.6
		var tri := PackedVector2Array([
			_display_player + Vector2(0, -s), _display_player + Vector2(s * 0.9, s * 0.85),
			_display_player + Vector2(-s * 0.9, s * 0.85),
		])
		draw_colored_polygon(tri, Color(1, 1, 1, 0.35))
		draw_colored_polygon(tri, _player_color)

	var legend_y := _map_origin.y + _map_size.y + 1.0
	_draw_legend(Vector2(PADDING, legend_y))


func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]


func _is_discovered(tile: Vector2i) -> bool:
	return not _fog_enabled or _discovered.has(_tile_key(tile))


func _tile_center(tile: Vector2i) -> Vector2:
	return _map_origin + Vector2((tile.x + 0.5) * TILE_PX, (tile.y + 0.5) * TILE_PX)


func _draw_echo_marker(center: Vector2, color: Color) -> void:
	draw_circle(center, TILE_PX * 0.22, Color(color.r, color.g, color.b, color.a * 0.4))
	draw_circle(center, TILE_PX * 0.14, color)


func _draw_floor_tile(rect: Rect2) -> void:
	draw_rect(rect, _floor_color.darkened(0.06))
	draw_rect(rect.grow(-0.4), _floor_color.lightened(0.08))


func _draw_wall_tile(rect: Rect2) -> void:
	draw_rect(rect, _wall_color)


func _draw_enemy_marker(center: Vector2) -> void:
	draw_circle(center, 1.4, _enemy_color)


func _draw_legend(origin: Vector2) -> void:
	var lc := Color(0.86, 0.86, 0.92)
	var row1: Array = [
		[_player_color, "Tu"],
		[_echo_color, "E"],
		[_exit_color, "X"],
	]
	var x := origin.x
	for item in row1:
		draw_circle(Vector2(x + 2.0, origin.y + 3.5), 1.8, item[0])
		_draw_label(Vector2(x + 5.0, origin.y), item[1], lc, 7)
		x += 17.0

	var row2: Array = [[_enemy_color, "!"]]
	if not _pillar_tiles.is_empty():
		row2.append([_pillar_color, "P"])
	x = origin.x
	for item in row2:
		draw_circle(Vector2(x + 2.0, origin.y + 9.5), 1.8, item[0])
		_draw_label(Vector2(x + 5.0, origin.y + 6.0), item[1], lc, 7)
		x += 17.0


func _draw_label(pos: Vector2, text: String, color: Color, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
