extends Control
class_name DeathScreen
## Death Screen - Shown when player dies, displays lost rewards

# UI References
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var time_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var kills_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/KillsLabel
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/GoldLabel
@onready var essence_lost_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LostRewardsContainer/EssenceLostLabel
@onready var return_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ReturnButton

# Death results
var death_results: Dictionary = {}

func _ready() -> void:
	# Get death results from GlobalData
	death_results = GlobalData.last_death_results

	# Connect button
	if return_button:
		return_button.pressed.connect(_on_return_pressed)

	# Update UI with death stats
	update_ui()

	print("DeathScreen initialized")

func update_ui() -> void:
	"""Display death statistics"""
	if title_label:
		title_label.text = "YOU DIED"

	# Time survived
	if time_label and death_results.has("time_survived"):
		var time = death_results["time_survived"]
		time_label.text = "Time Survived: %s" % format_time(time)

	# Enemies killed
	if kills_label and death_results.has("enemies_killed"):
		kills_label.text = "Enemies Killed: %d" % death_results["enemies_killed"]

	# Gold lost
	if gold_label and death_results.has("gold_lost"):
		gold_label.text = "Gold Lost: %d" % death_results["gold_lost"]

	# Essence that would have been earned (but was lost)
	if essence_lost_label and death_results.has("essence_lost"):
		essence_lost_label.text = "Essence Lost: %d" % int(death_results["essence_lost"])

func _on_return_pressed() -> void:
	"""Return to main menu"""
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func format_time(seconds: float) -> String:
	"""Format seconds as MM:SS"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
