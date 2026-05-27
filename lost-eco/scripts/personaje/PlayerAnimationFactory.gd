extends RefCounted
class_name PlayerAnimationFactory
## Genera SpriteFrames desde texturas del proyecto (skins CharacterArt).

const ANIMS: PackedStringArray = ["idle", "run", "jump", "dash", "attack_pulse"]


static func build_from_skin(skin_key: String) -> SpriteFrames:
	var tex := _texture_for_skin(skin_key)
	if tex == null:
		tex = _texture_for_skin("exploradora")
	if tex == null:
		tex = _texture_for_skin("alex")
	return build_from_texture(tex)


static func _texture_for_skin(skin_key: String) -> Texture2D:
	var spr := CharacterArt.make_sprite(skin_key)
	return spr.texture if spr else null


static func build_from_texture(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if tex == null:
		return sf
	var tw := tex.get_width()
	var th := tex.get_height()
	var cols := 1
	# Hoja horizontal de animación (ancho >> alto).
	if tw >= th * 2:
		cols = maxi(1, int(roundf(float(tw) / float(th))))
	elif tw > th * 1.25:
		cols = 2
	for anim_name in ANIMS:
		if not sf.has_animation(anim_name):
			sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, anim_name in ["idle", "run"])
		sf.set_animation_speed(anim_name, _speed_for(anim_name))
		var frame_count := _frame_count_for(anim_name, cols)
		for i in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			var fw := float(tw) / float(cols) if cols > 1 else float(tw)
			atlas.region = Rect2((i % cols) * fw, 0.0, fw, float(th))
			sf.add_frame(anim_name, atlas, 1.0)
	return sf


static func _speed_for(anim: String) -> float:
	match anim:
		"run": return 9.0
		"attack_pulse": return 12.0
		"dash": return 14.0
		"jump": return 8.0
		_: return 5.0


static func _frame_count_for(anim: String, cols: int) -> int:
	if cols >= 4 and anim == "run":
		return mini(4, cols)
	if cols >= 2 and anim == "idle":
		return mini(2, cols)
	return 1
