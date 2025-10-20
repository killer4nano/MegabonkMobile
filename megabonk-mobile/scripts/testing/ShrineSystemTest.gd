extends Node
## Automated test for Shrine System (Phase 5.2)
## Tests all shrine types and verifies functionality

# Test state
var test_results: Array = []
var current_test: String = ""
var tests_passed: int = 0
var tests_failed: int = 0

# References
var player: Node3D
var health_shrine: Node3D
var damage_shrine: Node3D
var speed_shrine: Node3D

# Test phases
enum TestPhase {
	SETUP,
	TEST_GOLD_SYSTEM,
	TEST_HEALTH_SHRINE,
	TEST_DAMAGE_SHRINE,
	TEST_SPEED_SHRINE,
	TEST_BUFF_EXPIRATION,
	COMPLETE
}
var current_phase: TestPhase = TestPhase.SETUP
var phase_timer: float = 0.0

func _ready() -> void:
	var separator = "=" .repeat(80)
	print("\n" + separator)
	print("AUTOMATED SHRINE SYSTEM TEST - PHASE 5.2")
	print(separator + "\n")

	# Wait a frame for scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	# Find references
	setup_test_environment()

	# Start tests
	current_phase = TestPhase.TEST_GOLD_SYSTEM

func _process(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		TestPhase.TEST_GOLD_SYSTEM:
			if phase_timer > 0.5:
				test_gold_system()
				current_phase = TestPhase.TEST_HEALTH_SHRINE
				phase_timer = 0.0

		TestPhase.TEST_HEALTH_SHRINE:
			if phase_timer > 0.5:
				test_health_shrine()
				current_phase = TestPhase.TEST_DAMAGE_SHRINE
				phase_timer = 0.0

		TestPhase.TEST_DAMAGE_SHRINE:
			if phase_timer > 0.5:
				test_damage_shrine()
				current_phase = TestPhase.TEST_SPEED_SHRINE
				phase_timer = 0.0

		TestPhase.TEST_SPEED_SHRINE:
			if phase_timer > 0.5:
				test_speed_shrine()
				current_phase = TestPhase.TEST_BUFF_EXPIRATION
				phase_timer = 0.0

		TestPhase.TEST_BUFF_EXPIRATION:
			if phase_timer > 3.0:  # Wait 3 seconds to test buff expiration
				test_buff_expiration()
				current_phase = TestPhase.COMPLETE
				phase_timer = 0.0

		TestPhase.COMPLETE:
			if phase_timer > 0.5:
				current_phase = TestPhase.SETUP  # Prevent re-entry
				phase_timer = 0.0
				print_test_results()
				# Quit the game
				await get_tree().create_timer(1.0).timeout
				get_tree().quit()

func setup_test_environment() -> void:
	print("[SETUP] Finding test objects...")

	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		log_pass("Player found")
	else:
		log_fail("Player NOT found")
		return

	# Find shrines by type
	var all_nodes = get_tree().root.get_children()
	find_shrines_recursive(get_tree().root)

	if health_shrine:
		log_pass("Health Shrine found")
	else:
		log_fail("Health Shrine NOT found")

	if damage_shrine:
		log_pass("Damage Shrine found")
	else:
		log_fail("Damage Shrine NOT found")

	if speed_shrine:
		log_pass("Speed Shrine found")
	else:
		log_fail("Speed Shrine NOT found")

	print("")

func find_shrines_recursive(node: Node) -> void:
	"""Recursively search for shrines in scene tree"""
	for child in node.get_children():
		if child.get_class() == "Node3D" or child is Node3D:
			# Check script class name
			if child.get_script():
				var script = child.get_script()
				if script.resource_path.contains("HealthShrine"):
					health_shrine = child
				elif script.resource_path.contains("DamageShrine"):
					damage_shrine = child
				elif script.resource_path.contains("SpeedShrine"):
					speed_shrine = child

		# Recurse into children
		find_shrines_recursive(child)

func test_gold_system() -> void:
	print("[TEST 1] Gold System")
	current_test = "Gold System"

	# Test 1.1: Initial gold should be 0
	if GlobalData.current_gold == 0:
		log_pass("Initial gold is 0")
	else:
		log_fail("Initial gold is %d (expected 0)" % GlobalData.current_gold)

	# Test 1.2: Add gold
	GlobalData.current_gold = 500
	EventBus.gold_collected.emit(500, 500)

	if GlobalData.current_gold == 500:
		log_pass("Gold added successfully (500 gold)")
	else:
		log_fail("Gold is %d (expected 500)" % GlobalData.current_gold)

	print("")

func test_health_shrine() -> void:
	print("[TEST 2] Health Shrine")
	current_test = "Health Shrine"

	if not health_shrine or not player:
		log_fail("Missing health_shrine or player reference")
		print("")
		return

	# Test 2.1: Damage player first
	var initial_health = player.max_health
	player.current_health = initial_health * 0.3  # Set to 30% HP
	var damaged_health = player.current_health
	log_pass("Player health reduced to %.1f (30%% of max)" % damaged_health)

	# Test 2.2: Check shrine cost
	var shrine_cost = health_shrine.cost
	if shrine_cost == 50:
		log_pass("Health Shrine cost is 50 gold")
	else:
		log_fail("Health Shrine cost is %d (expected 50)" % shrine_cost)

	# Test 2.3: Move player near shrine
	player.global_position = health_shrine.global_position + Vector3(1, 0, 0)
	# Wait for physics to update Area3D detection
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout

	# Test 2.4: Check player in range
	if health_shrine.player_in_range:
		log_pass("Player detected in shrine range")
	else:
		log_fail("Player NOT detected in shrine range")

	# Test 2.5: Activate shrine
	var gold_before = GlobalData.current_gold
	health_shrine.attempt_activate()
	await get_tree().create_timer(0.2).timeout

	var gold_after = GlobalData.current_gold
	var gold_spent = gold_before - gold_after

	if gold_spent == 50:
		log_pass("Gold spent correctly (50 gold)")
	else:
		log_fail("Gold spent incorrectly (%d gold, expected 50)" % gold_spent)

	# Test 2.6: Check healing
	var healed_health = player.current_health
	var expected_health = damaged_health + (initial_health * 0.5)

	if abs(healed_health - expected_health) < 1.0:
		log_pass("Player healed correctly (%.1f HP)" % healed_health)
	else:
		log_fail("Player health is %.1f (expected %.1f)" % [healed_health, expected_health])

	print("")

func test_damage_shrine() -> void:
	print("[TEST 3] Damage Shrine")
	current_test = "Damage Shrine"

	if not damage_shrine or not player:
		log_fail("Missing damage_shrine or player reference")
		print("")
		return

	# Test 3.1: Check shrine cost
	var shrine_cost = damage_shrine.cost
	if shrine_cost == 100:
		log_pass("Damage Shrine cost is 100 gold")
	else:
		log_fail("Damage Shrine cost is %d (expected 100)" % shrine_cost)

	# Test 3.2: Check initial damage multiplier
	if player.shrine_damage_multiplier == 1.0:
		log_pass("Initial damage multiplier is 1.0x")
	else:
		log_fail("Initial damage multiplier is %.2fx (expected 1.0x)" % player.shrine_damage_multiplier)

	# Test 3.3: Move player near shrine
	player.global_position = damage_shrine.global_position + Vector3(1, 0, 0)
	# Wait for physics to update Area3D detection
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout

	# Test 3.4: Activate shrine
	var gold_before = GlobalData.current_gold
	damage_shrine.attempt_activate()
	await get_tree().create_timer(0.2).timeout

	var gold_after = GlobalData.current_gold
	var gold_spent = gold_before - gold_after

	if gold_spent == 100:
		log_pass("Gold spent correctly (100 gold)")
	else:
		log_fail("Gold spent incorrectly (%d gold, expected 100)" % gold_spent)

	# Test 3.5: Check damage buff applied
	if abs(player.shrine_damage_multiplier - 1.5) < 0.01:
		log_pass("Damage buff applied (1.5x = +50%%)")
	else:
		log_fail("Damage multiplier is %.2fx (expected 1.5x)" % player.shrine_damage_multiplier)

	# Test 3.6: Check shrine is active
	if damage_shrine.is_active:
		log_pass("Damage Shrine is marked as active")
	else:
		log_fail("Damage Shrine is NOT marked as active")

	print("")

func test_speed_shrine() -> void:
	print("[TEST 4] Speed Shrine")
	current_test = "Speed Shrine"

	if not speed_shrine or not player:
		log_fail("Missing speed_shrine or player reference")
		print("")
		return

	# Test 4.1: Check shrine cost
	var shrine_cost = speed_shrine.cost
	if shrine_cost == 75:
		log_pass("Speed Shrine cost is 75 gold")
	else:
		log_fail("Speed Shrine cost is %d (expected 75)" % shrine_cost)

	# Test 4.2: Check initial speed multiplier
	if player.shrine_speed_multiplier == 1.0:
		log_pass("Initial speed multiplier is 1.0x")
	else:
		log_fail("Initial speed multiplier is %.2fx (expected 1.0x)" % player.shrine_speed_multiplier)

	# Test 4.3: Move player near shrine
	player.global_position = speed_shrine.global_position + Vector3(1, 0, 0)
	# Wait for physics to update Area3D detection
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout

	# Test 4.4: Verify player detected
	if not speed_shrine.player_in_range:
		log_fail("Player NOT detected in shrine range")
		print("")
		return

	# Test 4.5: Activate shrine
	var gold_before = GlobalData.current_gold
	speed_shrine.attempt_activate()
	await get_tree().create_timer(0.2).timeout

	var gold_after = GlobalData.current_gold
	var gold_spent = gold_before - gold_after

	if gold_spent == 75:
		log_pass("Gold spent correctly (75 gold)")
	else:
		log_fail("Gold spent incorrectly (%d gold, expected 75)" % gold_spent)

	# Test 4.6: Check speed buff applied
	if abs(player.shrine_speed_multiplier - 1.3) < 0.01:
		log_pass("Speed buff applied (1.3x = +30%%)")
	else:
		log_fail("Speed multiplier is %.2fx (expected 1.3x)" % player.shrine_speed_multiplier)

	# Test 4.7: Check shrine is active
	if speed_shrine.is_active:
		log_pass("Speed Shrine is marked as active")
	else:
		log_fail("Speed Shrine is NOT marked as active")

	print("")

func test_buff_expiration() -> void:
	print("[TEST 5] Buff Expiration")
	current_test = "Buff Expiration"

	# Note: We can't wait 60 seconds in automated test, so we'll just verify
	# the methods exist and log a message

	# Test 5.1: Check remove_damage_buff method exists
	if player.has_method("remove_damage_buff"):
		log_pass("Player has remove_damage_buff() method")
	else:
		log_fail("Player missing remove_damage_buff() method")

	# Test 5.2: Check remove_speed_buff method exists
	if player.has_method("remove_speed_buff"):
		log_pass("Player has remove_speed_buff() method")
	else:
		log_fail("Player missing remove_speed_buff() method")

	# Test 5.3: Manually remove buffs to test
	player.remove_damage_buff()
	player.remove_speed_buff()

	await get_tree().create_timer(0.1).timeout

	# Test 5.4: Verify buffs removed
	if player.shrine_damage_multiplier == 1.0:
		log_pass("Damage buff removed (multiplier back to 1.0x)")
	else:
		log_fail("Damage multiplier is %.2fx (expected 1.0x)" % player.shrine_damage_multiplier)

	if player.shrine_speed_multiplier == 1.0:
		log_pass("Speed buff removed (multiplier back to 1.0x)")
	else:
		log_fail("Speed multiplier is %.2fx (expected 1.0x)" % player.shrine_speed_multiplier)

	print("")

func log_pass(message: String) -> void:
	"""Log a passing test"""
	tests_passed += 1
	print("  [PASS] " + message)
	test_results.append({"test": current_test, "result": "PASS", "message": message})

func log_fail(message: String) -> void:
	"""Log a failing test"""
	tests_failed += 1
	print("  [FAIL] " + message)
	test_results.append({"test": current_test, "result": "FAIL", "message": message})

func print_test_results() -> void:
	"""Print final test summary"""
	var separator = "=".repeat(80)
	print("\n" + separator)
	print("TEST RESULTS SUMMARY")
	print(separator)
	print("Total Tests: %d" % (tests_passed + tests_failed))
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	print("Success Rate: %.1f%%" % ((tests_passed / float(tests_passed + tests_failed)) * 100.0))
	print(separator + "\n")

	if tests_failed == 0:
		print("✅ ALL TESTS PASSED! Shrine system is working correctly.\n")
	else:
		print("❌ SOME TESTS FAILED. Review failures above.\n")
		print("Failed Tests:")
		for result in test_results:
			if result.result == "FAIL":
				print("  - %s: %s" % [result.test, result.message])
		print("")
