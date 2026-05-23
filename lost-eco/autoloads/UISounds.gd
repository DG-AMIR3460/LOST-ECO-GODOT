extends Node
## Sonidos de interfaz: hover y click con el mismo tono celestial/místico.

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer


func _ready() -> void:
	var celestial := _build_celestial_hover()
	_hover_player = _create_player(celestial)
	_click_player = _create_player(celestial.duplicate())
	add_child(_hover_player)
	add_child(_click_player)


func play_hover() -> void:
	_play_one_shot(_hover_player)


func play_click() -> void:
	_play_one_shot(_click_player)


func _create_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	return player


func _play_one_shot(player: AudioStreamPlayer) -> void:
	if SettingsManager.sfx_volume <= 0.0:
		return
	player.stop()
	player.play()


## Campanada etérea con armónicos suaves y un leve brillo ascendente (estilo fantasy UI).
func _build_celestial_hover() -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 0.34
	var sample_count := int(mix_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)

	var frequencies: PackedFloat32Array = PackedFloat32Array([523.25, 659.25, 783.99, 1046.5, 1318.5])
	var harmonic_gains: PackedFloat32Array = PackedFloat32Array([1.0, 0.72, 0.58, 0.38, 0.22])

	for i in sample_count:
		var t := float(i) / float(mix_rate)
		var progress := t / duration

		var attack := smoothstep(0.0, 0.018, t)
		var decay := exp(-3.2 * progress)
		var envelope := attack * decay

		var pitch_bend := 1.0 + progress * 0.06
		var vibrato := 1.0 + 0.004 * sin(t * 10.5 * TAU)

		var sample := 0.0
		for h in frequencies.size():
			var wave_freq := frequencies[h] * pitch_bend * vibrato
			sample += sin(t * wave_freq * TAU) * harmonic_gains[h]

		sample += sin(t * 2100.0 * TAU) * 0.035 * envelope
		sample *= envelope * 0.16

		var int_sample := int(clamp(sample, -1.0, 1.0) * 32767.0)
		pcm[i * 2] = int_sample & 0xFF
		pcm[i * 2 + 1] = (int_sample >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = pcm
	return stream
