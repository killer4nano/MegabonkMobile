extends BaseEnemy
class_name RangedEnemy
## Ranged enemy that shoots projectiles at the player from a distance

# Projectile configuration
const PROJECTILE_SCENE = preload("res://scenes/enemies/EnemyProjectile.tscn")

@export var projectile_damage: float = 8.0
@export var projectile_speed: float = 7.0  # Reduced from 10.0 for dodgeability
@export var attack_cooldown: float = 2.0
@export var shoot_range: float = 8.0
@export var charge_time: float = 0.8  # Telegraph windup time before firing

# State tracking
var attack_timer: float = 0.0
var can_shoot: bool = true

# BUG FIX: TASK-014 - Repositioning when line of sight blocked
var is_repositioning: bool = false
var reposition_direction: Vector3 = Vector3.ZERO
var reposition_timer: float = 0.0
var reposition_duration: float = 2.0  # Try to reposition for 2 seconds before recalculating

# BUG FIX: TASK-004 - Attack telegraph system for skill-based dodging
# Adds 0.8s charge-up with visual indicator before firing
# This makes ranged attacks dodgeable at close range through timing
var is_charging: bool = false
var charge_timer: float = 0.0
var charge_indicator: Node3D = null  # Visual cue during charge

func _ready() -> void:
	super._ready()

	# Set ranged enemy specific values
	max_health = 40.0
	current_health = max_health
	move_speed = 2.0
	damage = 10.0  # Contact damage
	xp_value = 15.0
	gold_value = 3
	attack_range = shoot_range

	# BUG FIX: TASK-004 - Create visual charge indicator
	# Shows glowing sphere during 0.8s attack windup for dodging
	_create_charge_indicator()

	print("RangedEnemy spawned - HP: ", max_health, " Speed: ", move_speed)

func _should_update_navigation_path() -> bool:
	"""RangedEnemy uses direct movement, not NavigationAgent3D"""
	return false

func _process_enemy_behavior(delta: float) -> void:
	"""RangedEnemy-specific behavior: shooting, repositioning, direct movement"""
	# Update charge timer
	if is_charging:
		charge_timer -= delta
		if charge_timer <= 0.0:
			_fire_projectile()
			is_charging = false
			if charge_indicator:
				charge_indicator.visible = false

	# Update attack cooldown
	if not can_shoot:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_shoot = true

	# Wait for navigation to be ready
	if not navigation_ready:
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# Calculate distance to player
	var distance_to_player = global_position.distance_to(target_player.global_position)

	# === IN SHOOTING RANGE ===
	if distance_to_player <= shoot_range:
		var has_los = _has_line_of_sight()

		if has_los:
			# Stop and shoot
			is_repositioning = false
			velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)

			# Face player
			var dir_to_player = global_position.direction_to(target_player.global_position)
			dir_to_player.y = 0
			if dir_to_player.length() > 0.1:
				var target_rot = atan2(dir_to_player.x, dir_to_player.z)
				rotation.y = lerp_angle(rotation.y, target_rot, rotation_speed * delta)

			# Start charging shot
			if can_shoot and not is_charging:
				_start_charge()
		else:
			# No line of sight - reposition
			if not is_repositioning:
				_start_repositioning()

			reposition_timer -= delta
			if reposition_timer <= 0.0:
				_start_repositioning()

			# Move perpendicular to get around obstacle
			var target_velocity = reposition_direction * move_speed
			velocity = velocity.lerp(target_velocity, acceleration * delta)

			# Face movement direction
			if velocity.length() > 0.1:
				var angle = atan2(reposition_direction.x, reposition_direction.z)
				rotation.y = lerp_angle(rotation.y, angle, rotation_speed * delta)
	else:
		# === OUT OF RANGE - APPROACH PLAYER ===
		# Cancel charge/reposition
		if is_charging:
			is_charging = false
			if charge_indicator:
				charge_indicator.visible = false
		is_repositioning = false

		# Move directly toward player
		var direction = global_position.direction_to(target_player.global_position)
		direction.y = 0
		direction = direction.normalized()

		var target_velocity = direction * move_speed
		velocity = velocity.lerp(target_velocity, acceleration * delta)

		# Face movement direction
		if velocity.length() > 0.1:
			var angle = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, angle, rotation_speed * delta)

func _start_charge() -> void:
	"""BUG FIX: TASK-004 - Begin attack telegraph/charge-up phase"""
	is_charging = true
	charge_timer = charge_time
	can_shoot = false
	attack_timer = attack_cooldown

	# Show visual indicator
	if charge_indicator:
		charge_indicator.visible = true

	print("RangedEnemy charging attack... (", charge_time, "s windup)")

