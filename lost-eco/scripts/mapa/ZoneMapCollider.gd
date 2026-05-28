extends RefCounted
class_name ZoneMapCollider
## Colisión de paredes en un solo StaticBody2D (evita congelar al cargar mapas grandes).


static func build(parent: Node2D, wall_rects: Array) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "WallCollider"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	for entry in wall_rects:
		if entry is not Rect2:
			continue
		var rect: Rect2 = entry
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		shape_node.shape = shape
		shape_node.position = rect.position + rect.size * 0.5
		body.add_child(shape_node)
	return body
