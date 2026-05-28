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
	var regions: Array = _detect_frame_regions(tex)
	if regions.is_empty():
		regions = [Rect2(0.0, 0.0, float(tex.get_width()), float(tex.get_height()))]
	for anim_name in ANIMS:
		if not sf.has_animation(anim_name):
			sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, anim_name in ["idle", "run"])
		sf.set_animation_speed(anim_name, _speed_for(anim_name, regions.size()))
		for region: Rect2 in _regions_for_anim(anim_name, regions):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = region
			sf.add_frame(anim_name, atlas, 1.0)
	return sf


static func _detect_frame_regions(tex: Texture2D) -> Array:
	var img := tex.get_image()
	if img == null:
		return []
	var tw := img.get_width()
	var th := img.get_height()
	if tw <= 0 or th <= 0:
		return []
	# Hoja horizontal (frames en fila).
	if tw >= th * 2:
		var cols := maxi(1, int(roundf(float(tw) / float(th))))
		var fw := float(tw) / float(cols)
		var out: Array = []
		for i in cols:
			out.append(Rect2(float(i) * fw, 0.0, fw, float(th)))
		return out
	# Hoja vertical (alex.png, exploradora.png…).
	if th >= tw * 2:
		return _detect_vertical_bands(img)
	if tw > th * 1.25:
		var fw := float(tw) * 0.5
		return [Rect2(0.0, 0.0, fw, float(th)), Rect2(fw, 0.0, fw, float(th))]
	return [Rect2(0.0, 0.0, float(tw), float(th))]


static func _detect_vertical_bands(img: Image) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var regions: Array = []
	var y := 0
	while y < h:
		while y < h and _row_alpha_count(img, y, w) < 5:
			y += 1
		if y >= h:
			break
		var band_start := y
		while y < h:
			if _row_alpha_count(img, y, w) < 3:
				var gap_start := y
				while y < h and _row_alpha_count(img, y, w) < 12:
					y += 1
				if y - gap_start >= 3:
					break
			else:
				y += 1
		var band_end := y - 1
		while band_end > band_start and _row_alpha_count(img, band_end, w) < 12:
			band_end -= 1
		for piece: Rect2 in _split_band_by_gaps(img, band_start, band_end, w):
			regions.append(piece)
	return regions


static func _split_band_by_gaps(img: Image, start: int, end: int, w: int) -> Array:
	var pieces: Array = []
	var seg_start := start
	var y := start + 1
	while y <= end:
		if _row_alpha_count(img, y, w) < 12:
			var gap_start := y
			while y <= end and _row_alpha_count(img, y, w) < 12:
				y += 1
			if y - gap_start >= 3 and y - seg_start >= 8:
				var seg_end := gap_start - 1
				while seg_end > seg_start and _row_alpha_count(img, seg_end, w) < 5:
					seg_end -= 1
				if seg_end - seg_start >= 8:
					pieces.append(Rect2(0.0, float(seg_start), float(w), float(seg_end - seg_start + 1)))
				seg_start = y
				continue
		y += 1
	if end - seg_start >= 8:
		pieces.append(Rect2(0.0, float(seg_start), float(w), float(end - seg_start + 1)))
	if pieces.is_empty():
		pieces.append(Rect2(0.0, float(start), float(w), float(end - start + 1)))
	return _filter_small_regions(pieces)


static func _filter_small_regions(regions: Array) -> Array:
	var out: Array = []
	for region: Rect2 in regions:
		if region.size.y >= 16.0 and region.size.x >= 8.0:
			out.append(region)
	return out


static func _row_alpha_count(img: Image, y: int, w: int) -> int:
	var count := 0
	for x in w:
		if img.get_pixel(x, y).a > 10:
			count += 1
	return count


static func _regions_for_anim(anim_name: String, regions: Array) -> Array:
	var total := regions.size()
	if total <= 0:
		return []
	match anim_name:
		"idle":
			return [regions[0]]
		"run":
			if total >= 3:
				return regions.slice(1)
			if total == 2:
				return [regions[0], regions[1]]
			return [regions[0]]
		"jump", "dash", "attack_pulse":
			var idx := mini(1, total - 1)
			return [regions[idx]]
		_:
			return [regions[0]]


static func _speed_for(anim: String, frame_count: int) -> float:
	match anim:
		"run":
			if frame_count >= 4:
				return 10.0
			if frame_count >= 3:
				return 9.0
			return 7.5
		"attack_pulse":
			return 12.0
		"dash":
			return 14.0
		"jump":
			return 8.0
		_:
			return 5.0
