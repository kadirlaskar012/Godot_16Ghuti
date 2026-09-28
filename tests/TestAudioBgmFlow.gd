extends Node

func _ready() -> void:
	print("\n=== RUNNING TEST: Audio BGM Glitch-Free Playback ===")
	
	# 1. Verify stream loading and loop mode
	var bgm_stream = AudioManager.sounds.get("bgm")
	assert(bgm_stream != null, "BGM stream must exist")
	print("✔ BGM stream exists. Type: ", bgm_stream.get_class())
	if bgm_stream is AudioStreamWAV:
		print("  Loop mode: ", bgm_stream.loop_mode, " (1=LOOP_FORWARD)")
		assert(bgm_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Stream must loop forward")
		assert(bgm_stream.loop_begin == 0, "Loop begin must be 0")
	
	# 2. Start music and verify active playback
	print("Music player initial playing:", AudioManager.music_player.playing)
	AudioManager.music_player.finished.connect(func(): print("EVENT: music_player finished emitted!"))
	
	# Wait a small duration
	await get_tree().create_timer(0.2).timeout
	print("Music player playing after 0.2s:", AudioManager.music_player.playing)
	print("Stream:", AudioManager.music_player.stream)
	if AudioManager.music_player.stream is AudioStreamWAV:
		print("WAV loop_mode:", AudioManager.music_player.stream.loop_mode, " loop_begin:", AudioManager.music_player.stream.loop_begin, " loop_end:", AudioManager.music_player.stream.loop_end)
	assert(AudioManager.music_player.playing, "Music player must be active")
	
	# 3. Simulate multiple scene calls to play_music() (e.g. entering game, opening menu)
	# It must NOT interrupt or change stream!
	var stream_before = AudioManager.music_player.stream
	AudioManager.play_music()
	AudioManager.play_music("bgm")
	assert(AudioManager.music_player.stream == stream_before, "Stream must remain identical")
	assert(AudioManager.music_player.playing, "Music player must remain playing continuously")
	print("✔ Seamless non-interrupting play_music() verified (No scene transition glitches).")
	
	# 4. Test disable and enable toggle
	AudioManager.update_audio_settings()
	SaveManager.settings.music_enabled = false
	AudioManager.update_audio_settings()
	assert(not AudioManager.music_player.playing, "Music must stop when disabled")
	
	SaveManager.settings.music_enabled = true
	AudioManager.update_audio_settings()
	assert(AudioManager.music_player.playing, "Music must resume when enabled")
	print("✔ Music settings toggle verified.")
	
	print("\nALL AUDIO BGM TESTS PASSED (100%)!\n")
	get_tree().quit(0)
