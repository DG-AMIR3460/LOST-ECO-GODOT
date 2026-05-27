extends Node2D
## Cinemática de rescate — Alex encuentra a Mateo (Zona 4).

const UI_FONT_PATH := "res://PatrickHand-Regular.ttf"
const TITLE_FONT_PATH := "res://Fonts/AmaticSC-Bold.ttf"
const SKY_SHADER := preload("res://shaders/cutscene_clearing_sky.gdshader")
const VIGNETTE_SHADER := preload("res://shaders/vignette_screen.gdshader")
const FOG_SHADER := preload("res://assets/shaders/fog_shader.gdshader")
const GRAIN_SHADER := preload("res://shaders/cutscene_film_grain.gdshader")

const VIEWPORT_SIZE := Vector2i(320, 180)
const GROUND_Y := 142.0

const PAL_VOID := Color(0.03, 0.06, 0.05)
const PAL_SIL := Color(0.06, 0.12, 0.08)
const PAL_ARCH := Color(0.10, 0.20, 0.12)
const PAL_FOG := Color(0.14, 0.26, 0.16, 0.42)
const PAL_FG := Color(0.04, 0.09, 0.06, 0.55)
const PAL_GRASS_TOP := Color(0.12, 0.28, 0.14)
const PAL_GRASS_BOT := Color(0.06, 0.14, 0.08)

const DIALOGUE_LINES: Array[Dictionary] = [
	{"speaker": "Alex", "text": "Mateo... ¿estás ahí? No huyas, por favor."},
	{"speaker": "Mateo", "text": "¡Aléjate! No sé si puedo confiar en ti..."},
	{"speaker": "Alex", "text": "Tiré el arma. Fui un cobarde. Lo siento mucho, perdóname."},
	{"speaker": "Mateo", "text": "...Está bien, Alex. Solo quiero ir a casa."},
]

var _ui_layer: CanvasLayer
var _fx_layer: CanvasLayer
var _world_root: Node2D
var _dialogue_label: RichTextLabel
var _dialogue_panel: Panel
var _speaker_tag: Label
var _continue_hint: Label
var _fade_rect: ColorRect
var _sky_rect: ColorRect
var _sky_mat: ShaderMaterial
var _fog_rect: ColorRect
var _fog_mat: ShaderMaterial
var _vignette_rect: ColorRect
var _vignette_mat: ShaderMaterial
var _title_label: Label
var _menu_layer: CanvasLayer

var _camera: Camera2D
var _alex: Sprite2D
var _mateo: Sprite2D
var _alex_light: PointLight2D
var _mateo_light: PointLight2D
var _fireflies: GPUParticles2D
var _dawn_motes: GPUParticles2D

var _dialogue_index: int = 0
var _dialogue_active: bool = false
var _sequence_done: bool = false
var _menu_shown: bool = false
var _exiting: bool = false
var _dawn_progress: float = 0.0
var _time_accum: float = 0.0
var _ui_font: Font
var _title_font: Font


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameManager.player = null
	RenderingServer.set_default_clear_color(Color(0.05, 0.07, 0.11))
	_ui_font = load(UI_FONT_PATH) as Font
	_title_font = load(TITLE_FONT_PATH) as Font
	_setup_camera()
	_build_world()
	_build_characters()
	_build_ui()
	_build_cinematic_fx()
	await _play_intro_sequence()


func _exit_tree() -> void:
	_exiting = true


