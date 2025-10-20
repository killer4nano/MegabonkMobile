extends Node3D
## Automated test for enemy collision precision
## Verifies that enemies only damage player on actual mesh contact

# Test results tracking
var test_results = {}
var test_count = 0
var passed_count = 0
var failed_count = 0

# Test state
var test_player: CharacterBody3D = null

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("ENEMY COLLISION PRECISION TEST")
	print("=".repeat(60))

	# Run all tests
	await get_tree().create_timer(0.5).timeout
	run_all_tests()

func run_all_tests() -> void:
	"""Execute all test scenarios"""
	await test_basic_enemy_collision_shape()
	await test_fast_enemy_collision_shape()
	await test_tank_enemy_collision_shape()
	await test_no_damage_outside_mesh()
	await test_attack_cooldown()

	# Final report
	report_results()

func test_basic_enemy_collision_shape() -> void:
	"""Test 1: Verify BasicEnemy attack range has small buffer (0.1m)"""
	test_count += 1
	var test_name = "BasicEnemy Attack Range Buffer"
	print("\n[TEST %d] %s" % [test_count, test_name])

	# Load BasicEnemy scene
	var enemy_scene = load("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	# Get collision shape and attack range
	var collision_shape = enemy.get_node("CollisionShape3D").shape as CapsuleShape3D
	var attack_range = enemy.get_node("AttackRange/CollisionShape3D").shape as CapsuleShape3D

	var collision_radius = collision_shape.radius
	var attack_radius = attack_range.radius
	var buffer = attack_radius - collision_radius

	# Check for 0.1m buffer (allow 0.05-0.15m tolerance)
	if buffer >= 0.05 and buffer <= 0.15:
		print("  ✅ PASS: Attack range has %.2fm buffer (good)" % buffer)
		print("    Collision: %.2fm radius" % collision_radius)
		print("    Attack: %.2fm radius" % attack_radius)
		test_results[test_name] = "PASS"
		passed_count += 1
	else:
		print("  ❌ FAIL: Attack buffer out of range: %.2fm (expected 0.1m)" % buffer)
		print("    Collision: %.2fm radius" % collision_radius)
		print("    Attack: %.2fm radius" % attack_radius)
		test_results[test_name] = "FAIL"
		failed_count += 1

	enemy.queue_free()

func test_fast_enemy_collision_shape() -> void:
	"""Test 2: Verify FastEnemy attack range has small buffer (0.1m)"""
	test_count += 1
	var test_name = "FastEnemy Attack Range Buffer"
	print("\n[TEST %d] %s" % [test_count, test_name])

	var enemy_scene = load("res://scenes/enemies/FastEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	var collision_shape = enemy.get_node("CollisionShape3D").shape as CapsuleShape3D
	var attack_range = enemy.get_node("AttackRange/CollisionShape3D").shape as CapsuleShape3D

	var collision_radius = collision_shape.radius
	var attack_radius = attack_range.radius
	var buffer = attack_radius - collision_radius

	# Check for 0.1m buffer (allow 0.05-0.15m tolerance)
	if buffer >= 0.05 and buffer <= 0.15:
		print("  ✅ PASS: Attack range has %.2fm buffer (good)" % buffer)
		print("    Collision: %.2fm radius" % collision_radius)
		print("    Attack: %.2fm radius" % attack_radius)
		test_results[test_name] = "PASS"
		passed_count += 1
	else:
		print("  ❌ FAIL: Attack buffer out of range: %.2fm (expected 0.1m)" % buffer)
		print("    Collision: %.2fm radius" % collision_radius)
		print("    Attack: %.2fm radius" % attack_radius)
		test_results[test_name] = "FAIL"
		failed_count += 1

	enemy.queue_free()

func test_tank_enemy_collision_shape() -> void:
	"""Test 3: Verify TankEnemy attack range has small buffer (0.1m)"""
	test_count += 1
	var test_name = "TankEnemy Attack Range Buffer"
	print("\n[TEST %d] %s" % [test_count, test_name])

	var enemy_scene = load("res://scenes/enemies/TankEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	await get_tree().process_frame

	var collision_shape = enemy.get_node("CollisionShape3D").shape as CapsuleShape3D
	var attack_range = enemy.get_node("AttackRange/CollisionShape3D").shape as CapsuleShape3D

	var collision_radius = collision_shape.radius
	var attack_radius = attack_range.radius
	var buffer = attack_radius - collision_radius

	# Check for 0.1m buffer (allow 0.05-0.15m tolerance)
	if buffer >= 0.05 and buffer <= 0.15:
		print("  ✅ PASS: Attack range has %.2fm buffer (good)" % buffer)
		print("    Collision: %.2fm radius" % collision_radius)
		print("    Attack: %.2fm radius" % attack_radius)
		test_results[test_name] = "PASS"
		passed_count += 1
	else:
		print("  ❌ FAIL: Attack buffer out of range: %.2fm (expected 0.1m)" % buffer)
		print("    Collision: %.2fm radius" % collision_radius)
		print("    Attack: %.2fm radius" % attack_radius)
		test_results[test_name] = "FAIL"
		failed_count += 1

	enemy.queue_free()

func test_no_damage_outside_mesh() -> void:
	"""Test 4: Verify player takes no damage when just outside attack buffer"""
	test_count += 1
	var test_name = "No Damage Outside Attack Buffer"
	print("\n[TEST %d] %s" % [test_count, test_name])

	# Create test player
	test_player = create_test_player(Vector3.ZERO)
	var initial_health = test_player.current_health

	# Create enemy just outside attack range (0.8m away, attack radius is 0.6m + player 0.4m = 1.0m total)
	var enemy_scene = load("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.position = Vector3(1.2, 0, 0)  # Outside 1.0m combined range
	add_child(enemy)

	await get_tree().create_timer(2.0).timeout

	# Check if player took damage
	var current_health = test_player.current_health
	if current_health == initial_health:
		print("  ✅ PASS: No damage when 1.2m away (outside 1.0m range)")
		print("    Player health unchanged: %.0f" % current_health)
		test_results[test_name] = "PASS"
		passed_count += 1
	else:
		print("  ❌ FAIL: Player took damage outside attack range")
		print("    Health: %.0f -> %.0f (should not change)" % [initial_health, current_health])
		test_results[test_name] = "FAIL"
		failed_count += 1

	test_player.queue_free()
	enemy.queue_free()

func test_attack_cooldown() -> void:
	"""Test 5: Verify enemies have 1-second attack cooldown"""
	test_count += 1
	var test_name = "1-Second Attack Cooldown"
	print("\n[TEST %d] %s" % [test_count, test_name])

	# Create test player
	test_player = create_test_player(Vector3.ZERO)
	var initial_health = test_player.current_health

	# Create enemy at same position (touching)
	var enemy_scene = load("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.position = Vector3.ZERO
	add_child(enemy)

	# Wait for first attack
	await get_tree().create_timer(0.5).timeout
	var health_after_first_hit = test_player.current_health
	var first_damage = initial_health - health_after_first_hit

	if first_damage <= 0:
		print("  ❌ FAIL: No damage dealt on contact (enemy not attacking)")
		test_results[test_name] = "FAIL"
		failed_count += 1
		test_player.queue_free()
		enemy.queue_free()
		return

	print("    First hit: %.0f damage" % first_damage)

	# Wait another 0.5 seconds (total 1.0s - should NOT attack again yet)
	await get_tree().create_timer(0.5).timeout
	var health_at_one_second = test_player.current_health

	if health_at_one_second == health_after_first_hit:
		print("  ✅ PASS: No second attack within 1 second")
		print("    Health stayed at %.0f for 1 second" % health_at_one_second)
		test_results[test_name] = "PASS"
		passed_count += 1
	else:
		print("  ❌ FAIL: Enemy attacked again before cooldown")
		print("    Health: %.0f -> %.0f (should not change)" % [health_after_first_hit, health_at_one_second])
		test_results[test_name] = "FAIL"
		failed_count += 1

	test_player.queue_free()
	enemy.queue_free()

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
	capsule_shape.radius = 0.4
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

func report_results() -> void:
	"""Print final test report"""
	print("\n" + "=".repeat(60))
	print("TEST REPORT - ENEMY COLLISION PRECISION")
	print("=".repeat(60))

	for test_name in test_results:
		var result = test_results[test_name]
		var icon = "✅" if result == "PASS" else "❌"
		print("%s %s: %s" % [icon, test_name, result])

	print("\n" + "-".repeat(60))
	print("SUMMARY: %d/%d tests passed (%d failed)" % [passed_count, test_count, failed_count])
	print("=".repeat(60))

	if failed_count == 0:
		print("\n🎉 ALL TESTS PASSED! Collision precision verified.")
		print("✅ Enemies only damage on actual mesh contact")
		print("✅ No phantom damage outside visual range")
		print("✅ 1-second attack cooldown prevents spam")
	else:
		print("\n⚠️  TESTS FAILED! Collision precision has issues.")
		push_error("Enemy collision precision tests failed!")

	# Exit after report
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
