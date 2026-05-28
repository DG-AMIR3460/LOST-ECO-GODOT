extends RefCounted
class_name CharacterArt
## Sprites embebidos en el proyecto (funcionan aunque OneDrive bloquee archivos).

const SPRITE_DIR := "res://assets/sprites/"

const SPRITE_FILES: Dictionary = {
	"alex": "alex.png",
	"mateo": "mateo.png",
	"exploradora": "exploradora.png",
	"monje": "monje.png",
	"medium": "medium.png",
	"cazador": "cazador.png",
	"tirador": "tirador.png",
	"niña_perdida": "nina_perdida.png",
	"navegante": "navegante.png",
	"susurrantes": "susurrantes.png",
	"parasito": "parasito.png",
	"ahogados": "ahogados.png",
	"hombre_lodo": "hombre_lodo.png",
	"humo_negro": "humo_negro.png",
	"vigilantes": "vigilantes.png",
	"caballero": "caballero.png",
	"espectro": "espectro.png",
}

const FACES_LEFT: Dictionary = {
	"alex": true,
	"mateo": false,
	"exploradora": false,
	"monje": false,
	"medium": false,
	"cazador": false,
	"tirador": false,
	"niña_perdida": false,
	"navegante": false,
	"susurrantes": true,
	"parasito": true,
	"ahogados": true,
	"hombre_lodo": true,
	"humo_negro": true,
	"vigilantes": false,
	"caballero": false,
	"espectro": true,
}


const DEFAULT_SCALE: Dictionary = {
	"alex": 0.112,
	"mateo": 0.36,
	"exploradora": 0.15,
	"monje": 0.15,
	"medium": 0.15,
	"cazador": 0.15,
	"niña_perdida": 0.14,
	"navegante": 0.15,
	"tirador": 0.15,
	"susurrantes": 0.14,
	"parasito": 0.14,
	"ahogados": 0.14,
	"hombre_lodo": 0.13,
	"humo_negro": 0.14,
	"vigilantes": 0.14,
	"caballero": 0.15,
	"espectro": 0.14,
}

static var _cache: Dictionary = {}


static func clear_cache() -> void:
	_cache.clear()


static func is_ready() -> bool:
	return make_sprite("alex") != null


static func get_sprite_scale(key: String, scale_override: float = -1.0) -> float:
	return scale_override if scale_override > 0.0 else DEFAULT_SCALE.get(key, 0.14)


static func sprite_faces_left(key: String) -> bool:
	return FACES_LEFT.get(key, false)


static func make_sprite(key: String, scale_override: float = -1.0) -> Sprite2D:
	var tex := _load_texture(key)
	if tex == null:
		return null

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.centered = true
	var scale_val: float = get_sprite_scale(key, scale_override)
	sprite.scale = Vector2(scale_val, scale_val)
	var h := tex.get_height() * scale_val
	sprite.offset = Vector2(0, -h * 0.30)
	return sprite


static func _load_texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]

	var tex := _load_embedded(key)
	if tex == null:
		tex = _load_from_disk(key)
	if tex:
		_cache[key] = tex
	return tex


static func _load_embedded(key: String) -> Texture2D:
	if not CharacterSpritesData.EMBEDDED.has(key):
		return null
	var raw := Marshalls.base64_to_raw(CharacterSpritesData.EMBEDDED[key])
	var img := Image.new()
	if img.load_png_from_buffer(raw) != OK:
		return null
	return ImageTexture.create_from_image(img)


static func _load_from_disk(key: String) -> Texture2D:
	var file_name: String = SPRITE_FILES.get(key, "")
	if file_name.is_empty():
		return null
	var img := _read_png_image(SPRITE_DIR + file_name)
	if img == null:
		return null
	return ImageTexture.create_from_image(img)


static func _read_png_image(resource_path: String) -> Image:
	var paths: Array[String] = [resource_path]
	var abs_path := ProjectSettings.globalize_path(resource_path)
	if not abs_path.is_empty():
		paths.append(abs_path)
	for path in paths:
		var img := Image.new()
		if img.load(path) == OK:
			return img
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			if img.load_png_from_buffer(file.get_buffer(file.get_length())) == OK:
				return img
	return null
