extends RefCounted
class_name ZoneVisualBootstrap
## Aplica atmósfera gótica + HUD premium a zonas legacy.


static func apply_atmosphere(zone: Node2D, player: Node2D, theme: String) -> GothicAtmosphere:
	var fog_ui := zone.get_node_or_null("CanvasLayer")
	if fog_ui:
		fog_ui.visible = false
	var atm := GothicAtmosphere.new()
	atm.name = "GothicAtmosphere"
	zone.add_child(atm)
	atm.setup(zone, player, theme)
	return atm


static func setup_gothic_alex(alex: CharacterBody2D) -> GothicPlayerVisual:
	if alex == null:
		return null
	var old_vis := alex.get_node_or_null("Visual")
	if old_vis:
		old_vis.visible = false
		old_vis.queue_free()
	var old_anim := alex.get_node_or_null("AnimatedSprite2D")
	if old_anim:
		old_anim.visible = false
	var mud := alex.get_node_or_null("MudParticles") as GPUParticles2D
	if mud:
		mud.emitting = false
	var gv := alex.get_node_or_null("GothicVisual") as GothicPlayerVisual
	if gv == null:
		gv = GothicPlayerVisual.new()
		gv.name = "GothicVisual"
		alex.add_child(gv)
	var skin := SettingsManager.player_skin if SettingsManager.player_skin else "alex"
	gv.setup(alex, skin)
	return gv


static func create_hud(zone: Node, title: String, max_light: int = 3) -> PremiumZoneHUD:
	var hud := PremiumZoneHUD.new()
	hud.setup(title, GameManager.max_health, max_light)
	zone.add_child(hud)
	return hud