func _process(delta: float) -> void:
	if _exiting:
		return
	_time_accum += delta
	if _sky_mat:
		_sky_mat.set_shader_parameter("time_sec", _time_accum)
		_sky_mat.set_shader_parameter("dawn_progress", _dawn_progress)
	_update_spotlight()
	_update_character_bob(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _menu_shown or not _dialogue_active:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_advance_dialogue()


# =============================================================================
# Montaje visual
# =============================================================================

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_camera.position = Vector2(VIEWPORT_SIZE) * 0.5
	_camera.zoom = Vector2(1.02, 1.02)
	add_child(_camera)
	_camera.make_current()


func _build_world() -> void:
	_world_root = Node2D.new()
	_world_root.name = "World"
	add_child(_world_root)

	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -3
	add_child(bg_layer)

	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SKY_SHADER
	_sky_mat.set_shader_parameter("dawn_progress", 0.0)
	_sky_mat.set_shader_parameter("time_sec", 0.0)
	_sky_rect = ColorRect.new()
	_sky_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_rect.material = _sky_mat
	_sky_rect.color = Color.WHITE
	bg_layer.add_child(_sky_rect)

	_build_parallax()
	_build_ground()

	var fog_layer := CanvasLayer.new()
	fog_layer.layer = 2
	add_child(fog_layer)
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = FOG_SHADER
	_fog_mat.set_shader_parameter("player_pos", Vector2(0.5, 0.55))
	_fog_mat.set_shader_parameter("light_radius", 0.38)
	_fog_mat.set_shader_parameter("edge_softness", 0.22)
	_fog_mat.set_shader_parameter("fog_color", Color(0.02, 0.04, 0.06, 0.72))
	_fog_rect = ColorRect.new()
	_fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_rect.material = _fog_mat
	_fog_rect.color = Color.WHITE
	fog_layer.add_child(_fog_rect)

	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = VIGNETTE_SHADER
	_vignette_mat.set_shader_parameter("intensity", 0.72)
	_vignette_mat.set_shader_parameter("softness", 0.52)
	_vignette_mat.set_shader_parameter("aspect_ratio", 1.777)
	_vignette_mat.set_shader_parameter("tint", Color(0.01, 0.02, 0.04, 1.0))
	_vignette_rect = ColorRect.new()
	_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_rect.material = _vignette_mat
	_vignette_rect.color = Color.WHITE
	var vig_layer := CanvasLayer.new()
	vig_layer.layer = 4
	add_child(vig_layer)
	vig_layer.add_child(_vignette_rect)


func _build_parallax() -> void:
	var para := ParallaxBackground.new()
	para.name = "ClearingParallax"
	para.scroll_ignore_camera_zoom = true
	_world_root.add_child(para)

	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.05, 0.02)
	far.z_index = -30
	para.add_child(far)
	var void_bg := ColorRect.new()
	void_bg.size = Vector2(400, 200)
	void_bg.position = Vector2(-40, -20)
	void_bg.color = PAL_VOID
	far.add_child(void_bg)

	var trees := ParallaxLayer.new()
	trees.motion_scale = Vector2(0.12, 0.04)
	trees.z_index = -25
	para.add_child(trees)
	for i in 9:
		var tree := Polygon2D.new()
		var x := -60.0 + float(i) * 44.0
		var h := 52.0 + float(i % 3) * 8.0
		tree.color = PAL_SIL.darkened(0.05 + float(i % 2) * 0.04)
		tree.polygon = PackedVector2Array([
			Vector2(x, GROUND_Y - 4), Vector2(x + 10, GROUND_Y - h),
			Vector2(x + 22, GROUND_Y - 4), Vector2(x + 5, GROUND_Y - h - 14),
			Vector2(x + 16, GROUND_Y - 4),
		])
		trees.add_child(tree)

	var mid := ParallaxLayer.new()
	mid.motion_scale = Vector2(0.28, 0.06)
	mid.z_index = -18
	para.add_child(mid)
	for i in 4:
		var hill := Polygon2D.new()
		var ox := float(i) * 95.0 - 30.0
		hill.color = PAL_ARCH * Color(1, 1, 1, 0.75)
		hill.polygon = PackedVector2Array([
			Vector2(ox, GROUND_Y + 6), Vector2(ox + 50, GROUND_Y - 28),
			Vector2(ox + 110, GROUND_Y + 6),
		])
		mid.add_child(hill)

	var fog_plane := ParallaxLayer.new()
	fog_plane.motion_scale = Vector2(0.5, 0.08)
	fog_plane.z_index = -8
	para.add_child(fog_plane)
	var mist := ColorRect.new()
	mist.size = Vector2(360, 70)
	mist.position = Vector2(-20, GROUND_Y - 55)
	mist.color = PAL_FOG
	fog_plane.add_child(mist)

	var fg := ParallaxLayer.new()
	fg.motion_scale = Vector2(1.05, 0.12)
	fg.z_index = 8
	para.add_child(fg)
	for side in [-1, 1]:
		var vine := Polygon2D.new()
		vine.color = PAL_FG
		var sx := 300.0 if side > 0 else -50.0
		vine.polygon = PackedVector2Array([
			Vector2(sx, GROUND_Y + 20), Vector2(sx + 35.0 * side, GROUND_Y - 90),
			Vector2(sx + 70.0 * side, GROUND_Y + 20), Vector2(sx + 20.0 * side, GROUND_Y + 5),
		])
		fg.add_child(vine)


