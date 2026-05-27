extends ParallaxBackground
## Cinco capas de siluetas góticas + niebla atmosférica.

var _player: Node2D = null


func build(player: Node2D, theme: String = "cave") -> void:
	_player = player
	scroll_ignore_camera_zoom = true
	var palette := _palette_for(theme)
	var specs := [
		{"n": "FarVoid", "motion": Vector2(0.03, 0.01), "z": -60},
		{"n": "DeepSilhouette", "motion": Vector2(0.08, 0.02), "z": -45},
		{"n": "MidArches", "motion": Vector2(0.22, 0.04), "z": -28},
		{"n": "FogPlane", "motion": Vector2(0.55, 0.05), "z": -12, "fog": true},
		{"n": "ForegroundHooks", "motion": Vector2(1.1, 0.08), "z": 18},
	]
	for i in specs.size():
		var layer := ParallaxLayer.new()
		layer.name = str(specs[i]["n"])
		layer.motion_scale = specs[i]["motion"] as Vector2
		layer.z_index = int(specs[i]["z"])
		add_child(layer)
		if specs[i].get("fog", false):
			_add_fog_plane(layer, palette)
		elif i == 0:
			_add_void(layer, palette)
		elif i == 1:
			_add_trees(layer, palette)
		elif i == 2:
			_add_arches(layer, palette)
		else:
			_add_foreground(layer, palette)


func _pal_color(pal: Dictionary, key: String) -> Color:
	return pal[key] as Color


func _palette_for(theme: String) -> Dictionary:
	if theme == "river":
		return {
			"void": Color(0.02, 0.05, 0.1),
			"sil": Color(0.05, 0.1, 0.16),
			"arch": Color(0.08, 0.14, 0.22),
			"fog": Color(0.12, 0.22, 0.35, 0.38),
			"fg": Color(0.03, 0.08, 0.14, 0.45),
		}
	if theme == "swamp":
		return {
			"void": Color(0.02, 0.04, 0.03),
			"sil": Color(0.04, 0.07, 0.05),
			"arch": Color(0.07, 0.11, 0.08),
			"fog": Color(0.12, 0.16, 0.1, 0.35),
			"fg": Color(0.02, 0.05, 0.03, 0.55),
		}
	return {
		"void": Color(0.03, 0.03, 0.06),
		"sil": Color(0.06, 0.05, 0.1),
		"arch": Color(0.1, 0.09, 0.14),
		"fog": Color(0.14, 0.12, 0.2, 0.4),
		"fg": Color(0.04, 0.03, 0.08, 0.5),
	}


func _add_void(layer: ParallaxLayer, pal: Dictionary) -> void:
	var grad := ColorRect.new()
	grad.size = Vector2(800, 260)
	grad.position = Vector2(-100, -60)
	grad.color = _pal_color(pal, "void")
	layer.add_child(grad)


func _add_trees(layer: ParallaxLayer, pal: Dictionary) -> void:
	for i in 11:
		var tree := Polygon2D.new()
		tree.color = _pal_color(pal, "sil")
		var x := -90.0 + float(i) * 78.0
		tree.polygon = PackedVector2Array([
			Vector2(x, 180), Vector2(x + 14, 70), Vector2(x + 30, 180),
			Vector2(x + 6, 50), Vector2(x + 22, 180),
		])
		layer.add_child(tree)


func _add_arches(layer: ParallaxLayer, pal: Dictionary) -> void:
	var base := ColorRect.new()
	base.size = Vector2(640, 140)
	base.position = Vector2(-40, 30)
	base.color = _pal_color(pal, "arch") * Color(1, 1, 1, 0.65)
	layer.add_child(base)
	for i in 5:
		var arch := Polygon2D.new()
		arch.color = _pal_color(pal, "arch")
		var ox := float(i) * 130.0
		arch.polygon = PackedVector2Array([
			Vector2(ox, 130), Vector2(ox + 18, 45), Vector2(ox + 65, 25),
			Vector2(ox + 112, 45), Vector2(ox + 130, 130),
		])
		layer.add_child(arch)


func _add_fog_plane(layer: ParallaxLayer, pal: Dictionary) -> void:
	var fog := ColorRect.new()
	fog.size = Vector2(720, 200)
	fog.position = Vector2(-80, 20)
	var fog_col := _pal_color(pal, "fog")
	fog.color = fog_col
	layer.add_child(fog)
	for i in 6:
		var wisp := Polygon2D.new()
		wisp.color = Color(fog_col.r, fog_col.g, fog_col.b, 0.18)
		var x := float(i) * 120.0
		wisp.polygon = PackedVector2Array([
			Vector2(x, 80), Vector2(x + 80, 60), Vector2(x + 100, 120), Vector2(x + 10, 130),
		])
		layer.add_child(wisp)


func _add_foreground(layer: ParallaxLayer, pal: Dictionary) -> void:
	var vine_l := Polygon2D.new()
	vine_l.color = _pal_color(pal, "fg")
	vine_l.polygon = PackedVector2Array([
		Vector2(-50, 220), Vector2(10, 0), Vector2(70, 220), Vector2(0, 200),
	])
	layer.add_child(vine_l)
	var vine_r := Polygon2D.new()
	vine_r.color = _pal_color(pal, "fg")
	vine_r.polygon = PackedVector2Array([
		Vector2(260, 220), Vector2(310, 10), Vector2(370, 220), Vector2(300, 200),
	])
	layer.add_child(vine_r)
