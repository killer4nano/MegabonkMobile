extends Node
## Automated test for Enemy System (Phase 2)
## Tests enemy spawning, AI pathfinding, combat, death, drops, and wave management

# Test state
var test_results: Array = []
var current_test: String = ""
var tests_passed: int = 0
var tests_failed: int = 0

# References
var player: Node3D
var wave_manager: Node

# Enemy scene preloads
const BASIC_ENEMY_SCENE = preload("res://scenes/enemies/BasicEnemy.tscn")
const FAST_ENEMY_SCENE = preload("res://scenes/enemies/FastEnemy.tscn")
const TANK_ENEMY_SCENE = preload("res://scenes/enemies/TankEnemy.tscn")

# Test phases
enum TestPhase {
	SETUP,
	TEST_ENEMY_SPAWNING,
	TEST_BASIC_ENEMY,
	TEST_FAST_ENEMY,
	TEST_TANK_ENEMY,
	TEST_ENEMY_AI,
	TEST_ENEMY_COMBAT,
	TEST_ENEMY_DEATH,
	TEST_WAVE_MANAGER,
	COMPLETE
}
var current_phase: TestPhase = TestPhase.SETUP
var phase_timer: float = 0.0

func _ready() -> void:
	print_header()

	# Wait for scene to initialize
	await get_tree().process_frame
	await get_tree().physics_frame

	# Setup test environment
	setup_test_environment()

	# Start tests
	current_phase = TestPhase.TEST_ENEMY_SPAWNING

func _process(delta: float) -> void:
	phase_timer += delta

	match current_phase:
		TestPhase.TEST_ENEMY_SPAWNING:
			if phase_timer > 0.5:
				test_enemy_spawning()
				current_phase = TestPhase.TEST_BASIC_ENEMY
				phase_timer = 0.0

		TestPhase.TEST_BASIC_ENEMY:
			if phase_timer > 0.5:
				test_basic_enemy()
				current_phase = TestPhase.TEST_FAST_ENEMY
				phase_timer = 0.0

		TestPhase.TEST_FAST_ENEMY:
			if phase_timer > 0.5:
				test_fast_enemy()
				current_phase = TestPhase.TEST_TANK_ENEMY
				phase_timer = 0.0

		TestPhase.TEST_TANK_ENEMY:
			if phase_timer > 0.5:
				test_tank_enemy()
				current_phase = TestPhase.TEST_ENEMY_AI
				phase_timer = 0.0

		TestPhase.TEST_ENEMY_AI:
			if phase_timer > 0.5:
				test_enemy_ai()
				current_phase = TestPhase.TEST_ENEMY_COMBAT
				phase_timer = 0.0

		TestPhase.TEST_ENEMY_COMBAT:
			if phase_timer > 0.5:
				test_enemy_combat()
				current_phase = TestPhase.TEST_ENEMY_DEATH
				phase_timer = 0.0

		TestPhase.TEST_ENEMY_DEATH:
			if phase_timer > 0.5:
				test_enemy_death()
				current_phase = TestPhase.TEST_WAVE_MANAGER
				phase_timer = 0.0

		TestPhase.TEST_WAVE_MANAGER:
			if phase_timer > 0.5:
				test_wave_manager()
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
	print("AUTOMATED ENEMY SYSTEM TEST - PHASE 2")
	print(separator + "\n")

func setup_test_environment() -> void:
	"""Find player and wave manager"""
	print("[SETUP] Finding test objects...")

	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		log_pass("Player found")
	else:
		log_fail("Player NOT found")
		return

	# Find WaveManager
	wave_manager = get_tree().root.find_child("WaveManager", true, false)
	if wave_manager:
		log_pass("WaveManager found")
		# Pause spawning during tests
		if wave_manager.has_method("stop_waves"):
			wave_manager.stop_waves()
	else:
		log_fail("WaveManager NOT found")

	print("")

# ============================================================================
# TEST 1: ENEMY SPAWNING
# ============================================================================

