extends Area2D

signal collected

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collect_sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var light: PointLight2D = $PointLight2D

var time_elapsed: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.play("float")

func _process(delta: float) -> void:
	time_elapsed += delta
	if light:
		light.energy = 0.6 + sin(time_elapsed * 2.0) * 0.4

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	set_deferred("monitoring", false)
	if collect_sfx:
		collect_sfx.play()
	collected.emit()
	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
