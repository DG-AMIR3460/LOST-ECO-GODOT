extends Node2D

signal dialogue_triggered(npc_id: String)

@export var npc_id: String = "la_voz"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var whisper_area: Area2D = $WhisperAudioArea
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var player_in_range: bool = false
var dialogue_done: bool = false

func _ready() -> void:
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	whisper_area.body_entered.connect(_on_whisper_range_entered)
	whisper_area.body_exited.connect(_on_whisper_range_exited)
	if animated_sprite:
		animated_sprite.play("idle")

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if animated_sprite:
			animated_sprite.play("talking")
		GameManager.show_interact_prompt(true)

func _on_player_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if animated_sprite:
			animated_sprite.play("idle")
		GameManager.show_interact_prompt(false)

func _on_whisper_range_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not dialogue_done:
		audio_player.play()
		if animated_sprite:
			animated_sprite.speed_scale = 2.5

func _on_whisper_range_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		audio_player.stop()
		if animated_sprite:
			animated_sprite.speed_scale = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		_trigger_dialogue()

func _trigger_dialogue() -> void:
	var quest_stage = QuestManager.get_quest_stage("zone1")
	var dialogue_key = "la_voz_stage_" + str(quest_stage)
	DialogueManager.start_dialogue(dialogue_key, self)
	dialogue_triggered.emit(npc_id)

func mark_dialogue_complete() -> void:
	dialogue_done = true
	if animated_sprite:
		animated_sprite.play("idle")
