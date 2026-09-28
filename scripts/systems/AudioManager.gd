extends Node

## AudioManager Singleton
## Manages SFX playback, seamless ambient music loops, and volume fading.

var sfx_players: Dictionary = {}
var music_player: AudioStreamPlayer

var sounds: Dictionary = {
	"click": preload("res://assets/audio/sfx_click.wav"),
	"select": preload("res://assets/audio/sfx_select.wav"),
	"move": preload("res://assets/audio/sfx_move.wav"),
	"capture": preload("res://assets/audio/sfx_capture.wav"),
	"invalid": preload("res://assets/audio/sfx_invalid.wav"),
	"turn": preload("res://assets/audio/sfx_turn.wav"),
	"thinking": preload("res://assets/audio/sfx_thinking.wav"),
	"victory": preload("res://assets/audio/sfx_victory.wav"),
	"defeat": preload("res://assets/audio/sfx_defeat.wav"),
	"tick": preload("res://assets/audio/sfx_tick.wav"),
	"alert": preload("res://assets/audio/sfx_alert.wav"),
	"bgm": preload("res://assets/audio/bgm_ambient.wav")
}

func _ready() -> void:
	# Create music player on Game bus
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Game"
	music_player.volume_db = -8.0
	add_child(music_player)
	
	# Configure loop on BGM stream
	var bgm_stream = sounds.get("bgm")
	if bgm_stream and bgm_stream is AudioStreamWAV:
		bgm_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm_stream.loop_begin = 0
		bgm_stream.loop_end = -1
		
	# Fallback restart ONLY if stream is not already natively looping
	music_player.finished.connect(func():
		var sm = get_node_or_null("/root/SaveManager")
		var is_enabled = sm.settings.music_enabled if (sm and sm.settings) else true
		if is_enabled and music_player.stream:
			if music_player.stream is AudioStreamWAV and music_player.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
				music_player.play()
	)
	
	# Create pool of SFX players on Game bus with custom acoustic mix levels
	var volume_offsets = {
		"move": 1.5,
		"capture": 3.0,
		"select": -5.0,
		"click": -2.0,
		"invalid": -4.0,
		"turn": -2.0,
		"thinking": -80.0,
		"victory": 0.5,
		"defeat": -1.0,
		"tick": 2.0,
		"alert": 1.5
	}
	for sfx_name in sounds.keys():
		if sfx_name == "bgm":
			continue
		var p = AudioStreamPlayer.new()
		p.stream = sounds[sfx_name]
		p.bus = "Game"
		p.volume_db = volume_offsets.get(sfx_name, 0.0)
		add_child(p)
		sfx_players[sfx_name] = p
		
	sync_all_bus_settings()
	start_bgm()

func play_sfx(sound_name: String, pitch: float = 1.0) -> void:
	var sound_on: bool = true
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.settings:
		sound_on = sm.settings.sound_enabled
		
	if not sound_on:
		return
		
	if sfx_players.has(sound_name):
		var p: AudioStreamPlayer = sfx_players[sound_name]
		p.pitch_scale = pitch
		p.play()

func play_music(music_name: String = "bgm") -> void:
	var music_on: bool = true
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.settings:
		music_on = sm.settings.music_enabled
		
	if not music_on:
		if music_player and music_player.playing:
			music_player.stop()
		return
		
	if sounds.has(music_name):
		var stream = sounds[music_name]
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = -1
			
		# If this music is ALREADY playing smoothly, do not interrupt or re-assign stream!
		if music_player.playing and music_player.stream == stream:
			return
			
		if music_player.stream != stream:
			music_player.stream = stream
			
		if not music_player.playing:
			music_player.play()

func stop_music() -> void:
	music_player.stop()

func update_audio_settings() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.settings:
		if sm.settings.music_enabled:
			if not music_player.playing:
				play_music()
		else:
			stop_music()
		sync_all_bus_settings()

func sync_all_bus_settings() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm or not sm.settings:
		return
	var s = sm.settings
	set_bus_volume("Master", s.master_volume)
	set_bus_volume("Game", s.game_volume)
	set_bus_volume("Voice", s.voice_volume)
	set_bus_mute("Master", not (s.sound_enabled or s.music_enabled))
	set_bus_mute("Voice", s.speaker_muted or s.opponent_voice_muted)

func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		var db = linear_to_db(clampf(linear, 0.001, 1.0))
		AudioServer.set_bus_volume_db(idx, db)

func set_bus_mute(bus_name: String, mute: bool) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, mute)

func start_bgm() -> void:
	play_music()
