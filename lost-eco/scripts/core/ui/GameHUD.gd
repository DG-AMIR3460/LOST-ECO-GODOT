extends CanvasLayer
class_name GameHUD
## HUD premium para El Pantano (corazones + barra de luz gótica).

const UI_FONT := "res://PatrickHand-Regular.ttf"
const TITLE_FONT := "res://Fonts/AmaticSC-Bold.ttf"

var _session: GameSession = null
var _hearts: Array[Control] = []
var _light_bar: ProgressBar = null
var _light_fill_style: StyleBoxFlat = null
var _score_lbl: Label = null


func bind_session(session: GameSession) -> void:
	if _session:
		_disconnect_session()
	_session = session
	_session.health_changed.connect(_on_health_changed)
	_session.light_energy_changed.connect(_on_light_changed)
	_on_health_changed(_session.current_health, _session.max_health)
	_on_light_changed(_session.light_energy, _session.max_light_energy)


func _disconnect_session() -> void:
	if _session.health_changed.is_connected(_on_health_changed):
		_session.health_changed.disconnect(_on_health_changed)
	if _session.light_energy_changed.is_connected(_on_light_changed):
		_session.light_energy_changed.disconnect(_on_light_changed)


func _ready() -> void:
	layer = 15
	_build_ui()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(4, 4)
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.04, 0.03, 0.08, 0.9)
	pstyle.border_color = Color(0.72, 0.58, 0.22, 0.88)
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(5)
	pstyle.shadow_size = 5
	pstyle.shadow_color = Color(0, 0, 0, 0.45)
	panel.add_theme_stylebox_override("panel", pstyle)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	_score_lbl = _mk_label("LOST ECO", 9, Color(0.92, 0.82, 0.42), true)
	box.add_child(_score_lbl)
	var heart_row := HBoxContainer.new()
	heart_row.add_theme_constant_override("separation", 3)
	box.add_child(heart_row)
	for _i in 6:
		var heart := Control.new()
		heart.custom_minimum_size = Vector2(12, 12)
		heart.set_script(preload("res://scripts/core/ui/HeartIcon.gd"))
		heart_row.add_child(heart)
		_hearts.append(heart)
	_light_bar = ProgressBar.new()
	_light_bar.custom_minimum_size = Vector2(84, 10)
	_light_bar.max_value = 100.0
	_light_bar.show_percentage = false
	_light_fill_style = StyleBoxFlat.new()
	_light_fill_style.bg_color = Color(0.92, 0.78, 0.28)
	_light_fill_style.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.06, 0.11)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.42, 0.36, 0.18)
	_light_bar.add_theme_stylebox_override("fill", _light_fill_style)
	_light_bar.add_theme_stylebox_override("background", bg)
	box.add_child(_light_bar)
	var hint := _mk_label("[J] Pulso  [Shift] Dash  [Space] Salto", 7, Color(0.55, 0.6, 0.52))
	box.add_child(hint)


func _mk_label(text: String, size: int, color: Color, title: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	var f: Font = load(TITLE_FONT if title else UI_FONT) as Font
	if f:
		lbl.add_theme_font_override("font", f)
	return lbl


func _on_health_changed(current: int, maximum: int) -> void:
	for i in _hearts.size():
		var h: Control = _hearts[i]
		if h.has_method("set_filled"):
			h.set_filled(i < current, i < maximum)
		h.visible = i < maximum
	if _score_lbl:
		_score_lbl.text = "VIDA %d/%d" % [current, maximum]


func _on_light_changed(current: float, maximum: float) -> void:
	if _light_bar:
		_light_bar.max_value = maximum
		_light_bar.value = current
	if _light_fill_style:
		var ratio := current / maxf(maximum, 1.0)
		_light_fill_style.bg_color = Color(0.45 + ratio * 0.5, 0.38 + ratio * 0.4, 0.12 + ratio * 0.2)
