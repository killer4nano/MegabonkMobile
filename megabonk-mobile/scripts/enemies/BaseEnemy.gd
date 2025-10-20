extends CharacterBody3D
class_name BaseEnemy
## Base enemy controller for mobile roguelite
## Handles enemy AI, pathfinding, combat, and health management

# Pickup scenes for spawning
const XP_GEM_SCENE = preload("res://scenes/pickups/XPGem.tscn")
const GOLD_COIN_SCENE = preload("res://scenes/pickups/GoldCoin.tscn")

# Enemy stats
@export_group("Stats")
@export var max_health: float = 50.0
@export var move_speed: float = 3.0
@export var damage: float = 10.0
@export var xp_value: float = 10.0
@export var gold_value: int = 1  # Gold coins dropped on death

@export_group("AI Behavior")
@export var attack_range: float = 1.5
@export var detection_range: float = 20.0
@export var path_update_rate: float = 0.3  # How often to recalculate path (seconds)

@export_group("Movement")
@export var acceleration: float = 10.0
@export var rotation_speed: float = 8.0
@export var climb_speed: float = 3.0  # Base speed when climbing obstacles - reduced from 8.0 for realism

# Use project gravity for consistency
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Signals
signal enemy_died(xp_value: float)
signal enemy_damaged(damage: float)

# Current state
var current_health: float
var is_alive: bool = true
var target_player: CharacterBody3D = null

# Pathfinding
var path_update_timer: float = 0.0
var can_attack: bool = false

# Status effects
var is_slowed: bool = false
var slow_multiplier: float = 1.0
var slow_timer: float = 0.0
var is_burning: bool = false
var burn_damage_per_second: float = 0.0
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0

# Teleport system (keeps enemies near player on large maps)
var teleport_distance_threshold: float = 50.0  # Teleport if player gets >50m away
var teleport_cooldown: float = 5.0  # Wait 5 seconds before teleporting
var teleport_timer: float = 0.0
var player_too_far: bool = false

# Navigation readiness (prevents jitter on spawn/teleport)
var navigation_ready: bool = false
var navigation_ready_timer: float = 0.0
var navigation_ready_delay_spawn: float = 0.1  # Wait 0.1 seconds after spawn
var navigation_ready_delay_teleport: float = 0.5  # Wait 0.5 seconds after teleport (path recalc time)

# Force direct movement after teleport (bypasses broken NavigationAgent3D state)
var force_direct_movement: bool = false
var force_direct_movement_timer: float = 0.0
var force_direct_movement_duration: float = 3.0  # Use direct movement for 3s after teleport

# Climbing system
var is_climbing: bool = false
var climb_target_height: float = 0.0
var obstacle_check_ray: RayCast3D  # Forward ray to detect walls
var ground_check_ray: RayCast3D  # Downward ray to check ground
var top_check_ray: RayCast3D  # Upper forward ray to check if we can climb over
var stuck_timer: float = 0.0  # Track if enemy is stuck
var last_position: Vector3  # Track position to detect stuck state
var climb_cooldown: float = 0.0  # Prevent immediate re-climbing after landing
var landing_timer: float = 0.0  # Time to stabilize after climbing
var edge_clear_mode: bool = false  # Special mode for clearing edges
var bounce_prevention_timer: float = 0.0  # Prevent oscillation at edges

# References
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_area: Area3D = $AttackRange
@onready var body_mesh: MeshInstance3D = $Body

