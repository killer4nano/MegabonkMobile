extends Node
class_name Phase4Tests
## Phase 4 - Automated Unit Tests
## Tests extraction multiplier calculation, Essence rewards, and core logic

# Test results tracking
var tests_passed: int = 0
var tests_failed: int = 0
var test_results: Array[String] = []

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("PHASE 4 - AUTOMATED UNIT TESTS")
	print("=".repeat(60) + "\n")

	# Run all tests
	run_all_tests()

	# Print summary
	print_summary()

func run_all_tests() -> void:
	"""Run all Phase 4 automated tests"""
	# Extraction multiplier tests
	test_extraction_multiplier_tier1()
	test_extraction_multiplier_tier2()
	test_extraction_multiplier_tier3()
	test_extraction_multiplier_tier4()
	test_extraction_multiplier_boundaries()

	# Essence calculation tests
	test_essence_calculation_basic()
	test_essence_calculation_no_kills()
	test_essence_calculation_no_time()
	test_essence_calculation_large_values()

	# Run time tracking tests
	test_run_time_tracking_start()
	test_run_time_tracking_reset()

	# Format time tests
	test_format_time()

func test_extraction_multiplier_tier1() -> void:
	"""Test Tier 1 multiplier (< 3 min) = 1.0x"""
	var test_name = "Extraction Multiplier - Tier 1 (< 3 min)"

	var time_values = [0.0, 120.0, 179.0]  # 0 sec, 2 min, 2:59
	for time in time_values:
		var result = ExtractionManager.calculate_extraction_multiplier(time)
		if result == 1.0:
			record_pass(test_name + " @ " + str(time) + "s")
		else:
			record_fail(test_name + " @ " + str(time) + "s", "Expected 1.0, got " + str(result))

func test_extraction_multiplier_tier2() -> void:
	"""Test Tier 2 multiplier (3-6 min) = 1.5x"""
	var test_name = "Extraction Multiplier - Tier 2 (3-6 min)"

	var time_values = [180.0, 240.0, 359.0]  # 3 min, 4 min, 5:59
	for time in time_values:
		var result = ExtractionManager.calculate_extraction_multiplier(time)
		if result == 1.5:
			record_pass(test_name + " @ " + str(time) + "s")
		else:
			record_fail(test_name + " @ " + str(time) + "s", "Expected 1.5, got " + str(result))

func test_extraction_multiplier_tier3() -> void:
	"""Test Tier 3 multiplier (6-9 min) = 2.0x"""
	var test_name = "Extraction Multiplier - Tier 3 (6-9 min)"

	var time_values = [360.0, 420.0, 539.0]  # 6 min, 7 min, 8:59
	for time in time_values:
		var result = ExtractionManager.calculate_extraction_multiplier(time)
		if result == 2.0:
			record_pass(test_name + " @ " + str(time) + "s")
		else:
			record_fail(test_name + " @ " + str(time) + "s", "Expected 2.0, got " + str(result))

func test_extraction_multiplier_tier4() -> void:
	"""Test Tier 4 multiplier (9+ min) = 3.0x"""
	var test_name = "Extraction Multiplier - Tier 4 (9+ min)"

	var time_values = [540.0, 600.0, 1000.0]  # 9 min, 10 min, 16:40
	for time in time_values:
		var result = ExtractionManager.calculate_extraction_multiplier(time)
		if result == 3.0:
			record_pass(test_name + " @ " + str(time) + "s")
		else:
			record_fail(test_name + " @ " + str(time) + "s", "Expected 3.0, got " + str(result))

func test_extraction_multiplier_boundaries() -> void:
	"""Test boundary conditions for multiplier tiers"""
	var test_name = "Extraction Multiplier - Boundaries"

	# Exact boundary values
	var boundaries = [
		{"time": 179.999, "expected": 1.0, "desc": "Just below 3min"},
		{"time": 180.0, "expected": 1.5, "desc": "Exactly 3min"},
		{"time": 359.999, "expected": 1.5, "desc": "Just below 6min"},
		{"time": 360.0, "expected": 2.0, "desc": "Exactly 6min"},
		{"time": 539.999, "expected": 2.0, "desc": "Just below 9min"},
		{"time": 540.0, "expected": 3.0, "desc": "Exactly 9min"},
	]

	for b in boundaries:
		var result = ExtractionManager.calculate_extraction_multiplier(b["time"])
		if result == b["expected"]:
			record_pass(test_name + " - " + b["desc"])
		else:
			record_fail(test_name + " - " + b["desc"], "Expected " + str(b["expected"]) + ", got " + str(result))

