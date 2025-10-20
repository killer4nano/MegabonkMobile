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

# References
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_area: Area3D = $AttackRange
@onready var body_mesh: MeshInstance3D = $Body

func _ready() -> void:
	current_health = max_health
	print("Enemy spawned with ", max_health, " HP")

	# Add to enemies group for weapon targeting
	add_to_group("enemies")

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

	# VERIFIED FIX: Always use direct movement (like RangedEnemy)
	# NavigationAgent3D enters corrupted state after teleport, causing jitter
	# Direct movement recalculates direction to player every frame - always smooth
	handle_direct_movement(delta)

	# Rotate to face movement direction
	if velocity.length() > 0.1:
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

	# Normal navigation-based movement for slower enemies
	if nav_agent.is_navigation_finished():
		# Reached destination or path invalid
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# Get next position in path
	var next_path_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_position)
	direction.y = 0  # Keep movement on ground plane
	direction = direction.normalized()

	# Accelerate toward target direction (apply slow effect)
	var effective_speed = move_speed * slow_multiplier
	var target_velocity = direction * effective_speed
	velocity = velocity.lerp(target_velocity, acceleration * delta)

func handle_direct_movement(delta: float) -> void:
	"""Direct movement for fast enemies (bypasses navigation to prevent jittering)"""
	if not target_player or not is_instance_valid(target_player):
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# Direct movement toward player - no NavigationAgent3D, no pathfinding
	var direction = global_position.direction_to(target_player.global_position)
	direction.y = 0  # Keep on ground plane
	direction = direction.normalized()

	# Set velocity directly toward player (apply slow effect)
	var effective_speed = move_speed * slow_multiplier
	var target_velocity = direction * effective_speed
	velocity = velocity.lerp(target_velocity, acceleration * delta)

	# Rotate to face movement direction (overrides rotation in _physics_process)
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
