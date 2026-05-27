extends CharacterBody2D

enum State { IDLE, MIRRORING, CONFUSED, VULNERABLE, HEALING, DEFEATED }

@export var mirror_delay: float = 0.8
@export var attack_damage: float = 20.0
@export var confusion_time: float = 10.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var healing_particles: GPUParticles2D = $HealingParticles

var current_state: State = State.IDLE
var player_ref: CharacterBody2D = null
var action_queue: Array = []
var peaceful_timer: float = 0.0
var dodge_count: int = 0
var attack_multiplier: float = 1.0
var shake_time: float = 0.0
var base_x: float = 0.0

func _ready() -> void:
	base_x = global_position.x
	if sprite:
		sprite.play("idle_corrupt")
	$ArenaDetection.body_entered.connect(_on_player_entered_arena)

func _physics_process(delta: float) -> void:
	match current_state:
		State.MIRRORING:
			_process_mirroring(delta)
		State.CONFUSED:
			shake_time += delta
			position.x = base_x + sin(shake_time * 20.0) * 1.5
		State.VULNERABLE:
			_check_healing_input()

func _on_player_entered_arena(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		_change_state(State.MIRRORING)
		if player_ref.has_signal("action_performed"):
			player_ref.action_performed.connect(_queue_mirror_action)

func _queue_mirror_action(action_name: String, intensity: float) -> void:
	action_queue.append({
		"action": action_name,
		"intensity": intensity,
		"time": Time.get_ticks_msec() / 1000.0 + mirror_delay
	})
	if action_name == "attack":
		attack_multiplier = clamp(attack_multiplier + 0.3, 1.0, 3.0)
		peaceful_timer = 0.0

func _process_mirroring(delta: float) -> void:
	peaceful_timer += delta
	var current_time = Time.get_ticks_msec() / 1000.0
	var to_execute = action_queue.filter(func(a): return a["time"] <= current_time)
	for action in to_execute:
		_execute_mirror_action(action)
		action_queue.erase(action)
	if peaceful_timer >= confusion_time:
		_change_state(State.CONFUSED)
		_start_confusion()

func _execute_mirror_action(action: Dictionary) -> void:
	match action["action"]:
		"attack":
			if sprite:
				sprite.play("attack")
			if player_ref:
				var dir = (player_ref.global_position - global_position).normalized()
				_launch_crystal_shard(dir)
		"move":
			velocity = Vector2(-action["intensity"] * 60, 0)
			move_and_slide()

func _launch_crystal_shard(direction: Vector2) -> void:
	var shard_scene = load("res://scenes/enemies/CrystalShard.tscn")
	if shard_scene:
		var shard = shard_scene.instantiate()
		shard.global_position = global_position
		shard.set("direction", direction)
		shard.set("damage", attack_damage * attack_multiplier)
		get_parent().add_child(shard)

func _start_confusion() -> void:
	shake_time = 0.0
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 1.5)
	await get_tree().create_timer(3.0).timeout
	if current_state == State.CONFUSED:
		_change_state(State.VULNERABLE)
		if sprite:
			sprite.modulate = Color(1, 1, 1)

func _check_healing_input() -> void:
	if not player_ref:
		return
	var dist = global_position.distance_to(player_ref.global_position)
	if dist < 24 and Input.is_action_just_pressed("interact"):
		if not player_ref.has_weapon_equipped():
			_begin_healing()
		else:
			DialogueManager.show_floating_text(
				"Suelta el arma primero...",
				global_position + Vector2(0, -20),
				Color(1, 0.8, 0.4)
			)

func _begin_healing() -> void:
	_change_state(State.HEALING)
	if sprite:
		sprite.play("heal_transform")
	if healing_particles:
		healing_particles.emitting = true
	GameManager.update_empathy(0.34)
	AudioManager.play_sfx("heal_chime")
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.85, 0.2), 2.0)
	tween.tween_callback(_defeat)

func _defeat() -> void:
	_change_state(State.DEFEATED)
	QuestManager.advance_quest("zone3")
	if sprite:
		sprite.play("idle_corrupt")
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/world/Clearing.tscn")

func _change_state(new_state: State) -> void:
	current_state = new_state