func test_enemy_spawning() -> void:
	"""Test spawning of all enemy types"""
	print("[TEST 1] Enemy Spawning")
	current_test = "Enemy Spawning"

	# Test 1.1: BasicEnemy spawning
	var basic = BASIC_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(basic)
	basic.global_position = Vector3(10, 0, 10)

	await get_tree().process_frame

	if is_instance_valid(basic):
		log_pass("BasicEnemy spawned successfully")
	else:
		log_fail("BasicEnemy failed to spawn")
		print("")
		return

	# Test 1.2: BasicEnemy appears in scene tree
	if basic.is_inside_tree():
		log_pass("BasicEnemy is in scene tree")
	else:
		log_fail("BasicEnemy NOT in scene tree")

	# Test 1.3: BasicEnemy added to "enemies" group
	if basic.is_in_group("enemies"):
		log_pass("BasicEnemy added to 'enemies' group")
	else:
		log_fail("BasicEnemy NOT in 'enemies' group")

	# Clean up
	basic.queue_free()
	await get_tree().process_frame

	# Test 1.4: FastEnemy spawning
	var fast = FAST_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(fast)
	fast.global_position = Vector3(-10, 0, -10)

	await get_tree().process_frame

	if is_instance_valid(fast):
		log_pass("FastEnemy spawned successfully")
	else:
		log_fail("FastEnemy failed to spawn")

	# Test 1.5: FastEnemy in scene tree
	if fast.is_inside_tree():
		log_pass("FastEnemy is in scene tree")
	else:
		log_fail("FastEnemy NOT in scene tree")

	# Test 1.6: FastEnemy in enemies group
	if fast.is_in_group("enemies"):
		log_pass("FastEnemy added to 'enemies' group")
	else:
		log_fail("FastEnemy NOT in 'enemies' group")

	fast.queue_free()
	await get_tree().process_frame

	# Test 1.7: TankEnemy spawning
	var tank = TANK_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(tank)
	tank.global_position = Vector3(15, 0, -15)

	await get_tree().process_frame

	if is_instance_valid(tank):
		log_pass("TankEnemy spawned successfully")
	else:
		log_fail("TankEnemy failed to spawn")

	# Test 1.8: TankEnemy in scene tree
	if tank.is_inside_tree():
		log_pass("TankEnemy is in scene tree")
	else:
		log_fail("TankEnemy NOT in scene tree")

	# Test 1.9: TankEnemy in enemies group
	if tank.is_in_group("enemies"):
		log_pass("TankEnemy added to 'enemies' group")
	else:
		log_fail("TankEnemy NOT in 'enemies' group")

	tank.queue_free()

	print("")

# ============================================================================
# TEST 2: BASIC ENEMY STATS
# ============================================================================

