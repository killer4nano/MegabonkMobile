extends BaseWeapon
class_name ShieldRing
## Shield Ring weapon - Large orbital ring that damages and blocks projectiles

# Orbital movement settings
@export var orbit_radius: float = 3.0  # Larger than other orbitals
@export var orbit_speed: float = 1.5   # Slower, more defensive
@export var blocks_projectiles: bool = true

# Visual feedback
@export var spin_speed: float = 3.0
@export var hit_scale_multiplier: float = 1.15
@export var hit_duration: float = 0.1

# Collision-based damage tracking
var hit_enemies: Dictionary = {}  # enemy: last_hit_time
var hit_cooldown: float = 0.6  # Slower than other orbitals

# Internal state
var orbit_angle: float = 0.0
var angle_offset: float = 0.0
var is_hitting: bool = false

# References
var shield_visual: Node3D
var player: Node3D

func _ready() -> void:
	# Set weapon type to orbital (disables range-based auto-attack)
	weapon_type = "orbital"

	# Call parent ready
	super._ready()

	# Find player
	player = get_parent().get_parent() if get_parent() else null
	if not player:
		push_warning("ShieldRing: Could not find player!")

	# Find visual mesh
	shield_visual = get_node_or_null("ShieldVisual")

	# Connect to AttackRange area for collision-based damage
	var attack_range_area = get_node_or_null("AttackRange")
	if attack_range_area and attack_range_area is Area3D:
		attack_range_area.body_entered.connect(_on_attack_range_body_entered)

		# Also connect to area_entered for blocking projectiles
		if blocks_projectiles:
			attack_range_area.area_entered.connect(_on_attack_range_area_entered)

		print("ShieldRing: Collision-based damage enabled")
	else:
		push_warning("ShieldRing: AttackRange Area3D not found!")

	print("ShieldRing ready! Orbit radius: ", orbit_radius, ", Speed: ", orbit_speed)
	DebugLogger.log("shield_ring", "ShieldRing initialized - damage: " + str(damage) + ", orbit_radius: " + str(orbit_radius) + ", blocks_projectiles: " + str(blocks_projectiles))

func _process(delta: float) -> void:
	"""Handle orbital movement around player and cleanup hit tracking"""
	if not player:
		return

	# Update orbit angle (slower than other orbitals for defensive feel)
	orbit_angle += orbit_speed * delta

	# Calculate orbital position using sin/cos
	var final_angle = orbit_angle + angle_offset
	var offset = Vector3(
		cos(final_angle) * orbit_radius,
		0.3,  # Slightly elevated
		sin(final_angle) * orbit_radius
	)

	# Set position relative to player
	global_position = player.global_position + offset

	# Rotate the shield visual
	if shield_visual:
		# Face outward from player
		shield_visual.rotation.y = final_angle
		# Slow spin for visual effect
		shield_visual.rotation.z += delta * spin_speed

	# Clean up old hit tracking entries
	var current_time = Time.get_ticks_msec() / 1000.0
	var enemies_to_remove = []
	for enemy in hit_enemies:
		if not is_instance_valid(enemy) or current_time - hit_enemies[enemy] > hit_cooldown:
			enemies_to_remove.append(enemy)
	for enemy in enemies_to_remove:
		hit_enemies.erase(enemy)

func _on_attack_range_body_entered(body: Node3D) -> void:
	"""Handle collision-based damage when shield touches an enemy"""
	# Check if it's an enemy
	if not body.is_in_group("enemies"):
		return

	# Check hit cooldown to prevent multi-hitting same enemy
	var current_time = Time.get_ticks_msec() / 1000.0
	if hit_enemies.has(body):
		var last_hit_time = hit_enemies[body]
		if current_time - last_hit_time < hit_cooldown:
			return  # Too soon to hit again

	# Damage the enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)
		weapon_hit.emit(body)
		hit_enemies[body] = current_time
		print("Shield Ring hit enemy for ", damage, " damage")
		DebugLogger.log("shield_ring", "Enemy collision: damage_dealt: " + str(damage) + ", enemy_id: " + str(body.get_instance_id()))

		# Apply knockback if player has it enabled
		if player and "knockback_enabled" in player and player.knockback_enabled:
			_apply_knockback(body)

		_on_attack_hit(body)  # Visual feedback

func _on_attack_range_area_entered(area: Area3D) -> void:
	"""Block/destroy enemy projectiles"""
	if not blocks_projectiles:
		return

	# Check if it's an enemy projectile
	if area.is_in_group("enemy_projectile"):
		DebugLogger.log("shield_ring", "Blocked enemy projectile!")
		area.queue_free()

func _on_attack_hit(target: Node3D) -> void:
	"""Visual feedback when hitting an enemy"""
	if is_hitting or not shield_visual:
		return

	is_hitting = true

	# Scale up the shield briefly
	var original_scale = shield_visual.scale
	shield_visual.scale = original_scale * hit_scale_multiplier

	# Reset after duration
	await get_tree().create_timer(hit_duration).timeout
	if is_instance_valid(shield_visual):
		shield_visual.scale = original_scale

	is_hitting = false

func _apply_knockback(enemy: Node3D) -> void:
	"""Apply knockback force to enemy away from player"""
	if not player or not enemy:
		return

	# Calculate knockback direction (away from player)
	var knockback_dir = (enemy.global_position - player.global_position).normalized()

	# Apply knockback if enemy has the method
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(knockback_dir, player.knockback_force)
	elif "velocity" in enemy:
		# Fallback: directly modify velocity
		enemy.velocity = knockback_dir * player.knockback_force
