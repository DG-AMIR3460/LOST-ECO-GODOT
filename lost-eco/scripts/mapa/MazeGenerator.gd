extends RefCounted
class_name MazeGenerator
## Generadores de mapas distintos por zona.


static func build_zone1_labyrinth() -> Array:
	const W := 49
	const H := 33
	var grid := _solid_grid(W, H)
	_carve_recursive_backtracker(grid, W, H, Vector2i(1, 1))
	_add_loops(grid, W, H, 28)
	_set_cell(grid, Vector2i(1, 1), "S")
	var floors := _collect_floor_tiles(grid)
	var exit_cell := _farthest_tile(floors, Vector2i(1, 1))
	_set_cell(grid, exit_cell, "X")
	for p: Vector2i in _pick_spread_tiles(floors, Vector2i(1, 1), exit_cell, 4):
		if _get_cell(grid, p) == ".":
			_set_cell(grid, p, "E")
	return _normalize_grid(grid, W)


static func build_zone2_swamp() -> Array:
	const W := 41
	const H := 25
	var grid := _solid_grid(W, H)
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			_set_cell(grid, Vector2i(x, y), ".")
	for band in [6, 12, 18]:
		for x in range(2, W - 2):
			if x % 9 != 3 and x % 9 != 4:
				_set_cell(grid, Vector2i(x, band), "#")
	for x in range(1, W - 1):
		if x % 7 != 2:
			_set_cell(grid, Vector2i(x, 9), "#")
	_set_cell(grid, Vector2i(2, 2), "S")
	_set_cell(grid, Vector2i(5, 4), "E")
	_set_cell(grid, Vector2i(28, 7), "E")
	_set_cell(grid, Vector2i(14, 15), "E")
	_set_cell(grid, Vector2i(34, 21), "X")
	_set_cell(grid, Vector2i(10, 5), "P")
	_set_cell(grid, Vector2i(22, 11), "P")
	_set_cell(grid, Vector2i(30, 17), "P")
	return _normalize_grid(grid, W)


static func build_zone3_cave() -> Array:
	const W := 41
	const H := 27
	var grid := _solid_grid(W, H)
	_carve_room(grid, Rect2i(2, 2, 10, 6))
	_carve_room(grid, Rect2i(14, 2, 10, 6))
	_carve_room(grid, Rect2i(26, 2, 10, 6))
	_carve_room(grid, Rect2i(6, 11, 12, 6))
	_carve_room(grid, Rect2i(22, 11, 12, 6))
	_carve_room(grid, Rect2i(14, 19, 12, 5))
	_connect_rooms(grid, Vector2i(11, 5), Vector2i(14, 5))
	_connect_rooms(grid, Vector2i(24, 5), Vector2i(26, 5))
	_connect_rooms(grid, Vector2i(7, 8), Vector2i(7, 11))
	_connect_rooms(grid, Vector2i(31, 8), Vector2i(31, 11))
	_connect_rooms(grid, Vector2i(18, 17), Vector2i(18, 19))
	_connect_rooms(grid, Vector2i(12, 14), Vector2i(14, 14))
	_connect_rooms(grid, Vector2i(22, 14), Vector2i(22, 14))
	_set_cell(grid, Vector2i(3, 3), "S")
	_set_cell(grid, Vector2i(18, 4), "E")
	_set_cell(grid, Vector2i(8, 14), "E")
	_set_cell(grid, Vector2i(30, 14), "E")
	_set_cell(grid, Vector2i(20, 22), "B")
	return _normalize_grid(grid, W)


static func build_zone4_river() -> Array:
	const W := 45
	const H := 25
	var grid := _solid_grid(W, H)
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			_set_cell(grid, Vector2i(x, y), ".")
	for y in range(3, H - 3):
		if not (y in [6, 13, 20]):
			_set_cell(grid, Vector2i(22, y), "#")
	for island: Vector2i in [Vector2i(12, 8), Vector2i(30, 6), Vector2i(16, 16), Vector2i(32, 15)]:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				_set_cell(grid, island + Vector2i(dx, dy), "#")
	for x in range(18, 27):
		_set_cell(grid, Vector2i(x, 10), "#")
	_set_cell(grid, Vector2i(21, 10), ".")
	_set_cell(grid, Vector2i(3, 3), "S")
	_set_cell(grid, Vector2i(8, 5), "E")
	_set_cell(grid, Vector2i(36, 4), "E")
	_set_cell(grid, Vector2i(10, 17), "E")
	_set_cell(grid, Vector2i(40, 21), "X")
	return _normalize_grid(grid, W)


static func _solid_grid(w: int, h: int) -> Array:
	var grid: Array = []
	for _y in h:
		grid.append("#".repeat(w))
	return grid


