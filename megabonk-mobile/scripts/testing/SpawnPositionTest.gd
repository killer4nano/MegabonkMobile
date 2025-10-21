extends Node
## Automated test for enemy spawn position verification
## Tests that enemies spawn at correct distance from player

# Test configuration
const MIN_SPAWN_DISTANCE = 15.0
const EXPECTED_SPAWN_DISTANCE = 20.0
const DISTANCE_TOLERANCE = 2.0
const NUM_TEST_SPAWNS = 10

# Test results
var test_count = 0
var passed_count = 0
var failed_count = 0
var test_results = []

# References
var wave_manager: Node
var player: Node3D

func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("SPAWN POSITION TEST - STARTING")
	print("=".repeat(80))

	# Wait for scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame

	# Find required nodes
	player = get_tree().get_first_node_in_group("player")
	wave_manager = get_node_or_null("../WaveManager")

	if not player:
		push_error("TEST FAILED: No player found in scene!")
		return

	if not wave_manager:
		push_error("TEST FAILED: No WaveManager found in scene!")
		return

	print("Player found at: ", player.global_position)
	print("WaveManager found")
	print()

	# Run all tests
	await run_all_tests()

	# Report results
	report_results()

func run_all_tests() -> void:
	print("Running spawn position tests...")
	print()

	# Test 1: Verify spawn position calculation
	await test_spawn_position_calculation()

	# Test 2: Verify multiple spawn positions
	await test_multiple_spawns()

	# Test 3: Verify player position is used correctly
	await test_player_position_usage()

func test_spawn_position_calculation() -> void:
	"""Test that get_random_spawn_position returns valid positions"""
	test_count += 1
	print("TEST 1: Spawn Position Calculation")
	print("-" * 40)

	var player_pos = player.global_position
	print("Player position: ", player_pos)

	var spawn_pos = wave_manager.get_random_spawn_position()
	print("Calculated spawn position: ", spawn_pos)

	var distance = player_pos.distance_to(spawn_pos)
	print("Distance from player: ", distance, "m")
	print("Expected distance: ", EXPECTED_SPAWN_DISTANCE, "m")

	var result = {
		"test": "Spawn Position Calculation",
		"player_pos": player_pos,
		"spawn_pos": spawn_pos,
		"distance": distance,
		"expected": EXPECTED_SPAWN_DISTANCE,
		"passed": false
	}

	if distance >= MIN_SPAWN_DISTANCE:
		if abs(distance - EXPECTED_SPAWN_DISTANCE) <= DISTANCE_TOLERANCE:
			print("✅ PASS: Spawn distance within tolerance")
			passed_count += 1
			result.passed = true
		else:
			print("⚠️ PASS (with warning): Distance acceptable but not exact (", distance, "m vs ", EXPECTED_SPAWN_DISTANCE, "m expected)")
			passed_count += 1
			result.passed = true
	else:
		print("❌ FAIL: Spawn too close to player! (", distance, "m < ", MIN_SPAWN_DISTANCE, "m minimum)")
		failed_count += 1

	test_results.append(result)
	print()

func test_multiple_spawns() -> void:
	"""Test multiple spawn positions to verify consistency"""
	test_count += 1
	print("TEST 2: Multiple Spawn Positions (", NUM_TEST_SPAWNS, " spawns)")
	print("-" * 40)

	var player_pos = player.global_position
	var all_passed = true
	var min_distance = INF
	var max_distance = 0.0
	var avg_distance = 0.0

	for i in range(NUM_TEST_SPAWNS):
		var spawn_pos = wave_manager.get_random_spawn_position()
		var distance = player_pos.distance_to(spawn_pos)

		print("  Spawn ", i + 1, ": ", spawn_pos, " (distance: ", snappedf(distance, 0.01), "m)")

		min_distance = min(min_distance, distance)
		max_distance = max(max_distance, distance)
		avg_distance += distance

		if distance < MIN_SPAWN_DISTANCE:
			print("    ❌ TOO CLOSE!")
			all_passed = false

	avg_distance /= NUM_TEST_SPAWNS

	print()
	print("Min distance: ", snappedf(min_distance, 0.01), "m")
	print("Max distance: ", snappedf(max_distance, 0.01), "m")
	print("Avg distance: ", snappedf(avg_distance, 0.01), "m")

	var result = {
		"test": "Multiple Spawn Positions",
		"min_distance": min_distance,
		"max_distance": max_distance,
		"avg_distance": avg_distance,
		"all_passed": all_passed
	}

	if all_passed and min_distance >= MIN_SPAWN_DISTANCE:
		print("✅ PASS: All spawns at safe distance")
		passed_count += 1
		result.passed = true
	else:
		print("❌ FAIL: Some spawns too close to player")
		failed_count += 1
		result.passed = false

	test_results.append(result)
	print()

