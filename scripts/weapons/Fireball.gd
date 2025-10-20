extends BaseWeapon
class_name Fireball
## Fireball weapon - Shoots explosive projectiles that deal AOE damage on impact

# Projectile scene
const PROJECTILE_SCENE = preload("res://scenes/weapons/FireballProjectile.tscn")

# Weapon settings
@export var projectile_speed: float = 12.0
@export var projectile_lifetime: float = 5.0
@export var explosion_radius: float = 2.0

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
		push_warning("Fireball: Could not find player!")

	DebugLogger.log("fireball", "Fireball ready! Damage: " + str(damage) + ", Cooldown: " + str(attack_cooldown) + "s")

func _process(delta: float) -> void:
	"""Keep weapon positioned near player"""
	# Position at a fixed local offset (right side, slightly up)
	var offset = Vector3(0.6, 1.2, 0.4)
	position = offset

func attack(target: Node3D) -> void:
	"""Fire explosive projectile at target"""
	DebugLogger.log("fireball", "attack() called! Target: " + (target.name if target else "null"))

	if not target or not is_instance_valid(target):
		DebugLogger.log("fireball", "Invalid target, aborting")
		return

	# Calculate spawn position (above player)
	var spawn_player = get_parent().get_parent() if get_parent() else null
	var spawn_position = global_position
	if spawn_player:
		spawn_position = spawn_player.global_position + Vector3.UP * 1.5
		DebugLogger.log("fireball", "Spawn position (above player): " + str(spawn_position))

	# Fire projectile(s)
	for i in range(projectile_count):
		# Spawn projectile
		var projectile = PROJECTILE_SCENE.instantiate()

		# Add to scene tree
		var arena = get_tree().current_scene
		arena.add_child(projectile)

		# Calculate initial direction with slight spread for multiple projectiles
		var direction_to_target = spawn_position.direction_to(target.global_position)

		# Add spread if firing multiple projectiles
		if projectile_count > 1:
			var spread_angle = (i - (projectile_count - 1) / 2.0) * 0.3
			var spread_rotation = Basis(Vector3.UP, spread_angle)
			direction_to_target = spread_rotation * direction_to_target

		# Initialize projectile
		projectile.initialize(spawn_position, direction_to_target, damage, projectile_speed, explosion_radius)
		projectile.lifetime = projectile_lifetime

		DebugLogger.log("fireball", "Projectile " + str(i + 1) + "/" + str(projectile_count) + " fired")

	# Emit signal
	weapon_hit.emit(target)

	# Visual feedback
	if visual_node:
		_do_shoot_animation()

	# Start cooldown timer
	can_attack = false
	attack_timer.start(attack_cooldown)
	DebugLogger.log("fireball", "Cooldown started - " + str(attack_cooldown) + "s")

func _do_shoot_animation() -> void:
	"""Visual feedback when shooting"""
	if not visual_node:
		return

	# Scale pulse
	var original_scale = visual_node.scale
	visual_node.scale = original_scale * 1.3

	# Reset after delay
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(visual_node):
		visual_node.scale = original_scale