func _build_ground() -> void:
	var ground := Node2D.new()
	ground.name = "Ground"
	ground.z_index = -5
	_world_root.add_child(ground)

	var base := Polygon2D.new()
	base.color = PAL_GRASS_BOT
	base.polygon = PackedVector2Array([
		Vector2(-20, GROUND_Y + 2), Vector2(VIEWPORT_SIZE.x + 20, GROUND_Y + 2),
		Vector2(VIEWPORT_SIZE.x + 20, VIEWPORT_SIZE.y + 10),
		Vector2(-20, VIEWPORT_SIZE.y + 10),
	])
	ground.add_child(base)

	var top := Polygon2D.new()
	top.color = PAL_GRASS_TOP
	top.polygon = PackedVector2Array([
		Vector2(-20, GROUND_Y - 2), Vector2(VIEWPORT_SIZE.x + 20, GROUND_Y - 2),
		Vector2(VIEWPORT_SIZE.x + 20, GROUND_Y + 10),
		Vector2(-20, GROUND_Y + 10),
	])
	ground.add_child(top)

	for i in 14:
		var blade := Polygon2D.new()
		var bx := 8.0 + float(i) * 22.0
		blade.color = PAL_GRASS_TOP.lightened(0.06 + float(i % 3) * 0.03)
		blade.polygon = PackedVector2Array([
			Vector2(bx, GROUND_Y), Vector2(bx + 3, GROUND_Y - 5 - float(i % 2)),
			Vector2(bx + 6, GROUND_Y),
		])
		ground.add_child(blade)

	var path := Polygon2D.new()
	path.color = Color(0.09, 0.11, 0.08, 0.55)
	path.polygon = PackedVector2Array([
		Vector2(0, GROUND_Y + 8), Vector2(VIEWPORT_SIZE.x, GROUND_Y + 8),
		Vector2(VIEWPORT_SIZE.x * 0.7, GROUND_Y + 22), Vector2(0, GROUND_Y + 18),
	])
	ground.add_child(path)


func _build_characters() -> void:
	var chars := Node2D.new()
	chars.name = "Characters"
	chars.z_index = 10
	_world_root.add_child(chars)

	_alex = CharacterArt.make_sprite("alex", 0.15)
	if _alex == null:
		_alex = _fallback_sprite("Alex", Color(0.55, 0.72, 0.95))
	_alex.name = "Alex"
	_alex.position = Vector2(-48.0, GROUND_Y)
	_add_sprite_shadow(_alex)
	chars.add_child(_alex)
	_alex_light = _make_character_light(Color(0.75, 0.82, 1.0), 0.42)
	_alex.add_child(_alex_light)

	_mateo = CharacterArt.make_sprite("mateo", 0.38)
	if _mateo == null:
		_mateo = _fallback_sprite("Mateo", Color(0.58, 0.74, 0.44))
	_mateo.name = "Mateo"
	_mateo.position = Vector2(268.0, GROUND_Y)
	_mateo.flip_h = true
	_mateo.modulate = Color(0.82, 0.85, 0.95, 1.0)
	_add_sprite_shadow(_mateo)
	chars.add_child(_mateo)
	_mateo_light = _make_character_light(Color(0.9, 0.75, 0.55), 0.32)
	_mateo.add_child(_mateo_light)