func _ready() -> void:
	current_health = max_health
	print("Enemy spawned with ", max_health, " HP")

	# Add to enemies group for weapon targeting
	add_to_group("enemies")

	# Initialize climbing detection
	last_position = global_position

	# Setup obstacle detection raycasts for climbing system
	# Forward ray at waist height to detect walls
	obstacle_check_ray = RayCast3D.new()
	add_child(obstacle_check_ray)
	obstacle_check_ray.position = Vector3(0, 0.5, 0)  # Waist height
	obstacle_check_ray.target_position = Vector3(0, 0, -1.0)  # Check 1m forward
	obstacle_check_ray.enabled = true
	obstacle_check_ray.collision_mask = 1  # Only collide with layer 1 (environment/static bodies)
	obstacle_check_ray.exclude_parent = true  # Don't detect self
	obstacle_check_ray.debug_shape_custom_color = Color.RED
	obstacle_check_ray.debug_shape_thickness = 5
	if OS.is_debug_build():
		obstacle_check_ray.visible = true  # Show debug shape in debug builds

	# Upper ray to check if there's space to climb over
	top_check_ray = RayCast3D.new()
	add_child(top_check_ray)
	top_check_ray.position = Vector3(0, 2.0, 0)  # Above enemy height
	top_check_ray.target_position = Vector3(0, 0, -1.0)  # Check 1m forward
	top_check_ray.enabled = true
	top_check_ray.collision_mask = 1  # Only layer 1
	top_check_ray.exclude_parent = true
	top_check_ray.debug_shape_custom_color = Color.GREEN
	top_check_ray.debug_shape_thickness = 3

	# Ground check ray
	ground_check_ray = RayCast3D.new()
	add_child(ground_check_ray)
	ground_check_ray.position = Vector3(0, 0.1, 0)  # Slightly above feet
	ground_check_ray.target_position = Vector3(0, -2.0, 0)  # Check 2m down
	ground_check_ray.enabled = true
	ground_check_ray.collision_mask = 1  # Only layer 1
	ground_check_ray.exclude_parent = true
	ground_check_ray.debug_shape_custom_color = Color.YELLOW
	ground_check_ray.debug_shape_thickness = 3

	# Make material unique so damage flash doesn't affect all enemies
	var body = get_node_or_null("Body")
	if body and body is MeshInstance3D:
		var mesh_instance = body as MeshInstance3D
		if mesh_instance.get_surface_override_material_count() > 0:
			var mat = mesh_instance.get_surface_override_material(0)
			if mat:
				mesh_instance.set_surface_override_material(0, mat.duplicate())
		elif mesh_instance.mesh and mesh_instance.mesh.surface_get_material(0):
			var mat = mesh_instance.mesh.surface_get_material(0).duplicate()
			mesh_instance.set_surface_override_material(0, mat)

	# Configure NavigationAgent3D
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = attack_range
	nav_agent.max_speed = move_speed

	# Connect attack range signals
	if attack_area:
		attack_area.body_entered.connect(_on_attack_range_entered)
		attack_area.body_exited.connect(_on_attack_range_exited)

	# Find the player (assuming player is in "player" group)
	call_deferred("_find_player")

	# Start navigation readiness timer (prevents jitter on spawn)
	navigation_ready_timer = navigation_ready_delay_spawn

	# Emit spawn signal
	EventBus.enemy_spawned.emit(self)

func _find_player() -> void:
	"""Find the player in the scene"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		print("Enemy found player: ", target_player.name)
	else:
		push_warning("Enemy could not find player!")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if not target_player:
		return

	# === CORE SYSTEMS (all enemies) ===
	_update_navigation_ready_timer(delta)
	# NOTE: force_direct_movement timer no longer needed - we always use direct movement
	# _update_force_direct_movement_timer(delta)
	_update_status_effects(delta)
	_check_teleport_distance(delta)

	# === NAVIGATION PATH UPDATES (for navigation-based movement) ===
	if _should_update_navigation_path():
		path_update_timer += delta
		if path_update_timer >= path_update_rate:
			path_update_timer = 0.0
			update_target_position()

	# === ENEMY-SPECIFIC BEHAVIOR (override in subclasses) ===
	_process_enemy_behavior(delta)

	# === COOLDOWN UPDATES ===
	if climb_cooldown > 0:
		climb_cooldown -= delta
	if landing_timer > 0:
		landing_timer -= delta
	if bounce_prevention_timer > 0:
		bounce_prevention_timer -= delta

	# === STUCK DETECTION ===
	detect_stuck_state(delta)

	# === PROXIMITY CLIMBING CHECK ===
	# Always check for climbing opportunities when player is above
	if not is_climbing and target_player and climb_cooldown <= 0:
		var to_player = target_player.global_position - global_position
		var horizontal_dist = Vector2(to_player.x, to_player.z).length()

		# If player is above us at ANY distance within detection range
		if horizontal_dist < detection_range and to_player.y > 2.0:
			# Force check for obstacles
			var check_dir = Vector3(to_player.x, 0, to_player.z).normalized()
			check_for_obstacle_ahead(check_dir)

	# === CLIMBING & GRAVITY ===
	handle_climbing_and_gravity(delta)

	# === MOVEMENT APPLICATION ===
	move_and_slide()

func _update_navigation_ready_timer(delta: float) -> void:
	"""Update navigation readiness timer (prevents jitter on spawn/teleport)"""
	if not navigation_ready:
		navigation_ready_timer -= delta
		if navigation_ready_timer <= 0.0:
			navigation_ready = true
			print("Enemy navigation ready")

func _update_force_direct_movement_timer(delta: float) -> void:
	"""Update forced direct movement timer (after teleport)"""
	if force_direct_movement:
		force_direct_movement_timer -= delta
		if force_direct_movement_timer <= 0.0:
			force_direct_movement = false
			print("Switched back to navigation movement")

func _should_update_navigation_path() -> bool:
	"""Override in subclasses that don't use NavigationAgent3D"""
	return move_speed < 4.0  # Only update nav path for slow enemies using navigation

