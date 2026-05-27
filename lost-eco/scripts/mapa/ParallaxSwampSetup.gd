extends ParallaxBackground
## Parallax de fondo — sin capa de niebla que tapaba la pantalla.

var _player: Node2D = null


func build(player: Node2D) -> void:
	_player = player
	scroll_ignore_camera_zoom = true
	z_index = -10
	var layers := [
		{"name": "DeepTrees", "motion": Vector2(0.05, 0.02), "z": -50, "trees": true},
		{"name": "Architecture", "motion": Vector2(0.35, 0.05), "z": -30, "arches": true},
		{"name": "ForegroundVines", "motion": Vector2(1.15, 0.06), "z": 15, "vines": true},
	]
	for data in layers:
		var layer_node := ParallaxLayer.new()
		layer_node.name = data["name"]
		layer_node.motion_scale = data["motion"]
		layer_node.z_index = data["z"]
		add_child(layer_node)
		if data.get("trees", false):
			_add_tree_silhouettes(layer_node)
		elif data.get("arches", false):
			_add_swamp_arches(layer_node)
		elif data.get("vines", false):
			_add_foreground_vines(layer_node)


func _add_tree_silhouettes(parallax_layer: ParallaxLayer) -> void:
	var back := ColorRect.new()
	back.size = Vector2(720, 200)
	back.position = Vector2(-120, -40)
	back.color = Color(0.03, 0.04, 0.07, 0.85)
	parallax_layer.add_child(back)
	for i in 9:
		var tree := Polygon2D.new()
		tree.color = Color(0.05, 0.06, 0.09)
		var x := -80.0 + float(i) * 85.0
		tree.polygon = PackedVector2Array([
			Vector2(x, 160), Vector2(x + 18, 80), Vector2(x + 36, 160),
			Vector2(x + 8, 60), Vector2(x + 28, 160),
		])
		parallax_layer.add_child(tree)


func _add_swamp_arches(parallax_layer: ParallaxLayer) -> void:
	var base := ColorRect.new()
	base.size = Vector2(600, 120)
	base.position = Vector2(-60, 40)
	base.color = Color(0.07, 0.1, 0.08, 0.55)
	parallax_layer.add_child(base)
	for i in 4:
		var arch := Polygon2D.new()
		arch.color = Color(0.09, 0.14, 0.1, 0.75)
		var ox := float(i) * 140.0
		arch.polygon = PackedVector2Array([
			Vector2(ox, 120), Vector2(ox + 20, 50), Vector2(ox + 70, 30),
			Vector2(ox + 120, 50), Vector2(ox + 140, 120),
		])
		parallax_layer.add_child(arch)


func _add_foreground_vines(parallax_layer: ParallaxLayer) -> void:
	var vine_l := Polygon2D.new()
	vine_l.color = Color(0.02, 0.05, 0.03, 0.45)
	vine_l.polygon = PackedVector2Array([
		Vector2(-40, 200), Vector2(20, 0), Vector2(60, 200), Vector2(0, 180),
	])
	parallax_layer.add_child(vine_l)
	var vine_r := Polygon2D.new()
	vine_r.color = Color(0.02, 0.04, 0.03, 0.35)
	vine_r.polygon = PackedVector2Array([
		Vector2(280, 200), Vector2(320, 20), Vector2(360, 200), Vector2(300, 190),
	])
	parallax_layer.add_child(vine_r)
