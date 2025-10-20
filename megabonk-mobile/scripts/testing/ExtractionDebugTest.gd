extends Node
## Automated Debug Test for Extraction System

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("EXTRACTION DEBUG TEST")
	print("=".repeat(60) + "\n")

	# Wait one frame for autoloads to initialize
	await get_tree().process_frame

	# Test 1: Check GlobalData initialization
	print("TEST 1: GlobalData State")
	print("  is_game_running: ", GlobalData.is_game_running)
	print("  current_run_time: ", GlobalData.current_run_time)
	print("")

	# Test 2: Start a run
	print("TEST 2: Starting Run")
	GlobalData.start_run()
	print("  is_game_running after start_run(): ", GlobalData.is_game_running)
	print("  current_run_time after start_run(): ", GlobalData.current_run_time)
	print("")

	# Test 3: Simulate time passing
	print("TEST 3: Simulating 5 seconds of gameplay")
	for i in range(5):
		await get_tree().create_timer(1.0).timeout
		print("  After ", i+1, "s - current_run_time: ", GlobalData.current_run_time)
	print("")

	# Test 4: Manually set time and test extraction
	print("TEST 4: Simulating Extraction at 3:30 (210s)")
	GlobalData.current_run_time = 210.0
	GlobalData.enemies_killed = 25
	GlobalData.current_gold = 150

	# Calculate what ExtractionManager would calculate
	var time_survived = GlobalData.current_run_time
	var multiplier = ExtractionManager.calculate_extraction_multiplier(time_survived)
	var base_essence = ExtractionManager.calculate_base_essence(GlobalData.enemies_killed, time_survived)
	var final_essence = int(base_essence * multiplier)

	print("  Time: ", time_survived, "s (", format_time(time_survived), ")")
	print("  Enemies killed: ", GlobalData.enemies_killed)
	print("  Multiplier: ", multiplier, "x")
	print("  Base essence: ", base_essence)
	print("  Final essence: ", final_essence)
	print("")

	# Test 5: Store results and check retrieval
	print("TEST 5: Testing result storage")
	GlobalData.set("last_extraction_results", {
		"time_survived": time_survived,
		"enemies_killed": GlobalData.enemies_killed,
		"essence_earned": final_essence,
		"multiplier": multiplier,
		"gold_collected": GlobalData.current_gold
	})

	var retrieved = GlobalData.get("last_extraction_results")
	print("  Stored data: ", retrieved)
	print("  Data type: ", typeof(retrieved))
	print("  Has 'time_survived' key: ", retrieved.has("time_survived") if retrieved else "N/A")
	print("")

	# Test 6: Check MainMenu scene exists
	print("TEST 6: Checking scene files")
	var main_menu_exists = FileAccess.file_exists("res://scenes/ui/MainMenu.tscn")
	var success_screen_exists = FileAccess.file_exists("res://scenes/ui/ExtractionSuccessScreen.tscn")
	print("  MainMenu.tscn exists: ", main_menu_exists)
	print("  ExtractionSuccessScreen.tscn exists: ", success_screen_exists)
	print("")

	# Test 7: Try loading ExtractionSuccessScreen
	print("TEST 7: Loading ExtractionSuccessScreen")
	print("  Changing scene to ExtractionSuccessScreen...")
	get_tree().change_scene_to_file("res://scenes/ui/ExtractionSuccessScreen.tscn")

func format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
