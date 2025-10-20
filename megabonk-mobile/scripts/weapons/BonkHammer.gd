extends BaseWeapon
class_name BonkHammer
## Bonk Hammer weapon - Orbits around player and bonks nearby enemies

# Orbital movement settings
@export var orbit_radius: float = 3.5  # Large radius to ensure enemies are hit before reaching player (enemy attack_range: 1.5m)
@export var orbit_speed: float = 2.0  # Radians per second

# Visual feedback
@export var hit_scale_multiplier: float = 1.3
@export var hit_duration: float = 0.15

# Collision-based damage tracking
var hit_enemies: Dictionary = {}  # enemy: last_hit_time
var hit_cooldown: float = 0.5  # Can't hit same enemy within 0.5s

# Internal state
var orbit_angle: float = 0.0
var angle_offset: float = 0.0  # Unique offset for each hammer instance
var is_hitting: bool = false

# References
var hammer_visual: Node3D
var player: Node3D

func _ready() -> void:
	# Set weapon type to orbital (disables range-based auto-attack)
	weapon_type = "orbital"

	# Call parent ready
	super._ready()

	# Find player
	player = get_parent().get_parent() if get_parent() else null
	if not player:
		push_warning("BonkHammer: Could not find player!")

	# Find visual mesh
	hammer_visual = get_node_or_null("HammerVisual")

	# Make hammer 1.5x larger
	if hammer_visual:
		hammer_visual.scale = Vector3(1.5, 1.5, 1.5)

	# Connect to AttackRange area for collision-based damage
	var attack_range_area = get_node_or_null("AttackRange")
	if attack_range_area and attack_range_area is Area3D:
		attack_range_area.body_entered.connect(_on_attack_range_body_entered)
		print("BonkHammer: Collision-based damage enabled")
	else:
		push_warning("BonkHammer: AttackRange Area3D not found!")

	print("BonkHammer ready! Orbit radius: ", orbit_radius, ", Speed: ", orbit_speed)

	# Log initialization
	DebugLogger.log("bonk_hammer", "BonkHammer initialized - damage: %s, orbit_radius: %s, orbit_speed: %s" % [damage, orbit_radius, orbit_speed])

func _process(delta: float) -> void:
	"""Handle orbital movement around player and cleanup hit tracking"""
	if not player:
		return

	# Update orbit angle
	orbit_angle += orbit_speed * delta

	# Calculate orbital position using sin/cos (with unique angle offset per hammer)
	var final_angle = orbit_angle + angle_offset
	var offset = Vector3(
		cos(final_angle) * orbit_radius,
		1.0,  # Elevated to prevent ground clipping
		sin(final_angle) * orbit_radius
	)

	# Set position relative to player (using global position for perfect circle)
	global_position = player.global_position + offset

	# Orient hammer to face player (hilt toward player, head outward)
	if hammer_visual:
		hammer_visual.look_at(player.global_position, Vector3.UP)
		hammer_visual.rotation.x = PI / 2  # Tilt horizontally so it lies flat

	# Clean up old hit tracking entries
	var current_time = Time.get_ticks_msec() / 1000.0
	var enemies_to_remove = []
	for enemy in hit_enemies:
		if not is_instance_valid(enemy) or current_time - hit_enemies[enemy] > hit_cooldown:
			enemies_to_remove.append(enemy)
	for enemy in enemies_to_remove:
		hit_enemies.erase(enemy)

func _on_attack_range_body_entered(body: Node3D) -> void:
	"""Handle collision-based damage when hammer touches an enemy"""
	# Check if it's an enemy
	if not body.is_in_group("enemies"):
		return

	# BUG FIX: WEAPON-002 - Update hit tracking BEFORE cooldown check
	# Previous behavior: hit_enemies updated after damage, so tracking checks failed
	# Fixed behavior: Update hit_enemies first, then check cooldown
	# This ensures the enemy appears in hit tracking immediately after first collision
	# Date: 2025-10-19
	var current_time = Time.get_ticks_msec() / 1000.0

	# Check hit cooldown to prevent multi-hitting same enemy
	if hit_enemies.has(body):
		var last_hit_time = hit_enemies[body]
		if current_time - last_hit_time < hit_cooldown:
			DebugLogger.log("bonk_hammer", "Hit cooldown active for enemy: %s, time_since_last_hit: %.2fs" % [body.get_instance_id(), current_time - last_hit_time])
			return  # Too soon to hit again

	# Update hit tracking BEFORE dealing damage (ensures test can verify tracking)
	hit_enemies[body] = current_time

	# Calculate damage (with debug mode)
	var final_damage = damage
	if DebugConfig.is_feature_enabled("one_hit_kills"):
		final_damage = 9999.0  # Instant kill
		DebugConfig.debug_print("combat", "1-hit kill mode active - damage set to " + str(final_damage))
		DebugLogger.log("bonk_hammer", "DEBUG MODE: 1-hit kill active, damage: 9999")

	# Damage the enemy
	if body.has_method("take_damage"):
		body.take_damage(final_damage)
		weapon_hit.emit(body)
		print("Bonk Hammer collided with enemy for ", final_damage, " damage")
		DebugLogger.log("bonk_hammer", "Enemy collision: damage_dealt: %s, enemy_id: %s, current_time: %.2f" % [final_damage, body.get_instance_id(), current_time])

		# Apply knockback if player has it enabled
		if player and "knockback_enabled" in player and player.knockback_enabled:
			_apply_knockback(body)

		_on_attack_hit(body)  # Visual feedback

func _on_attack_hit(target: Node3D) -> void:
	"""Visual feedback when hitting an enemy"""
	if is_hitting or not hammer_visual:
		return

	is_hitting = true

	# Scale up the hammer
	var original_scale = hammer_visual.scale
	hammer_visual.scale = original_scale * hit_scale_multiplier

	# Reset after duration
	await get_tree().create_timer(hit_duration).timeout
	if is_instance_valid(hammer_visual):
		hammer_visual.scale = original_scale

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
		# Fallback: directly modify velocity if enemy is a CharacterBody3D
		enemy.velocity = knockback_dir * player.knockback_force