func _add_sprite_shadow(sprite: Sprite2D) -> void:
	var sh := Polygon2D.new()
	sh.name = "Shadow"
	sh.color = Color(0, 0, 0, 0.38)
	sh.z_index = -2
	sh.position = Vector2(0, 5)
	sh.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(16, 0), Vector2(12, 5), Vector2(-12, 5),
	])
	sprite.add_child(sh)
	sprite.move_child(sh, 0)


func _make_character_light(tint: Color, energy: float) -> PointLight2D:
	var pl := PointLight2D.new()
	pl.energy = energy
	pl.color = tint
	pl.texture_scale = 1.35
	pl.shadow_enabled = false
	pl.blend_mode = Light2D.BLEND_MODE_ADD
	return pl


func _fallback_sprite(sprite_name: String, tint: Color) -> Sprite2D:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(tint)
	var s := Sprite2D.new()
	s.name = sprite_name
	s.texture = ImageTexture.create_from_image(img)
	s.centered = true
	s.scale = Vector2(2.5, 2.5)
	return s


func _build_cinematic_fx() -> void:
	_fireflies = _make_particles(28, 3.5, Color(0.65, 0.95, 0.55, 0.7), 0.08, 18.0)
	_fireflies.position = Vector2(VIEWPORT_SIZE.x * 0.5, 95)
	_world_root.add_child(_fireflies)

	_dawn_motes = _make_particles(20, 2.8, Color(1.0, 0.82, 0.45, 0.55), 0.04, 12.0)
	_dawn_motes.position = Vector2(120, 80)
	_dawn_motes.emitting = false
	_world_root.add_child(_dawn_motes)

	_fx_layer = CanvasLayer.new()
	_fx_layer.layer = 6
	add_child(_fx_layer)
	var grain_mat := ShaderMaterial.new()
	grain_mat.shader = GRAIN_SHADER
	grain_mat.set_shader_parameter("strength", 0.05)
	grain_mat.set_shader_parameter("time_sec", 0.0)
	var grain := ColorRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.material = grain_mat
	grain.color = Color.WHITE
	_fx_layer.add_child(grain)