func _fire_projectile() -> void:
	"""BUG FIX: TASK-004 - Fire projectile after charge completes (renamed from shoot_projectile)"""
	if not target_player or not is_instance_valid(target_player):
		return

	# BUG FIX: TASK-013 - Check line of sight before firing
	# Prevents shooting through walls/obstacles
	if not _has_line_of_sight():
		print("RangedEnemy: No line of sight to player, canceling shot")
		return

	# Create projectile
	var projectile = PROJECTILE_SCENE.instantiate()

	# Set projectile position (spawn slightly above enemy)
	projectile.global_position = global_position + Vector3(0, 1.5, 0)

	# Calculate direction to player
	var direction = global_position.direction_to(target_player.global_position)
	direction.y = 0  # Keep on horizontal plane
	direction = direction.normalized()

	# BUG FIX: TASK-004 - Set projectile properties (speed reduced to 7.0 for dodgeability)
	projectile.direction = direction
	projectile.speed = projectile_speed  # Now 7.0 instead of 10.0
	projectile.damage = projectile_damage

	# Add to scene
	get_parent().add_child(projectile)

	print("RangedEnemy fired projectile! Damage: ", projectile_damage, " Speed: ", projectile_speed)

func _has_line_of_sight() -> bool:
	"""BUG FIX: TASK-013 - Check if there's a clear line of sight to player"""
	if not target_player or not is_instance_valid(target_player):
		return false

	# Raycast from enemy to player
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 1.5, 0)  # Shoot height
	var to = target_player.global_position + Vector3(0, 1.0, 0)  # Player center

	var query = PhysicsRayQueryParameters3D.create(from, to)
	# Exclude self from raycast
	query.exclude = [self]
	# Only check for obstacles (StaticBody3D) and player
	query.collision_mask = 1  # Layer 1 (default physics layer)

	var result = space_state.intersect_ray(query)

	# If raycast hits player first, we have line of sight
	if result.is_empty():
		return true  # Nothing in the way

	# Check if what we hit is the player
	if result.collider == target_player:
		return true  # Hit player directly

	# Hit something else (obstacle), no line of sight
	return false

func _start_repositioning() -> void:
	"""BUG FIX: TASK-014 - Start repositioning to get line of sight"""
	if not target_player or not is_instance_valid(target_player):
		return

	is_repositioning = true
	reposition_timer = reposition_duration

	# Calculate direction to player
	var to_player = global_position.direction_to(target_player.global_position)
	to_player.y = 0
	to_player = to_player.normalized()

	# Calculate perpendicular direction (strafe left or right randomly)
	var perpendicular = Vector3(-to_player.z, 0, to_player.x)  # 90 degrees

	# Randomly choose left or right
	if randf() > 0.5:
		perpendicular = -perpendicular

	# Mix perpendicular movement with forward movement (spiral around obstacle)
	reposition_direction = (to_player * 0.3 + perpendicular * 0.7).normalized()

	print("RangedEnemy: Repositioning to get line of sight (blocked by obstacle)")

func _on_attack_range_entered(body: Node3D) -> void:
	"""Override base attack range - ranged enemy should NOT deal instant damage on range entry"""
	if body == target_player:
		# Player entered shooting range - the charging/shooting logic will handle attacks
		# DO NOT call attack_player() here like the base enemy does
		print("RangedEnemy: Player entered shooting range (8m)")

func _on_attack_range_exited(body: Node3D) -> void:
	"""Called when player leaves attack range"""
	if body == target_player:
		print("RangedEnemy: Player left shooting range")

func attack_player() -> void:
	"""Override base attack - ranged enemy uses projectiles only, NO contact damage"""
	# Ranged enemies should NEVER deal contact damage
	# They only damage through projectiles
	# This method is intentionally empty to prevent contact damage
	pass

func _create_charge_indicator() -> void:
	"""BUG FIX: TASK-004 - Create visual telegraph indicator for attack windup"""
	# Create a glowing sphere that appears during charge-up
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	sphere_mesh.height = 0.6
	sphere.mesh = sphere_mesh

	# Create glowing material (bright yellow/orange for warning)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.0, 0.8)  # Yellow-orange
	material.emission_enabled = true
	material.emission = Color(1.0, 0.6, 0.0)  # Glowing orange
	material.emission_energy_multiplier = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.set_surface_override_material(0, material)

	# Position in front of enemy's face (where projectile spawns)
	sphere.position = Vector3(0, 1.5, 0.5)  # Slightly above and forward

	# Start hidden
	sphere.visible = false

	# Add as child and store reference
	add_child(sphere)
	charge_indicator = sphere

	print("RangedEnemy: Charge indicator created")