func test_essence_calculation_basic() -> void:
	"""Test basic Essence calculation"""
	var test_name = "Essence Calculation - Basic"

	# enemies=50, time=360s → (50*10) + (360/10) = 500 + 36 = 536
	var enemies = 50
	var time = 360.0
	var expected = 536.0

	var result = ExtractionManager.calculate_base_essence(enemies, time)
	if result == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected " + str(expected) + ", got " + str(result))

func test_essence_calculation_no_kills() -> void:
	"""Test Essence calculation with 0 kills (survival time only)"""
	var test_name = "Essence Calculation - No Kills"

	# enemies=0, time=300s → (0*10) + (300/10) = 0 + 30 = 30
	var enemies = 0
	var time = 300.0
	var expected = 30.0

	var result = ExtractionManager.calculate_base_essence(enemies, time)
	if result == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected " + str(expected) + ", got " + str(result))

func test_essence_calculation_no_time() -> void:
	"""Test Essence calculation with minimal time"""
	var test_name = "Essence Calculation - No Time"

	# enemies=10, time=0s → (10*10) + (0/10) = 100 + 0 = 100
	var enemies = 10
	var time = 0.0
	var expected = 100.0

	var result = ExtractionManager.calculate_base_essence(enemies, time)
	if result == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected " + str(expected) + ", got " + str(result))

func test_essence_calculation_large_values() -> void:
	"""Test Essence calculation with large values"""
	var test_name = "Essence Calculation - Large Values"

	# enemies=200, time=600s → (200*10) + (600/10) = 2000 + 60 = 2060
	var enemies = 200
	var time = 600.0
	var expected = 2060.0

	var result = ExtractionManager.calculate_base_essence(enemies, time)
	if result == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected " + str(expected) + ", got " + str(result))

func test_run_time_tracking_start() -> void:
	"""Test run time tracking starts correctly"""
	var test_name = "Run Time Tracking - Start"

	GlobalData.reset_run_data()
	GlobalData.start_run()

	if GlobalData.is_game_running == true and GlobalData.current_run_time == 0.0:
		record_pass(test_name)
	else:
		record_fail(test_name, "is_game_running=" + str(GlobalData.is_game_running) + ", run_time=" + str(GlobalData.current_run_time))

func test_run_time_tracking_reset() -> void:
	"""Test run time resets properly"""
	var test_name = "Run Time Tracking - Reset"

	GlobalData.current_run_time = 123.45
	GlobalData.enemies_killed = 99
	GlobalData.reset_run_data()

	if GlobalData.current_run_time == 0.0 and GlobalData.enemies_killed == 0:
		record_pass(test_name)
	else:
		record_fail(test_name, "run_time=" + str(GlobalData.current_run_time) + ", enemies=" + str(GlobalData.enemies_killed))

func test_format_time() -> void:
	"""Test time formatting function"""
	var test_name = "Format Time"

	var test_cases = [
		{"seconds": 0.0, "expected": "0:00"},
		{"seconds": 30.0, "expected": "0:30"},
		{"seconds": 60.0, "expected": "1:00"},
		{"seconds": 90.0, "expected": "1:30"},
		{"seconds": 180.0, "expected": "3:00"},
		{"seconds": 599.0, "expected": "9:59"},
		{"seconds": 600.0, "expected": "10:00"},
	]

	for tc in test_cases:
		var result = ExtractionManager.format_time(tc["seconds"])
		if result == tc["expected"]:
			record_pass(test_name + " - " + str(tc["seconds"]) + "s")
		else:
			record_fail(test_name + " - " + str(tc["seconds"]) + "s", "Expected '" + tc["expected"] + "', got '" + result + "'")

# ============================================================================
# Test Result Tracking
# ============================================================================

func record_pass(test_name: String) -> void:
	"""Record a passing test"""
	tests_passed += 1
	test_results.append("✓ PASS: " + test_name)
	print("✓ PASS: " + test_name)

func record_fail(test_name: String, reason: String) -> void:
	"""Record a failing test"""
	tests_failed += 1
	test_results.append("✗ FAIL: " + test_name + " - " + reason)
	print("✗ FAIL: " + test_name + " - " + reason)

func print_summary() -> void:
	"""Print test summary"""
	print("\n" + "=".repeat(60))
	print("TEST SUMMARY")
	print("=".repeat(60))
	print("Total Tests: " + str(tests_passed + tests_failed))
	print("Passed: " + str(tests_passed))
	print("Failed: " + str(tests_failed))

	if tests_failed == 0:
		print("\n🎉 ALL TESTS PASSED! 🎉")
	else:
		print("\n⚠️  SOME TESTS FAILED - See details above")

	print("=".repeat(60) + "\n")
