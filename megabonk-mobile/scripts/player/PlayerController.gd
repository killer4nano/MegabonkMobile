extends CharacterBody3D
class_name PlayerController
## Player controller for mobile roguelite
## Handles movement, stats, and basic player functionality

# ============================================================================
# DEBUG MODE - Set to false to disable all debug features
# ============================================================================
const DEBUG_MODE: bool = true  # MASTER TOGGLE - Change this to enable/disable debug (ENABLED for testing)
const DEBUG_GOD_MODE: bool = true  # Player takes no damage - DISABLED
const DEBUG_ONE_HIT_KILL: bool = false  # Weapons 1-shot all enemies - DISABLED


# Player stats
@export_group("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var acceleration: float = 20.0
@export var friction: float = 15.0

@export_group("Combat")
@export var base_damage: float = 10.0
@export var base_damage_bonus: float = 0.0  # Added by upgrades
@export var crit_chance: float = 0.05  # 5%
@export var crit_multiplier: float = 2.0
@export var pickup_range: float = 3.0

# Character-specific bonuses (from CharacterData)
var damage_reduction_percent: float = 0.0
var melee_damage_multiplier: float = 1.0
var ranged_damage_multiplier: float = 1.0
var xp_multiplier: float = 1.0
var character_color: Color = Color.RED
var extra_starting_weapons: int = 0

# Shrine buffs (temporary, from shrines)
var shrine_damage_multiplier: float = 1.0
var shrine_speed_multiplier: float = 1.0

# Passive abilities (from upgrades)
var hp_regen_per_second: float = 0.0
var hp_regen_timer: float = 0.0
var knockback_enabled: bool = false
var knockback_force: float = 5.0
var lifesteal_percent: float = 0.0
var thorns_damage_percent: float = 0.0
var dodge_chance: float = 0.0
var has_second_wind: bool = false
var second_wind_used: bool = false
var gold_drop_multiplier: float = 1.0
var explosion_on_kill: bool = false
var explosion_damage: float = 0.0
var explosion_radius: float = 0.0
var slow_on_hit: bool = false
var slow_percent: float = 0.0
var slow_duration: float = 0.0
var burn_on_hit: bool = false
var burn_damage_per_second: float = 0.0
var burn_duration: float = 0.0

# Attack speed multiplier (affects all weapons)
var global_attack_speed_multiplier: float = 1.0
var global_damage_multiplier: float = 1.0

@export_group("Leveling")
@export var base_xp_requirement: float = 100.0
@export var xp_curve_multiplier: float = 1.5  # XP needed increases by 50% per level

# Current state
var current_health: float
var is_alive: bool = true

# XP and Leveling
var current_xp: float = 0.0
var current_level: int = 1
var xp_to_next_level: float = 100.0

# Movement
var movement_input: Vector2 = Vector2.ZERO
var last_movement_direction: Vector3 = Vector3.FORWARD

# References (will be set externally or via signals)
var camera_pivot: Node3D

func _ready() -> void:
	current_health = max_health
	print("Player initialized with ", max_health, " HP")
	Engine.time_scale = 4.0
	# DEBUG MODE notifications
	if DEBUG_MODE:
		print("========================================")
		print("⚠️  DEBUG MODE ACTIVE ⚠️")
		if DEBUG_GOD_MODE:
			print("  ✓ God Mode: ON (invincible)")
		if DEBUG_ONE_HIT_KILL:
			print("  ✓ 1-Hit Kill: ON (instant kill)")
		print("  ✓ Game Speed: 1x (normal)")
		
		print("========================================")

	# Add to player group for enemy targeting
	add_to_group("player")

	# Initialize XP system
	xp_to_next_level = calculate_xp_needed(current_level)
	print("Player starting at level ", current_level, " (needs ", xp_to_next_level, " XP to level up)")

	# Find camera pivot (SpringArm3D)
	camera_pivot = get_node_or_null("CameraArm")
	if not camera_pivot:
		push_warning("Camera pivot not found!")

	# Connect to event bus
	EventBus.player_damaged.connect(_on_damaged)
	EventBus.player_healed.connect(_on_healed)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Handle HP regeneration
	if hp_regen_per_second > 0:
		hp_regen_timer += delta
		if hp_regen_timer >= 1.0:
			heal(hp_regen_per_second)
			hp_regen_timer = 0.0

	# Handle movement
	handle_movement(delta)

	# Move the character
	move_and_slide()

	# Rotate ONLY the body mesh to face movement direction, not the whole player
	# (Camera should stay independent)
	if velocity.length() > 0.1:
		var body := get_node_or_null("Body")
		if body:
			var target_direction := velocity.normalized()
			var target_rotation := atan2(target_direction.x, target_direction.z)
			body.rotation.y = lerp_angle(body.rotation.y, target_rotation, 10.0 * delta)

func handle_movement(delta: float) -> void:
	"""Handle player movement with acceleration and friction - camera relative"""
	var input_dir := Vector3.ZERO

	if movement_input.length() > 0:
		if camera_pivot:
			# Get camera's forward and right directions (ignore Y component for ground movement)
			var camera_forward := -camera_pivot.global_transform.basis.z
			camera_forward.y = 0
			camera_forward = camera_forward.normalized()

			var camera_right := camera_pivot.global_transform.basis.x
			camera_right.y = 0
			camera_right = camera_right.normalized()

			# Calculate movement direction relative to camera
			# movement_input.y = forward/back (W=-1, S=+1), movement_input.x = left/right (A=-1, D=+1)
			# Flip Y input so W moves forward
			input_dir = (camera_right * movement_input.x + camera_forward * (-movement_input.y)).normalized()
		else:
			# Fallback to world-space movement
			input_dir = Vector3(movement_input.x, 0, movement_input.y).normalized()

	if input_dir.length() > 0:
		# Accelerate toward input direction
		velocity = velocity.lerp(input_dir * move_speed, acceleration * delta)
		# Update last movement direction for character rotation
		last_movement_direction = input_dir
	else:
		# Apply friction when no input
		velocity = velocity.lerp(Vector3.ZERO, friction * delta)

func set_movement_input(input: Vector2) -> void:
	"""Called by input system (touch controls or keyboard)"""
	movement_input = input

func take_damage(amount: float, attacker: Node = null) -> void:
	"""Deal damage to the player"""
	# DEBUG: God mode check
	if DEBUG_MODE and DEBUG_GOD_MODE:
		print("[DEBUG] God mode active - ignoring ", amount, " damage")
		DebugLogger.log("player_stats", "God mode active - ignored damage: %s" % amount)
		return  # Don't take any damage

	if not is_alive:
		return

	# Dodge chance check
	if dodge_chance > 0:
		var roll = randf()
		if roll < dodge_chance:
			print("DODGED! (", dodge_chance * 100, "% chance)")
			DebugLogger.log("player_stats", "Dodged attack! Roll: %.2f < %.2f" % [roll, dodge_chance])
			return  # Completely avoid damage

	# Apply character damage reduction
	var reduced_amount = amount * (1.0 - damage_reduction_percent)

	var old_health = current_health
	current_health -= reduced_amount
	EventBus.player_damaged.emit(reduced_amount)

	DebugLogger.log("player_stats", "Damage taken: %s (reduced from %s), HP: %s → %s (Max: %s)" % [reduced_amount, amount, old_health, current_health, max_health])

	# Thorns damage reflection
	if thorns_damage_percent > 0 and attacker and attacker.has_method("take_damage"):
		var reflected_damage = reduced_amount * thorns_damage_percent
		attacker.take_damage(reflected_damage)
		print("Thorns reflected ", reflected_damage, " damage to attacker")

	if current_health <= 0:
		current_health = 0
		die()

	print("Player took ", reduced_amount, " damage. HP: ", current_health, "/", max_health)

func heal(amount: float) -> void:
	"""Heal the player"""
	if not is_alive:
		return

	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	EventBus.player_healed.emit(amount)
	DebugLogger.log("player_stats", "Healed: %s, HP: %s → %s (Max: %s)" % [amount, old_health, current_health, max_health])
	print("Player healed ", amount, ". HP: ", current_health, "/", max_health)

func die() -> void:
	"""Handle player death"""
	if not is_alive:
		return

	# Second Wind: Revive once at 50% HP
	if has_second_wind and not second_wind_used:
		second_wind_used = true
		current_health = max_health * 0.5
		print("SECOND WIND ACTIVATED! Revived at 50% HP!")
		DebugLogger.log("player_stats", "Second Wind triggered! HP: %s" % current_health)
		# TODO: Visual effect for revival
		return

	is_alive = false
	EventBus.player_died.emit()
	print("Player died!")

	# TODO: Play death animation, show death screen, etc.

func _on_damaged(damage: float) -> void:
	"""Response to taking damage (visual feedback, etc.)"""
	# TODO: Screen shake, red flash, etc.
	pass

func _on_healed(amount: float) -> void:
	"""Response to healing (visual feedback, etc.)"""
	# TODO: Green particles, etc.
	pass

func get_health_percent() -> float:
	"""Returns health as a percentage (0.0 to 1.0)"""
	return current_health / max_health

# ============================================================================
# XP AND LEVELING SYSTEM
# ============================================================================

func collect_xp(amount: float) -> void:
	"""Collect XP and check for level up"""
	if not is_alive:
		return

	# Apply character XP multiplier
	var modified_amount = amount * xp_multiplier

	var old_xp = current_xp
	current_xp += modified_amount
	var progress_percent = (current_xp / xp_to_next_level) * 100.0
	print("Collected ", modified_amount, " XP (Total: ", current_xp, "/", xp_to_next_level, ")")
	DebugLogger.log("player_stats", "XP collected: %s (base: %s, mult: %.2fx), Total: %s → %s/%s (%.1f%%)" % [modified_amount, amount, xp_multiplier, old_xp, current_xp, xp_to_next_level, progress_percent])

	# Emit event for UI updates
	EventBus.xp_collected.emit(modified_amount, current_xp, xp_to_next_level)

	# Check for level up
	while current_xp >= xp_to_next_level:
		level_up()

func level_up() -> void:
	"""Level up the player"""
	# Subtract XP requirement (carry over excess)
	var old_level = current_level
	current_xp -= xp_to_next_level

	# Increase level
	current_level += 1

	# Calculate new XP requirement
	var old_xp_requirement = xp_to_next_level
	xp_to_next_level = calculate_xp_needed(current_level)

	print("=====================================")
	print("⭐ LEVEL UP! Now level ", current_level, " ⭐")
	print("XP needed for next level: ", xp_to_next_level)
	print("=====================================")
	DebugLogger.log("player_stats", "LEVEL UP: %s → %s, XP requirement: %s → %s, Overflow XP: %s" % [old_level, current_level, old_xp_requirement, xp_to_next_level, current_xp])

	# Emit level up signal
	EventBus.player_leveled_up.emit(current_level)

	# Optional: Heal player on level up (common in survivor-likes)
	# heal(max_health * 0.2)  # Heal 20% of max HP

func calculate_xp_needed(level: int) -> float:
	"""Calculate XP needed for the next level using exponential curve"""
	# Formula: base_xp * (curve_multiplier ^ (level - 1))
	# Level 1->2: 100
	# Level 2->3: 150
	# Level 3->4: 225
	# Level 4->5: 337.5
	return base_xp_requirement * pow(xp_curve_multiplier, level - 1)

func get_xp_percent() -> float:
	"""Returns XP progress as a percentage (0.0 to 1.0)"""
	if xp_to_next_level <= 0:
		return 0.0
	return current_xp / xp_to_next_level

# ============================================================================
# UPGRADE SYSTEM INTEGRATION
# ============================================================================

func add_base_damage(amount: float) -> void:
	"""Add base damage bonus from upgrades"""
	var old_bonus = base_damage_bonus
	base_damage_bonus += amount
	var total_damage = get_total_damage()
	print("Base damage bonus increased by ", amount, " (Total bonus: ", base_damage_bonus, ")")
	DebugLogger.log("player_stats", "Base damage bonus: %s → %s (Total damage: %s)" % [old_bonus, base_damage_bonus, total_damage])

func get_total_damage() -> float:
	"""Get total damage including bonuses"""
	return base_damage + base_damage_bonus

func add_hp_regen(amount: float) -> void:
	"""Add HP regeneration from upgrades"""
	var old_regen = hp_regen_per_second
	hp_regen_per_second += amount
	print("HP regeneration increased to ", hp_regen_per_second, " HP/sec")
	DebugLogger.log("player_stats", "HP regen: %s → %s HP/sec" % [old_regen, hp_regen_per_second])

func apply_attack_speed_multiplier(multiplier: float) -> void:
	"""Apply attack speed multiplier to all weapons"""
	global_attack_speed_multiplier *= multiplier
	var weapon_manager = get_node_or_null("WeaponManager")
	if weapon_manager:
		for weapon in weapon_manager.equipped_weapons:
			if "attack_cooldown" in weapon:
				weapon.attack_cooldown /= multiplier
				if weapon.weapon_data:
					weapon.weapon_data.attack_cooldown = weapon.attack_cooldown
	print("Attack speed multiplier: ", global_attack_speed_multiplier, " (cooldowns reduced)")
	DebugLogger.log("player_stats", "Global attack speed: %.2fx" % global_attack_speed_multiplier)

func apply_damage_multiplier(multiplier: float) -> void:
	"""Apply damage multiplier to all weapons"""
	global_damage_multiplier *= multiplier
	var weapon_manager = get_node_or_null("WeaponManager")
	if weapon_manager:
		for weapon in weapon_manager.equipped_weapons:
			if "damage" in weapon:
				weapon.damage *= multiplier
				if weapon.weapon_data:
					weapon.weapon_data.base_damage = weapon.damage
	print("Damage multiplier: ", global_damage_multiplier)
	DebugLogger.log("player_stats", "Global damage multiplier: %.2fx" % global_damage_multiplier)

# ============================================================================
# CHARACTER SYSTEM INTEGRATION
# ============================================================================

func apply_character_data(data: CharacterData) -> void:
	"""Apply character data to player stats and abilities"""
	if not data:
		push_error("CharacterData is null! Using default stats.")
		return

	print("========================================")
	print("Applying character: ", data.character_name)
	print("========================================")

	# Copy base stats from character
	max_health = data.max_health
	move_speed = data.move_speed
	base_damage = data.base_damage
	pickup_range = data.pickup_range

	# Reset health to new max
	current_health = max_health

	# Apply character passive bonuses
	damage_reduction_percent = data.damage_reduction
	melee_damage_multiplier = 1.0 + data.melee_damage_bonus
	ranged_damage_multiplier = 1.0 + data.ranged_damage_bonus
	xp_multiplier = data.xp_multiplier
	character_color = data.character_color
	extra_starting_weapons = data.extra_starting_weapons

	# Apply crit bonuses to base stats
	crit_chance += data.crit_chance_bonus
	crit_multiplier += data.crit_damage_bonus

	# Change player visual color
	var body = get_node_or_null("Body")
	if body and body is MeshInstance3D:
		var mat = body.get_surface_override_material(0)
		if mat:
			mat.albedo_color = character_color
		else:
			# Create new material if none exists
			var new_mat = StandardMaterial3D.new()
			new_mat.albedo_color = character_color
			body.set_surface_override_material(0, new_mat)

	print("Character Applied:")
	print("  HP: ", max_health)
	print("  Speed: ", move_speed)
	print("  Damage: ", base_damage)
	print("  Pickup Range: ", pickup_range)
	print("  Passive: ", data.passive_name)
	if damage_reduction_percent > 0:
		print("    - Damage Reduction: ", damage_reduction_percent * 100, "%")
	if melee_damage_multiplier > 1.0:
		print("    - Melee Damage: +", (melee_damage_multiplier - 1.0) * 100, "%")
	if ranged_damage_multiplier > 1.0:
		print("    - Ranged Damage: +", (ranged_damage_multiplier - 1.0) * 100, "%")
	if xp_multiplier > 1.0:
		print("    - XP Gain: +", (xp_multiplier - 1.0) * 100, "%")
	if extra_starting_weapons > 0:
		print("    - Extra Starting Weapons: ", extra_starting_weapons)
	print("========================================")

# ============================================================================
# Shrine Buff Management
# ============================================================================

func apply_damage_buff(multiplier: float) -> void:
	"""Apply temporary damage multiplier from shrine"""
	shrine_damage_multiplier = multiplier
	print("Damage buff applied: %.0f%% damage" % (multiplier * 100))

func remove_damage_buff() -> void:
	"""Remove temporary damage multiplier"""
	shrine_damage_multiplier = 1.0
	print("Damage buff expired")

func apply_speed_buff(multiplier: float) -> void:
	"""Apply temporary speed multiplier from shrine"""
	shrine_speed_multiplier = multiplier
	print("Speed buff applied: %.0f%% speed" % (multiplier * 100))

func remove_speed_buff() -> void:
	"""Remove temporary speed multiplier"""
	shrine_speed_multiplier = 1.0
	print("Speed buff expired")

func get_effective_damage() -> float:
	"""Get total damage including all multipliers"""
	return get_total_damage() * shrine_damage_multiplier

func get_effective_speed() -> float:
	"""Get total speed including all multipliers"""
	return move_speed * shrine_speed_multiplier
