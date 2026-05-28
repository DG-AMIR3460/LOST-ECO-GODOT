extends CanvasLayer
class_name PremiumZoneHUD
## HUD de zona: vidas, ecos/objetivos, puntos y cargas de luz.

const UI_FONT := "res://PatrickHand-Regular.ttf"
const TITLE_FONT := "res://Fonts/AmaticSC-Bold.ttf"

var _hearts: Array[Control] = []
var _light_pips: Array[Control] = []
var _score_lbl: Label = null
var _zone_lbl: Label = null
var _status_lbl: Label = null
var _panel: PanelContainer = null
var _rest_pos: Vector2 = Vector2(4, 4)


func setup_compact(zone_title: String, max_health: int = 3, max_light: int = 3) -> void:
	layer = 100
	_build_shell(zone_title, max_health, max_light)
	GameManager.health_changed.connect(_on_health)
	GameManager.score_changed.connect(_on_score)
	_on_health(GameManager.current_health)
	_on_score(GameManager.score)
	set_process(true)


func _process(delta: float) -> void:
	if _panel == null or GameManager.player == null:
		return
	var player: Node2D = GameManager.player as Node2D
	if player == null:
		return
	var vp_size: Vector2 = ZoneHUDAvoidance.viewport_size(self)
	var player_rect: Rect2 = ZoneHUDAvoidance.player_screen_rect(player)
	var panel_size: Vector2 = _panel.get_combined_minimum_size()
	if _panel.size.x > panel_size.x:
		panel_size = _panel.size
	var result: Dictionary = ZoneHUDAvoidance.update_panel(
		_panel.position,
		_rest_pos,
		panel_size,
		player_rect,
		vp_size,
		delta,
		ZoneHUDAvoidance.Anchor.TOP_LEFT
	)
	_panel.position = result["position"]
	_panel.visible = result["visible"]


func setup(zone_title: String, max_health: int = 3, max_light: int = 3) -> void:
	setup_compact(zone_title, max_health, max_light)


func _build_shell(zone_title: String, max_health: int, max_light: int) -> void:
	_panel = PanelContainer.new()
	_panel.position = _rest_pos
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.06, 0.05, 0.10, 0.92)
	pstyle.border_color = Color(0.82, 0.68, 0.28, 0.9)
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override("panel", pstyle)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 4)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	_zone_lbl = _label(zone_title, 8, Color(0.95, 0.88, 0.42), true)
	box.add_child(_zone_lbl)

	var lives_row := HBoxContainer.new()
	lives_row.add_theme_constant_override("separation", 4)
	box.add_child(lives_row)
	lives_row.add_child(_label("VIDAS", 7, Color(0.95, 0.75, 0.55)))
	for _i in max_health:
		var h := Control.new()
		h.custom_minimum_size = Vector2(11, 11)
		h.set_script(preload("res://scripts/puntuacion/HeartIcon.gd"))
		lives_row.add_child(h)
		_hearts.append(h)

	var obj_row := HBoxContainer.new()
	obj_row.add_theme_constant_override("separation", 5)
	box.add_child(obj_row)
	_status_lbl = _label("ECOS 0/0", 7, Color(0.95, 0.90, 0.40))
	obj_row.add_child(_status_lbl)
	_score_lbl = _label("0 pts", 7, Color(0.82, 0.78, 0.62))
	obj_row.add_child(_score_lbl)

	var light_row := HBoxContainer.new()
	light_row.add_theme_constant_override("separation", 4)
	box.add_child(light_row)
	light_row.add_child(_label("LUZ", 7, Color(0.75, 0.88, 1.0)))
	for _i in max_light:
		var pip := Control.new()
		pip.custom_minimum_size = Vector2(8, 8)
		pip.set_script(preload("res://scripts/puntuacion/LightPipIcon.gd"))
		light_row.add_child(pip)
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
			_hearts[i].set_filled(i < current, true)


func _on_score(score: int) -> void:
	if _score_lbl:
		_score_lbl.text = "%d pts" % score