func _process_enemy_behavior(delta: float) -> void:
	"""Default enemy behavior - override in subclasses for custom behavior"""
	if not navigation_ready:
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# PROACTIVE CLIMBING CHECK - Always check for obstacles toward player
	if target_player and not is_climbing and climb_cooldown <= 0:
		var distance_to_player = global_position.distance_to(target_player.global_position)
		# Check at any distance within detection range
		if distance_to_player <= detection_range:
			var to_player = global_position.direction_to(target_player.global_position)
			to_player.y = 0
			if to_player.length() > 0.1:
				to_player = to_player.normalized()
				# Always check if there's an obstacle between us and player
				check_for_obstacle_ahead(to_player)

	# Use handle_movement which already decides between direct and navigation
	handle_movement(delta)

	# Rotate to face movement direction (only if not climbing)
	if not is_climbing and velocity.length() > 0.1:
		var target_direction = velocity.normalized()
		var target_rotation = atan2(target_direction.x, target_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

func update_target_position() -> void:
	"""Update the navigation target to the player's position"""
	if target_player and is_alive:
		nav_agent.target_position = target_player.global_position
		# Debug output removed - too spammy
		# print("Enemy pathfinding to player at: ", target_player.global_position)

func handle_movement(delta: float) -> void:
	"""Handle enemy movement using NavigationAgent3D or direct movement for fast enemies"""

	# Wait for navigation to be ready (prevents jitter on spawn/teleport)
	if not navigation_ready:
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# FastEnemy uses direct movement (no navigation) to avoid jittering at high speeds
	if move_speed >= 4.0:
		handle_direct_movement(delta)
		return

	# Don't handle normal movement if climbing - let climbing system handle it
	if is_climbing:
		return

	# During landing phase, reduce horizontal movement
	if landing_timer > 0:
		velocity.x *= 0.5
		velocity.z *= 0.5
		return

	# Normal navigation-based movement for slower enemies
	if nav_agent.is_navigation_finished():
		# Reached destination or path invalid
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# Get next position in path
	var next_path_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_position)

	# Check for obstacles ahead and initiate climbing if needed
	check_for_obstacle_ahead(direction)

	# CRITICAL: If climbing just started, don't apply navigation movement
	if is_climbing:
		return

	# Normal ground movement
	direction.y = 0  # Keep movement on ground plane
	direction = direction.normalized()

	# Accelerate toward target direction (apply slow effect)
	var effective_speed = move_speed * slow_multiplier
	var target_velocity = direction * effective_speed

	# Only apply horizontal velocity
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

