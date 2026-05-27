extends Area2D

signal fragment_collected(fragment_data: Dictionary)

@export var fragment_id: int = 0
@export var fragment_text: String = ""
@export var orb_color: Color = Color.CYAN

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var collect_sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_collected: bool = false
var time_elapsed: float = 0.0

func _ready() -> void:
	if sprite:
		sprite.modulate = orb_color
		sprite.play("float")
	if light:
		light.color = orb_color
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_elapsed += delta
	if light:
		light.energy = 0.8 + sin(time_elapsed * 3.0) * 0.3
	# Flotación suave
	if sprite:
		sprite.position.y = sin(time_elapsed * 1.5) * 4.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_collected:
		_collect()

func _collect() -> void:
	is_collected = true
	set_deferred("monitoring", false)
	if collect_sfx:
		collect_sfx.play()
	DialogueManager.show_memory_fragment(fragment_id, fragment_text, orb_color)
	QuestManager.collect_memory()
	fragment_collected.emit({"id": fragment_id, "text": fragment_text})
	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.4)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	if light:
		tween.tween_property(light, "energy", 0.0, 0.4)
	tween.chain().tween_callback(queue_free)
