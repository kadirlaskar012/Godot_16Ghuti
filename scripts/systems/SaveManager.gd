extends Node

## SaveManager Singleton
## Persists player data and settings locally to user://save_data.json

const SAVE_PATH: String = "user://save_data.json"

var settings: GameSettings = GameSettings.new()
var player_data: PlayerData = PlayerData.new()

signal data_loaded
signal data_saved

func _ready() -> void:
	load_data()

func save_data() -> void:
	var payload = {
		"version": 1,
		"settings": settings.to_dict(),
		"player": player_data.to_dict()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(payload, "\t")
		file.store_string(json_str)
		file.close()
		data_saved.emit()
	else:
		push_error("Failed to write save file at %s: %s" % [SAVE_PATH, FileAccess.get_open_error()])

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# Create initial save
		save_data()
		data_loaded.emit()
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_err = json.parse(content)
		if parse_err == OK and json.data is Dictionary:
			var d = json.data
			if d.has("settings"):
				settings.from_dict(d["settings"])
			if d.has("player"):
				player_data.from_dict(d["player"])
			data_loaded.emit()
		else:
			push_warning("Save file parse error; using defaults.")
	else:
		push_warning("Could not open save file; using defaults.")