func handle_direct_movement(delta: float) -> void:
	"""Direct movement for fast enemies (bypasses navigation to prevent jittering)"""
	if not target_player or not is_instance_valid(target_player):
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# Don't handle normal movement if climbing - let climbing system handle it
	if is_climbing:
		return

	# During landing phase, reduce horizontal movement
	if landing_timer > 0:
		velocity.x *= 0.5
		velocity.z *= 0.5
		return

	# Direct movement toward player - no NavigationAgent3D, no pathfinding
	var direction = global_position.direction_to(target_player.global_position)

	# Check for obstacles ahead and initiate climbing if needed
	check_for_obstacle_ahead(direction)

	# CRITICAL: If climbing just started, don't apply movement
	if is_climbing:
		return

	# Normal ground movement
	direction.y = 0  # Keep on ground plane
	direction = direction.normalized()

	# Set velocity directly toward player (apply slow effect)
	var effective_speed = move_speed * slow_multiplier
	var target_velocity = direction * effective_speed

	# Only apply horizontal velocity
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

	# Rotate to face movement direction
	if velocity.length() > 0.1:
		var angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, angle, rotation_speed * delta)

func take_damage(amount: float) -> void:
	"""Deal damage to the enemy"""
	if not is_alive:
		return

	current_health -= amount
	enemy_damaged.emit(amount)

	print("Enemy took ", amount, " damage. HP: ", current_health, "/", max_health)

	# Flash red visual feedback
	_flash_damage()

	if current_health <= 0:
		current_health = 0
		die()

func die() -> void:
	"""Handle enemy death"""
	print("DEBUG: die() method called - is_alive:", is_alive, " current_health:", current_health)

	if not is_alive:
		return

	is_alive = false
	print("Enemy died! Dropping ", xp_value, " XP")

	# Emit signals
	enemy_died.emit(xp_value)
	EventBus.enemy_killed.emit(self, xp_value)

	# Check for player's explosion on kill upgrade
	var player = get_tree().get_first_node_in_group("player")
	if player and player.explosion_on_kill:
		_create_explosion(player.explosion_damage, player.explosion_radius)

	# Spawn XP gem at enemy's position
	spawn_xp_gem()

	# Spawn gold coins at enemy's position
	spawn_gold()

	# Disable collision and hide
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	visible = false

	# Queue for deletion after a short delay
	await get_tree().create_timer(0.1).timeout
	queue_free()

func spawn_xp_gem() -> void:
	"""Spawn an XP gem at the enemy's death location"""
	var gem = XP_GEM_SCENE.instantiate()

	# Set gem position to enemy's position (slightly above ground)
	gem.global_position = global_position + Vector3(0, 0.5, 0)

	# Set XP value from enemy's stats
	gem.xp_value = xp_value

	# Add to the world (parent's parent is usually the Game/Level scene)
	get_parent().add_child(gem)

	print("Spawned XP gem worth ", xp_value, " XP at ", gem.global_position)

func spawn_gold() -> void:
	"""Spawn gold coins at the enemy's death location"""
	if gold_value <= 0:
		return

	# Spawn multiple coins if gold_value > 1 (spread them out slightly)
	for i in range(gold_value):
		var coin = GOLD_COIN_SCENE.instantiate()

		# Randomize position slightly for visual variety
		var offset = Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
		coin.global_position = global_position + Vector3(0, 0.5, 0) + offset

		# Add to the world
		get_parent().add_child(coin)

	print("Spawned ", gold_value, " gold coin(s) at death location")

func apply_knockback(direction: Vector3, force: float) -> void:
	"""Apply knockback force to enemy"""
	# Set velocity to push enemy away
	velocity = direction * force
	# The velocity will be applied in the next move_and_slide() call

func _flash_damage() -> void:
	"""Visual feedback when taking damage"""
	if body_mesh:
		# Create a quick flash effect by changing material color
		var material = body_mesh.get_active_material(0)
		if material:
			var original_color = material.albedo_color
			material.albedo_color = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(body_mesh):
				material.albedo_color = original_color

func _on_attack_range_entered(body: Node3D) -> void:
	"""Called when something enters the attack range"""
	if body == target_player:
		can_attack = true
		print("Player entered attack range!")
		# Perform attack
		attack_player()

