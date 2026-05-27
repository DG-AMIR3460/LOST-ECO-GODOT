extends Node
class_name PlayerSkinMapper
## Pipeline de skins inclusivo — hot-swap de Sprite2D sin Singleton.

signal skin_changed(skin_id: String)

const SKINS: Dictionary = {
	"exploradora": "exploradora",
	"monje": "monje",
	"medium": "medium",
	"cazador": "cazador",
	"niña_perdida": "niña_perdida",
	"navegante": "navegante",
	"alex": "alex",
}

var _player: PlayerController2D = null
var _current_id: String = "exploradora"


func bind_player(player: PlayerController2D) -> void:
	_player = player
	apply_skin(_current_id)


func apply_skin(skin_id: String) -> void:
	if not SKINS.has(skin_id):
		push_warning("PlayerSkinMapper: skin '%s' no existe" % skin_id)
		return
	_current_id = skin_id
	if _player == null:
		return
	var gv := _player.get_node_or_null("GothicVisual") as GothicPlayerVisual
	if gv:
		gv.apply_skin(SKINS[skin_id])
		if _player.sprite:
			_player.sprite.visible = false
		skin_changed.emit(skin_id)
		return
	if _player.sprite == null:
		return
	var sprite_node := CharacterArt.make_sprite(SKINS[skin_id])
	if sprite_node == null:
		if _player.has_method("_use_fallback_visual"):
			_player._use_fallback_visual()
		return
	_player.sprite.texture = sprite_node.texture
	_player.sprite.scale = sprite_node.scale
	_player.sprite.visible = true
	skin_changed.emit(skin_id)


func get_current_skin() -> String:
	return _current_id


func get_skin_list() -> PackedStringArray:
	var keys: PackedStringArray = []
	for k in SKINS.keys():
		keys.append(k)
	return keys
