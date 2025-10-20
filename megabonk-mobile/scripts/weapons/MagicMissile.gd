extends BaseWeapon
class_name MagicMissile
## Magic Missile weapon - Shoots homing projectiles at nearest enemy

# Projectile scene
const PROJECTILE_SCENE = preload("res://scenes/weapons/MissileProjectile.tscn")

# Weapon settings
@export var projectile_speed: float = 10.0
@export var homing_strength: float = 5.0
@export var projectile_lifetime: float = 5.0

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
		push_warning("MagicMissile: Could not find player!")
		print("DEBUG: Parent = ", get_parent())
		if get_parent():
			print("DEBUG: Parent's parent = ", get_parent().get_parent())

	# Check how many Magic Missiles exist
	var weapon_manager = get_parent()
	if weapon_manager:
		var magic_missile_count = 0
		for weapon in weapon_manager.get_children():
			if "MagicMissile" in weapon.name:
				magic_missile_count += 1
		DebugLogger.log("magic_missile", "⚠️ WARNING: " + str(magic_missile_count) + " Magic Missile instances detected!")

	DebugLogger.log("magic_missile", "Magic Missile ready! Damage: " + str(damage) + ", Cooldown: " + str(attack_cooldown) + "s")
	DebugLogger.log("magic_missile", "weapon_type = " + str(weapon_type))
	DebugLogger.log("magic_missile", "attack_range = " + str(attack_range))
	DebugLogger.log("magic_missile", "Weapon global_position = " + str(global_position))
	DebugLogger.log("magic_missile", "Weapon position (local) = " + str(position))
	if visual_node:
		DebugLogger.log("magic_missile", "Visual node position = " + str(visual_node.position))
		DebugLogger.log("magic_missile", "Visual node global_position = " + str(visual_node.global_position))

func _process(delta: float) -> void:
	"""Keep weapon positioned near player"""
	# Position wand at a fixed local offset (right side, slightly up)
	# Since WeaponManager is now a Node3D child of Player, we can use local position
	var offset = Vector3(0.5, 1.0, 0.3)  # Right 0.5m, up 1.0m, forward 0.3m
	position = offset

func attack(target: Node3D) -> void:
	"""Fire homing projectile(s) at target"""
	DebugLogger.log("magic_missile", "========================================")
	DebugLogger.log("magic_missile", "attack() called! Target: " + (target.name if target else "null"))
	DebugLogger.log("magic_missile", "Current time: " + str(Time.get_ticks_msec() / 1000.0))
	DebugLogger.log("magic_missile", "can_attack = " + str(can_attack))
	DebugLogger.log("magic_missile", "projectile_count = " + str(projectile_count))
	DebugLogger.log("magic_missile", "damage = " + str(damage))
	DebugLogger.log("magic_missile", "attack_cooldown = " + str(attack_cooldown) + "s")
	DebugLogger.log("magic_missile", "attack_range = " + str(attack_range) + "m")

	if not target or not is_instance_valid(target):
		DebugLogger.log("magic_missile", "Invalid target, aborting")
		return

	# Calculate spawn position (above player)
	var spawn_player = get_parent().get_parent() if get_parent() else null
	var spawn_position = global_position
	if spawn_player:
		spawn_position = spawn_player.global_position + Vector3.UP * 1.5
		DebugLogger.log("magic_missile", "Spawn position (above player): " + str(spawn_position))
	else:
		DebugLogger.log("magic_missile", "No player found, spawning at weapon position: " + str(spawn_position))

	# Fire multiple projectiles (for Multi-Missile upgrade)
	for i in range(projectile_count):
		# Spawn projectile
		var projectile = PROJECTILE_SCENE.instantiate()

		# Add to scene tree (as child of arena/level, not weapon)
		var arena = get_tree().current_scene
		arena.add_child(projectile)

		# Calculate initial direction with slight spread for multiple projectiles
		var direction_to_target = spawn_position.direction_to(target.global_position)

		# Add spread if firing multiple projectiles
		if projectile_count > 1:
			var spread_angle = (i - (projectile_count - 1) / 2.0) * 0.2  # Spread in radians
			var spread_rotation = Basis(Vector3.UP, spread_angle)
			direction_to_target = spread_rotation * direction_to_target

		# Initialize projectile
		projectile.initialize(spawn_position, direction_to_target, damage, projectile_speed, homing_strength)
		projectile.target_enemy = target
		projectile.lifetime = projectile_lifetime

		DebugLogger.log("magic_missile", "Projectile " + str(i + 1) + "/" + str(projectile_count) + " fired")

	# Emit signal
	weapon_hit.emit(target)

	# Visual feedback (pulse effect)
	if visual_node:
		_do_shoot_animation()

	# CRITICAL: Start cooldown timer to prevent firing every frame
	can_attack = false
	attack_timer.start(attack_cooldown)
	DebugLogger.log("magic_missile", "Cooldown started - " + str(attack_cooldown) + "s")

	DebugLogger.log("magic_missile", "Magic Missile fired " + str(projectile_count) + " projectile(s) at " + target.name + "!")

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
