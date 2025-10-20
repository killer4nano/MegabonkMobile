extends Node3D
class_name BaseWeapon
## Base weapon controller for auto-attack weapons
## Vampire Survivors-style auto-attack system

# Weapon configuration
@export var weapon_data: WeaponData
@export_enum("ranged", "orbital", "aura") var weapon_type: String = "ranged"

# Weapon stats (loaded from WeaponData)
var weapon_name: String = "Base Weapon"
var damage: float = 10.0
var attack_cooldown: float = 1.0
var attack_range: float = 5.0
var projectile_count: int = 1
var level: int = 1

# Weapon modifiers (from upgrades)
var pierces_enemies: bool = false
var chain_lightning: bool = false

# Attack state
var can_attack: bool = true
var current_target: Node3D = null

# References
var attack_timer: Timer
var attack_area: Area3D

# Signals
signal weapon_attacked(target: Node3D, damage: float)
signal weapon_hit(target: Node3D)

func _ready() -> void:
	# Load weapon data if provided
	if weapon_data:
		load_weapon_data()

	# Setup attack timer
	attack_timer = Timer.new()
	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Find attack range area if it exists
	attack_area = get_node_or_null("AttackRange")
	if attack_area:
		print("Weapon: ", weapon_name, " initialized with attack range area")

	print("Weapon initialized: ", weapon_name, " | Damage: ", damage, " | Cooldown: ", attack_cooldown, " | Range: ", attack_range)

func load_weapon_data() -> void:
	"""Load stats from WeaponData resource"""
	weapon_name = weapon_data.weapon_name
	damage = weapon_data.base_damage
	attack_cooldown = weapon_data.attack_cooldown
	attack_range = weapon_data.attack_range
	projectile_count = weapon_data.projectile_count
	level = weapon_data.level

func _physics_process(_delta: float) -> void:
	"""Auto-attack logic - finds and attacks enemies"""
	# Only for ranged/projectile weapons - orbital weapons use collision-based damage
	if weapon_type != "ranged":
		return

	if not can_attack:
		return

	var targets = find_all_enemies_in_range()
	if targets.size() > 0:
		print("DEBUG BaseWeapon: Found ", targets.size(), " enemies in range, attacking!")
		attack_multiple(targets)

func find_nearest_enemy() -> Node3D:
	"""Find the nearest enemy within attack range"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var nearest_distance: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance

	return nearest

func find_all_enemies_in_range() -> Array[Node3D]:
	"""Find all enemies within attack range"""
	var enemies_in_range: Array[Node3D] = []
	var all_enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if enemy and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= attack_range:
				enemies_in_range.append(enemy)

	return enemies_in_range

func attack(target: Node3D) -> void:
	"""Attack a single target (for single-target weapons)"""
	if not is_instance_valid(target):
		return

	# Deal damage to target
	if target.has_method("take_damage"):
		var damage_dealt = damage
		target.take_damage(damage_dealt)
		weapon_attacked.emit(target, damage_dealt)
		weapon_hit.emit(target)
		print("Weapon '", weapon_name, "' attacked enemy for ", damage_dealt, " damage")

		# Apply player passive effects
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# Lifesteal
			if player.lifesteal_percent > 0:
				var heal_amount = damage_dealt * player.lifesteal_percent
				if player.has_method("heal"):
					player.heal(heal_amount)

			# Slow effect
			if player.slow_on_hit and "apply_slow" in target:
				target.apply_slow(player.slow_percent, player.slow_duration)

			# Burn DoT
			if player.burn_on_hit and "apply_burn" in target:
				target.apply_burn(player.burn_damage_per_second, player.burn_duration)

		# Visual feedback
		_on_attack_hit(target)

	# Start attack cooldown
	can_attack = false
	attack_timer.start(attack_cooldown)

func attack_multiple(targets: Array[Node3D]) -> void:
	"""Attack all enemies in range"""
	# Call the weapon's attack() method for the first target
	# This allows weapons to override attack behavior (e.g., spawn projectiles)
	if targets.size() > 0 and targets[0] and is_instance_valid(targets[0]):
		attack(targets[0])

func _on_attack_hit(target: Node3D) -> void:
	"""Override this for weapon-specific visual feedback"""
	pass

func _on_attack_timer_timeout() -> void:
	"""Reset attack cooldown"""
	can_attack = true

func upgrade() -> void:
	"""Upgrade the weapon to the next level"""
	if weapon_data:
		weapon_data.upgrade()
		load_weapon_data()
		print("Weapon upgraded to level ", level)
	else:
		# Manual upgrade if no WeaponData
		level += 1
		damage *= 1.15
		attack_cooldown *= 0.95
		attack_range *= 1.10
		print("Weapon upgraded to level ", level)

func get_stats() -> Dictionary:
	"""Return weapon stats as dictionary"""
	return {
		"name": weapon_name,
		"damage": damage,
		"cooldown": attack_cooldown,
		"range": attack_range,
		"level": level
	}