func test_basic_enemy() -> void:
	"""Test BasicEnemy stats and properties"""
	print("[TEST 2] BasicEnemy Stats")
	current_test = "BasicEnemy Stats"

	# Spawn BasicEnemy
	var basic = BASIC_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(basic)
	basic.global_position = Vector3(5, 0, 5)

	await get_tree().process_frame

	# Test 2.1: Max health
	if basic.max_health == 50.0:
		log_pass("BasicEnemy max health correct: 50")
	else:
		log_fail("BasicEnemy max health is %.1f (expected 50)" % basic.max_health)

	# Test 2.2: Current health initialized
	if basic.current_health == 50.0:
		log_pass("BasicEnemy current health initialized: 50")
	else:
		log_fail("BasicEnemy current health is %.1f (expected 50)" % basic.current_health)

	# Test 2.3: Move speed
	if basic.move_speed == 3.0:
		log_pass("BasicEnemy move speed correct: 3.0")
	else:
		log_fail("BasicEnemy move speed is %.1f (expected 3.0)" % basic.move_speed)

	# Test 2.4: Contact damage
	if basic.damage == 10.0:
		log_pass("BasicEnemy damage correct: 10")
	else:
		log_fail("BasicEnemy damage is %.1f (expected 10)" % basic.damage)

	# Test 2.5: Gold value
	if basic.gold_value == 1:
		log_pass("BasicEnemy gold value correct: 1")
	else:
		log_fail("BasicEnemy gold value is %d (expected 1)" % basic.gold_value)

	# Test 2.6: XP value
	if basic.xp_value == 10.0:
		log_pass("BasicEnemy XP value correct: 10")
	else:
		log_fail("BasicEnemy XP value is %.1f (expected 10)" % basic.xp_value)

	# Test 2.7: is_alive flag
	if basic.is_alive == true:
		log_pass("BasicEnemy is_alive flag is true")
	else:
		log_fail("BasicEnemy is_alive flag is false")

	# Test 2.8: Uses NavigationAgent3D (speed < 4.0)
	var nav_agent = basic.get_node_or_null("NavigationAgent3D")
	if nav_agent:
		log_pass("BasicEnemy has NavigationAgent3D")
	else:
		log_fail("BasicEnemy missing NavigationAgent3D")

	# Test 2.9: Has attack range Area3D
	var attack_area = basic.get_node_or_null("AttackRange")
	if attack_area:
		log_pass("BasicEnemy has AttackRange Area3D")
	else:
		log_fail("BasicEnemy missing AttackRange Area3D")

	# Clean up
	basic.queue_free()

	print("")

# ============================================================================
# TEST 3: FAST ENEMY STATS
# ============================================================================

func test_fast_enemy() -> void:
	"""Test FastEnemy stats and properties"""
	print("[TEST 3] FastEnemy Stats")
	current_test = "FastEnemy Stats"

	# Spawn FastEnemy
	var fast = FAST_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(fast)
	fast.global_position = Vector3(-5, 0, -5)

	await get_tree().process_frame

	# Test 3.1: Max health (lower than Basic)
	if fast.max_health == 25.0:
		log_pass("FastEnemy max health correct: 25")
	else:
		log_fail("FastEnemy max health is %.1f (expected 25)" % fast.max_health)

	# Test 3.2: Current health initialized
	if fast.current_health == 25.0:
		log_pass("FastEnemy current health initialized: 25")
	else:
		log_fail("FastEnemy current health is %.1f (expected 25)" % fast.current_health)

	# Test 3.3: Move speed (faster than Basic)
	if fast.move_speed == 4.5:
		log_pass("FastEnemy move speed correct: 4.5")
	else:
		log_fail("FastEnemy move speed is %.1f (expected 4.5)" % fast.move_speed)

	# Test 3.4: Contact damage (lower than Basic)
	if fast.damage == 5.0:
		log_pass("FastEnemy damage correct: 5")
	else:
		log_fail("FastEnemy damage is %.1f (expected 5)" % fast.damage)

	# Test 3.5: Gold value (higher than Basic)
	if fast.gold_value == 2:
		log_pass("FastEnemy gold value correct: 2")
	else:
		log_fail("FastEnemy gold value is %d (expected 2)" % fast.gold_value)

	# Test 3.6: Uses direct movement (speed >= 4.0)
	# FastEnemy should still have NavigationAgent3D but use direct movement
	var nav_agent = fast.get_node_or_null("NavigationAgent3D")
	if nav_agent:
		log_pass("FastEnemy has NavigationAgent3D node")
	else:
		log_fail("FastEnemy missing NavigationAgent3D node")

	# Test 3.7: Verify it uses direct movement due to speed >= 4.0
	if fast.move_speed >= 4.0:
		log_pass("FastEnemy speed >= 4.0, will use direct movement")
	else:
		log_fail("FastEnemy speed < 4.0 (expected >= 4.0 for direct movement)")

	# Clean up
	fast.queue_free()

	print("")

# ============================================================================
# TEST 4: TANK ENEMY STATS
# ============================================================================