func _on_attack_range_exited(body: Node3D) -> void:
	"""Called when something exits the attack range"""
	if body == target_player:
		can_attack = false
		print("Player left attack range!")

func attack_player() -> void:
	"""Attack the player (collision-based damage)"""
	if not is_alive or not target_player:
		return

	# Deal damage to player (pass self as attacker for thorns)
	if target_player.has_method("take_damage"):
		target_player.take_damage(damage, self)
		print("Enemy attacked player for ", damage, " damage!")

	# TODO: Add attack cooldown to prevent continuous damage
	# For now, this will trigger every time player enters range

func get_health_percent() -> float:
	"""Returns health as a percentage (0.0 to 1.0)"""
	return current_health / max_health

# ============================================================================
# STATUS EFFECTS (from player upgrades)
# ============================================================================

func apply_slow(slow_percent: float, duration: float) -> void:
	"""Apply slow effect to enemy"""
	is_slowed = true
	slow_multiplier = 1.0 - slow_percent
	slow_timer = duration
	print("Enemy slowed by ", slow_percent * 100, "% for ", duration, "s")

func apply_burn(damage_per_second: float, duration: float) -> void:
	"""Apply burn DoT to enemy"""
	is_burning = true
	burn_damage_per_second = damage_per_second
	burn_timer = duration
	burn_tick_timer = 0.0
	print("Enemy burning for ", damage_per_second, " damage/sec for ", duration, "s")

func _update_status_effects(delta: float) -> void:
	"""Update all status effects"""
	# Handle slow effect
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false
			slow_multiplier = 1.0
			print("Slow effect expired")

	# Handle burn DoT
	if is_burning:
		burn_timer -= delta
		burn_tick_timer += delta

		# Apply burn damage every second
		if burn_tick_timer >= 1.0:
			burn_tick_timer = 0.0
			take_damage(burn_damage_per_second)
			print("Burn DoT: ", burn_damage_per_second, " damage")

		if burn_timer <= 0:
			is_burning = false
			print("Burn effect expired")

func _check_teleport_distance(delta: float) -> void:
	"""Check if player is too far and teleport enemy closer after cooldown"""
	if not target_player:
		return

	# Don't check teleport while navigation is being recalculated (prevents infinite teleport loop)
	if not navigation_ready:
		return

	var distance_to_player = global_position.distance_to(target_player.global_position)

	# Check if player is too far
	if distance_to_player > teleport_distance_threshold:
		if not player_too_far:
			# Player just got too far, start cooldown
			player_too_far = true
			teleport_timer = teleport_cooldown
			print("Player too far (", distance_to_player, "m), starting teleport cooldown")
		else:
			# Player has been too far, update timer
			teleport_timer -= delta
			if teleport_timer <= 0.0:
				# Cooldown expired, teleport to player
				_teleport_near_player()
				player_too_far = false
	else:
		# Player is close enough, reset
		if player_too_far:
			print("Player returned to range, canceling teleport")
		player_too_far = false
		teleport_timer = 0.0

func _teleport_near_player() -> void:
	"""Teleport enemy to random position within 30m of player"""
	if not target_player:
		return

	# Random angle around player
	var angle = randf() * 2.0 * PI
	# Random distance between 15m and 30m
	var distance = randf_range(15.0, 30.0)

	# Calculate position
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	var new_position = target_player.global_position + offset

	# Keep at ground level (y = 1)
	new_position.y = 1.0

	# Teleport
	global_position = new_position
	velocity = Vector3.ZERO  # Reset velocity on teleport

	# CRITICAL: Immediately update NavigationAgent3D target to player's current position
	# Without this, navigation-based enemies try to follow old path and get stuck
	if nav_agent:
		nav_agent.target_position = target_player.global_position
		print("Updated navigation target after teleport")

	# CRITICAL FIX: Force direct movement for 3 seconds after teleport
	# This bypasses NavigationAgent3D entirely, avoiding jitter from bad state
	force_direct_movement = true
	force_direct_movement_timer = force_direct_movement_duration
	print("Forcing direct movement for ", force_direct_movement_duration, "s after teleport")

	# Reset navigation readiness timer (shorter now since we're using direct movement)
	navigation_ready = false
	navigation_ready_timer = navigation_ready_delay_spawn  # Use spawn delay (0.1s)

	print("Enemy teleported to ", distance, "m from player (player was too far)")

