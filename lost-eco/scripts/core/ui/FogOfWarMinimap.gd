extends Control
class_name FogOfWarMinimap
## Grid procedural: revela celdas al recorrer coordenadas globales del jugador.

const TILE: float = 3.2
const PADDING: float = 4.0
const HEADER_H: float = 11.0

var _cols: int = 0
var _rows: int = 0
var _discovered: Dictionary = {}
var _floor_cells: Array[Vector2i] = []
var _wall_cells: Array[Vector2i] = []
var _echo_cells: Array[Vector2i] = []
var _collected_echoes: Array[Vector2i] = []
var _enemy_cells: Array[Vector2i] = []
var _player_cell: Vector2i = Vector2i(-1, -1)
var _pulse: float = 0.0
var _colors: Dictionary = {
	"floor": Color(0.14, 0.18, 0.12),
	"wall": Color(0.07, 0.06, 0.1),
	"player": Color(0.5, 0.88, 1.0),
	"echo": Color(1.0, 0.88, 0.35),
	"enemy": Color(0.95, 0.25, 0.32),
	"fog": Color(0.02, 0.02, 0.05, 0.75),
	"border": Color(0.72, 0.58, 0.22, 0.9),
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func setup_from_grid(grid: Array, colors: Dictionary = {}) -> void:
	for k in colors:
		_colors[k] = colors[k]
	_rows = grid.size()
	_cols = grid[0].length() if _rows > 0 else 0
	_floor_cells.clear()
	_wall_cells.clear()
	_echo_cells.clear()
	for y in _rows:
		for x in _cols:
			var c: String = grid[y][x]
			var cell := Vector2i(x, y)
			if c == "#":
				_wall_cells.append(cell)
			elif c != " ":
				_floor_cells.append(cell)
			if c == "E":
				_echo_cells.append(cell)
	custom_minimum_size = Vector2(_cols * TILE + PADDING * 2.0, _rows * TILE + PADDING * 2.0 + HEADER_H)
	size = custom_minimum_size
	queue_redraw()


func reveal_at_world(world_pos: Vector2, tile_size: float, radius: int = 3) -> void:
	if tile_size <= 0.0:
		return
	var cx := int(floor(world_pos.x / tile_size))
	var cy := int(floor(world_pos.y / tile_size))
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if abs(dx) + abs(dy) > radius + 1:
				continue
			_discovered[_cell_key(Vector2i(cx + dx, cy + dy))] = true
	_player_cell = Vector2i(cx, cy)
	queue_redraw()


func mark_echo_collected(cell: Vector2i) -> void:
	_collected_echoes.append(cell)
	queue_redraw()


func set_enemy_world_positions(positions: Array[Vector2], tile_size: float) -> void:
	_enemy_cells.clear()
	for pos in positions:
		_enemy_cells.append(Vector2i(int(floor(pos.x / tile_size)), int(floor(pos.y / tile_size))))


func _process(delta: float) -> void:
	_pulse += delta * 3.5
	queue_redraw()


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _draw() -> void:
	var origin := Vector2(PADDING, PADDING + HEADER_H)
	var map_size := Vector2(_cols * TILE, _rows * TILE)
	draw_string(ThemeDB.fallback_font, Vector2(PADDING, 9.0), "EL PANTANO", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, _colors["border"])
	draw_rect(Rect2(origin - Vector2(1, 1), map_size + Vector2(2, 2)), _colors["border"], false, 1.0)
	for y in _rows:
		for x in _cols:
			var cell := Vector2i(x, y)
			var r := Rect2(origin + Vector2(x * TILE, y * TILE), Vector2(TILE, TILE))
			if not _discovered.has(_cell_key(cell)):
				draw_rect(r, _colors["fog"])
	for cell in _floor_cells:
		if not _discovered.has(_cell_key(cell)):
			continue
		var r := Rect2(origin + Vector2(cell.x * TILE, cell.y * TILE), Vector2(TILE, TILE))
		draw_rect(r, _colors["floor"])
	for cell in _wall_cells:
		if not _discovered.has(_cell_key(cell)):
			continue
		var r := Rect2(origin + Vector2(cell.x * TILE, cell.y * TILE), Vector2(TILE, TILE))
		draw_rect(r, _colors["wall"])
	for cell in _echo_cells:
		if not _discovered.has(_cell_key(cell)):
			continue
		if cell in _collected_echoes:
			continue
		var r := Rect2(origin + Vector2(cell.x * TILE, cell.y * TILE), Vector2(TILE, TILE))
		var ecol: Color = _colors["echo"]
		ecol.a = 0.65 + sin(_pulse) * 0.35
		draw_rect(r.grow(-0.5), ecol)
	for cell in _enemy_cells:
		if not _discovered.has(_cell_key(cell)):
			continue
		var er := Rect2(origin + Vector2(cell.x * TILE, cell.y * TILE), Vector2(TILE, TILE))
		draw_rect(er.grow(-1.0), _colors["enemy"])
	if _player_cell.x >= 0:
		var pr := Rect2(origin + Vector2(_player_cell.x * TILE, _player_cell.y * TILE), Vector2(TILE, TILE))
		draw_rect(pr.grow(-0.8), _colors["player"])
