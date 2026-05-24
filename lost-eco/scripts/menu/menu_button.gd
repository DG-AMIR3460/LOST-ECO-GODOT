extends Button
class_name GameMenuButton
## Botón de menú con hover glow, animación suave y sonidos de interfaz.

@export var hover_scale: float = 1.06
@export var animation_duration: float = 0.18
@export var glow_color: Color = Color(1.0, 0.88, 0.45, 1.0)

var _base_scale: Vector2 = Vector2.ONE
var _tween: Tween


func _ready() -> void:
	_base_scale = scale
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)


func _on_mouse_entered() -> void:
	UISounds.play_hover()
	_animate_hover(true)


func _on_mouse_exited() -> void:
	_animate_hover(false)


func _on_pressed() -> void:
	UISounds.play_click()


func _animate_hover(is_hovered: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)

	var target_scale := _base_scale * (hover_scale if is_hovered else 1.0)
	_tween.tween_property(self, "scale", target_scale, animation_duration)

	if is_hovered:
		_tween.tween_property(self, "modulate", glow_color, animation_duration)
	else:
		_tween.tween_property(self, "modulate", Color.WHITE, animation_duration)
