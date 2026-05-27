extends CanvasLayer
class_name PremiumZoneHUD
## HUD compacto — no tapa el juego.

const UI_FONT := "res://PatrickHand-Regular.ttf"
const TITLE_FONT := "res://Fonts/AmaticSC-Bold.ttf"

var _hearts: Array[Control] = []
var _light_pips: Array[Control] = []
var _score_lbl: Label = null
var _zone_lbl: Label = null
var _status_lbl: Label = null
var _panel: PanelContainer = null


func setup_compact(zone_title: String, max_health: int = 3, max_light: int = 3) -> void:
	layer = 100
	_build_compact_shell(zone_title, max_health, max_light)
	GameManager.health_changed.connect(_on_health)
	GameManager.score_changed.connect(_on_score)
	_on_health(GameManager.current_health)
	_on_score(GameManager.score)


func setup(zone_title: String, max_health: int = 3, max_light: int = 3) -> void:
	setup_compact(zone_title, max_health, max_light)


func _build_compact_shell(zone_title: String, max_health: int, max_light: int) -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(2, 2)
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.08, 0.06, 0.11, 0.88)
	pstyle.border_color = Color(0.75, 0.62, 0.22, 0.8)
	pstyle.set_border_width_all(1)
	pstyle.set_corner_radius_all(3)
	_panel.add_theme_stylebox_override("panel", pstyle)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 3)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	_zone_lbl = _label(zone_title, 7, Color(0.92, 0.84, 0.45), true)
	box.add_child(_zone_lbl)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)
	box.add_child(row1)
	for _i in max_health:
		var h := Control.new()
		h.custom_minimum_size = Vector2(7, 7)
		h.set_script(preload("res://scripts/core/ui/HeartIcon.gd"))
		row1.add_child(h)
		_hearts.append(h)
	_status_lbl = _label("ECOS 0/0", 7, Color(0.95, 0.88, 0.38))
	row1.add_child(_status_lbl)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 3)
	box.add_child(row2)
	_score_lbl = _label("0 pts", 7, Color(0.82, 0.78, 0.58))
	row2.add_child(_score_lbl)
	for _i in max_light:
		var pip := Control.new()
		pip.custom_minimum_size = Vector2(5, 5)
		pip.set_script(preload("res://scripts/visual/LightPipIcon.gd"))
		row2.add_child(pip)
		_light_pips.append(pip)


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
	update_status("ECOS %d/%d" % [collected, total])


func update_status(text: String) -> void:
	if _status_lbl:
		_status_lbl.text = text


func update_light_charges(current: int, maximum: int) -> void:
	for i in _light_pips.size():
		if _light_pips[i].has_method("set_lit"):
			_light_pips[i].set_lit(i < current)


func _on_health(current: int) -> void:
	for i in _hearts.size():
		if _hearts[i].has_method("set_filled"):
			_hearts[i].set_filled(i < current, false)


func _on_score(score: int) -> void:
	if _score_lbl:
		_score_lbl.text = "%d pts" % score
