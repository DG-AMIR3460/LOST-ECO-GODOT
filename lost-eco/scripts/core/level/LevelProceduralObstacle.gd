extends Node
class_name LevelProceduralObstacle
## Dificultad máxima: picos ocultos, plataformas que caen y Ecos reubicados al iniciar.

signal generation_complete(stats: Dictionary)

@export var difficulty: float = 1.35
@export var spike_count: int = 14
@export var collapsing_platform_count: int = 7
@export var echo_relocate_count: int = 5
@export var seed_override: int = -1

const SPIKE_SCENE := preload("res://scenes/core/level/hidden_spike.tscn")
const COLLAPSE_SCENE := preload("res://scenes/core/level/collapsing_platform.tscn")
const ECHO_SCENE := preload("res://scenes/core/level/memory_echo.tscn")

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _floor_markers: Array[Vector2] = []
var _echo_parent: Node2D = null
var _hazard_parent: Node2D = null
var _exclude_positions: Array[Vector2] = []
var _exclude_radius: float = 56.0


func configure(
	echo_parent: Node2D,
	hazard_parent: Node2D,
	floor_positions: Array[Vector2],
	exclude_near: Array[Vector2] = [],
	exclude_radius: float = 56.0
) -> void:
	_echo_parent = echo_parent
	_hazard_parent = hazard_parent
	_floor_markers = floor_positions
	_exclude_positions = exclude_near
	_exclude_radius = exclude_radius


func generate() -> Dictionary:
	if _hazard_parent == null or _echo_parent == null:
		return {}
	if seed_override >= 0:
		_rng.seed = seed_override
	else:
		_rng.randomize()
	var mult := maxf(0.8, difficulty)
	var spikes_n := int(float(spike_count) * mult)
	var plat_n := int(float(collapsing_platform_count) * mult)
	var echo_n := echo_relocate_count
	var used: Dictionary = {}
	var stats := {"spikes": 0, "platforms": 0, "echos": 0, "difficulty": mult}
	var floors := _floor_markers.duplicate()
	floors.shuffle()
	var fi := 0
	for _i in spikes_n:
		if fi >= floors.size():
			break
		var pos := _pick_unique(floors, fi, used)
		fi += 1
		if pos.x > -99990.0:
			_spawn_spike(pos)
			stats["spikes"] += 1
	for _i in plat_n:
		if fi >= floors.size():
			break
		var pos := _pick_unique(floors, fi, used)
		fi += 1
		if pos.x > -99990.0:
			_spawn_collapse(pos, mult)
			stats["platforms"] += 1
	for _i in echo_n:
		if fi >= floors.size():
			break
		var pos := _pick_unique(floors, fi, used)
		fi += 1
		if pos.x > -99990.0:
			_spawn_echo(pos)
			stats["echos"] += 1
	generation_complete.emit(stats)
	return stats


func _pick_unique(floors: Array[Vector2], start_idx: int, used: Dictionary) -> Vector2:
	for i in range(start_idx, floors.size()):
		var base: Vector2 = floors[i]
		var key := str(base)
		if used.has(key):
			continue
		if _is_too_close_to_excludes(base):
			continue
		used[key] = true
		return base + Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-6.0, -2.0))
	return Vector2(-99999.0, -99999.0)


func _is_too_close_to_excludes(pos: Vector2) -> bool:
	for ex in _exclude_positions:
		if pos.distance_to(ex) < _exclude_radius:
			return true
	return false


func _spawn_spike(pos: Vector2) -> void:
	var s := SPIKE_SCENE.instantiate()
	_hazard_parent.add_child(s)
	s.global_position = pos


func _spawn_collapse(pos: Vector2, mult: float) -> void:
	var p := COLLAPSE_SCENE.instantiate()
	_hazard_parent.add_child(p)
	p.global_position = pos
	if p.has_method("set_difficulty"):
		p.set_difficulty(mult)


func _spawn_echo(pos: Vector2) -> void:
	var e := ECHO_SCENE.instantiate()
	_echo_parent.add_child(e)
	e.global_position = pos
