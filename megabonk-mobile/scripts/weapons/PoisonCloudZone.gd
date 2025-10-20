extends Area3D
class_name PoisonCloudZone
## Poison cloud zone - Persistent area that damages enemies over time

# Cloud stats
var damage_per_tick: float = 5.0
var duration: float = 10.0
var radius: float = 3.0
var tick_rate: float = 1.0

# Internal state
var time_alive: float = 0.0
var tick_timer: float = 0.0

func _ready() -> void:
	# Set collision layers
	collision_layer = 0
	collision_mask = 2  # Detect enemies

	# Setup collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.shape is SphereShape3D:
		collision_shape.shape.radius = radius

	DebugLogger.log("poison_cloud_zone", "Poison cloud zone created - damage/tick: " + str(damage_per_tick) + ", duration: " + str(duration) + "s, radius: " + str(radius) + "m")

func _physics_process(delta: float) -> void:
	# Update lifetime
	time_alive += delta
	if time_alive >= duration:
		DebugLogger.log("poison_cloud_zone", "Cloud duration expired, despawning")
		despawn()
		return

	# Update damage tick timer
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		deal_damage()

func deal_damage() -> void:
	"""Deal damage to all enemies currently in the cloud"""
	var enemies_in_cloud = get_overlapping_bodies()
	var hit_count = 0

	for body in enemies_in_cloud:
		if not is_instance_valid(body):
			continue

		# Check if it's an enemy
		if not body.is_in_group("enemies"):
			continue

		# Deal damage
		if body.has_method("take_damage"):
			body.take_damage(damage_per_tick)
			hit_count += 1

	if hit_count > 0:
		DebugLogger.log("poison_cloud_zone", "Cloud tick - damaged " + str(hit_count) + " enemies for " + str(damage_per_tick) + " each")

func despawn() -> void:
	"""Remove the cloud"""
	DebugLogger.log("poison_cloud_zone", "queue_free() called - despawning")
	queue_free()

func initialize(cloud_position: Vector3, damage: float, cloud_duration: float, cloud_radius: float, damage_tick_rate: float) -> void:
	"""Initialize cloud with parameters"""
	DebugLogger.log("poison_cloud_zone", "initialize() called")
	DebugLogger.log("poison_cloud_zone", "  position: " + str(cloud_position))
	DebugLogger.log("poison_cloud_zone", "  damage_per_tick: " + str(damage))
	DebugLogger.log("poison_cloud_zone", "  duration: " + str(cloud_duration))
	DebugLogger.log("poison_cloud_zone", "  radius: " + str(cloud_radius))

	global_position = cloud_position
	damage_per_tick = damage
	duration = cloud_duration
	radius = cloud_radius
	tick_rate = damage_tick_rate

	# Update visual size
	var visual = get_node_or_null("Visual")
	if visual:
		visual.scale = Vector3.ONE * (radius / 1.5)  # Scale visual to match radius

	DebugLogger.log("poison_cloud_zone", "Initialized at " + str(global_position))