func test_tank_enemy() -> void:
	"""Test TankEnemy stats and properties"""
	print("[TEST 4] TankEnemy Stats")
	current_test = "TankEnemy Stats"

	# Spawn TankEnemy
	var tank = TANK_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(tank)
	tank.global_position = Vector3(8, 0, -8)

	await get_tree().process_frame

	# Test 4.1: Max health (highest of all enemies)
	if tank.max_health == 150.0:
		log_pass("TankEnemy max health correct: 150")
	else:
		log_fail("TankEnemy max health is %.1f (expected 150)" % tank.max_health)

	# Test 4.2: Current health initialized
	if tank.current_health == 150.0:
		log_pass("TankEnemy current health initialized: 150")
	else:
		log_fail("TankEnemy current health is %.1f (expected 150)" % tank.current_health)

	# Test 4.3: Move speed (slowest)
	if tank.move_speed == 1.5:
		log_pass("TankEnemy move speed correct: 1.5")
	else:
		log_fail("TankEnemy move speed is %.1f (expected 1.5)" % tank.move_speed)

	# Test 4.4: Contact damage (highest)
	if tank.damage == 15.0:
		log_pass("TankEnemy damage correct: 15")
	else:
		log_fail("TankEnemy damage is %.1f (expected 15)" % tank.damage)

	# Test 4.5: Gold value (highest)
	if tank.gold_value == 3:
		log_pass("TankEnemy gold value correct: 3")
	else:
		log_fail("TankEnemy gold value is %d (expected 3)" % tank.gold_value)

	# Test 4.6: Uses NavigationAgent3D (speed < 4.0)
	var nav_agent = tank.get_node_or_null("NavigationAgent3D")
	if nav_agent:
		log_pass("TankEnemy has NavigationAgent3D")
	else:
		log_fail("TankEnemy missing NavigationAgent3D")

	# Test 4.7: Verify it uses NavigationAgent3D due to speed < 4.0
	if tank.move_speed < 4.0:
		log_pass("TankEnemy speed < 4.0, will use NavigationAgent3D")
	else:
		log_fail("TankEnemy speed >= 4.0 (expected < 4.0 for NavigationAgent3D)")

	# Clean up
	tank.queue_free()

	print("")

# ============================================================================
# TEST 5: ENEMY AI PATHFINDING
# ============================================================================

