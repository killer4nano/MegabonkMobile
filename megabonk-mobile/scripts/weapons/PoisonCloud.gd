extends BaseWeapon
class_name PoisonCloud
## Poison Cloud weapon - Creates damage over time zones that persist

# Cloud scene
const CLOUD_SCENE = preload("res://scenes/weapons/PoisonCloudZone.tscn")

# Weapon settings
@export var cloud_duration: float = 10.0
@export var cloud_radius: float = 3.0
@export var tick_rate: float = 1.0  # Damage per second

# Visual
var visual_node: Node3D

# References
var player: Node3D

func _ready() -> void:
	# Set weapon type to ranged (uses auto-attack system)
	weapon_type = "ranged"

	# Call parent ready
	super._ready()

	# Find visual node
	visual_node = get_node_or_null("Visual")

	# Find player reference
	player = get_parent().get_parent() if get_parent() else null
	if not player:
		push_warning("PoisonCloud: Could not find player!")

	DebugLogger.log("poison_cloud", "Poison Cloud ready! Damage/sec: " + str(damage / tick_rate) + ", Duration: " + str(cloud_duration) + "s")

func _process(delta: float) -> void:
	"""Keep weapon positioned near player"""
	# Position at a fixed local offset
	var offset = Vector3(0.0, 1.3, 0.0)
	position = offset

func attack(target: Node3D) -> void:
	"""Create poison cloud at target location"""
	DebugLogger.log("poison_cloud", "attack() called! Target: " + (target.name if target else "null"))

	if not target or not is_instance_valid(target):
		DebugLogger.log("poison_cloud", "Invalid target, aborting")
		return

	# Create cloud at target's position
	var cloud_position = target.global_position

	# Spawn cloud
	var cloud = CLOUD_SCENE.instantiate()

	# Add to scene tree
	var arena = get_tree().current_scene
	arena.add_child(cloud)

	# Initialize cloud
	cloud.initialize(cloud_position, damage, cloud_duration, cloud_radius, tick_rate)

	DebugLogger.log("poison_cloud", "Poison cloud created at " + str(cloud_position))

	# Emit signal
	weapon_hit.emit(target)

	# Visual feedback
	if visual_node:
		_do_cast_animation()

	# Start cooldown timer
	can_attack = false
	attack_timer.start(attack_cooldown)
	DebugLogger.log("poison_cloud", "Cooldown started - " + str(attack_cooldown) + "s")

func _do_cast_animation() -> void:
	"""Visual feedback when casting"""
	if not visual_node:
		return

	# Scale pulse
	var original_scale = visual_node.scale
	visual_node.scale = original_scale * 1.4

	# Reset after delay
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(visual_node):
		visual_node.scale = original_scale
