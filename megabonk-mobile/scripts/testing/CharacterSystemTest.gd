extends Node
## Automated test for Character System (Phase 5A)
## Tests all 5 playable characters and their unique passive abilities

# Test state
var test_results: Array = []
var current_test: String = ""
var tests_passed: int = 0
var tests_failed: int = 0

# References
var player: PlayerController
var game_manager: Node

# Test phases
enum TestPhase {
	SETUP,
	TEST_CHARACTER_LOADING,
	TEST_WARRIOR,
	TEST_RANGER,
	TEST_TANK,
	TEST_ASSASSIN,
	TEST_MAGE,
	TEST_UNLOCK_SYSTEM,
	COMPLETE
}
var current_phase: TestPhase = TestPhase.SETUP
var phase_timer: float = 0.0

func _ready() -> void:
	print_header()

	# Wait for scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	# Setup test environment
	setup_test_environment()

	# Start tests
	current_phase = TestPhase.TEST_CHARACTER_LOADING

func _process(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		TestPhase.TEST_CHARACTER_LOADING:
			if phase_timer > 0.5:
				test_character_loading()
				current_phase = TestPhase.TEST_WARRIOR
				phase_timer = 0.0

		TestPhase.TEST_WARRIOR:
			if phase_timer > 0.5:
				test_warrior()
				current_phase = TestPhase.TEST_RANGER
				phase_timer = 0.0

		TestPhase.TEST_RANGER:
			if phase_timer > 0.5:
				test_ranger()
				current_phase = TestPhase.TEST_TANK
				phase_timer = 0.0

		TestPhase.TEST_TANK:
			if phase_timer > 0.5:
				test_tank()
				current_phase = TestPhase.TEST_ASSASSIN
				phase_timer = 0.0

		TestPhase.TEST_ASSASSIN:
			if phase_timer > 0.5:
				test_assassin()
				current_phase = TestPhase.TEST_MAGE
				phase_timer = 0.0

		TestPhase.TEST_MAGE:
			if phase_timer > 0.5:
				test_mage()
				current_phase = TestPhase.TEST_UNLOCK_SYSTEM
				phase_timer = 0.0

		TestPhase.TEST_UNLOCK_SYSTEM:
			if phase_timer > 0.5:
				test_unlock_system()
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

func print_header() -> void:
	"""Print test header"""
	var separator = "=".repeat(80)
	print("\n" + separator)
	print("AUTOMATED CHARACTER SYSTEM TEST - PHASE 5A")
	print(separator + "\n")

func setup_test_environment() -> void:
	"""Find player and game manager"""
	print("[SETUP] Finding test objects...")

	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		log_pass("Player found")
	else:
		log_fail("Player NOT found")
		return

	# Find GameManager
	game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		log_pass("GameManager found")
	else:
		log_fail("GameManager NOT found")

	print("")

# ============================================================================
# TEST 1: CHARACTER LOADING
# ============================================================================

func test_character_loading() -> void:
	"""Test loading all character .tres files"""
	print("[TEST 1] Character Loading")
	current_test = "Character Loading"

	# Test 1.1: Load Warrior
	var warrior = load("res://resources/characters/warrior.tres")
	if warrior:
		log_pass("Warrior character loaded")
	else:
		log_fail("Failed to load Warrior")
		return

	# Test 1.2: Verify Warrior properties
	if warrior.character_name == "Warrior":
		log_pass("Warrior name correct: 'Warrior'")
	else:
		log_fail("Warrior name is '%s' (expected 'Warrior')" % warrior.character_name)

	if warrior.starting_weapon_id == "bonk_hammer":
		log_pass("Warrior starting weapon correct: 'bonk_hammer'")
	else:
		log_fail("Warrior starting weapon is '%s' (expected 'bonk_hammer')" % warrior.starting_weapon_id)

	if warrior.unlock_cost == 0:
		log_pass("Warrior unlock cost correct: 0 (free)")
	else:
		log_fail("Warrior unlock cost is %d (expected 0)" % warrior.unlock_cost)

	# Test 1.3: Load Ranger
	var ranger = load("res://resources/characters/ranger.tres")
	if ranger:
		log_pass("Ranger character loaded")
	else:
		log_fail("Failed to load Ranger")

	if ranger.character_name == "Ranger":
		log_pass("Ranger name correct: 'Ranger'")
	else:
		log_fail("Ranger name is '%s' (expected 'Ranger')" % ranger.character_name)

	if ranger.starting_weapon_id == "magic_missile":
		log_pass("Ranger starting weapon correct: 'magic_missile'")
	else:
		log_fail("Ranger starting weapon is '%s' (expected 'magic_missile')" % ranger.starting_weapon_id)

	# Test 1.4: Load Tank
	var tank = load("res://resources/characters/tank.tres")
	if tank:
		log_pass("Tank character loaded")
	else:
		log_fail("Failed to load Tank")

	if tank.character_name == "Tank":
		log_pass("Tank name correct: 'Tank'")
	else:
		log_fail("Tank name is '%s' (expected 'Tank')" % tank.character_name)

	# Test 1.5: Load Assassin
	var assassin = load("res://resources/characters/assassin.tres")
	if assassin:
		log_pass("Assassin character loaded")
	else:
		log_fail("Failed to load Assassin")

	if assassin.character_name == "Assassin":
		log_pass("Assassin name correct: 'Assassin'")
	else:
		log_fail("Assassin name is '%s' (expected 'Assassin')" % assassin.character_name)

	# Test 1.6: Load Mage
	var mage = load("res://resources/characters/mage.tres")
	if mage:
		log_pass("Mage character loaded")
	else:
		log_fail("Failed to load Mage")

	if mage.character_name == "Mage":
		log_pass("Mage name correct: 'Mage'")
	else:
		log_fail("Mage name is '%s' (expected 'Mage')" % mage.character_name)

	print("")

# ============================================================================
# TEST 2: WARRIOR CHARACTER
# ============================================================================

func test_warrior() -> void:
	"""Test Warrior character and passive ability"""
	print("[TEST 2] Warrior Character")
	current_test = "Warrior Character"

	if not player:
		log_fail("Player reference missing")
		print("")
		return

	# Test 2.1: Apply Warrior character
	var warrior_data = load("res://resources/characters/warrior.tres")
	if not warrior_data:
		log_fail("Failed to load Warrior data")
		print("")
		return

	player.apply_character_data(warrior_data)
	await get_tree().create_timer(0.1).timeout

	# Test 2.2: Verify base stats applied
	if player.max_health == 100.0:
		log_pass("Warrior max health correct: 100")
	else:
		log_fail("Warrior max health is %.1f (expected 100)" % player.max_health)

	if player.move_speed == 5.0:
		log_pass("Warrior move speed correct: 5.0")
	else:
		log_fail("Warrior move speed is %.1f (expected 5.0)" % player.move_speed)

	if player.base_damage == 10.0:
		log_pass("Warrior base damage correct: 10.0")
	else:
		log_fail("Warrior base damage is %.1f (expected 10.0)" % player.base_damage)

	# Test 2.3: Verify passive ability (Melee Mastery: +20% melee damage)
	if abs(player.melee_damage_multiplier - 1.2) < 0.01:
		log_pass("Warrior melee damage multiplier correct: 1.2x (+20%)")
	else:
		log_fail("Warrior melee damage multiplier is %.2fx (expected 1.2x)" % player.melee_damage_multiplier)

	# Test 2.4: Verify no damage reduction (Warrior doesn't have this)
	if player.damage_reduction_percent == 0.0:
		log_pass("Warrior damage reduction correct: 0% (none)")
	else:
		log_fail("Warrior damage reduction is %.1f%% (expected 0%%)" % (player.damage_reduction_percent * 100))

	# Test 2.5: Verify XP multiplier is normal
	if player.xp_multiplier == 1.0:
		log_pass("Warrior XP multiplier correct: 1.0x (normal)")
	else:
		log_fail("Warrior XP multiplier is %.2fx (expected 1.0x)" % player.xp_multiplier)

	print("")

# ============================================================================
# TEST 3: RANGER CHARACTER
# ============================================================================

func test_ranger() -> void:
	"""Test Ranger character and passive ability"""
	print("[TEST 3] Ranger Character")
	current_test = "Ranger Character"

	if not player:
		log_fail("Player reference missing")
		print("")
		return

	# Test 3.1: Apply Ranger character
	var ranger_data = load("res://resources/characters/ranger.tres")
	if not ranger_data:
		log_fail("Failed to load Ranger data")
		print("")
		return

	player.apply_character_data(ranger_data)
	await get_tree().create_timer(0.1).timeout

	# Test 3.2: Verify base stats
	if player.max_health == 75.0:
		log_pass("Ranger max health correct: 75 (lower than Warrior)")
	else:
		log_fail("Ranger max health is %.1f (expected 75)" % player.max_health)

	if player.move_speed == 6.5:
		log_pass("Ranger move speed correct: 6.5 (faster than Warrior)")
	else:
		log_fail("Ranger move speed is %.1f (expected 6.5)" % player.move_speed)

	# Test 3.3: Verify passive ability (Sharpshooter: +30% ranged damage)
	if abs(player.ranged_damage_multiplier - 1.3) < 0.01:
		log_pass("Ranger ranged damage multiplier correct: 1.3x (+30%)")
	else:
		log_fail("Ranger ranged damage multiplier is %.2fx (expected 1.3x)" % player.ranged_damage_multiplier)

	# Test 3.4: Verify increased pickup range
	if player.pickup_range == 5.0:
		log_pass("Ranger pickup range correct: 5.0m (+2m bonus)")
	else:
		log_fail("Ranger pickup range is %.1f (expected 5.0)" % player.pickup_range)

	# Test 3.5: Verify melee multiplier is normal
	if player.melee_damage_multiplier == 1.0:
		log_pass("Ranger melee damage multiplier correct: 1.0x (normal)")
	else:
		log_fail("Ranger melee damage multiplier is %.2fx (expected 1.0x)" % player.melee_damage_multiplier)

	print("")

# ============================================================================
# TEST 4: TANK CHARACTER
# ============================================================================

func test_tank() -> void:
	"""Test Tank character and passive ability"""
	print("[TEST 4] Tank Character")
	current_test = "Tank Character"

	if not player:
		log_fail("Player reference missing")
		print("")
		return

	# Test 4.1: Apply Tank character
	var tank_data = load("res://resources/characters/tank.tres")
	if not tank_data:
		log_fail("Failed to load Tank data")
		print("")
		return

	player.apply_character_data(tank_data)
	await get_tree().create_timer(0.1).timeout

	# Test 4.2: Verify increased health (Fortified passive)
	if player.max_health == 150.0:
		log_pass("Tank max health correct: 150 (+50% base HP)")
	else:
		log_fail("Tank max health is %.1f (expected 150)" % player.max_health)

	if player.current_health == 150.0:
		log_pass("Tank current health initialized to max: 150")
	else:
		log_fail("Tank current health is %.1f (expected 150)" % player.current_health)

	# Test 4.3: Verify reduced speed (Tank is slower)
	if player.move_speed == 3.5:
		log_pass("Tank move speed correct: 3.5 (slower than Warrior)")
	else:
		log_fail("Tank move speed is %.1f (expected 3.5)" % player.move_speed)

	# Test 4.4: Verify damage reduction passive (15%)
	if abs(player.damage_reduction_percent - 0.15) < 0.01:
		log_pass("Tank damage reduction correct: 15%")
	else:
		log_fail("Tank damage reduction is %.1f%% (expected 15%%)" % (player.damage_reduction_percent * 100))

	# Test 4.5: Test actual damage reduction
	var initial_hp = player.current_health
	player.take_damage(100.0)  # Deal 100 raw damage
	await get_tree().create_timer(0.1).timeout

	var damage_taken = initial_hp - player.current_health
	var expected_damage = 100.0 * (1.0 - 0.15)  # 85 damage after 15% reduction

	if abs(damage_taken - expected_damage) < 1.0:
		log_pass("Tank damage reduction working: took %.1f damage (85 expected from 100 raw)" % damage_taken)
	else:
		log_fail("Tank damage reduction incorrect: took %.1f damage (expected 85)" % damage_taken)

	# Heal player back to full for next tests
	player.current_health = player.max_health

	print("")

# ============================================================================
# TEST 5: ASSASSIN CHARACTER
# ============================================================================

func test_assassin() -> void:
	"""Test Assassin character and passive ability"""
	print("[TEST 5] Assassin Character")
	current_test = "Assassin Character"

	if not player:
		log_fail("Player reference missing")
		print("")
		return

	# Test 5.1: Apply Assassin character
	var assassin_data = load("res://resources/characters/assassin.tres")
	if not assassin_data:
		log_fail("Failed to load Assassin data")
		print("")
		return

	player.apply_character_data(assassin_data)
	await get_tree().create_timer(0.1).timeout

	# Test 5.2: Verify glass cannon stats (low HP, high speed)
	if player.max_health == 60.0:
		log_pass("Assassin max health correct: 60 (lowest HP)")
	else:
		log_fail("Assassin max health is %.1f (expected 60)" % player.max_health)

	if player.move_speed == 7.0:
		log_pass("Assassin move speed correct: 7.0 (fastest)")
	else:
		log_fail("Assassin move speed is %.1f (expected 7.0)" % player.move_speed)

	# Test 5.3: Verify passive ability (Deadly Precision: +25% crit chance)
	# Base crit chance is 0.05 (5%), Assassin adds 0.25 (25%) = 0.30 (30%) total
	if abs(player.crit_chance - 0.30) < 0.01:
		log_pass("Assassin crit chance correct: 30% (5% base + 25% bonus)")
	else:
		log_fail("Assassin crit chance is %.1f%% (expected 30%%)" % (player.crit_chance * 100))

	# Test 5.4: Verify crit damage bonus (+50% crit damage)
	# Base crit multiplier is 2.0x, Assassin adds 0.5 = 2.5x total
	if abs(player.crit_multiplier - 2.5) < 0.01:
		log_pass("Assassin crit multiplier correct: 2.5x (2.0x base + 0.5x bonus)")
	else:
		log_fail("Assassin crit multiplier is %.2fx (expected 2.5x)" % player.crit_multiplier)

	# Test 5.5: Verify starting weapon
	if assassin_data.starting_weapon_id == "spinning_blade":
		log_pass("Assassin starting weapon correct: 'spinning_blade'")
	else:
		log_fail("Assassin starting weapon is '%s' (expected 'spinning_blade')" % assassin_data.starting_weapon_id)

	print("")

# ============================================================================
# TEST 6: MAGE CHARACTER
# ============================================================================

func test_mage() -> void:
	"""Test Mage character and passive ability"""
	print("[TEST 6] Mage Character")
	current_test = "Mage Character"

	if not player:
		log_fail("Player reference missing")
		print("")
		return

	# Test 6.1: Apply Mage character
	var mage_data = load("res://resources/characters/mage.tres")
	if not mage_data:
		log_fail("Failed to load Mage data")
		print("")
		return

	player.apply_character_data(mage_data)
	await get_tree().create_timer(0.1).timeout

	# Test 6.2: Verify base stats
	if player.max_health == 70.0:
		log_pass("Mage max health correct: 70 (low HP)")
	else:
		log_fail("Mage max health is %.1f (expected 70)" % player.max_health)

	if player.move_speed == 5.0:
		log_pass("Mage move speed correct: 5.0 (normal)")
	else:
		log_fail("Mage move speed is %.1f (expected 5.0)" % player.move_speed)

	# Test 6.3: Verify passive ability (Arcane Mastery: +15% XP gain)
	if abs(player.xp_multiplier - 1.15) < 0.01:
		log_pass("Mage XP multiplier correct: 1.15x (+15%)")
	else:
		log_fail("Mage XP multiplier is %.2fx (expected 1.15x)" % player.xp_multiplier)

	# Test 6.4: Test XP collection with multiplier
	var initial_xp = player.current_xp
	player.collect_xp(100.0)  # Collect 100 base XP
	await get_tree().create_timer(0.1).timeout

	var xp_gained = player.current_xp - initial_xp
	var expected_xp = 100.0 * 1.15  # 115 XP after multiplier

	if abs(xp_gained - expected_xp) < 1.0:
		log_pass("Mage XP multiplier working: gained %.1f XP (115 expected from 100 base)" % xp_gained)
	else:
		log_fail("Mage XP multiplier incorrect: gained %.1f XP (expected 115)" % xp_gained)

	# Test 6.5: Verify extra starting weapons
	if mage_data.extra_starting_weapons == 1:
		log_pass("Mage extra starting weapons correct: 1 (starts with 2 total)")
	else:
		log_fail("Mage extra starting weapons is %d (expected 1)" % mage_data.extra_starting_weapons)

	# Test 6.6: Verify character color
	var expected_color = Color(0.2, 0.5, 0.9, 1)  # Blue-ish
	if player.character_color.is_equal_approx(expected_color):
		log_pass("Mage character color applied correctly (blue)")
	else:
		log_fail("Mage character color is %s (expected %s)" % [player.character_color, expected_color])

	print("")

# ============================================================================
# TEST 7: UNLOCK SYSTEM
# ============================================================================

func test_unlock_system() -> void:
	"""Test character unlock system"""
	print("[TEST 7] Character Unlock System")
	current_test = "Unlock System"

	# Test 7.1: Verify Warrior is unlocked by default
	if GlobalData.is_character_unlocked("warrior"):
		log_pass("Warrior is unlocked by default")
	else:
		log_fail("Warrior is NOT unlocked (should be default)")

	# Test 7.2: Verify unlock costs
	var warrior_data = load("res://resources/characters/warrior.tres")
	var ranger_data = load("res://resources/characters/ranger.tres")
	var tank_data = load("res://resources/characters/tank.tres")
	var assassin_data = load("res://resources/characters/assassin.tres")
	var mage_data = load("res://resources/characters/mage.tres")

	if warrior_data.unlock_cost == 0:
		log_pass("Warrior unlock cost: 0 (free)")
	else:
		log_fail("Warrior unlock cost is %d (expected 0)" % warrior_data.unlock_cost)

	if ranger_data.unlock_cost == 500:
		log_pass("Ranger unlock cost: 500 Essence")
	else:
		log_fail("Ranger unlock cost is %d (expected 500)" % ranger_data.unlock_cost)

	if tank_data.unlock_cost == 750:
		log_pass("Tank unlock cost: 750 Essence")
	else:
		log_fail("Tank unlock cost is %d (expected 750)" % tank_data.unlock_cost)

	if assassin_data.unlock_cost == 1000:
		log_pass("Assassin unlock cost: 1000 Essence")
	else:
		log_fail("Assassin unlock cost is %d (expected 1000)" % assassin_data.unlock_cost)

	if mage_data.unlock_cost == 1500:
		log_pass("Mage unlock cost: 1500 Essence")
	else:
		log_fail("Mage unlock cost is %d (expected 1500)" % mage_data.unlock_cost)

	# Test 7.3: Test unlocking characters
	GlobalData.unlock_character("ranger")
	if GlobalData.is_character_unlocked("ranger"):
		log_pass("Ranger unlocked successfully")
	else:
		log_fail("Failed to unlock Ranger")

	GlobalData.unlock_character("tank")
	if GlobalData.is_character_unlocked("tank"):
		log_pass("Tank unlocked successfully")
	else:
		log_fail("Failed to unlock Tank")

	# Test 7.4: Test character selection
	GlobalData.current_character = "ranger"
	if GlobalData.current_character == "ranger":
		log_pass("Character selection working: Ranger selected")
	else:
		log_fail("Character selection failed: current_character is '%s'" % GlobalData.current_character)

	# Test 7.5: Verify is_starter flag
	if warrior_data.is_starter == true:
		log_pass("Warrior is_starter flag: true")
	else:
		log_fail("Warrior is_starter flag is false (expected true)")

	if ranger_data.is_starter == false:
		log_pass("Ranger is_starter flag: false")
	else:
		log_fail("Ranger is_starter flag is true (expected false)")

	print("")

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

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

	var success_rate = 0.0
	if (tests_passed + tests_failed) > 0:
		success_rate = (tests_passed / float(tests_passed + tests_failed)) * 100.0

	print("Success Rate: %.1f%%" % success_rate)
	print(separator + "\n")

	if tests_failed == 0:
		print("ALL TESTS PASSED! Character system is working correctly.\n")
	else:
		print("SOME TESTS FAILED. Review failures above.\n")
		print("Failed Tests:")
		for result in test_results:
			if result.result == "FAIL":
				print("  - %s: %s" % [result.test, result.message])
		print("")
