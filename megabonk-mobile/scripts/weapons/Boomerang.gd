extends BaseWeapon
class_name Boomerang
## Boomerang weapon - Throws a returning projectile that hits twice

# Projectile scene
const PROJECTILE_SCENE = preload("res://scenes/weapons/BoomerangProjectile.tscn")

# Weapon settings
@export var throw_speed: float = 15.0
@export var max_distance: float = 8.0  # Distance before returning
@export var return_speed_multiplier: float = 1.2  # Faster on return

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
		push_warning("Boomerang: Could not find player!")

	DebugLogger.log("boomerang", "Boomerang ready! Damage: " + str(damage) + ", Cooldown: " + str(attack_cooldown) + "s")

func _process(delta: float) -> void:
	"""Keep weapon positioned near player"""
	# Position at a fixed local offset (left side)
	var offset = Vector3(-0.5, 1.0, 0.3)
	position = offset

func attack(target: Node3D) -> void:
	"""Throw boomerang at target"""
	DebugLogger.log("boomerang", "attack() called! Target: " + (target.name if target else "null"))

	if not target or not is_instance_valid(target):
		DebugLogger.log("boomerang", "Invalid target, aborting")
		return

	# Calculate spawn position (at player)
	var spawn_player = get_parent().get_parent() if get_parent() else null
	var spawn_position = global_position
	var player_position = spawn_position

	if spawn_player:
		player_position = spawn_player.global_position + Vector3.UP * 1.0
		spawn_position = player_position
		DebugLogger.log("boomerang", "Spawn position (at player): " + str(spawn_position))

	# Fire boomerang(s)
	for i in range(projectile_count):
		# Spawn projectile
		var projectile = PROJECTILE_SCENE.instantiate()

		# Add to scene tree
		var arena = get_tree().current_scene
		arena.add_child(projectile)

		# Calculate initial direction with slight spread for multiple boomerangs
		var direction_to_target = spawn_position.direction_to(target.global_position)

		# Add spread if firing multiple boomerangs
		if projectile_count > 1:
			var spread_angle = (i - (projectile_count - 1) / 2.0) * 0.4
			var spread_rotation = Basis(Vector3.UP, spread_angle)
			direction_to_target = spread_rotation * direction_to_target

		# Initialize projectile
		projectile.initialize(spawn_position, direction_to_target, damage, throw_speed, max_distance, return_speed_multiplier, player_position)

		DebugLogger.log("boomerang", "Boomerang " + str(i + 1) + "/" + str(projectile_count) + " thrown")

	# Emit signal
	weapon_hit.emit(target)

	# Visual feedback
	if visual_node:
		_do_throw_animation()

	# Start cooldown timer
	can_attack = false
	attack_timer.start(attack_cooldown)
	DebugLogger.log("boomerang", "Cooldown started - " + str(attack_cooldown) + "s")

func _do_throw_animation() -> void:
	"""Visual feedback when throwing"""
	if not visual_node:
		return

	# Scale pulse
	var original_scale = visual_node.scale
	visual_node.scale = original_scale * 1.2

	# Reset after delay
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(visual_node):
		visual_node.scale = original_scale
