extends Control
class_name ZoneMinimap
## Minimapa compacto en esquina de pantalla.


const TILE_PX := 2.0

var _map: Array = []
var _cols: int = 0
var _rows: int = 0
var _echo_tiles: Array[Vector2i] = []
var _exit_tile: Vector2i = Vector2i(-1, -1)
var _boss_tile: Vector2i = Vector2i(-1, -1)
var _start_tile: Vector2i = Vector2i(-1, -1)

var _floor_color: Color = Color(0.18, 0.15, 0.22)
var _wall_color: Color = Color(0.08, 0.07, 0.12)
var _player_color: Color = Color(0.35, 0.75, 1.0)
var _echo_color: Color = Color(0.95, 0.90, 0.40)
var _exit_color: Color = Color(0.25, 0.90, 0.45)

var _player_tile: Vector2i = Vector2i.ZERO
var _echoes_left: int = 0
var _exit_open: bool = false


func setup(map: Array, colors: Dictionary = {}) -> void:
	_map = map
	_rows = map.size()
	_cols = map[0].length() if _rows > 0 else 0
	_floor_color = colors.get("floor", _floor_color)
	_wall_color = colors.get("wall", _wall_color)
	_player_color = colors.get("player", _player_color)
	_echo_color = colors.get("echo", _echo_color)
	_exit_color = colors.get("exit", _exit_color)

	_echo_tiles.clear()
	for y in _rows:
		for x in _cols:
			var c: String = map[y][x]
			match c:
				"E":
					_echo_tiles.append(Vector2i(x, y))
				"X":
					_exit_tile = Vector2i(x, y)
				"B":
					_boss_tile = Vector2i(x, y)
				"S":
					_start_tile = Vector2i(x, y)

	custom_minimum_size = Vector2(_cols * TILE_PX, _rows * TILE_PX + 8)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_player_world_pos(world_pos: Vector2, tile_size: float) -> void:
	if tile_size <= 0.0:
		return
	_player_tile = Vector2i(
		int(floor(world_pos.x / tile_size)),
		int(floor(world_pos.y / tile_size))
	)
	queue_redraw()


func set_echoes_remaining(count: int) -> void:
	_echoes_left = count
	queue_redraw()


func set_exit_open(open: bool) -> void:
	_exit_open = open
	queue_redraw()


func _draw() -> void:
	for y in _rows:
		for x in _cols:
			var tile := Vector2(x * TILE_PX, y * TILE_PX)
			var rect := Rect2(tile, Vector2(TILE_PX, TILE_PX))
			if _map[y][x] == "#":
				draw_rect(rect, _wall_color)
			else:
				draw_rect(rect, _floor_color)

	if _echoes_left > 0:
		for t in _echo_tiles:
			draw_rect(Rect2(t.x * TILE_PX, t.y * TILE_PX, TILE_PX, TILE_PX), _echo_color)

	if _exit_tile.x >= 0:
		var exit_c := _exit_color if _exit_open else Color(0.35, 0.35, 0.40)
		draw_rect(
			Rect2(_exit_tile.x * TILE_PX, _exit_tile.y * TILE_PX, TILE_PX, TILE_PX),
			exit_c
		)
	elif _boss_tile.x >= 0 and _exit_open:
		draw_rect(
			Rect2(_boss_tile.x * TILE_PX, _boss_tile.y * TILE_PX, TILE_PX, TILE_PX),
			_exit_color
		)

	if _player_tile.x >= 0 and _player_tile.y >= 0:
		draw_rect(
			Rect2(_player_tile.x * TILE_PX, _player_tile.y * TILE_PX, TILE_PX, TILE_PX),
			_player_color
		)
