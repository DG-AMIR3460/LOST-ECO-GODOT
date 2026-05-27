extends RefCounted
class_name LightTextureFactory
## Generación procedural de texturas radiales para PointLight2D (jugador y enemigos).


static func create_halo_gradient(size: int = 128, inner_power: float = 1.65, peak_alpha: float = 0.92) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center) / radius
			var core := clampf(1.0 - d * 0.55, 0.0, 1.0)
			var a := pow(clampf(1.0 - d, 0.0, 1.0), inner_power) * peak_alpha * core
			var warmth := 1.0 - d * 0.35
			img.set_pixel(x, y, Color(warmth, warmth * 0.9, warmth * 0.72, a))
	return ImageTexture.create_from_image(img)


static func create_crimson_eye(size: int = 32, intensity: float = 1.0) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center) / radius
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.8) * intensity
			img.set_pixel(x, y, Color(1.0, 0.08, 0.12, a))
	return ImageTexture.create_from_image(img)


static func apply_halo_to_light(light: PointLight2D, color: Color = Color(1.0, 0.9, 0.68), energy: float = 0.65, scale: float = 1.4) -> void:
	if light == null:
		return
	light.texture = create_halo_gradient()
	light.color = color
	light.energy = energy
	light.texture_scale = scale
	light.shadow_enabled = false
	light.blend_mode = Light2D.BLEND_MODE_MIX


static func apply_crimson_eye(light: PointLight2D, offset: Vector2 = Vector2.ZERO, energy: float = 1.15) -> void:
	if light == null:
		return
	light.texture = create_crimson_eye()
	light.color = Color(1.0, 0.05, 0.1)
	light.energy = energy
	light.texture_scale = 0.55
	light.position = offset
	light.shadow_enabled = false
	light.blend_mode = Light2D.BLEND_MODE_ADD