func _create_explosion(damage: float, radius: float) -> void:
	"""Create explosion that damages nearby enemies"""
	print("EXPLOSION! Damage: ", damage, " Radius: ", radius)

	# Find all enemies within radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				print("  Explosion hit enemy at distance ", distance)

	# TODO: Visual explosion effect (particle system)

# ============================================================================
# CLIMBING SYSTEM
# ============================================================================

func check_for_obstacle_ahead(movement_direction: Vector3) -> void:
	"""Check for obstacles in movement direction and initiate climbing if needed"""
	if not obstacle_check_ray or is_climbing:
		return

	# More lenient cooldown check - only block if very recent
	if climb_cooldown > 1.5:  # Only block first 0.5s of 2s cooldown
		return

	# Get movement direction - use player direction if not moving much
	var forward_dir: Vector3
	if movement_direction.length() > 0.1:
		forward_dir = Vector3(movement_direction.x, 0, movement_direction.z).normalized()
	elif target_player:
		# Even if not moving, check toward player
		forward_dir = global_position.direction_to(target_player.global_position)
		forward_dir.y = 0
		forward_dir = forward_dir.normalized()
	else:
		return  # No direction to check

	# Multiple detection heights and ranges for better coverage
	var detection_configs = [
		{"height": 0.2, "range": 1.0},  # Low and far
		{"height": 0.5, "range": 0.8},  # Mid and medium
		{"height": 0.8, "range": 0.6},  # High and close
	]

	for config in detection_configs:
		obstacle_check_ray.position = Vector3(0, config.height, 0)
		obstacle_check_ray.target_position = forward_dir * config.range
		obstacle_check_ray.force_raycast_update()

		if obstacle_check_ray.is_colliding():
			var collider = obstacle_check_ray.get_collider()

			# Only climb static obstacles
			if collider is StaticBody3D:
				# Don't climb on player or enemies
				if collider.is_in_group("player") or collider.is_in_group("enemies"):
					continue

				# Don't climb the ground
				if "Ground" in collider.name or "ground" in collider.name:
					continue

				# More lenient angle check - just needs to be somewhat facing
				var collision_normal = obstacle_check_ray.get_collision_normal()
				var dot = collision_normal.dot(-forward_dir)
				if dot < 0.3:  # Much more lenient - 0.3 instead of 0.5
					continue

				# We hit a climbable obstacle!
				var obstacle_height = find_obstacle_top(forward_dir)

				if obstacle_height > 0.3:  # Lower minimum (was 0.5)
					start_climbing(obstacle_height)
					# print("[CLIMB DETECT] ", name, " climbing ", collider.name, " (", obstacle_height, "m) at height check ", config.height)
					return  # Successfully started climbing

func find_obstacle_top(forward_dir: Vector3) -> float:
	"""Find the top of the obstacle by casting rays upward"""
	var space_state = get_world_3d().direct_space_state
	var max_check_height = 50.0  # Check up to 50m high
	var step = 0.5  # Check every 0.5m
	var current_height = 0.5
	var obstacle_top = 0.0
	var last_hit_height = 0.0

	# Start from bottom and work our way up
	while current_height < max_check_height:
		# Cast ray forward at this height
		var ray_origin = global_position + Vector3(0, current_height, 0)
		var ray_end = ray_origin + forward_dir * 1.0  # Check 1m ahead

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collision_mask = 1  # Environment layer
		query.exclude = [self]  # Exclude self from collision
		var result = space_state.intersect_ray(query)

		if not result.is_empty():
			# Still hitting obstacle at this height
			last_hit_height = current_height
		else:
			# No collision at this height - we found the top!
			if last_hit_height > 0:
				obstacle_top = last_hit_height + 0.5  # Add a bit extra to ensure we clear it
				break

		current_height += step

	# If we're still hitting something at max height, climb anyway
	if obstacle_top == 0.0 and last_hit_height > 0:
		obstacle_top = min(last_hit_height + 1.0, max_check_height)

	return obstacle_top

