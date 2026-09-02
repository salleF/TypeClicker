extends Node

# SoundManager.gd - Handles sound effects using recorded MP3 audio assets and procedural fallbacks

var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 16

# Loaded Audio Assets
var sfx_key_1: AudioStream = preload("res://assets/sound/Keyboard Typing 1.mp3")
var sfx_erro: AudioStream = preload("res://assets/sound/Erro.mp3")
var sfx_lever: AudioStream = preload("res://assets/sound/Lever.mp3")
var sfx_bell: AudioStream = preload("res://assets/sound/Bell.mp3")
var sfx_next_page: AudioStream = preload("res://assets/sound/Next page.mp3")
var sfx_paper_crumple: AudioStream = preload("res://assets/sound/Paper Crump.mp3")
var sfx_buy: AudioStream = preload("res://assets/sound/buy_1.mp3")

# Procedural Fallbacks for Coffee
var coffee_serve_stream: AudioStreamWAV

func _ready() -> void:
	for i in range(max_sfx_players):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

	# Ensure all one-shot SFX streams never loop infinitely
	for sfx in [sfx_key_1, sfx_erro, sfx_lever, sfx_bell, sfx_next_page, sfx_paper_crumple, sfx_buy]:
		if sfx is AudioStreamMP3:
			(sfx as AudioStreamMP3).loop = false
		elif sfx is AudioStreamWAV:
			(sfx as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED

	_generate_procedural_chimes()

func _generate_procedural_chimes() -> void:
	coffee_serve_stream = _synthesize_coffee_serve()

func _get_available_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

func play_sound(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not GameManager.sound_enabled or stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED

	var player = _get_available_player()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(GameManager.sfx_volume)
	player.pitch_scale = pitch_scale
	player.play()

# --- Game Audio Triggers ---

# Plays Keyboard Typing 1 with natural organic pitch variation
func play_key_clack(is_special: bool = false) -> void:
	var pitch = randf_range(0.94, 1.06)
	var vol = -2.0 if not is_special else 1.0
	play_sound(sfx_key_1, vol, pitch)

# Played when completing an entire word (Carriage return lever pulled)
func play_word_lever() -> void:
	play_sound(sfx_lever, 0.0, randf_range(0.98, 1.02))

# Played on page completion: Bell ding followed by Next Page flip sound
func play_page_complete() -> void:
	play_sound(sfx_bell, 1.0, 1.0)
	await get_tree().create_timer(0.22).timeout
	play_sound(sfx_next_page, 0.0, randf_range(0.98, 1.02))

# Played when a mistake is made
func play_mistake() -> void:
	play_sound(sfx_erro, 1.0, randf_range(0.96, 1.04))

# Played when crumpling / discarding the paper
func play_paper_crumple() -> void:
	play_sound(sfx_paper_crumple, 0.0, randf_range(0.96, 1.04))

func play_paper_rip() -> void:
	play_sound(sfx_paper_crumple, -1.0, randf_range(1.05, 1.15))

func play_paper_insert() -> void:
	play_sound(sfx_next_page, -3.0, 1.2)

func play_trash_thud() -> void:
	play_sound(sfx_paper_crumple, -2.0, 0.9)

func play_coffee_serve() -> void:
	play_sound(coffee_serve_stream, 1.0, 1.0)

# Played when purchasing a tome upgrade
func play_upgrade_buy() -> void:
	play_sound(sfx_buy, 0.0, 1.0)

# Procedural chimes
func _synthesize_coffee_serve() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.4
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 8.0)
		var tone = sin(2.0 * PI * 880.0 * t) * 0.5 + sin(2.0 * PI * 1320.0 * t) * 0.5
		var sample = tone * env * 0.8
		data[i] = int(clamp((sample + 1.0) * 127.5, 0, 255))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _synthesize_upgrade_buy() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 10.0)
		var freq = 523.25 if t < 0.1 else (659.25 if t < 0.2 else 783.99)
		var tone = sin(2.0 * PI * freq * t)
		var sample = tone * env * 0.7
		data[i] = int(clamp((sample + 1.0) * 127.5, 0, 255))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav
