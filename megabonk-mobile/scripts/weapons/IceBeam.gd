extends BaseWeapon
class_name IceBeam
## Ice Beam weapon - Continuous damage beam that slows enemies

# Beam settings
@export var beam_range: float = 12.0
@export var beam_width: float = 0.4
@export var tick_rate: float = 0.2  # Damage every 0.2 seconds
@export var slow_percentage: float = 0.5  # 50% slow
@export var slow_duration: float = 2.0  # Slow lasts 2 seconds after being hit

# Internal state
var beam_timer: float = 0.0
var is_firing: bool = false
var slowed_enemies: Dictionary = {}  # enemy: {original_speed, slow_timer}

# Visual
var beam_visual: Node3D
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
	beam_visual = get_node_or_null("BeamVisual")

	# Find player reference
	player = get_parent().get_parent() if get_parent() else null
	if not player:
		push_warning("IceBeam: Could not find player!")

	# Hide beam visual initially
	if beam_visual:
		beam_visual.visible = false

	DebugLogger.log("ice_beam", "Ice Beam ready! Damage/sec: " + str(damage / tick_rate) + ", Range: " + str(beam_range) + "m, Slow: " + str(slow_percentage * 100) + "%")

func _process(delta: float) -> void:
	"""Keep weapon positioned near player and update beam"""
	# Position at a fixed local offset (left side)
	var offset = Vector3(-0.7, 1.0, 0.5)
	position = offset

	# Update beam firing
	if is_firing:
		beam_timer += delta
		if beam_timer >= tick_rate:
			beam_timer = 0.0
			fire_beam()

	# Update slow timers for affected enemies
	update_slowed_enemies(delta)

func attack(target: Node3D) -> void:
	"""Start continuous beam on target"""
	DebugLogger.log("ice_beam", "attack() called! Target: " + (target.name if target else "null"))

	if not target or not is_instance_valid(target):
		DebugLogger.log("ice_beam", "Invalid target, aborting")
		return

	# Start firing beam
	is_firing = true
	beam_timer = 0.0

	# Show beam visual
	if beam_visual:
		beam_visual.visible = true

	# Fire immediately
	fire_beam()

	# Start cooldown timer (beam duration = cooldown)
	can_attack = false
	attack_timer.start(attack_cooldown)

	# Stop beam when cooldown expires
	await attack_timer.timeout
	stop_beam()

func fire_beam() -> void:
	"""Deal damage and apply slow to all enemies in beam path"""
	if not player:
		return

	# Find nearest enemy to aim at
	var target = find_nearest_enemy()
	if not target:
		DebugLogger.log("ice_beam", "No target found for beam")
		stop_beam()
		return

	# Calculate beam direction
	var beam_direction = global_position.direction_to(target.global_position)
	var beam_end = global_position + beam_direction * beam_range

	# Check all enemies along the beam path
	var hit_enemies: Array[Node3D] = []
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		# Check if enemy is within beam range
		var distance_to_player = global_position.distance_to(enemy.global_position)
		if distance_to_player > beam_range:
			continue

		# Check if enemy is in beam path
		var to_enemy = enemy.global_position - global_position
		var projected = to_enemy.project(beam_direction)
		var perpendicular = to_enemy - projected

		# If perpendicular distance is small enough, enemy is hit
		if perpendicular.length() <= beam_width and projected.dot(beam_direction) > 0:
			hit_enemies.append(enemy)

	# Deal damage and apply slow to all hit enemies
	for enemy in hit_enemies:
		# Deal damage
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			weapon_hit.emit(enemy)
			DebugLogger.log("ice_beam", "Ice beam hit " + enemy.name + " for " + str(damage) + " damage")

		# Apply slow effect
		apply_slow(enemy)

	if hit_enemies.size() > 0:
		DebugLogger.log("ice_beam", "Ice beam hit " + str(hit_enemies.size()) + " enemies")

	# Update beam visual direction
	if beam_visual and target:
		beam_visual.look_at(target.global_position, Vector3.UP)

func apply_slow(enemy: Node3D) -> void:
	"""Apply slow effect to enemy"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Check if enemy has move_speed property
	if not "move_speed" in enemy:
		return

	# If not already slowed, save original speed
	if not slowed_enemies.has(enemy):
		slowed_enemies[enemy] = {
			"original_speed": enemy.move_speed,
			"slow_timer": slow_duration
		}
		# Apply slow
		enemy.move_speed *= (1.0 - slow_percentage)
		DebugLogger.log("ice_beam", "Applied slow to " + enemy.name + " (new speed: " + str(enemy.move_speed) + ")")
	else:
		# Refresh slow duration
		slowed_enemies[enemy]["slow_timer"] = slow_duration

func update_slowed_enemies(delta: float) -> void:
	"""Update slow timers and remove expired slows"""
	var enemies_to_remove: Array = []

	for enemy in slowed_enemies:
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
			continue

		# Decrease slow timer
		slowed_enemies[enemy]["slow_timer"] -= delta

		# If slow expired, restore original speed
		if slowed_enemies[enemy]["slow_timer"] <= 0:
			enemy.move_speed = slowed_enemies[enemy]["original_speed"]
			enemies_to_remove.append(enemy)
			DebugLogger.log("ice_beam", "Slow expired for " + enemy.name + " (restored speed: " + str(enemy.move_speed) + ")")

	# Remove expired slows
	for enemy in enemies_to_remove:
		slowed_enemies.erase(enemy)

func stop_beam() -> void:
	"""Stop firing the beam"""
	is_firing = false

	# Hide beam visual
	if beam_visual:
		beam_visual.visible = false

	DebugLogger.log("ice_beam", "Ice beam stopped")