static func _carve_recursive_backtracker(grid: Array, w: int, h: int, start: Vector2i) -> void:
	var stack: Array[Vector2i] = [start]
	_set_cell(grid, start, ".")
	var dirs: Array[Vector2i] = [
		Vector2i(0, -2), Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, 0)
	]
	while not stack.is_empty():
		var cell: Vector2i = stack[-1]
		var neighbors: Array[Vector2i] = []
		for dir_step: Vector2i in dirs:
			var nxt: Vector2i = cell + dir_step
			if nxt.x <= 0 or nxt.x >= w - 1 or nxt.y <= 0 or nxt.y >= h - 1:
				continue
			if _get_cell(grid, nxt) == "#":
				neighbors.append(dir_step)
		if neighbors.is_empty():
			stack.pop_back()
		else:
			var chosen: Vector2i = neighbors[randi() % neighbors.size()]
			var mid: Vector2i = cell + Vector2i(int(chosen.x / 2), int(chosen.y / 2))
			var next_cell: Vector2i = cell + chosen
			_set_cell(grid, mid, ".")
			_set_cell(grid, next_cell, ".")
			stack.append(next_cell)


static func _add_loops(grid: Array, w: int, h: int, count: int) -> void:
	var tries := 0
	var added := 0
	while added < count and tries < count * 12:
		tries += 1
		var x := randi_range(2, w - 3)
		var y := randi_range(2, h - 3)
		if _get_cell(grid, Vector2i(x, y)) != "#":
			continue
		var open_neighbors := 0
		var probe_dirs: Array[Vector2i] = [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
		]
		for d: Vector2i in probe_dirs:
			if _get_cell(grid, Vector2i(x, y) + d) == ".":
				open_neighbors += 1
		if open_neighbors >= 2:
			_set_cell(grid, Vector2i(x, y), ".")
			added += 1


static func _carve_room(grid: Array, room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			_set_cell(grid, Vector2i(x, y), ".")


static func _connect_rooms(grid: Array, a: Vector2i, b: Vector2i) -> void:
	var x: int = a.x
	while x != b.x:
		_set_cell(grid, Vector2i(x, a.y), ".")
		x += 1 if b.x > x else -1
	var y: int = a.y
	while y != b.y:
		_set_cell(grid, Vector2i(b.x, y), ".")
		y += 1 if b.y > y else -1
	_set_cell(grid, b, ".")


static func _collect_floor_tiles(grid: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var c: String = row[x]
			if c == "." or c == "S" or c == "E" or c == "X":
				out.append(Vector2i(x, y))
	return out


static func _farthest_tile(tiles: Array[Vector2i], origin: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_dist: float = -1.0
	for t: Vector2i in tiles:
		var d: float = float(origin.distance_squared_to(t))
		if d > best_dist:
			best_dist = d
			best = t
	return best


static func _pick_spread_tiles(tiles: Array[Vector2i], start: Vector2i, exit_cell: Vector2i, count: int) -> Array[Vector2i]:
	var ranked: Array = []
	for t: Vector2i in tiles:
		if t == start or t == exit_cell:
			continue
		if _get_cell_at_tiles(tiles, t) == "#":
			continue
		var score: float = float(start.distance_to(t)) + float(t.distance_to(exit_cell)) * 0.35
		ranked.append({"tile": t, "score": score})
	ranked.sort_custom(func(a, b): return a["score"] > b["score"])
	var out: Array[Vector2i] = []
	for entry: Dictionary in ranked:
		if out.size() >= count:
			break
		var tile: Vector2i = entry["tile"]
		var ok: bool = true
		for used: Vector2i in out:
			if used.distance_to(tile) < 6:
				ok = false
				break
		if ok:
			out.append(tile)
	return out


static func _get_cell_at_tiles(_tiles: Array[Vector2i], _tile: Vector2i) -> String:
	return "."


static func _get_cell(grid: Array, pos: Vector2i) -> String:
	var row: String = grid[pos.y]
	return row.substr(pos.x, 1)


static func _normalize_grid(grid: Array, width: int) -> Array:
	for i in grid.size():
		var row: String = grid[i]
		if row.length() < width:
			row = row + "#".repeat(width - row.length())
		elif row.length() > width:
			row = row.substr(0, width)
		grid[i] = row
	return grid


static func _set_cell(grid: Array, pos: Vector2i, ch: String) -> void:
	if pos.y < 0 or pos.y >= grid.size():
		return
	var row: String = grid[pos.y]
	if pos.x < 0 or pos.x >= row.length():
		return
	grid[pos.y] = row.substr(0, pos.x) + ch + row.substr(pos.x + 1, row.length() - pos.x - 1)
