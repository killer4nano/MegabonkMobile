extends Area3D
class_name MissileProjectile
## Homing projectile for Magic Missile weapon
## Homes in on target enemy and despawns on hit or timeout

# Projectile stats
var damage: float = 20.0
var speed: float = 10.0
var homing_strength: float = 5.0
var lifetime: float = 5.0

# Target tracking
var target_enemy: Node3D = null
var velocity: Vector3 = Vector3.ZERO

# Internal state
var time_alive: float = 0.0
var has_hit: bool = false

func _ready() -> void:
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)

	# Set collision layers
	collision_layer = 0  # Projectile doesn't block anything
	collision_mask = 2   # Detect enemies (layer 2)

	DebugLogger.log("missile_projectile", "Projectile spawned - damage: " + str(damage) + ", speed: " + str(speed))

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		despawn()
		return

	# Homing behavior
	if is_instance_valid(target_enemy):
		# Calculate direction to target
		var direction_to_target = global_position.direction_to(target_enemy.global_position)

		# Blend current velocity with direction to target (homing)
		velocity = velocity.lerp(direction_to_target * speed, homing_strength * delta)
		velocity = velocity.normalized() * speed
	else:
		# If no target, try to find one
		find_nearest_enemy()

		# If still no target, maintain forward velocity
		if velocity.length() < 0.1:
			velocity = -global_transform.basis.z * speed

	# Move projectile
	global_position += velocity * delta

	# Rotate to face movement direction
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)

func find_nearest_enemy() -> void:
	"""Find nearest enemy to home in on"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	var nearest_enemy: Node3D = null
	var nearest_distance: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	target_enemy = nearest_enemy

func _on_body_entered(body: Node3D) -> void:
	"""Handle collision with enemy"""
	DebugLogger.log("missile_projectile", "body_entered - " + body.name)

	if has_hit:
		DebugLogger.log("missile_projectile", "Already hit, ignoring")
		return

	# Check if it's an enemy
	if not body.is_in_group("enemies"):
		DebugLogger.log("missile_projectile", "Not an enemy, ignoring")
		return

	# Deal damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
		DebugLogger.log("missile_projectile", "HIT! Dealing " + str(damage) + " damage to " + body.name)

	has_hit = true
	DebugLogger.log("missile_projectile", "Despawning now")
	despawn()

func despawn() -> void:
	"""Remove the projectile"""
	DebugLogger.log("missile_projectile", "queue_free() called - despawning")
	queue_free()

func initialize(start_position: Vector3, initial_direction: Vector3, projectile_damage: float, projectile_speed: float, homing: float) -> void:
	"""Initialize projectile with starting parameters"""
	DebugLogger.log("missile_projectile", "initialize() called")
	DebugLogger.log("missile_projectile", "  start_position: " + str(start_position))
	DebugLogger.log("missile_projectile", "  initial_direction: " + str(initial_direction))
	DebugLogger.log("missile_projectile", "  damage: " + str(projectile_damage))
	DebugLogger.log("missile_projectile", "  speed: " + str(projectile_speed))

	global_position = start_position
	velocity = initial_direction.normalized() * projectile_speed
	damage = projectile_damage
	speed = projectile_speed
	homing_strength = homing

	# Set initial rotation
	if initial_direction.length() > 0.1:
		look_at(global_position + initial_direction, Vector3.UP)

	DebugLogger.log("missile_projectile", "Initialized at " + str(global_position) + " moving at " + str(velocity))