func _make_particles(amount: int, lifetime: float, tint: Color, vel: float, spread: float) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime * 0.5
	p.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(160, 50, 1)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = spread
	mat.initial_velocity_min = vel * 0.5
	mat.initial_velocity_max = vel
	mat.gravity = Vector3(0, -8, 0)
	mat.scale_min = 0.15
	mat.scale_max = 0.45
	mat.color = tint
	p.process_material = mat
	return p


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)

	for top_bar in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0.01, 0.01, 0.02, 0.92)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if top_bar:
			bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
			bar.offset_bottom = 14.0
		else:
			bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			bar.offset_top = -10.0
		_ui_layer.add_child(bar)

	_title_label = Label.new()
	_title_label.text = "EL CLARO"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector2(0.0, 20.0)
	_title_label.size = Vector2(VIEWPORT_SIZE.x, 28.0)
	_title_label.modulate.a = 0.0
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.48))
	_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	_title_label.add_theme_constant_override("shadow_offset_x", 1)
	_title_label.add_theme_constant_override("shadow_offset_y", 1)
	if _title_font:
		_title_label.add_theme_font_override("font", _title_font)
	_ui_layer.add_child(_title_label)

	_dialogue_panel = Panel.new()
	_dialogue_panel.position = Vector2(10.0, 112.0)
	_dialogue_panel.size = Vector2(VIEWPORT_SIZE.x - 20.0, 58.0)
	_dialogue_panel.modulate.a = 0.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.06, 0.11, 0.92)
	panel_style.border_color = Color(0.82, 0.65, 0.28, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 6
	panel_style.set_content_margin_all(10)
	_dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	_ui_layer.add_child(_dialogue_panel)

	_speaker_tag = Label.new()
	_speaker_tag.position = Vector2(12, 6)
	_speaker_tag.add_theme_font_size_override("font_size", 9)
	_speaker_tag.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42))
	if _ui_font:
		_speaker_tag.add_theme_font_override("font", _ui_font)
	_dialogue_panel.add_child(_speaker_tag)

	_dialogue_label = RichTextLabel.new()
	_dialogue_label.position = Vector2(10, 18)
	_dialogue_label.size = Vector2(VIEWPORT_SIZE.x - 40, 32)
	_dialogue_label.bbcode_enabled = true
	_dialogue_label.scroll_active = false
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_color_override("default_color", Color(0.9, 0.88, 0.82))
	_dialogue_label.add_theme_font_size_override("normal_font_size", 10)
	if _ui_font:
		_dialogue_label.add_theme_font_override("normal_font", _ui_font)
	_dialogue_panel.add_child(_dialogue_label)

	_continue_hint = Label.new()
	_continue_hint.text = "▼ Continuar"
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_hint.position = Vector2(VIEWPORT_SIZE.x - 72.0, 98.0)
	_continue_hint.modulate.a = 0.0
	_continue_hint.add_theme_font_size_override("font_size", 8)
	_continue_hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.55))
	if _ui_font:
		_continue_hint.add_theme_font_override("font", _ui_font)
	_ui_layer.add_child(_continue_hint)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 1.0
	_ui_layer.add_child(_fade_rect)


func _update_spotlight() -> void:
	if _fog_mat == null or _camera == null:
		return
	var focus := Vector2(0.5, 0.52)
	if _alex and _mateo and is_instance_valid(_alex) and is_instance_valid(_mateo):
		var mid := (_alex.global_position + _mateo.global_position) * 0.5
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 1.0 and vp.y > 1.0:
			var rel := (mid - _camera.global_position) * _camera.zoom + vp * 0.5
			focus = Vector2(rel.x / vp.x, rel.y / vp.y).clamp(Vector2(0.12, 0.2), Vector2(0.88, 0.75))
	_fog_mat.set_shader_parameter("player_pos", focus)
	if _vignette_mat:
		var vig := lerpf(0.78, 0.42, _dawn_progress)
		_vignette_mat.set_shader_parameter("intensity", vig)


func _update_character_bob(delta: float) -> void:
	for sprite in [_alex, _mateo]:
		if sprite == null or not is_instance_valid(sprite) or not sprite.has_meta("bob_base_y"):
			continue
		var base_y: float = sprite.get_meta("bob_base_y")
		var amp: float = sprite.get_meta("bob_amp", 0.0)
		var period: float = sprite.get_meta("bob_period", 1.0)
		if amp <= 0.0 or period <= 0.0:
			continue
		var factor := 1.0 if sprite.get_meta("walking", false) else 0.35
		sprite.position.y = base_y + sin(_time_accum * TAU / period) * amp * factor


# =============================================================================
# Secuencia
# =============================================================================

func _play_intro_sequence() -> void:
	if _exiting:
		return

	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "modulate:a", 0.0, 1.4)
	await fade_in.finished
	if _exiting:
		return

	var title_tw := create_tween()
	title_tw.tween_property(_title_label, "modulate:a", 1.0, 0.9)
	await get_tree().create_timer(1.6).timeout
	if _exiting:
		return
	title_tw = create_tween()
	title_tw.tween_property(_title_label, "modulate:a", 0.0, 0.7)
	await title_tw.finished
	if _exiting:
		return

	_start_idle_bob(_mateo, 3.0, 1.2)
	var mateo_base_x := _mateo.position.x
	var mateo_shake := create_tween().set_loops(8)
	mateo_shake.tween_property(_mateo, "position:x", mateo_base_x + 2.5, 0.07)
	mateo_shake.tween_property(_mateo, "position:x", mateo_base_x - 2.5, 0.07)

	_start_walk_bob(_alex)
	var walk := create_tween()
	walk.set_trans(Tween.TRANS_SINE)
	walk.set_ease(Tween.EASE_IN_OUT)
	walk.tween_property(_alex, "position", Vector2(108.0, GROUND_Y), 2.8)
	walk.parallel().tween_property(_camera, "position", Vector2(168.0, 90.0), 2.8)
	await walk.finished
	if _exiting:
		return
	_stop_walk_bob(_alex)
	_start_idle_bob(_alex, 2.0, 1.5)

	await get_tree().create_timer(0.4).timeout
	if _exiting:
		return
	if mateo_shake.is_valid():
		mateo_shake.kill()
	_mateo.position.x = mateo_base_x

	await _start_dialogue()


