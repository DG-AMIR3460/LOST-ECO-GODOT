extends CharacterBody2D

@export var float_speed: float = 0.3
@export var float_amplitude: float = 4.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floating_label: Label = $FloatingTextLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var time_elapsed: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	base_y = global_position.y
	modulate.a = 0.0
	if anim_player and anim_player.has_animation("fade_in"):
		anim_player.play("fade_in")
	$InteractionArea.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	position.y = base_y + sin(time_elapsed * float_speed) * float_amplitude

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if anim_player and anim_player.has_animation("appear_and_fade"):
			anim_player.play("appear_and_fade")
		_show_floating_message()

func _show_floating_message() -> void:
	var stage = QuestManager.get_quest_stage("zone2")
	var messages: Array[String] = [
		"¿Me ves? Nadie me veía.",
		"Empujar no ayuda. Solo los hunde más.",
		"Construiste algo para que alguien pudiera cruzar."
	]
	floating_label.text = messages[clamp(stage, 0, messages.size() - 1)]
	floating_label.visible = true
	floating_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(floating_label, "modulate:a", 0.0, 2.0).set_delay(2.0)
	tween.tween_callback(func(): floating_label.visible = false)