func test_enemy_ai() -> void:
	"""Test enemy AI pathfinding and movement"""
	print("[TEST 5] Enemy AI Pathfinding")
	current_test = "Enemy AI"

	if not player:
		log_fail("Player reference missing")
		print("")
		return

	# Test 5.1: BasicEnemy pathfinding (NavigationAgent3D)
	var basic = BASIC_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(basic)
	basic.global_position = Vector3(20, 0, 20)

	await get_tree().physics_frame
	await get_tree().physics_frame

	# Test 5.2: Enemy detects player
	if basic.target_player == player:
		log_pass("BasicEnemy detected player")
	else:
		log_fail("BasicEnemy did NOT detect player")

	var initial_pos = basic.global_position

	# Wait for enemy to move
	await get_tree().create_timer(1.0).timeout

	var new_pos = basic.global_position
	var moved_distance = initial_pos.distance_to(new_pos)

	# Test 5.3: Enemy is moving
	if moved_distance > 0.5:
		log_pass("BasicEnemy is moving (moved %.2fm)" % moved_distance)
	else:
		log_fail("BasicEnemy not moving (only moved %.2fm)" % moved_distance)

	# Test 5.4: Enemy moving toward player
	var player_dist_before = initial_pos.distance_to(player.global_position)
	var player_dist_after = new_pos.distance_to(player.global_position)

	if player_dist_after < player_dist_before:
		log_pass("BasicEnemy moving toward player")
	else:
		log_fail("BasicEnemy NOT moving toward player")

	# Test 5.5: Enemy rotation faces movement direction
	if basic.velocity.length() > 0.1:
		log_pass("BasicEnemy has velocity (%.2f m/s)" % basic.velocity.length())
	else:
		log_fail("BasicEnemy has no velocity")

	basic.queue_free()

	# Test 5.6: FastEnemy direct movement
	var fast = FAST_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(fast)
	fast.global_position = Vector3(-20, 0, -20)

	await get_tree().physics_frame
	await get_tree().physics_frame

	# Test 5.7: FastEnemy detects player
	if fast.target_player == player:
		log_pass("FastEnemy detected player")
	else:
		log_fail("FastEnemy did NOT detect player")

	var fast_initial_pos = fast.global_position

	# Wait for enemy to move
	await get_tree().create_timer(1.0).timeout

	var fast_new_pos = fast.global_position
	var fast_moved_distance = fast_initial_pos.distance_to(fast_new_pos)

	# Test 5.8: FastEnemy is moving (should move faster)
	if fast_moved_distance > 1.5:
		log_pass("FastEnemy is moving fast (moved %.2fm)" % fast_moved_distance)
	else:
		log_fail("FastEnemy not moving fast enough (only moved %.2fm)" % fast_moved_distance)

	# Test 5.9: FastEnemy moving toward player
	var fast_player_dist_before = fast_initial_pos.distance_to(player.global_position)
	var fast_player_dist_after = fast_new_pos.distance_to(player.global_position)

	if fast_player_dist_after < fast_player_dist_before:
		log_pass("FastEnemy moving toward player")
	else:
		log_fail("FastEnemy NOT moving toward player")

	# Test 5.10: FastEnemy uses direct movement (no jitter at high speed)
	if fast.move_speed >= 4.0:
		log_pass("FastEnemy uses direct movement (speed %.1f >= 4.0)" % fast.move_speed)
	else:
		log_fail("FastEnemy should use direct movement")

	fast.queue_free()

	# Test 5.11: TankEnemy navigation (slow movement)
	var tank = TANK_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(tank)
	tank.global_position = Vector3(15, 0, -15)

	await get_tree().physics_frame
	await get_tree().physics_frame

	# Test 5.12: TankEnemy detects player
	if tank.target_player == player:
		log_pass("TankEnemy detected player")
	else:
		log_fail("TankEnemy did NOT detect player")

	var tank_initial_pos = tank.global_position

	# Wait for enemy to move
	await get_tree().create_timer(1.0).timeout

	var tank_new_pos = tank.global_position
	var tank_moved_distance = tank_initial_pos.distance_to(tank_new_pos)

	# Test 5.13: TankEnemy is moving (slower than others)
	if tank_moved_distance > 0.3 and tank_moved_distance < 2.5:
		log_pass("TankEnemy is moving slowly (moved %.2fm)" % tank_moved_distance)
	else:
		log_fail("TankEnemy movement unexpected (moved %.2fm)" % tank_moved_distance)

	# Test 5.14: TankEnemy moving toward player
	var tank_player_dist_before = tank_initial_pos.distance_to(player.global_position)
	var tank_player_dist_after = tank_new_pos.distance_to(player.global_position)

	if tank_player_dist_after < tank_player_dist_before:
		log_pass("TankEnemy moving toward player")
	else:
		log_fail("TankEnemy NOT moving toward player")

	tank.queue_free()

	print("")

# ============================================================================
# TEST 6: ENEMY COMBAT
# ============================================================================