func _start_idle_bob(sprite: Sprite2D, amplitude: float, period: float) -> void:
	if sprite == null:
		return
	sprite.set_meta("bob_amp", amplitude)
	sprite.set_meta("bob_period", period)
	if not sprite.has_meta("bob_base_y"):
		sprite.set_meta("bob_base_y", sprite.position.y)


func _start_walk_bob(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.set_meta("walking", true)
	_start_idle_bob(sprite, 4.0, 0.22)


func _stop_walk_bob(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.set_meta("walking", false)


func _start_dialogue() -> void:
	if _exiting:
		return
	_dialogue_active = true
	_dialogue_index = 0

	var panel_in := create_tween()
	panel_in.tween_property(_dialogue_panel, "modulate:a", 1.0, 0.55)
	panel_in.parallel().tween_property(_continue_hint, "modulate:a", 1.0, 0.55)
	await panel_in.finished
	if _exiting:
		return

	_show_dialogue_line(0)
	_dialogue_index = 1
	_pulse_continue_hint()


func _pulse_continue_hint() -> void:
	if _continue_hint == null:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(_continue_hint, "modulate:a", 0.35, 0.55)
	tw.tween_property(_continue_hint, "modulate:a", 1.0, 0.55)


func _show_dialogue_line(index: int) -> void:
	if index < 0 or index >= DIALOGUE_LINES.size():
		return
	var line: Dictionary = DIALOGUE_LINES[index]
	var speaker: String = line.get("speaker", "")
	var body: String = line.get("text", "")
	var accent := Color(0.95, 0.82, 0.42) if speaker == "Alex" else Color(0.55, 0.92, 0.72)
	if _speaker_tag:
		_speaker_tag.text = speaker.to_upper()
		_speaker_tag.add_theme_color_override("font_color", accent)
	if _dialogue_label:
		_dialogue_label.text = (
			"[color=#%s]%s[/color]"
			% [accent.to_html(false), body]
		)
	_flash_dialogue_panel()
	_pulse_speaker(speaker)


func _flash_dialogue_panel() -> void:
	if _dialogue_panel == null:
		return
	var tw := create_tween()
	tw.tween_property(_dialogue_panel, "scale", Vector2(1.02, 1.02), 0.08)
	tw.tween_property(_dialogue_panel, "scale", Vector2.ONE, 0.12)


func _pulse_speaker(speaker: String) -> void:
	var target := _alex if speaker == "Alex" else _mateo
	if target == null or not is_instance_valid(target):
		return
	if not target.has_meta("base_scale"):
		target.set_meta("base_scale", target.scale)
	var base_scale: Vector2 = target.get_meta("base_scale")
	var tw := create_tween()
	tw.tween_property(target, "scale", base_scale * 1.07, 0.1)
	tw.tween_property(target, "scale", base_scale, 0.16)
	if speaker == "Alex" and _alex_light:
		tw.parallel().tween_property(_alex_light, "energy", 0.65, 0.12)
		tw.tween_property(_alex_light, "energy", 0.42, 0.2)


func _advance_dialogue() -> void:
	if not _dialogue_active or _sequence_done or _exiting:
		return
	if _dialogue_index < DIALOGUE_LINES.size():
		_show_dialogue_line(_dialogue_index)
		_dialogue_index += 1
		return
	_dialogue_active = false
	await _play_reconciliation()


func _play_reconciliation() -> void:
	if _exiting:
		return
	_sequence_done = true

	var hide_ui := create_tween()
	hide_ui.tween_property(_dialogue_panel, "modulate:a", 0.0, 0.45)
	hide_ui.parallel().tween_property(_continue_hint, "modulate:a", 0.0, 0.45)
	await hide_ui.finished
	if _exiting:
		return

	if _fireflies:
		var ff_out := create_tween()
		ff_out.tween_property(_fireflies, "modulate:a", 0.0, 1.5)
	if _dawn_motes:
		_dawn_motes.emitting = true

	var dawn := create_tween()
	dawn.tween_method(_set_dawn_progress, 0.0, 1.0, 3.2)
	if _fog_mat:
		dawn.parallel().tween_method(
			func(v: float): _fog_mat.set_shader_parameter("light_radius", v),
			0.38, 0.52, 3.0
		)
	if _mateo:
		dawn.parallel().tween_property(_mateo, "modulate", Color.WHITE, 2.6)
	if _alex_light:
		dawn.parallel().tween_property(_alex_light, "color", Color(1.0, 0.85, 0.55), 2.5)
	await dawn.finished
	if _exiting:
		return

	if _mateo:
		_mateo.flip_h = false
		_start_walk_bob(_mateo)
		var reunite := create_tween()
		reunite.set_trans(Tween.TRANS_SINE)
		reunite.set_ease(Tween.EASE_IN_OUT)
		reunite.tween_property(_mateo, "position", Vector2(148.0, GROUND_Y), 2.2)
		reunite.parallel().tween_property(_camera, "position", Vector2(160, 90), 2.2)
		await reunite.finished
		_stop_walk_bob(_mateo)
	if _exiting:
		return

	_title_label.text = "Ambos caminaron hacia casa.\nFin."
	_title_label.add_theme_font_size_override("font_size", 12)
	var end_title := create_tween()
	end_title.tween_property(_title_label, "modulate:a", 1.0, 1.1)
	await get_tree().create_timer(2.6).timeout
	if _exiting:
		return
	end_title = create_tween()
	end_title.tween_property(_title_label, "modulate:a", 0.0, 0.9)
	await end_title.finished
	if _exiting:
		return

	_show_main_menu_button()


func _set_dawn_progress(t: float) -> void:
	_dawn_progress = t
	var c := Color(0.05, 0.07, 0.11).lerp(Color(0.55, 0.42, 0.28), t)
	RenderingServer.set_default_clear_color(c)
	if _fog_mat:
		_fog_mat.set_shader_parameter(
			"fog_color",
			Color(0.02, 0.04, 0.06, 0.72).lerp(Color(0.25, 0.18, 0.08, 0.35), t)
		)


func _show_main_menu_button() -> void:
	if _menu_shown or _exiting:
		return
	_menu_shown = true

	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 20
	add_child(_menu_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_layer.add_child(center)

	var btn := _make_menu_button("Volver al menú principal")
	center.add_child(btn)
	btn.pressed.connect(_on_menu_pressed)

	btn.modulate.a = 0.0
	create_tween().tween_property(btn, "modulate:a", 1.0, 0.7)


func _make_menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(210, 34)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.22)
	style.border_color = Color(0.88, 0.68, 0.28)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	b.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.22, 0.32)
	hover.border_color = Color(1.0, 0.82, 0.4)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_color_override("font_color", Color(0.98, 0.9, 0.65))
	b.add_theme_font_size_override("font_size", 12)
	if _ui_font:
		b.add_theme_font_override("font", _ui_font)
	return b


func _on_menu_pressed() -> void:
	if _exiting:
		return
	_exiting = true
	if _menu_layer:
		_menu_layer.visible = false
	await GameManager.return_to_main_menu()
