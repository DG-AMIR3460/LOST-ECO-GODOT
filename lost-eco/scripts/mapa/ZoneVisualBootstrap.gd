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
	var skin := "alex"
	if SettingsManager and SettingsManager.player_skin:
		skin = SettingsManager.player_skin
	gv.setup(alex, skin)
	return gv


static func move_player_to_spawn(player: Node2D, map: Array, tile_size: int, marker: String = "S") -> void:
	if player == null:
		return
	for y in map.size():
		var row: String = map[y]
		for x in row.length():
			if row[x] == marker:
				player.global_position = Vector2(x * tile_size, y * tile_size) + Vector2(tile_size * 0.5, tile_size * 0.5)
				return


static func finish_player_setup(
	zone: Node2D,
	map: Array,
	tile_size: int,
	atmosphere_theme: String = "labyrinth"
) -> Dictionary:
	var out := {"player": null, "gothic": null, "atmosphere": null}
	var alex := zone.get_node_or_null("Alex") as CharacterBody2D
	if alex:
		GameManager.player = alex
	var player := GameManager.player as CharacterBody2D
	if player == null:
		return out
	out.player = player
	move_player_to_spawn(player, map, tile_size)
	player.set_can_move(true)
	out.gothic = setup_gothic_alex(player)
	if player.has_method("_ensure_visible_character"):
		player._ensure_visible_character()
	out.atmosphere = apply_atmosphere(zone, player, atmosphere_theme)
	GridMapPhysics.set_map(map, tile_size)
	return out


static func create_hud(zone: Node, title: String, max_light: int = 3) -> PremiumZoneHUD:
	var hud := PremiumZoneHUD.new()
	hud.setup(title, GameManager.max_health, max_light)
	zone.add_child(hud)
	return hud
