extends Control
class_name ExtractionSuccessScreen
## Extraction Success Screen - Shown after successful extraction, displays earned rewards

# UI References
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var time_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var kills_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/KillsLabel
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsContainer/GoldLabel
@onready var multiplier_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RewardsContainer/MultiplierLabel
@onready var essence_earned_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RewardsContainer/EssenceEarnedLabel
@onready var total_essence_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RewardsContainer/TotalEssenceLabel
@onready var return_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ReturnButton

# Extraction results
var extraction_results: Dictionary = {}

func _ready() -> void:
	# Get extraction results from GlobalData
	extraction_results = GlobalData.last_extraction_results
	if extraction_results and not extraction_results.is_empty():
		print("DEBUG: Extraction results loaded: ", extraction_results)
	else:
		print("WARNING: No extraction results found in GlobalData!")

	# Connect button
	if return_button:
		return_button.pressed.connect(_on_return_pressed)
		print("DEBUG: Return button connected successfully")
	else:
		push_error("ERROR: Return button not found!")

	# Update UI with extraction stats
	update_ui()

	print("ExtractionSuccessScreen initialized")

func update_ui() -> void:
	"""Display extraction success statistics and rewards"""
	if title_label:
		title_label.text = "EXTRACTION SUCCESSFUL!"

	# Time survived
	if time_label and extraction_results.has("time_survived"):
		var time = extraction_results["time_survived"]
		time_label.text = "Time Survived: %s" % format_time(time)

	# Enemies killed
	if kills_label and extraction_results.has("enemies_killed"):
		kills_label.text = "Enemies Killed: %d" % extraction_results["enemies_killed"]

	# Gold collected
	if gold_label and extraction_results.has("gold_collected"):
		gold_label.text = "Gold Collected: %d" % extraction_results["gold_collected"]

	# Extraction multiplier
	if multiplier_label and extraction_results.has("multiplier"):
		multiplier_label.text = "Extraction Multiplier: %.1fx" % extraction_results["multiplier"]

	# Essence earned this run
	if essence_earned_label and extraction_results.has("essence_earned"):
		essence_earned_label.text = "Essence Earned: +%d" % extraction_results["essence_earned"]

	# Total essence
	if total_essence_label:
		total_essence_label.text = "Total Essence: %d" % GlobalData.extraction_currency

func _on_return_pressed() -> void:
	"""Return to main menu"""
	print("======================")
	print("RETURN BUTTON CLICKED!")
	print("======================")
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	"""Debug: Track all input events"""
	if event is InputEventMouseButton and event.pressed:
		print("DEBUG: Mouse click detected at ", event.position)

func format_time(seconds: float) -> String:
	"""Format seconds as MM:SS"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
