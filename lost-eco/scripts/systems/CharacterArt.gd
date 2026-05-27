extends RefCounted
class_name CharacterArt
## Recorta sprites del sheet de personajes y enemigos del juego.
## Carga perezosa: no usa preload para evitar errores si Godot aún no importó las PNG.

const CHAR_SHEET_PATH := "res://assets/sprites/characters_enemies_sheet.png"
const RUN_SHEET_PATH := "res://assets/sprites/sprites_running_sheet.png"

static var _char_sheet: Texture2D
static var _run_sheet: Texture2D
static var _load_attempted: bool = false

# Hoja de concepto: fila superior = héroes, fila inferior = enemigos (1024×682)
const REGIONS: Dictionary = {
	"alex": Rect2(384, 8, 118, 300),
	"exploradora": Rect2(0, 8, 138, 300),
	"monje": Rect2(146, 8, 138, 300),
	"medium": Rect2(292, 8, 138, 300),
	"niña_perdida": Rect2(730, 8, 138, 300),
	"susurrantes": Rect2(0, 350, 120, 310),
	"parasito": Rect2(128, 350, 120, 310),
	"ahogados": Rect2(256, 350, 120, 310),
	"hombre_lodo": Rect2(384, 350, 120, 310),
	"humo_negro": Rect2(512, 350, 120, 310),
	"vigilantes": Rect2(640, 350, 120, 310),
	"caballero": Rect2(768, 350, 120, 310),
	"espectro": Rect2(896, 350, 120, 310),
}

const DEFAULT_SCALE: Dictionary = {
	"alex": 0.11,
	"susurrantes": 0.10,
	"parasito": 0.10,
	"ahogados": 0.10,
	"hombre_lodo": 0.095,
	"humo_negro": 0.10,
	"vigilantes": 0.10,
	"caballero": 0.11,
	"espectro": 0.10,
}


static func is_ready() -> bool:
	_ensure_sheets()
	return _char_sheet != null


static func _ensure_sheets() -> void:
	if _load_attempted:
		return
	_load_attempted = true
	if ResourceLoader.exists(CHAR_SHEET_PATH):
		_char_sheet = load(CHAR_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(RUN_SHEET_PATH):
		_run_sheet = load(RUN_SHEET_PATH) as Texture2D
	if _char_sheet == null:
		push_warning("CharacterArt: abre el proyecto en Godot para importar %s" % CHAR_SHEET_PATH)


static func make_sprite(key: String, scale_override: float = -1.0) -> Sprite2D:
	_ensure_sheets()
	var sheet: Texture2D = _run_sheet if key == "alex_run" else _char_sheet
	if sheet == null:
		return null

	var region: Rect2 = REGIONS.get(key, REGIONS["susurrantes"])
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	if key == "alex_run":
		atlas.region = Rect2(384, 8, 118, 140)
	else:
		atlas.region = region

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = atlas
	sprite.centered = true
	var scale_val: float = scale_override if scale_override > 0.0 else DEFAULT_SCALE.get(key, 0.10)
	sprite.scale = Vector2(scale_val, scale_val)
	sprite.offset = Vector2(0, -region.size.y * scale_val * 0.35)
	return sprite
