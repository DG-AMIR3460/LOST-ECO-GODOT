extends CanvasLayer
class_name PremiumZoneHUD
## HUD gótico premium para zonas legacy (reemplaza labels amarillos).

const UI_FONT := "res://PatrickHand-Regular.ttf"
const TITLE_FONT := "res://Fonts/AmaticSC-Bold.ttf"

var _hearts: Array[Control] = []
var _light_pips: Array[Control] = []
var _score_lbl: Label = null
var _zone_lbl: Label = null
var _echo_lbl: Label = null
var _light_bar: ProgressBar = null
var _light_fill: StyleBoxFlat = null
var _panel: PanelContainer = null


func setup(zone_title: String, max_health: int = 3, max_light: int = 3) -> void:
	layer = 12
	_build_shell(zone_title, max_health, max_light)
	GameManager.health_changed.connect(_on_health)
	GameManager.score_changed.connect(_on_score)
	_on_health(GameManager.current_health)
	_on_score(GameManager.score)


func _build_shell(zone_title: String, max_health: int, max_light: int) -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(4, 4)
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.04, 0.03, 0.08, 0.88)
	pstyle.border_color = Color(0.72, 0.58, 0.22, 0.85)
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(5)
	pstyle.shadow_color = Color(0, 0, 0, 0.5)
	pstyle.shadow_size = 6
	_panel.add_theme_stylebox_override("panel", pstyle)
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	_zone_lbl = _label(zone_title, 10, Color(0.92, 0.82, 0.42), true)
	box.add_child(_zone_lbl)
	_score_lbl = _label("PTS 0", 9, Color(0.85, 0.78, 0.55))
	box.add_child(_score_lbl)
	var heart_row := HBoxContainer.new()
	heart_row.add_theme_constant_override("separation", 3)
	box.add_child(heart_row)
	for _i in max_health:
		var h := Control.new()
		h.custom_minimum_size = Vector2(12, 12)
		h.set_script(preload("res://scripts/core/ui/HeartIcon.gd"))
		heart_row.add_child(h)
		_hearts.append(h)
	_echo_lbl = _label("ECOS 0/0", 8, Color(0.95, 0.88, 0.38))
	box.add_child(_echo_lbl)
	_light_bar = ProgressBar.new()
	_light_bar.custom_minimum_size = Vector2(88, 10)
	_light_bar.max_value = max_light
	_light_bar.show_percentage = false
	_light_fill = StyleBoxFlat.new()
	_light_fill.bg_color = Color(0.92, 0.78, 0.28)
	_light_fill.set_corner_radius_all(3)
	var lbg := StyleBoxFlat.new()
	lbg.bg_color = Color(0.08, 0.07, 0.12)
	lbg.set_border_width_all(1)
	lbg.border_color = Color(0.45, 0.38, 0.18)
	_light_bar.add_theme_stylebox_override("fill", _light_fill)
	_light_bar.add_theme_stylebox_override("background", lbg)
	box.add_child(_light_bar)
	var pip_row := HBoxContainer.new()
	pip_row.add_theme_constant_override("separation", 2)
	box.add_child(pip_row)
	for _i in max_light:
		var pip := Control.new()
		pip.custom_minimum_size = Vector2(8, 8)
		pip.set_script(preload("res://scripts/visual/LightPipIcon.gd"))
		pip_row.add_child(pip)
		_light_pips.append(pip)
	var hint := _label("[J] Pulso  [ESC] Menú", 7, Color(0.55, 0.58, 0.62))
	box.add_child(hint)


func _label(text: String, size: int, color: Color, title: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	var fpath := TITLE_FONT if title else UI_FONT
	var f: Font = load(fpath) as Font
	if f:
		lbl.add_theme_font_override("font", f)
	return lbl


func update_echoes(collected: int, total: int) -> void:
	if _echo_lbl:
		_echo_lbl.text = "ECOS %d/%d" % [collected, total]


func update_light_charges(current: int, maximum: int) -> void:
	if _light_bar:
		_light_bar.max_value = maximum
		_light_bar.value = current
	if _light_fill:
		var ratio := float(current) / float(maxi(maximum, 1))
		_light_fill.bg_color = Color(0.5 + ratio * 0.45, 0.42 + ratio * 0.35, 0.12)
	for i in _light_pips.size():
		if _light_pips[i].has_method("set_lit"):
			_light_pips[i].set_lit(i < current)


func _on_health(current: int) -> void:
	for i in _hearts.size():
		if _hearts[i].has_method("set_filled"):
			_hearts[i].set_filled(i < current, true)
			if i >= current and current < _hearts.size():
				_hearts[i].set_filled(false, true)


func _on_score(score: int) -> void:
	if _score_lbl:
		_score_lbl.text = "PTS %d" % score
