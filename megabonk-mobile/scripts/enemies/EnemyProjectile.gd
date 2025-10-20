extends Area3D
class_name EnemyProjectile
## Projectile fired by ranged enemies that damages the player

# BUG FIX: TASK-004 - Reduced projectile speed from 10.0 to 7.0 for dodgeability
# Projectile properties
var direction: Vector3 = Vector3.FORWARD
var speed: float = 7.0  # Reduced from 10.0 to allow skilled dodging at close range
var damage: float = 8.0
var lifetime: float = 5.0  # Auto-destroy after 5 seconds

# State
var time_alive: float = 0.0
var has_hit: bool = false

func _ready() -> void:
	# Set up collision layers (enemy projectile)
	collision_layer = 4  # Layer 3 (enemy projectile)
	collision_mask = 4   # Hits player (layer 3)

	# Add to group for testing/tracking
	add_to_group("enemy_projectiles")

	# Connect body entered signal
	body_entered.connect(_on_body_entered)

	print("EnemyProjectile created - Damage: ", damage, " Speed: ", speed)

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	# Move projectile
	global_position += direction * speed * delta

	# Track lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		print("EnemyProjectile expired")

func _on_body_entered(body: Node3D) -> void:
	"""Handle collision with player or environment"""
	if has_hit:
		return

	# Check if hit player
	if body.is_in_group("player"):
		# Deal damage to player
		if body.has_method("take_damage"):
			body.take_damage(damage, null)
			print("EnemyProjectile hit player for ", damage, " damage!")

		has_hit = true
		queue_free()
	else:
		# Hit environment (wall, obstacle, etc.)
		has_hit = true
		queue_free()
		print("EnemyProjectile hit environment")
