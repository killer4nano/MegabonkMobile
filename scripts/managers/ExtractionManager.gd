extends Node
## ExtractionManager - Manages extraction zone spawning and extraction logic
## Handles the risk/reward extraction system

# Extraction zone scene
const EXTRACTION_ZONE_SCENE = preload("res://scenes/levels/ExtractionZone.tscn")

# Configuration
@export var first_extraction_time: float = 180.0  # 3 minutes
@export var extraction_interval: float = 180.0  # Every 3 minutes after first
@export var arena_radius: float = 15.0  # Distance from center for extraction spawns

# State
var current_extraction_zone: Node3D = null
var extraction_timer: Timer
var extraction_spawn_timer: float = 0.0
var next_extraction_time: float = 0.0
var is_extraction_available: bool = false

# Extraction multiplier thresholds (in seconds)
const MULTIPLIER_TIER_1 = 180.0   # 3 min: 1.0x
const MULTIPLIER_TIER_2 = 360.0   # 6 min: 1.5x
const MULTIPLIER_TIER_3 = 540.0   # 9 min: 2.0x
const MULTIPLIER_TIER_4 = 540.0   # 9+ min: 3.0x

func _ready() -> void:
	# Connect to EventBus signals
	EventBus.extraction_success.connect(_on_extraction_success)
	EventBus.game_started.connect(_on_game_started)
	EventBus.player_died.connect(_on_player_died)

	# Create extraction timer
	extraction_timer = Timer.new()
	extraction_timer.one_shot = true
	extraction_timer.timeout.connect(_spawn_extraction_zone)
	add_child(extraction_timer)

	print("ExtractionManager initialized")

func _on_game_started() -> void:
	"""Start extraction timer when game begins"""
	next_extraction_time = first_extraction_time
	extraction_timer.start(first_extraction_time)
	print("ExtractionManager: First extraction zone will spawn in ", first_extraction_time, " seconds")

func _spawn_extraction_zone() -> void:
	"""Spawn an extraction zone at a random location"""
	# Remove existing zone if any
	if current_extraction_zone and is_instance_valid(current_extraction_zone):
		current_extraction_zone.queue_free()

	# Get the current scene (TestArena or game level)
	var current_scene = get_tree().current_scene
	if not current_scene:
		push_warning("ExtractionManager: No current scene found!")
		return

	# Load and instantiate extraction zone
	var extraction_zone = EXTRACTION_ZONE_SCENE.instantiate()

	# Position at random location around arena perimeter
	var angle = randf() * TAU
	var position = Vector3(
		cos(angle) * arena_radius,
		0.5,  # Slightly above ground
		sin(angle) * arena_radius
	)
	extraction_zone.global_position = position

	# Add to scene
	current_scene.add_child(extraction_zone)
	current_extraction_zone = extraction_zone
	is_extraction_available = true

	print("ExtractionManager: Extraction zone spawned at ", position)
	EventBus.extraction_started.emit()

	# Schedule next extraction zone (if this one isn't used)
	next_extraction_time += extraction_interval
	extraction_timer.start(extraction_interval)

func _on_extraction_success() -> void:
	"""Handle successful extraction"""
	# Calculate rewards based on time survived
	var time_survived = GlobalData.current_run_time
	var multiplier = calculate_extraction_multiplier(time_survived)
	var base_essence = calculate_base_essence(GlobalData.enemies_killed, time_survived)
	var final_essence = int(base_essence * multiplier)

	print("==== EXTRACTION SUCCESS ====")
	print("Time survived: ", time_survived, "s (", format_time(time_survived), ")")
	print("Enemies killed: ", GlobalData.enemies_killed)
	print("Extraction multiplier: ", multiplier, "x")
	print("Base Essence: ", base_essence)
	print("Final Essence: ", final_essence)
	print("============================")

	# Update GlobalData statistics
	GlobalData.successful_extractions += 1
	GlobalData.total_runs += 1
	GlobalData.total_enemies_killed += GlobalData.enemies_killed
	GlobalData.total_playtime += time_survived

	if time_survived > GlobalData.longest_run:
		GlobalData.longest_run = time_survived

	# Award extraction currency
	GlobalData.add_extraction_currency(final_essence)

	# Save the game
	SaveSystem.save_game()

	# Store extraction results for ExtractionSuccessScreen
	GlobalData.last_extraction_results = {
		"time_survived": time_survived,
		"enemies_killed": GlobalData.enemies_killed,
		"essence_earned": final_essence,
		"multiplier": multiplier,
		"gold_collected": GlobalData.current_gold
	}

	# Remove extraction zone
	if current_extraction_zone and is_instance_valid(current_extraction_zone):
		current_extraction_zone.queue_free()

	# Stop extraction timer
	extraction_timer.stop()

	# Show extraction success screen
	get_tree().change_scene_to_file("res://scenes/ui/ExtractionSuccessScreen.tscn")

func _on_player_died() -> void:
	"""Handle player death"""
	var time_survived = GlobalData.current_run_time

	print("==== PLAYER DIED ====")
	print("Time survived: ", time_survived, "s (", format_time(time_survived), ")")
	print("Enemies killed: ", GlobalData.enemies_killed)
	print("All loot lost!")
	print("=====================")

	# Update statistics (but no rewards)
	GlobalData.total_runs += 1
	GlobalData.total_enemies_killed += GlobalData.enemies_killed
	GlobalData.total_playtime += time_survived

	if time_survived > GlobalData.longest_run:
		GlobalData.longest_run = time_survived

	# Save statistics (but player doesn't get Essence)
	SaveSystem.save_game()

	# Store death results for DeathScreen
	GlobalData.set("last_death_results", {
		"time_survived": time_survived,
		"enemies_killed": GlobalData.enemies_killed,
		"gold_lost": GlobalData.current_gold,
		"essence_lost": calculate_base_essence(GlobalData.enemies_killed, time_survived)
	})

	# Stop extraction timer
	extraction_timer.stop()

	# Show death screen
	get_tree().change_scene_to_file("res://scenes/ui/DeathScreen.tscn")

func calculate_extraction_multiplier(time_survived: float) -> float:
	"""Calculate extraction multiplier based on time survived"""
	if time_survived < MULTIPLIER_TIER_1:
		return 1.0  # < 3 min
	elif time_survived < MULTIPLIER_TIER_2:
		return 1.5  # 3-6 min
	elif time_survived < MULTIPLIER_TIER_3:
		return 2.0  # 6-9 min
	else:
		return 3.0  # 9+ min

func calculate_base_essence(enemies_killed: int, time_survived: float) -> float:
	"""Calculate base Essence reward before multiplier"""
	# Formula: (enemies * 10) + (time / 10)
	var enemy_essence = enemies_killed * 10
	var time_essence = time_survived / 10.0
	return enemy_essence + time_essence

func format_time(seconds: float) -> String:
	"""Format seconds as MM:SS"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