func start_climbing(obstacle_height: float) -> void:
	"""Start climbing over an obstacle"""
	is_climbing = true
	# Add extra height to ensure we clear the obstacle
	# 1.5m extra to account for collision box and ensure clearance
	climb_target_height = global_position.y + obstacle_height + 1.5

	# Visual feedback - change color when climbing
	_set_climbing_visual(true)

	# Stop current movement to start climbing
	velocity = Vector3.ZERO

func detect_stuck_state(delta: float) -> void:
	"""Detect if enemy is stuck and should climb"""
	if is_climbing or not target_player:
		stuck_timer = 0.0
		last_position = global_position
		return

	# Don't reset timer for cooldowns - still track if stuck
	var distance_moved = global_position.distance_to(last_position)
	var distance_to_player = global_position.distance_to(target_player.global_position)

	# More aggressive stuck detection - works at any distance
	# Check if we're not making progress
	if distance_to_player > 1.5:  # Reduced from 3.0 - check almost always
		if distance_moved < 0.1:  # Very little movement
			stuck_timer += delta
		elif distance_moved < 0.3:  # Some movement but not much
			stuck_timer += delta * 0.5  # Accumulate slower
		else:
			stuck_timer = max(0, stuck_timer - delta)  # Reduce slowly if moving

		# Much faster stuck detection - 0.5 seconds instead of 1.0
		if stuck_timer > 0.5:
			# Check multiple directions for obstacles
			var directions_to_check = [
				velocity.normalized() if velocity.length() > 0.1 else Vector3.ZERO,
				global_position.direction_to(target_player.global_position),
				-transform.basis.z,  # Forward direction
			]

			for check_dir in directions_to_check:
				if check_dir == Vector3.ZERO:
					continue

				var forward_dir = Vector3(check_dir.x, 0, check_dir.z).normalized()

				# Cast at multiple heights
				for height in [0.2, 0.5, 0.8]:
					obstacle_check_ray.position = Vector3(0, height, 0)
					obstacle_check_ray.target_position = forward_dir * 1.0
					obstacle_check_ray.force_raycast_update()

					if obstacle_check_ray.is_colliding():
						var collider = obstacle_check_ray.get_collider()
						if collider is StaticBody3D and not "Ground" in collider.name:
							var obstacle_height = find_obstacle_top(forward_dir)
							if obstacle_height > 0.3:
								start_climbing(obstacle_height)
								# print("[STUCK FIX] ", name, " auto-climbing after stuck for ", stuck_timer, "s")
								stuck_timer = 0.0
								last_position = global_position
								return

			# If still stuck after checking, try a small random movement
			if stuck_timer > 1.0:
				velocity.x += randf_range(-1, 1)
				velocity.z += randf_range(-1, 1)
				stuck_timer = 0.5  # Reset partially

	last_position = global_position