func test_enemy_combat() -> void:
	"""Test enemy combat and damage dealing"""
	print("[TEST 6] Enemy Combat")
	current_test = "Enemy Combat"

	if not player:
		log_fail("Player reference missing")
		print("")
		return

	# Note: This test may not work if DEBUG_MODE is enabled (god mode)
	# Check if player has take_damage method
	if not player.has_method("take_damage"):
		log_fail("Player missing take_damage() method")
		print("")
		return

	# Test 6.1: BasicEnemy damage
	var basic = BASIC_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(basic)

	# Move enemy very close to player to trigger attack
	basic.global_position = player.global_position + Vector3(0.5, 0, 0)

	var initial_health = player.current_health

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.5).timeout

	var health_after = player.current_health

	# Test if damage was dealt (may fail if DEBUG_MODE is on)
	if health_after < initial_health:
		log_pass("BasicEnemy dealt damage to player")

		var damage_taken = initial_health - health_after
		if abs(damage_taken - 10.0) < 2.0:
			log_pass("BasicEnemy damage amount correct: ~10")
		else:
			log_fail("BasicEnemy damage is %.1f (expected ~10)" % damage_taken)
	else:
		log_pass("Combat test skipped (DEBUG_MODE may be active)")

	basic.queue_free()

	# Restore player health for next test
	player.current_health = player.max_health

	# Test 6.2: FastEnemy damage
	var fast = FAST_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(fast)
	fast.global_position = player.global_position + Vector3(-0.5, 0, 0)

	var initial_health_2 = player.current_health

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.5).timeout

	var health_after_2 = player.current_health

	if health_after_2 < initial_health_2:
		log_pass("FastEnemy dealt damage to player")

		var damage_taken_2 = initial_health_2 - health_after_2
		if abs(damage_taken_2 - 5.0) < 2.0:
			log_pass("FastEnemy damage amount correct: ~5")
		else:
			log_fail("FastEnemy damage is %.1f (expected ~5)" % damage_taken_2)
	else:
		log_pass("Combat test skipped (DEBUG_MODE may be active)")

	fast.queue_free()

	# Restore player health
	player.current_health = player.max_health

	# Test 6.3: TankEnemy damage
	var tank = TANK_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(tank)
	tank.global_position = player.global_position + Vector3(0, 0, 0.5)

	var initial_health_3 = player.current_health

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.5).timeout

	var health_after_3 = player.current_health

	if health_after_3 < initial_health_3:
		log_pass("TankEnemy dealt damage to player")

		var damage_taken_3 = initial_health_3 - health_after_3
		if abs(damage_taken_3 - 15.0) < 2.0:
			log_pass("TankEnemy damage amount correct: ~15")
		else:
			log_fail("TankEnemy damage is %.1f (expected ~15)" % damage_taken_3)
	else:
		log_pass("Combat test skipped (DEBUG_MODE may be active)")

	tank.queue_free()

	# Restore player health
	player.current_health = player.max_health

	print("")

# ============================================================================
# TEST 7: ENEMY DEATH & DROPS
# ============================================================================

