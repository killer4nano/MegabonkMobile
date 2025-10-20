extends Area3D
class_name FireballProjectile
## Explosive projectile for Fireball weapon
## Explodes on impact, dealing AOE damage to nearby enemies

# Projectile stats
var damage: float = 25.0
var speed: float = 12.0
var explosion_radius: float = 2.0
var lifetime: float = 5.0

# Movement
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

	DebugLogger.log("fireball_projectile", "Fireball projectile spawned - damage: " + str(damage) + ", speed: " + str(speed) + ", explosion_radius: " + str(explosion_radius))

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		despawn()
		return

	# Move projectile in straight line
	global_position += velocity * delta

	# Rotate to face movement direction
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	"""Handle collision with enemy - create explosion"""
	DebugLogger.log("fireball_projectile", "body_entered - " + body.name)

	if has_hit:
		DebugLogger.log("fireball_projectile", "Already hit, ignoring")
		return

	# Check if it's an enemy
	if not body.is_in_group("enemies"):
		DebugLogger.log("fireball_projectile", "Not an enemy, ignoring")
		return

	has_hit = true

	# Create explosion at impact point
	explode()

	DebugLogger.log("fireball_projectile", "Explosion triggered, despawning")
	despawn()

func explode() -> void:
	"""Deal AOE damage to all enemies in explosion radius"""
	DebugLogger.log("fireball_projectile", "EXPLODING at " + str(global_position) + " with radius " + str(explosion_radius))

	# Find all enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			# Deal damage to enemy
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hit_count += 1
				DebugLogger.log("fireball_projectile", "Explosion hit " + enemy.name + " for " + str(damage) + " damage (distance: " + str(distance) + "m)")

	DebugLogger.log("fireball_projectile", "Explosion hit " + str(hit_count) + " enemies")

	# TODO: Add visual explosion effect here in future

func despawn() -> void:
	"""Remove the projectile"""
	DebugLogger.log("fireball_projectile", "queue_free() called - despawning")
	queue_free()

func initialize(start_position: Vector3, initial_direction: Vector3, projectile_damage: float, projectile_speed: float, aoe_radius: float) -> void:
	"""Initialize projectile with starting parameters"""
	DebugLogger.log("fireball_projectile", "initialize() called")
	DebugLogger.log("fireball_projectile", "  start_position: " + str(start_position))
	DebugLogger.log("fireball_projectile", "  initial_direction: " + str(initial_direction))
	DebugLogger.log("fireball_projectile", "  damage: " + str(projectile_damage))
	DebugLogger.log("fireball_projectile", "  speed: " + str(projectile_speed))
	DebugLogger.log("fireball_projectile", "  explosion_radius: " + str(aoe_radius))

	global_position = start_position
	velocity = initial_direction.normalized() * projectile_speed
	damage = projectile_damage
	speed = projectile_speed
	explosion_radius = aoe_radius

	# Set initial rotation
	if initial_direction.length() > 0.1:
		look_at(global_position + initial_direction, Vector3.UP)

	DebugLogger.log("fireball_projectile", "Initialized at " + str(global_position) + " moving at " + str(velocity))
