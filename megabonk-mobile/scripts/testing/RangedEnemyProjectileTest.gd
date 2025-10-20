extends Node3D
## Automated test for RangedEnemy projectile collision fix
## Verifies that projectiles properly collide with player

# Test results tracking
var test_results = {}
var test_count = 0
var passed_count = 0
var failed_count = 0

# Test state
var ranged_enemy: Node3D = null
var test_player: CharacterBody3D = null
var projectile_spawned: bool = false
var projectile_hit_player: bool = false
var test_duration: float = 0.0
var max_test_time: float = 10.0  # Fail if no hit after 10 seconds

# Test phases
enum TestPhase { SETUP, WAITING_FOR_SPAWN, WAITING_FOR_HIT, COMPLETE }
var current_phase: TestPhase = TestPhase.SETUP

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("RANGED ENEMY PROJECTILE COLLISION TEST")
	print("=".repeat(60))

	# Run all tests
	await get_tree().create_timer(0.5).timeout
	run_all_tests()

func run_all_tests() -> void:
	"""Execute all test scenarios"""
	await test_projectile_collision_layers()
	await test_no_instant_damage_on_range_entry()
	await test_projectile_spawning()
	await test_projectile_hits_player()

	# Final report
	report_results()

func test_projectile_collision_layers() -> void:
	"""Test 1: Verify projectile collision configuration"""
	test_count += 1
	var test_name = "Projectile Collision Layers Configuration"
	print("\n[TEST %d] %s" % [test_count, test_name])

	# Create a test projectile
	var projectile_scene = load("res://scenes/enemies/EnemyProjectile.tscn")
	var projectile = projectile_scene.instantiate()
	add_child(projectile)

	await get_tree().process_frame

	# Check collision layer and mask
	var expected_layer = 4  # Layer 3
	var expected_mask = 4   # Detects Layer 3 (player)

	var layer_correct = projectile.collision_layer == expected_layer
	var mask_correct = projectile.collision_mask == expected_mask

	if layer_correct and mask_correct:
		print("  ✅ PASS: Collision layer=%d (expected %d)" % [projectile.collision_layer, expected_layer])
		print("  ✅ PASS: Collision mask=%d (expected %d)" % [projectile.collision_mask, expected_mask])
		test_results[test_name] = "PASS"
		passed_count += 1
	else:
		print("  ❌ FAIL: Collision layer=%d (expected %d)" % [projectile.collision_layer, expected_layer])
		print("  ❌ FAIL: Collision mask=%d (expected %d)" % [projectile.collision_mask, expected_mask])
		test_results[test_name] = "FAIL"
		failed_count += 1

	projectile.queue_free()

func test_no_instant_damage_on_range_entry() -> void:
	"""Test 2: Verify RangedEnemy does NOT deal instant damage when player enters range"""
	test_count += 1
	var test_name = "No Instant Damage on Range Entry"
	print("\n[TEST %d] %s" % [test_count, test_name])

	# Create test player
	test_player = create_test_player(Vector3(5, 0, 0))
	var initial_health = test_player.current_health

	# Create ranged enemy (player is within 8m attack range)
	ranged_enemy = create_ranged_enemy(Vector3.ZERO)

	# Wait for range detection to trigger
	await get_tree().create_timer(1.5).timeout

	# Check if player took any damage
	var current_health = test_player.current_health
	if current_health < initial_health:
		print("  ❌ FAIL: Player took %.0f instant damage on range entry!" % (initial_health - current_health))
		print("  ❌ RangedEnemy should only damage via projectiles, not contact")
		test_results[test_name] = "FAIL"
		failed_count += 1
	else:
		print("  ✅ PASS: No instant damage when entering attack range")
		print("  ✅ Player health unchanged: %.0f" % current_health)
		test_results[test_name] = "PASS"
		passed_count += 1

	# Cleanup
	test_player.queue_free()
	ranged_enemy.queue_free()

func test_projectile_spawning() -> void:
	"""Test 3: Verify RangedEnemy spawns projectiles"""
	test_count += 1
	var test_name = "RangedEnemy Projectile Spawning"
	print("\n[TEST %d] %s" % [test_count, test_name])

	# Create test player
	test_player = create_test_player(Vector3(5, 0, 0))

	# Create ranged enemy
	ranged_enemy = create_ranged_enemy(Vector3.ZERO)

	await get_tree().create_timer(0.5).timeout

	# Wait for enemy to charge and fire (max 3 seconds)
	var wait_time = 0.0
	var max_wait = 3.0
	projectile_spawned = false

	while wait_time < max_wait and not projectile_spawned:
		await get_tree().create_timer(0.1).timeout
		wait_time += 0.1

		# Check if any projectile exists
		var projectiles = get_tree().get_nodes_in_group("enemy_projectiles")
		if projectiles.size() > 0:
			projectile_spawned = true
			print("  ✅ PASS: Projectile spawned after %.1fs" % wait_time)
			test_results[test_name] = "PASS"
			passed_count += 1
			break

	if not projectile_spawned:
		print("  ❌ FAIL: No projectile spawned after %.1fs" % max_wait)
		test_results[test_name] = "FAIL"
		failed_count += 1