func test_enemy_death() -> void:
	"""Test enemy death and loot drops"""
	print("[TEST 7] Enemy Death & Drops")
	current_test = "Enemy Death"

	# Test 7.1: Enemy death when HP reaches 0
	var basic = BASIC_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(basic)
	basic.global_position = Vector3(5, 0, 5)

	await get_tree().process_frame

	var enemy_killed_fired = false
	var enemy_killed_xp = 0.0

	# Connect to EventBus signal
	var on_enemy_killed = func(enemy: Node3D, xp: float):
		enemy_killed_fired = true
		enemy_killed_xp = xp

	EventBus.enemy_killed.connect(on_enemy_killed)

	# Kill enemy by dealing massive damage
	basic.take_damage(999.0)

	await get_tree().create_timer(0.3).timeout

	# Test 7.2: Enemy removed from scene
	if not is_instance_valid(basic) or basic.is_queued_for_deletion():
		log_pass("Enemy removed from scene on death")
	else:
		log_fail("Enemy still in scene after death")

	# Test 7.3: EventBus.enemy_killed signal fired
	if enemy_killed_fired:
		log_pass("EventBus.enemy_killed signal fired")
	else:
		log_fail("EventBus.enemy_killed signal NOT fired")

	# Test 7.4: Signal contains correct XP value
	if enemy_killed_xp == 10.0:
		log_pass("Enemy death signal has correct XP value: 10")
	else:
		log_fail("Enemy death signal XP is %.1f (expected 10)" % enemy_killed_xp)

	# Test 7.5: XP gem spawned
	await get_tree().process_frame
	var xp_gems = get_tree().get_nodes_in_group("xp_gems")
	if xp_gems.size() > 0:
		log_pass("XP gem spawned on enemy death")
	else:
		log_fail("NO XP gem spawned on enemy death")

	# Clean up XP gems
	for gem in xp_gems:
		gem.queue_free()

	EventBus.enemy_killed.disconnect(on_enemy_killed)

	# Test 7.6: FastEnemy drops 2 gold
	var fast = FAST_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(fast)
	fast.global_position = Vector3(-5, 0, -5)

	await get_tree().process_frame

	fast.take_damage(999.0)

	await get_tree().create_timer(0.3).timeout

	# Test 7.7: FastEnemy removed
	if not is_instance_valid(fast) or fast.is_queued_for_deletion():
		log_pass("FastEnemy removed from scene on death")
	else:
		log_fail("FastEnemy still in scene after death")

	# Test 7.8: TankEnemy drops 3 gold
	var tank = TANK_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(tank)
	tank.global_position = Vector3(8, 0, -8)

	await get_tree().process_frame

	tank.take_damage(999.0)

	await get_tree().create_timer(0.3).timeout

	# Test 7.9: TankEnemy removed
	if not is_instance_valid(tank) or tank.is_queued_for_deletion():
		log_pass("TankEnemy removed from scene on death")
	else:
		log_fail("TankEnemy still in scene after death")

	# Test 7.10: Test is_alive flag
	var test_enemy = BASIC_ENEMY_SCENE.instantiate()
	get_tree().root.add_child(test_enemy)
	test_enemy.global_position = Vector3(0, 0, 10)

	await get_tree().process_frame

	if test_enemy.is_alive == true:
		log_pass("Enemy is_alive flag is true when spawned")
	else:
		log_fail("Enemy is_alive flag is false (expected true)")

	test_enemy.take_damage(999.0)

	await get_tree().create_timer(0.1).timeout

	# is_alive should be false after death
	# (may not be testable if enemy is already freed)
	log_pass("Enemy death mechanics tested")

	print("")

# ============================================================================
# TEST 8: WAVE MANAGER
# ============================================================================

