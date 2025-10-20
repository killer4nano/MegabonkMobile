extends Control
class_name MainMenu
## Main Menu - Entry point for the game

# UI References
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var essence_label: Label = $TopBar/EssenceLabel
@onready var stats_label: Label = $TopBar/StatsLabel

func _ready() -> void:
	# Connect button signals
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	# Update UI with current stats
	update_ui()

	print("MainMenu initialized")

func update_ui() -> void:
	"""Update UI labels with current player stats"""
	if essence_label:
		essence_label.text = "Essence: %d" % GlobalData.extraction_currency

	if stats_label:
		stats_label.text = "Runs: %d | Extractions: %d | Best: %s" % [
			GlobalData.total_runs,
			GlobalData.successful_extractions,
			format_time(GlobalData.longest_run)
		]

func _on_play_pressed() -> void:
	"""Open character selection screen"""
	print("Opening character selection...")

	# Go to character select screen (will handle run reset and game start)
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelectScreen.tscn")

func _on_settings_pressed() -> void:
	"""Open settings menu (not implemented yet)"""
	print("Settings button pressed (not implemented)")
	# TODO: Implement settings menu

func _on_quit_pressed() -> void:
	"""Quit the game"""
	print("Quitting game...")
	get_tree().quit()

func format_time(seconds: float) -> String:
	"""Format seconds as MM:SS"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
