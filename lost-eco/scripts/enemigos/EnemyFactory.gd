extends Node
class_name EnemyFactory
## Factory Method completo: Shadow Swarm + Swamp Stalker + oleadas de dificultad.

signal enemy_spawned(enemy: EnemyAIBase, enemy_type: String)
signal spawn_failed(enemy_type: String, reason: String)
signal wave_spawned(wave_index: int, count: int)

const SHADOW_SCENE := preload("res://scenes/core/enemies/shadow_swarm.tscn")
const STALKER_SCENE := preload("res://scenes/core/enemies/swamp_stalker.tscn")

const BULLYING_PHRASES: Array[String] = [
	"No vales nada",
	"Loser",
	"You suck!",
	"Nadie te quiere",
	"Eres un error",
	"Desaparece",
]

var _player: PlayerController2D = null
var _container: Node2D = null
var _difficulty: float = 1.0
var _spawned_total: int = 0


func configure(container: Node2D, player: PlayerController2D, difficulty: float = 1.0) -> void:
	_container = container
	_player = player
	_difficulty = maxf(0.5, difficulty)


func set_difficulty(multiplier: float) -> void:
	_difficulty = maxf(0.5, multiplier)


func spawn_shadow_swarm(world_pos: Vector2) -> EnemyAIBase:
	var enemy := _spawn(SHADOW_SCENE, "shadow_swarm", world_pos) as ShadowSwarmEnemy
	if enemy:
		enemy.apply_difficulty(_difficulty)
	return enemy


func spawn_swamp_stalker(world_pos: Vector2) -> EnemyAIBase:
	var enemy := _spawn(STALKER_SCENE, "swamp_stalker", world_pos) as SwampStalkerEnemy
	if enemy:
		enemy.apply_difficulty(_difficulty)
		enemy.set_phrase_pool(BULLYING_PHRASES)
	return enemy


func spawn_jury_encounter(anchor: Vector2) -> void:
	var count := int(3.0 + _difficulty * 2.0)
	var types: Array[String] = []
	var positions: Array[Vector2] = []
	for i in count:
		positions.append(anchor + Vector2(randf_range(-48.0, 48.0), randf_range(-20.0, 20.0)))
		types.append("shadow" if i % 3 != 2 else "stalker")
	spawn_batch(positions, types)
	wave_spawned.emit(int(_difficulty), count)


func spawn_batch(positions: Array, types: Array) -> void:
	for i in mini(positions.size(), types.size()):
		var pos: Vector2 = positions[i]
		var t: String = str(types[i])
		if t == "shadow" or t == "shadow_swarm":
			spawn_shadow_swarm(pos)
		elif t == "stalker" or t == "swamp_stalker":
			spawn_swamp_stalker(pos)


func _spawn(scene: PackedScene, type_name: String, world_pos: Vector2) -> EnemyAIBase:
	if _container == null:
		spawn_failed.emit(type_name, "container_no_configurado")
		return null
	var instance := scene.instantiate()
	if not instance is EnemyAIBase:
		instance.queue_free()
		spawn_failed.emit(type_name, "escena_invalida")
		return null
	var enemy := instance as EnemyAIBase
	_container.add_child(enemy)
	enemy.global_position = world_pos
	if _player:
		enemy.inject_player(_player)
	_spawned_total += 1
	enemy_spawned.emit(enemy, type_name)
	return enemy
