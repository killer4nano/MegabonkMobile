extends BaseWeapon
class_name SpinningBlade
## Spinning Blade weapon - Orbits player at higher speed and range than Bonk Hammer

# Orbital movement settings
@export var orbit_radius: float = 2.5  # Larger than Bonk Hammer (1.8m)
@export var orbit_speed: float = 3.0   # Faster than Bonk Hammer (2.0 rad/s)

# Visual feedback
@export var spin_speed: float = 8.0  # Visual rotation speed
@export var hit_scale_multiplier: float = 1.2
@export var hit_duration: float = 0.1

# Collision-based damage tracking
var hit_enemies: Dictionary = {}  # enemy: last_hit_time
var hit_cooldown: float = 0.3  # Faster than Bonk Hammer (0.5s)

# Internal state
var orbit_angle: float = 0.0
var angle_offset: float = 0.0  # Unique offset for each blade instance
var is_hitting: bool = false

# References
var blade_visual: Node3D
var player: Node3D

func _ready() -> void:
	# Set weapon type to orbital (disables range-based auto-attack)
	weapon_type = "orbital"

	# Call parent ready
	super._ready()

	# Find player
	player = get_parent().get_parent() if get_parent() else null
	if not player:
		push_warning("SpinningBlade: Could not find player!")

	# Find visual mesh
	blade_visual = get_node_or_null("BladeVisual")

	# Connect to AttackRange area for collision-based damage
	var attack_range_area = get_node_or_null("AttackRange")
	if attack_range_area and attack_range_area is Area3D:
		attack_range_area.body_entered.connect(_on_attack_range_body_entered)
		print("SpinningBlade: Collision-based damage enabled")
	else:
		push_warning("SpinningBlade: AttackRange Area3D not found!")

	print("SpinningBlade ready! Orbit radius: ", orbit_radius, ", Speed: ", orbit_speed)

func _process(delta: float) -> void:
	"""Handle orbital movement around player and cleanup hit tracking"""
	if not player:
		return

	# Update orbit angle (faster than Bonk Hammer)
	orbit_angle += orbit_speed * delta

	# Calculate orbital position using sin/cos (with unique angle offset per blade)
	var final_angle = orbit_angle + angle_offset
	var offset = Vector3(
		cos(final_angle) * orbit_radius,
		0.5,  # Slightly elevated
		sin(final_angle) * orbit_radius
	)

	# Set position relative to player
	global_position = player.global_position + offset

	# Spin the blade visual
	if blade_visual:
		# Face outward from player (with offset)
		blade_visual.rotation.y = final_angle
		# Constant high-speed spin for visual effect
		blade_visual.rotation.z += delta * spin_speed

	# Clean up old hit tracking entries
	var current_time = Time.get_ticks_msec() / 1000.0
	var enemies_to_remove = []
	for enemy in hit_enemies:
		if not is_instance_valid(enemy) or current_time - hit_enemies[enemy] > hit_cooldown:
			enemies_to_remove.append(enemy)
	for enemy in enemies_to_remove:
		hit_enemies.erase(enemy)

func _on_attack_range_body_entered(body: Node3D) -> void:
	"""Handle collision-based damage when blade touches an enemy"""
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
			return  # Too soon to hit again

	# Update hit tracking BEFORE dealing damage (ensures test can verify tracking)
	hit_enemies[body] = current_time

	# Damage the enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)
		weapon_hit.emit(body)
		print("Spinning Blade hit enemy for ", damage, " damage")

		# Apply knockback if player has it enabled
		if player and "knockback_enabled" in player and player.knockback_enabled:
			_apply_knockback(body)

		_on_attack_hit(body)  # Visual feedback

func _on_attack_hit(target: Node3D) -> void:
	"""Visual feedback when hitting an enemy"""
	if is_hitting or not blade_visual:
		return

	is_hitting = true

	# Scale up the blade briefly
	var original_scale = blade_visual.scale
	blade_visual.scale = original_scale * hit_scale_multiplier

	# Reset after duration
	await get_tree().create_timer(hit_duration).timeout
	if is_instance_valid(blade_visual):
		blade_visual.scale = original_scale

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
