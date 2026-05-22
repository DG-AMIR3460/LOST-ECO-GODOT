extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

var sfx_library: Dictionary = {}
var music_library: Dictionary = {}

func _ready() -> void:
	add_child(music_player)
	add_child(sfx_player)
	music_player.bus = "Music"
	sfx_player.bus = "SFX"

func play_sfx(sfx_name: String) -> void:
	if sfx_library.has(sfx_name):
		sfx_player.stream = sfx_library[sfx_name]
		sfx_player.play()

func fade_to_track(track_name: String, duration: float = 2.0) -> void:
	if not music_library.has(track_name):
		return
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, duration / 2)
	tween.tween_callback(func():
		music_player.stream = music_library[track_name]
		music_player.play()
	)
	tween.tween_property(music_player, "volume_db", 0.0, duration / 2)

func register_sfx(sfx_name: String, stream: AudioStream) -> void:
	sfx_library[sfx_name] = stream

func register_music(track_name: String, stream: AudioStream) -> void:
	music_library[track_name] = stream