func test_player_position_usage() -> void:
	"""Verify that spawn positions update when player moves"""
	test_count += 1
	print("TEST 3: Player Position Usage")
	print("-" * 40)

	var initial_player_pos = player.global_position
	print("Initial player position: ", initial_player_pos)

	# Get spawn position at initial location
	var spawn_pos_1 = wave_manager.get_random_spawn_position()
	var distance_1 = initial_player_pos.distance_to(spawn_pos_1)
	print("Spawn 1: ", spawn_pos_1, " (distance: ", snappedf(distance_1, 0.01), "m)")

	# Move player to a different location
	var new_player_pos = initial_player_pos + Vector3(50, 0, 50)
	player.global_position = new_player_pos
	await get_tree().process_frame

	print("Moved player to: ", new_player_pos)

	# Get spawn position at new location
	var spawn_pos_2 = wave_manager.get_random_spawn_position()
	var distance_2 = new_player_pos.distance_to(spawn_pos_2)
	print("Spawn 2: ", spawn_pos_2, " (distance: ", snappedf(distance_2, 0.01), "m)")

	# Calculate expected change in spawn position
	var spawn_moved_correctly = spawn_pos_2.distance_to(spawn_pos_1) > 40.0  # Should move ~50 units with player

	var result = {
		"test": "Player Position Usage",
		"initial_pos": initial_player_pos,
		"new_pos": new_player_pos,
		"spawn_1": spawn_pos_1,
		"spawn_2": spawn_pos_2,
		"distance_1": distance_1,
		"distance_2": distance_2,
		"spawn_moved": spawn_moved_correctly
	}

	# Restore player position
	player.global_position = initial_player_pos

	if spawn_moved_correctly and distance_2 >= MIN_SPAWN_DISTANCE:
		print("✅ PASS: Spawn positions correctly follow player")
		passed_count += 1
		result.passed = true
	else:
		print("❌ FAIL: Spawn positions not following player correctly")
		failed_count += 1
		result.passed = false

	test_results.append(result)
	print()

func report_results() -> void:
	print("=".repeat(80))
	print("SPAWN POSITION TEST - RESULTS")
	print("=".repeat(80))
	print("Tests run: ", test_count)
	print("Passed: ", passed_count)
	print("Failed: ", failed_count)
	print()

	if failed_count == 0:
		print("✅ ALL TESTS PASSED")
		print("Spawn system is working correctly!")
	else:
		print("❌ SOME TESTS FAILED")
		print("Spawn system needs fixes!")
		print()
		print("Failed tests:")
		for result in test_results:
			if not result.get("passed", false):
				print("  - ", result.test)

	print("=".repeat(80))
	print()

	# Save test report
	save_test_report()

func save_test_report() -> void:
	var date_time = Time.get_datetime_string_from_system()
	var report_path = "user://spawn_position_test_report.txt"

	var report = ""
	report += "SPAWN POSITION TEST REPORT\n"
	report += "Date: " + date_time + "\n"
	report += "=" * 80 + "\n\n"
	report += "Tests run: " + str(test_count) + "\n"
	report += "Passed: " + str(passed_count) + "\n"
	report += "Failed: " + str(failed_count) + "\n\n"

	for result in test_results:
		report += "Test: " + result.test + "\n"
		report += "Status: " + ("PASS" if result.get("passed", false) else "FAIL") + "\n"
		report += "Details: " + str(result) + "\n\n"

	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Test report saved to: ", report_path)
		print("(Check user:// directory: ", OS.get_user_data_dir(), ")")
	else:
		push_error("Failed to save test report")
