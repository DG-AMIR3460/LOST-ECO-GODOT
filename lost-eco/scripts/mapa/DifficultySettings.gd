extends RefCounted
class_name DifficultySettings
## Multiplicadores de dificultad leídos desde SettingsManager.


static func get_index() -> int:
	if SettingsManager:
		return clampi(
			SettingsManager.difficulty_index,
			SettingsManager.Difficulty.FACIL,
			SettingsManager.Difficulty.DIFICIL
		)
	return 1


static func get_label(index: int = -1) -> String:
	var i := index if index >= 0 else get_index()
	match i:
		SettingsManager.Difficulty.FACIL:
			return "Fácil"
		SettingsManager.Difficulty.NORMAL:
			return "Normal"
		SettingsManager.Difficulty.DIFICIL:
			return "Difícil"
		_:
			return "Normal"


static func get_speed_mult() -> float:
	match get_index():
		SettingsManager.Difficulty.FACIL:
			return 0.78
		SettingsManager.Difficulty.DIFICIL:
			return 1.38
		_:
			return 1.0


static func get_enemy_count(base: int, zone: int) -> int:
	var bonus := 0
	match get_index():
		SettingsManager.Difficulty.FACIL:
			bonus = -2
		SettingsManager.Difficulty.DIFICIL:
			bonus = 2 + zone
		_:
			bonus = 1
	return maxi(2, base + bonus)


static func get_hit_cooldown(base: float) -> float:
	match get_index():
		SettingsManager.Difficulty.FACIL:
			return base * 1.45
		SettingsManager.Difficulty.DIFICIL:
			return base * 0.72
		_:
			return base


static func get_surge_wait(base_min: float, base_max: float) -> Vector2:
	match get_index():
		SettingsManager.Difficulty.FACIL:
			return Vector2(base_min * 1.35, base_max * 1.35)
		SettingsManager.Difficulty.DIFICIL:
			return Vector2(base_min * 0.62, base_max * 0.62)
		_:
			return Vector2(base_min, base_max)


static func get_light_radius_bonus() -> float:
	match get_index():
		SettingsManager.Difficulty.FACIL:
			return 0.08
		SettingsManager.Difficulty.DIFICIL:
			return -0.04
		_:
			return 0.0


static func pick_enemy_tiles(map: Array, count: int, avoid: Vector2i, min_dist: float = 96.0) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in map.size():
		var row: String = map[y]
		for x in row.length():
			var c: String = row[x]
			if c == "#" or c == "P" or c == "B":
				continue
			var tile: Vector2i = Vector2i(x, y)
			if tile.distance_to(avoid) * 16.0 < min_dist:
				continue
			candidates.append(tile)
	candidates.shuffle()
	var out: Array[Vector2i] = []
	for tile: Vector2i in candidates:
		if out.size() >= count:
			break
		var too_close := false
		for used: Vector2i in out:
			if used.distance_to(tile) < 4:
				too_close = true
				break
		if not too_close:
			out.append(tile)
	return out