func test_projectile_hits_player() -> void:
	"""Test 4: Verify projectile collides with player"""
	test_count += 1
	var test_name = "Projectile Hits Player"
	print("\n[TEST %d] %s" % [test_count, test_name])

	# Clean up previous test
	if test_player:
		test_player.queue_free()
	if ranged_enemy:
		ranged_enemy.queue_free()

	await get_tree().create_timer(0.5).timeout

	# Create test player with damage tracking
	test_player = create_test_player(Vector3(5, 0, 0))
	var initial_health = test_player.current_health

	# Create ranged enemy positioned to shoot at player
	ranged_enemy = create_ranged_enemy(Vector3.ZERO)

	# CRITICAL: Wait for player to enter range, then verify NO instant damage
	await get_tree().create_timer(1.0).timeout

	var health_after_range_entry = test_player.current_health
	if health_after_range_entry < initial_health:
		print("  ❌ FAIL: Player took instant damage on range entry!")
		print("  ❌ Health: %.0f -> %.0f (should not change until projectile hits)" % [initial_health, health_after_range_entry])
		test_results[test_name] = "FAIL"
		failed_count += 1
		return

	# Wait for projectile to spawn and hit
	var wait_time = 0.0
	var max_wait = 8.0  # Give enough time for charge + travel
	projectile_hit_player = false

	while wait_time < max_wait and not projectile_hit_player:
		await get_tree().create_timer(0.1).timeout
		wait_time += 0.1

		# Check if player took damage
		if test_player.current_health < initial_health:
			projectile_hit_player = true
			var damage_taken = initial_health - test_player.current_health
			print("  ✅ PASS: No instant damage on range entry")
			print("  ✅ PASS: Projectile hit player after %.1fs" % wait_time)
			print("  ✅ Player took %.0f damage (health: %.0f -> %.0f)" % [damage_taken, initial_health, test_player.current_health])
			test_results[test_name] = "PASS"
			passed_count += 1
			break

	if not projectile_hit_player:
		print("  ❌ FAIL: Projectile did not hit player after %.1fs" % max_wait)
		print("  ❌ Player health unchanged: %.0f" % test_player.current_health)
		test_results[test_name] = "FAIL"
		failed_count += 1

func create_test_player(position: Vector3) -> CharacterBody3D:
	"""Create a minimal test player"""
	var player = CharacterBody3D.new()
	player.name = "TestPlayer"
	player.position = position

	# Set collision layers (same as real player)
	player.collision_layer = 4  # Layer 3
	player.collision_mask = 3   # Layer 1 and 2

	# Add collision shape
	var collision_shape = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.height = 1.8
	collision_shape.shape = capsule_shape
	collision_shape.position = Vector3(0, 0.9, 0)
	player.add_child(collision_shape)

	# Add to player group
	player.add_to_group("player")

	# Add health tracking
	player.set_script(load("res://scripts/player/PlayerController.gd"))

	add_child(player)
	print("  Created test player at %s" % position)
	return player

func create_ranged_enemy(position: Vector3) -> Node3D:
	"""Create a RangedEnemy for testing"""
	var enemy_scene = load("res://scenes/enemies/RangedEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.position = position
	add_child(enemy)

	# Wait for enemy to initialize
	await get_tree().process_frame

	print("  Created RangedEnemy at %s" % position)
	return enemy

func report_results() -> void:
	"""Print final test report"""
	print("\n" + "=".repeat(60))
	print("TEST REPORT - RANGED ENEMY PROJECTILE COLLISION")
	print("=".repeat(60))

	for test_name in test_results:
		var result = test_results[test_name]
		var icon = "✅" if result == "PASS" else "❌"
		print("%s %s: %s" % [icon, test_name, result])

	print("\n" + "-".repeat(60))
	print("SUMMARY: %d/%d tests passed (%d failed)" % [passed_count, test_count, failed_count])
	print("=".repeat(60))

	if failed_count == 0:
		print("\n🎉 ALL TESTS PASSED! Projectile collision fix verified.")
	else:
		print("\n⚠️  TESTS FAILED! Projectile collision still has issues.")
		push_error("Projectile collision tests failed!")

	# Exit after report
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
