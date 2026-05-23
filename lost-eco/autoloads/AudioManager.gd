extends Node

const MENU_MUSIC_PATH := "res://assets/audio/menu_ambient_nature.mp3"
const MENU_MUSIC_BASE_DB := -12.0

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

var sfx_library: Dictionary = {}
var music_library: Dictionary = {}
var _menu_music_active: bool = false
var _menu_music_fade: Tween


func _ready() -> void:
	add_child(music_player)
	add_child(sfx_player)
	music_player.bus = "Music"
	sfx_player.bus = "SFX"


func play_sfx(sfx_name: String) -> void:
	if sfx_library.has(sfx_name):
		sfx_player.stream = sfx_library[sfx_name]
		sfx_player.play()


func play_menu_music() -> void:
	# Si ya suena, no reiniciar ni cortar (menú ↔ opciones).
	if _menu_music_active and music_player.playing:
		return

	var loaded := load(MENU_MUSIC_PATH) as AudioStream
	if loaded == null:
		push_warning("AudioManager: no se encontró la música del menú en %s" % MENU_MUSIC_PATH)
		return

	var stream := loaded.duplicate() as AudioStream
	_set_stream_loop(stream, true)

	if _menu_music_fade and _menu_music_fade.is_valid():
		_menu_music_fade.kill()

	music_player.stream = stream
	music_player.volume_db = MENU_MUSIC_BASE_DB
	_menu_music_active = true
	music_player.play()


func stop_menu_music(fade_duration: float = 0.6) -> void:
	if not _menu_music_active or not music_player.playing:
		return

	_menu_music_active = false

	if _menu_music_fade and _menu_music_fade.is_valid():
		_menu_music_fade.kill()

	if fade_duration <= 0.0:
		music_player.stop()
		return

	var start_db := music_player.volume_db
	_menu_music_fade = create_tween()
	_menu_music_fade.tween_method(
		func(value: float) -> void: music_player.volume_db = value,
		start_db,
		-60.0,
		fade_duration
	)
	_menu_music_fade.tween_callback(func() -> void:
		music_player.stop()
		music_player.volume_db = MENU_MUSIC_BASE_DB
	)


func fade_to_track(track_name: String, duration: float = 2.0) -> void:
	if not music_library.has(track_name):
		return
	var tween := create_tween()
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


func _set_stream_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if enabled else AudioStreamWAV.LOOP_DISABLED
		)