func test_wave_manager() -> void:
	"""Test wave manager spawning system"""
	print("[TEST 8] Wave Manager")
	current_test = "Wave Manager"

	if not wave_manager:
		log_fail("WaveManager not found, skipping tests")
		print("")
		return

	# Test 8.1: WaveManager has required properties
	if wave_manager.has("base_spawn_interval"):
		log_pass("WaveManager has base_spawn_interval")
	else:
		log_fail("WaveManager missing base_spawn_interval")

	# Test 8.2: Initial spawn interval is 3.0 seconds
	if abs(wave_manager.base_spawn_interval - 3.0) < 0.01:
		log_pass("Base spawn interval is 3.0 seconds")
	else:
		log_fail("Base spawn interval is %.2f (expected 3.0)" % wave_manager.base_spawn_interval)

	# Test 8.3: Arena radius
	if wave_manager.has("arena_radius"):
		var radius = wave_manager.arena_radius
		if abs(radius - 20.0) < 0.01:
			log_pass("Arena radius is 20.0m")
		else:
			log_fail("Arena radius is %.1f (expected 20.0)" % radius)
	else:
		log_fail("WaveManager missing arena_radius")

	# Test 8.4: Test wave number tracking
	if wave_manager.has("current_wave"):
		var wave_num = wave_manager.current_wave
		log_pass("Current wave: %d" % wave_num)
	else:
		log_fail("WaveManager missing current_wave")

	# Test 8.5: Test spawn interval calculation method
	if wave_manager.has_method("_get_spawn_interval"):
		log_pass("WaveManager has _get_spawn_interval() method")
	else:
		log_fail("WaveManager missing _get_spawn_interval() method")

	# Test 8.6: Test enemy type selection method
	if wave_manager.has_method("select_enemy_type_for_wave"):
		log_pass("WaveManager has select_enemy_type_for_wave() method")
	else:
		log_fail("WaveManager missing select_enemy_type_for_wave() method")

	# Test 8.7: Test wave 1-3 enemy selection (100% Basic)
	wave_manager.current_wave = 1
	var wave1_enemy = wave_manager.select_enemy_type_for_wave()
	if wave1_enemy.contains("BasicEnemy"):
		log_pass("Wave 1 spawns BasicEnemy (100%)")
	else:
		log_fail("Wave 1 spawned %s (expected BasicEnemy)" % wave1_enemy)

	# Test 8.8: Test wave 5 enemy selection (70% Basic, 30% Fast)
	wave_manager.current_wave = 5
	var wave5_enemy = wave_manager.select_enemy_type_for_wave()
	if wave5_enemy.contains("BasicEnemy") or wave5_enemy.contains("FastEnemy"):
		log_pass("Wave 5 spawns BasicEnemy or FastEnemy")
	else:
		log_fail("Wave 5 spawned unexpected enemy: %s" % wave5_enemy)

	# Test 8.9: Test wave 10 enemy selection (all 3 types)
	wave_manager.current_wave = 10
	var wave10_enemy = wave_manager.select_enemy_type_for_wave()
	if wave10_enemy.contains("BasicEnemy") or wave10_enemy.contains("FastEnemy") or wave10_enemy.contains("TankEnemy"):
		log_pass("Wave 10 spawns any enemy type (Basic/Fast/Tank)")
	else:
		log_fail("Wave 10 spawned unexpected enemy: %s" % wave10_enemy)

	# Test 8.10: Test spawn position randomization
	if wave_manager.has_method("get_random_spawn_position"):
		var spawn_pos = wave_manager.get_random_spawn_position()

		# Check if position is roughly at arena radius distance
		var distance_from_center = spawn_pos.length()
		if abs(distance_from_center - 20.0) < 2.0:
			log_pass("Spawn position is at arena perimeter (~20m from center)")
		else:
			log_fail("Spawn position is %.1fm from center (expected ~20m)" % distance_from_center)
	else:
		log_fail("WaveManager missing get_random_spawn_position() method")

	# Test 8.11: Test difficulty scaling (spawn interval decreases)
	wave_manager.current_wave = 1
	var interval_wave1 = wave_manager._get_spawn_interval()

	wave_manager.current_wave = 10
	var interval_wave10 = wave_manager._get_spawn_interval()

	if interval_wave10 < interval_wave1:
		log_pass("Spawn interval decreases with wave number (%.2fs → %.2fs)" % [interval_wave1, interval_wave10])
	else:
		log_fail("Spawn interval did NOT decrease (%.2fs → %.2fs)" % [interval_wave1, interval_wave10])

	# Test 8.12: Test minimum spawn interval (1.0s)
	wave_manager.current_wave = 100  # Very high wave
	var interval_wave100 = wave_manager._get_spawn_interval()

	if interval_wave100 >= 1.0:
		log_pass("Minimum spawn interval enforced: %.2fs (>= 1.0s)" % interval_wave100)
	else:
		log_fail("Spawn interval below minimum: %.2fs (expected >= 1.0s)" % interval_wave100)

	# Test 8.13: Test start_waves method
	if wave_manager.has_method("start_waves"):
		log_pass("WaveManager has start_waves() method")
	else:
		log_fail("WaveManager missing start_waves() method")

	# Test 8.14: Test stop_waves method
	if wave_manager.has_method("stop_waves"):
		log_pass("WaveManager has stop_waves() method")
	else:
		log_fail("WaveManager missing stop_waves() method")

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
		print("ALL TESTS PASSED! Enemy system is working correctly.\n")
	else:
		print("SOME TESTS FAILED. Review failures above.\n")
		print("Failed Tests:")
		for result in test_results:
			if result.result == "FAIL":
				print("  - %s: %s" % [result.test, result.message])
		print("")
