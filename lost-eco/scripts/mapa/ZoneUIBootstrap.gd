extends RefCounted
class_name ZoneUIBootstrap
## HUD y minimapa compactos compartidos por todas las zonas.


static func attach_hud(zone: Node, title: String, max_light: int = 3) -> PremiumZoneHUD:
	var hud := PremiumZoneHUD.new()
	hud.setup_compact(title, GameManager.max_health, max_light)
	zone.add_child(hud)
	return hud


static func attach_minimap(
	zone: Node,
	map: Array,
	colors: Dictionary,
	fog: bool = true,
	reveal_radius: int = 4
) -> ZoneMinimap:
	var layer := CanvasLayer.new()
	layer.layer = 101
	zone.add_child(layer)
	var minimap := ZoneMinimap.new()
	minimap.setup(map, colors, true)
	if fog:
		minimap.enable_fog_of_war(reveal_radius)
	layer.add_child(minimap)
	var zone_ref: Node = zone
	zone_ref.get_tree().create_timer(0.05).timeout.connect(
		func(): anchor_minimap(zone_ref, minimap)
	)
	return minimap


static func anchor_minimap(zone: Node, minimap: ZoneMinimap) -> void:
	if minimap == null or not is_instance_valid(minimap):
		return
	var vp := zone.get_viewport().get_visible_rect().size
	var sz := minimap.custom_minimum_size
	var anchor := Vector2(vp.x - sz.x - 2.0, vp.y - sz.y - 2.0)
	minimap.set_rest_position(anchor)