func handle_climbing_and_gravity(delta: float) -> void:
	"""Handle climbing movement and gravity"""
	if is_climbing:
		var current_y = global_position.y
		var height_remaining = climb_target_height - current_y

		# Detect if we're stuck bouncing
		if bounce_prevention_timer <= 0 and velocity.y < -2.0 and height_remaining < 2.0 and height_remaining > -1.0:
			# We're falling while near the top - likely bouncing
			# print("[BOUNCE FIX] Detected bounce, forcing edge clear")
			edge_clear_mode = true
			bounce_prevention_timer = 1.0
			velocity.y = 2.0  # Force upward

		# Phase 1: Vertical climb (until near top)
		if height_remaining > 2.0 and not edge_clear_mode:
			# Scale climb speed based on total height - reduced multipliers for realism
			var total_height = climb_target_height - (global_position.y - height_remaining)
			var speed_multiplier = 1.0
			if total_height > 10.0:
				speed_multiplier = 1.2  # Was 1.5
			if total_height > 20.0:
				speed_multiplier = 1.4  # Was 2.0

			# Strong vertical movement
			velocity.y = climb_speed * speed_multiplier

			# Small forward to stay on wall
			if target_player:
				var direction = global_position.direction_to(target_player.global_position)
				direction.y = 0
				direction = direction.normalized()
				velocity.x = direction.x * 0.3
				velocity.z = direction.z * 0.3

		# Phase 2: Edge approach (getting ready to clear)
		elif height_remaining > 0 and not edge_clear_mode:
			# Enable edge clear mode
			edge_clear_mode = true
			# print("[CLIMB] Entering edge clear mode")

			# Moderate vertical with forward momentum building
			velocity.y = climb_speed * 0.4

			if target_player:
				var direction = global_position.direction_to(target_player.global_position)
				direction.y = 0
				direction = direction.normalized()
				velocity.x = lerp(velocity.x, direction.x * move_speed, 5.0 * delta)
				velocity.z = lerp(velocity.z, direction.z * move_speed, 5.0 * delta)

		# Phase 3: Edge clear mode - aggressive forward push
		elif edge_clear_mode or height_remaining > -3.0:
			edge_clear_mode = true

			# Fight gravity while pushing forward
			velocity.y = 1.5  # Reduced from 2.0 for more realistic movement

			# Get forward direction
			var forward_dir: Vector3
			if target_player:
				forward_dir = global_position.direction_to(target_player.global_position)
				forward_dir.y = 0
				forward_dir = forward_dir.normalized()
			else:
				forward_dir = -transform.basis.z

			# Strong forward movement to clear edge (reduced from 4x)
			var forward_speed = move_speed * 2.5  # Reduced from 4.0 for realism
			velocity.x = forward_dir.x * forward_speed
			velocity.z = forward_dir.z * forward_speed

			# Check if we've cleared the obstacle (moved forward enough)
			# Use raycasts to check if there's still a wall in front
			if obstacle_check_ray:
				obstacle_check_ray.target_position = forward_dir * 0.3
				obstacle_check_ray.force_raycast_update()

				if not obstacle_check_ray.is_colliding() and height_remaining < 0:
					# We've cleared it!
					edge_clear_mode = false
					is_climbing = false
					velocity.y = -5.0
					climb_cooldown = 2.0
					landing_timer = 1.0
					bounce_prevention_timer = 0.5
					# print("[CLIMB DONE] Successfully cleared edge")
					_set_climbing_visual(false)
					stuck_timer = 0.0

		else:
			# Fallback - definitely over
			edge_clear_mode = false
			is_climbing = false
			velocity.y = -5.0
			climb_cooldown = 2.0
			landing_timer = 1.0
			# print("[CLIMB DONE] ", name)
			_set_climbing_visual(false)
			stuck_timer = 0.0
	else:
		# Reset edge clear mode when not climbing
		edge_clear_mode = false

		# Landing phase - apply stronger gravity to get down from obstacles
		if landing_timer > 0 and not is_on_floor():
			velocity.y = -10.0  # Strong downward force during landing
			# Keep some forward momentum during landing
			if velocity.x != 0 or velocity.z != 0:
				var horizontal_vel = Vector3(velocity.x, 0, velocity.z).normalized()
				velocity.x = horizontal_vel.x * move_speed
				velocity.z = horizontal_vel.z * move_speed
		# Normal gravity application
		elif not is_on_floor():
			velocity.y -= gravity * delta
			velocity.y = max(velocity.y, -20.0)  # Terminal velocity
		else:
			# Stop downward velocity when on floor
			if velocity.y < 0:
				velocity.y = 0

func _set_climbing_visual(climbing: bool) -> void:
	"""Visual feedback for climbing state"""
	var body = get_node_or_null("Body")
	if body and body is MeshInstance3D:
		var mat = body.get_surface_override_material(0)
		if mat:
			if climbing:
				# Make enemy blue when climbing
				mat.albedo_color = Color(0.2, 0.2, 0.8, 1.0)
			else:
				# Reset to original color based on enemy type
				if self.name.contains("Fast"):
					mat.albedo_color = Color.YELLOW
				elif self.name.contains("Tank"):
					mat.albedo_color = Color.PURPLE
				else:
					mat.albedo_color = Color.RED
