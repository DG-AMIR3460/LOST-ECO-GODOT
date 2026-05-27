extends Area2D
class_name MemoryEcho
## Fragmento de memoria (ECO) con aura dorada y PointLight2D.

signal collected(echo: MemoryEcho)

@onready var glow: PointLight2D = $Glow
@onready var core: Polygon2D = $Core

var _collected: bool = false
var _time: float = 0.0


func _ready() -> void:
	add_to_group("memory_fragment")
	body_entered.connect(_on_body_entered)
	if glow:
		glow.color = Color(1.0, 0.92, 0.65)
		glow.energy = 0.75
	if core:
		core.color = Color(1.0, 0.88, 0.45, 0.9)


func _process(delta: float) -> void:
	_time += delta
	if core:
		core.position.y = sin(_time * 2.2) * 3.0
	if glow:
		glow.energy = 0.65 + sin(_time * 3.0) * 0.2


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is PlayerController2D:
		_collect(body)


func _collect(player: PlayerController2D) -> void:
	_collected = true
	set_deferred("monitoring", false)
	if player.session:
		player.session.register_memory()
		player.session.restore_light(18.0)
		player.session.add_score(80)
	collected.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.35)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)
