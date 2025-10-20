extends Node
## SaveSystem - Handles saving and loading player progression

const SAVE_PATH: String = "user://save_data.json"

func _ready() -> void:
	load_game()

func save_game() -> void:
	"""Save all persistent data to file"""
	var save_data: Dictionary = {
		"account_level": GlobalData.account_level,
		"account_xp": GlobalData.account_xp,
		"extraction_currency": GlobalData.extraction_currency,
		"unlocked_characters": GlobalData.unlocked_characters,
		"unlocked_weapons": GlobalData.unlocked_weapons,
		"unlocked_upgrades": GlobalData.unlocked_upgrades,
		"unlocked_maps": GlobalData.unlocked_maps,
		"settings": {
			"master_volume": GlobalData.master_volume,
			"music_volume": GlobalData.music_volume,
			"sfx_volume": GlobalData.sfx_volume,
			"graphics_quality": GlobalData.graphics_quality,
			"show_fps": GlobalData.show_fps,
			"control_scheme": GlobalData.control_scheme,
		},
		"statistics": {
			"total_runs": GlobalData.total_runs,
			"successful_extractions": GlobalData.successful_extractions,
			"total_enemies_killed": GlobalData.total_enemies_killed,
			"total_playtime": GlobalData.total_playtime,
			"longest_run": GlobalData.longest_run,
		}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("Game saved successfully!")
	else:
		push_error("Failed to save game!")

func load_game() -> void:
	"""Load persistent data from file"""
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found. Using default values.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string := file.get_as_text()
		file.close()

		var json := JSON.new()
		var parse_result := json.parse(json_string)

		if parse_result == OK:
			var save_data: Dictionary = json.data

			# Load data into GlobalData
			GlobalData.account_level = save_data.get("account_level", 1)
			GlobalData.account_xp = save_data.get("account_xp", 0)
			GlobalData.extraction_currency = save_data.get("extraction_currency", 0)
			GlobalData.unlocked_characters = save_data.get("unlocked_characters", ["warrior"])
			GlobalData.unlocked_weapons = save_data.get("unlocked_weapons", ["bonk_hammer"])
			GlobalData.unlocked_upgrades = save_data.get("unlocked_upgrades", [])
			GlobalData.unlocked_maps = save_data.get("unlocked_maps", ["arena_01"])

			# Load settings
			var settings: Dictionary = save_data.get("settings", {})
			GlobalData.master_volume = settings.get("master_volume", 1.0)
			GlobalData.music_volume = settings.get("music_volume", 0.7)
			GlobalData.sfx_volume = settings.get("sfx_volume", 1.0)
			GlobalData.graphics_quality = settings.get("graphics_quality", 1)
			GlobalData.show_fps = settings.get("show_fps", false)
			GlobalData.control_scheme = settings.get("control_scheme", 0)

			# Load statistics
			var stats: Dictionary = save_data.get("statistics", {})
			GlobalData.total_runs = stats.get("total_runs", 0)
			GlobalData.successful_extractions = stats.get("successful_extractions", 0)
			GlobalData.total_enemies_killed = stats.get("total_enemies_killed", 0)
			GlobalData.total_playtime = stats.get("total_playtime", 0.0)
			GlobalData.longest_run = stats.get("longest_run", 0.0)

			print("Game loaded successfully!")
		else:
			push_error("Failed to parse save file!")
	else:
		push_error("Failed to open save file!")

func delete_save() -> void:
	"""Delete save file (for debugging or reset)"""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted!")
