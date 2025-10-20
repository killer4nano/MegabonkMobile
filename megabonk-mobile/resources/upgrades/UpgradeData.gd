extends Resource
class_name UpgradeData
## Resource script for upgrade definitions
## Defines stats and behavior for player upgrades

enum UpgradeType {
	STAT_BOOST,           # Increases player stats (health, speed, damage)
	WEAPON_UPGRADE,       # Improves existing weapon
	NEW_WEAPON,           # Unlocks new weapon
	PASSIVE_ABILITY       # Adds passive effects
}

enum UpgradeRarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# Basic info
@export var upgrade_id: String = ""
@export var upgrade_name: String = ""
@export_multiline var description: String = ""
@export var icon_path: String = ""  # Path to icon texture (future)

# Upgrade classification
@export var upgrade_type: UpgradeType = UpgradeType.STAT_BOOST
@export var rarity: UpgradeRarity = UpgradeRarity.COMMON

# Stacking behavior
@export var max_stacks: int = 5  # -1 = infinite, 0 = one-time only, N = max stacks
@export var current_stacks: int = 0

# Stat modifications (for STAT_BOOST type)
@export_group("Stat Boosts")
@export var health_bonus: float = 0.0
@export var max_health_bonus: float = 0.0
@export var move_speed_multiplier: float = 1.0  # 1.1 = +10% speed
@export var pickup_range_bonus: float = 0.0
@export var base_damage_bonus: float = 0.0
@export var crit_chance_bonus: float = 0.0  # Additive (0.1 = +10% crit chance)
@export var attack_speed_multiplier: float = 1.0  # 1.2 = +20% attack speed (reduces cooldowns)
@export var base_damage_multiplier: float = 1.0  # 1.2 = +20% damage to all weapons

# Weapon modifications (for WEAPON_UPGRADE type)
@export_group("Weapon Upgrades")
@export var target_weapon_id: String = ""  # Which weapon to upgrade
@export var weapon_damage_multiplier: float = 1.0  # 1.25 = +25% damage
@export var weapon_speed_multiplier: float = 1.0   # 1.15 = +15% faster attack/orbit
@export var weapon_size_multiplier: float = 1.0    # 1.3 = +30% larger hitbox
@export var weapon_count_bonus: int = 0            # +1 = add another instance
@export var weapon_cooldown_multiplier: float = 1.0  # 0.8 = -20% cooldown (faster attacks)
@export var weapon_range_multiplier: float = 1.0    # 1.3 = +30% range
@export var weapon_projectile_count_bonus: int = 0  # +1 = fire 1 more projectile per attack
@export var weapon_pierce: bool = false            # Projectiles pierce through enemies
@export var weapon_chain_lightning: bool = false   # Attacks chain to nearby enemies
@export var global_projectile_bonus: int = 0       # +1 projectile to ALL ranged weapons

# New weapon unlock (for NEW_WEAPON type)
@export_group("Weapon Unlock")
@export var weapon_scene_path: String = ""  # Path to weapon scene to equip

# Passive abilities (for PASSIVE_ABILITY type)
@export_group("Passive Abilities")
@export var hp_regen_per_second: float = 0.0
@export var xp_magnet_range_bonus: float = 0.0
@export var knockback_on_hit: bool = false
@export var knockback_force: float = 5.0
@export var lifesteal_percent: float = 0.0  # 0.05 = 5% lifesteal
@export var thorns_damage_percent: float = 0.0  # 0.1 = reflect 10% damage
@export var dodge_chance: float = 0.0  # 0.1 = 10% dodge chance
@export var second_wind: bool = false  # Revive once at 50% HP
@export var gold_drop_multiplier: float = 1.0  # 1.5 = +50% gold/essence
@export var xp_gain_multiplier: float = 1.0  # 1.25 = +25% XP
@export var explosion_on_kill: bool = false  # Enemies explode on death
@export var explosion_damage: float = 0.0  # Damage of explosion
@export var explosion_radius: float = 0.0  # Radius of explosion
@export var slow_on_hit: bool = false  # Attacks slow enemies
@export var slow_percent: float = 0.0  # 0.3 = 30% slow
@export var slow_duration: float = 0.0  # Duration in seconds
@export var burn_on_hit: bool = false  # Attacks apply burn DoT
@export var burn_damage_per_second: float = 0.0  # Burn damage per second
@export var burn_duration: float = 0.0  # Burn duration in seconds

# Visual feedback
@export_group("Visual")
@export var display_color: Color = Color.WHITE

func can_be_offered(player: Node = null) -> bool:
	"""Check if this upgrade can be offered to the player"""
	# One-time upgrades (max_stacks = 0): Can't offer if already picked
	if max_stacks == 0 and current_stacks > 0:
		return false

	# Stackable upgrades (max_stacks > 0): Can't offer if at max stacks
	if max_stacks > 0 and current_stacks >= max_stacks:
		return false

	# WEAPON UPGRADES: Only offer if player has the weapon
	if upgrade_type == UpgradeType.WEAPON_UPGRADE:
		if not player:
			return false  # Need player reference to check weapons

		var weapon_manager = player.get_node_or_null("WeaponManager")
		if not weapon_manager:
			return false

		# Check if player has this weapon equipped
		var has_weapon = false
		for weapon in weapon_manager.equipped_weapons:
			if "weapon_data" in weapon and weapon.weapon_data:
				if weapon.weapon_data.weapon_name == target_weapon_id:
					has_weapon = true
					break

		if not has_weapon:
			return false  # Don't offer upgrades for weapons player doesn't have

	# NEW WEAPON: Don't offer if player already has this weapon
	if upgrade_type == UpgradeType.NEW_WEAPON:
		if not player:
			return false  # Need player reference to check weapons

		var weapon_manager = player.get_node_or_null("WeaponManager")
		if not weapon_manager:
			return false

		# Check if player already has this weapon equipped
		for weapon in weapon_manager.equipped_weapons:
			# Compare by scene path
			if weapon.scene_file_path == weapon_scene_path:
				return false  # Player already has this weapon, don't offer it

		# Also check by weapon name (more reliable)
		var weapon_name = upgrade_name  # Use upgrade name as weapon identifier
		for weapon in weapon_manager.equipped_weapons:
			if "weapon_data" in weapon and weapon.weapon_data:
				if weapon.weapon_data.weapon_name == weapon_name:
					return false  # Player already has this weapon

	return true

func apply_upgrade(player: Node) -> void:
	"""Apply this upgrade's effects to the player"""
	if not player:
		push_error("UpgradeData.apply_upgrade: Invalid player reference!")
		return

	current_stacks += 1

	match upgrade_type:
		UpgradeType.STAT_BOOST:
			_apply_stat_boost(player)
		UpgradeType.WEAPON_UPGRADE:
			_apply_weapon_upgrade(player)
		UpgradeType.NEW_WEAPON:
			_apply_weapon_unlock(player)
		UpgradeType.PASSIVE_ABILITY:
			_apply_passive_ability(player)

	print("Applied upgrade: ", upgrade_name, " (Stack: ", current_stacks, ")")

func _apply_stat_boost(player: Node) -> void:
	"""Apply stat boost to player"""
	if health_bonus > 0:
		if player.has_method("heal"):
			player.heal(health_bonus)

	if max_health_bonus > 0:
		var old_max_health = player.max_health
		player.max_health += max_health_bonus
		print("  +", max_health_bonus, " Max Health")
		DebugLogger.log("player_stats", "Max health: %s → %s" % [old_max_health, player.max_health])

	if move_speed_multiplier != 1.0:
		var old_speed = player.move_speed
		player.move_speed *= move_speed_multiplier
		print("  Move speed now: ", player.move_speed)
		DebugLogger.log("player_stats", "Move speed: %s → %s (multiplier: %s)" % [old_speed, player.move_speed, move_speed_multiplier])

	if pickup_range_bonus > 0:
		var old_range = player.pickup_range
		player.pickup_range += pickup_range_bonus
		print("  +", pickup_range_bonus, "m Pickup Range")
		DebugLogger.log("player_stats", "Pickup range: %s → %s" % [old_range, player.pickup_range])

	if base_damage_bonus > 0:
		# This would apply to all weapons via a damage multiplier
		if player.has_method("add_base_damage"):
			player.add_base_damage(base_damage_bonus)
		print("  +", base_damage_bonus, " Base Damage")

	if crit_chance_bonus > 0:
		var old_crit = player.crit_chance
		player.crit_chance += crit_chance_bonus
		print("  +", crit_chance_bonus * 100, "% Crit Chance")
		DebugLogger.log("player_stats", "Crit chance: %s → %s" % [old_crit, player.crit_chance])

	if attack_speed_multiplier != 1.0:
		if player.has_method("apply_attack_speed_multiplier"):
			player.apply_attack_speed_multiplier(attack_speed_multiplier)
			print("  +", (attack_speed_multiplier - 1.0) * 100, "% Attack Speed")

	if base_damage_multiplier != 1.0:
		if player.has_method("apply_damage_multiplier"):
			player.apply_damage_multiplier(base_damage_multiplier)
			print("  +", (base_damage_multiplier - 1.0) * 100, "% Damage to all weapons")

func _apply_weapon_upgrade(player: Node) -> void:
	"""Apply weapon-specific upgrades"""
	DebugLogger.log("upgrades", "_apply_weapon_upgrade called for: " + upgrade_name)
	DebugLogger.log("upgrades", "target_weapon_id = " + target_weapon_id)

	var weapon_manager = player.get_node_or_null("WeaponManager")
	if not weapon_manager:
		push_warning("WeaponManager not found on player!")
		return

	DebugLogger.log("upgrades", "WeaponManager found, equipped weapons: " + str(weapon_manager.equipped_weapons.size()))

	# Handle global weapon upgrades (apply to ALL weapons)
	if global_projectile_bonus > 0:
		for weapon in weapon_manager.equipped_weapons:
			if "projectile_count" in weapon:
				weapon.projectile_count += global_projectile_bonus
				if weapon.weapon_data:
					weapon.weapon_data.projectile_count = weapon.projectile_count
				DebugLogger.log("upgrades", "  Global projectile bonus: " + weapon.name + " projectile count increased")
		print("  +", global_projectile_bonus, " projectile to all ranged weapons")
		return  # Don't continue to specific weapon upgrade

	if weapon_pierce:
		for weapon in weapon_manager.equipped_weapons:
			if "pierces_enemies" in weapon:
				weapon.pierces_enemies = true
				DebugLogger.log("upgrades", "  Pierce enabled for: " + weapon.name)
		print("  Projectiles now pierce through enemies")
		return

	# Continue with specific weapon targeting if target_weapon_id is set
	if target_weapon_id.is_empty():
		return  # No specific weapon to target

	# Find the target weapon
	var found_weapon = false
	for weapon in weapon_manager.equipped_weapons:
		DebugLogger.log("upgrades", "Checking weapon: " + weapon.name)
		if "weapon_data" in weapon:
			if weapon.weapon_data:
				DebugLogger.log("upgrades", "  weapon_data.weapon_name = " + weapon.weapon_data.weapon_name)
		else:
			DebugLogger.log("upgrades", "  NO weapon_data property!")

		if "weapon_data" in weapon and weapon.weapon_data and weapon.weapon_data.weapon_name == target_weapon_id:
			found_weapon = true
			DebugLogger.log("upgrades", "FOUND MATCHING WEAPON!")

			# Apply upgrades
			if weapon_damage_multiplier != 1.0:
				var old_damage = weapon.damage
				weapon.damage *= weapon_damage_multiplier
				# BUG FIX: WEAPON-001 - Also update weapon_data.base_damage to persist upgrade
				# Previous behavior: Only updated weapon.damage, which got overwritten on reload
				# Fixed behavior: Update both instance damage AND weapon_data so upgrades persist
				# Date: 2025-10-19
				if weapon.weapon_data:
					weapon.weapon_data.base_damage = weapon.damage
				DebugLogger.log("upgrades", "  " + target_weapon_id + " damage: " + str(old_damage) + " → " + str(weapon.damage))

			if weapon_speed_multiplier != 1.0:
				if "orbit_speed" in weapon:
					var old_speed = weapon.orbit_speed
					weapon.orbit_speed *= weapon_speed_multiplier
					DebugLogger.log("upgrades", "  " + target_weapon_id + " orbit speed: " + str(old_speed) + " → " + str(weapon.orbit_speed))
				elif "attack_cooldown" in weapon:
					var old_cooldown = weapon.attack_cooldown
					weapon.attack_cooldown /= weapon_speed_multiplier
					# BUG FIX: WEAPON-001 - Also update weapon_data.attack_cooldown to persist upgrade
					if weapon.weapon_data:
						weapon.weapon_data.attack_cooldown = weapon.attack_cooldown
					DebugLogger.log("upgrades", "  " + target_weapon_id + " cooldown: " + str(old_cooldown) + " → " + str(weapon.attack_cooldown))

			if weapon_size_multiplier != 1.0:
				weapon.scale *= weapon_size_multiplier
				DebugLogger.log("upgrades", "  " + target_weapon_id + " size increased by " + str((weapon_size_multiplier - 1.0) * 100) + "%")

			if weapon_cooldown_multiplier != 1.0:
				if "attack_cooldown" in weapon:
					var old_cooldown = weapon.attack_cooldown
					weapon.attack_cooldown *= weapon_cooldown_multiplier
					# BUG FIX: WEAPON-001 - Also update weapon_data.attack_cooldown to persist upgrade
					if weapon.weapon_data:
						weapon.weapon_data.attack_cooldown = weapon.attack_cooldown
					DebugLogger.log("upgrades", "  " + target_weapon_id + " cooldown: " + str(old_cooldown) + " → " + str(weapon.attack_cooldown) + "s")

			if weapon_range_multiplier != 1.0:
				if "attack_range" in weapon:
					var old_range = weapon.attack_range
					weapon.attack_range *= weapon_range_multiplier
					# BUG FIX: WEAPON-001 - Also update weapon_data.attack_range to persist upgrade
					if weapon.weapon_data:
						weapon.weapon_data.attack_range = weapon.attack_range
					DebugLogger.log("upgrades", "  " + target_weapon_id + " range: " + str(old_range) + " → " + str(weapon.attack_range) + "m")

			if weapon_projectile_count_bonus > 0:
				if "projectile_count" in weapon:
					var old_count = weapon.projectile_count
					weapon.projectile_count += weapon_projectile_count_bonus
					# BUG FIX: WEAPON-001 - Also update weapon_data.projectile_count to persist upgrade
					if weapon.weapon_data:
						weapon.weapon_data.projectile_count = weapon.projectile_count
					DebugLogger.log("upgrades", "  " + target_weapon_id + " projectile count: " + str(old_count) + " → " + str(weapon.projectile_count))

			if weapon_count_bonus > 0:
				# Duplicate the weapon (spawn another instance)
				DebugLogger.log("upgrades", "weapon_count_bonus = " + str(weapon_count_bonus))
				DebugLogger.log("upgrades", "  +" + str(weapon_count_bonus) + " " + target_weapon_id)
				_duplicate_weapon(weapon, weapon_manager, weapon_count_bonus)

			# IMPORTANT: Break after upgrading first matching weapon
			# Otherwise we'll upgrade ALL weapons with this name (including newly spawned ones!)
			break

	if not found_weapon:
		DebugLogger.log("upgrades", "ERROR - Did not find weapon matching '" + target_weapon_id + "'")

func _apply_weapon_unlock(player: Node) -> void:
	"""Unlock and equip a new weapon"""
	if weapon_scene_path.is_empty():
		push_error("No weapon scene path specified!")
		return

	var weapon_manager = player.get_node_or_null("WeaponManager")
	if not weapon_manager:
		push_warning("WeaponManager not found on player!")
		return

	# Load and equip the weapon
	var weapon_scene = load(weapon_scene_path)
	if weapon_scene:
		var weapon_instance = weapon_scene.instantiate()
		weapon_manager.equip_weapon(weapon_instance)
		print("  Unlocked weapon: ", upgrade_name)
		EventBus.weapon_unlocked.emit(upgrade_id)
	else:
		push_error("Failed to load weapon scene: ", weapon_scene_path)

func _apply_passive_ability(player: Node) -> void:
	"""Apply passive ability effects"""
	if hp_regen_per_second > 0:
		# Add HP regen (would need a timer system on player)
		if player.has_method("add_hp_regen"):
			player.add_hp_regen(hp_regen_per_second)
		print("  +", hp_regen_per_second, " HP/sec regeneration")

	if xp_magnet_range_bonus > 0:
		var old_range = player.pickup_range
		player.pickup_range += xp_magnet_range_bonus
		print("  +", xp_magnet_range_bonus, "m XP Magnet Range")
		DebugLogger.log("player_stats", "XP Magnet range (pickup_range): %s → %s" % [old_range, player.pickup_range])

	if knockback_on_hit:
		# Enable knockback on player
		if "knockback_enabled" in player:
			player.knockback_enabled = true
			player.knockback_force = knockback_force
			print("  Knockback on hit enabled (force: ", knockback_force, ")")
			DebugLogger.log("player_stats", "Knockback enabled: force=%s" % knockback_force)
		else:
			push_warning("Player doesn't have knockback properties!")

	if lifesteal_percent > 0:
		if "lifesteal_percent" in player:
			player.lifesteal_percent += lifesteal_percent
			print("  +", lifesteal_percent * 100, "% Lifesteal")

	if thorns_damage_percent > 0:
		if "thorns_damage_percent" in player:
			player.thorns_damage_percent += thorns_damage_percent
			print("  +", thorns_damage_percent * 100, "% Thorns Damage")

	if dodge_chance > 0:
		if "dodge_chance" in player:
			player.dodge_chance += dodge_chance
			print("  +", dodge_chance * 100, "% Dodge Chance")

	if second_wind:
		if "has_second_wind" in player:
			player.has_second_wind = true
			print("  Second Wind enabled (revive once at 50% HP)")

	if gold_drop_multiplier != 1.0:
		if "gold_drop_multiplier" in player:
			player.gold_drop_multiplier *= gold_drop_multiplier
			print("  +", (gold_drop_multiplier - 1.0) * 100, "% Gold/Essence drops")

	if xp_gain_multiplier != 1.0:
		if "xp_multiplier" in player:
			player.xp_multiplier *= xp_gain_multiplier
			print("  +", (xp_gain_multiplier - 1.0) * 100, "% XP gain")

	if explosion_on_kill:
		if "explosion_on_kill" in player:
			player.explosion_on_kill = true
			player.explosion_damage = explosion_damage
			player.explosion_radius = explosion_radius
			print("  Enemies explode on death (", explosion_damage, " damage, ", explosion_radius, "m radius)")

	if slow_on_hit:
		if "slow_on_hit" in player:
			player.slow_on_hit = true
			player.slow_percent = slow_percent
			player.slow_duration = slow_duration
			print("  Attacks slow enemies by ", slow_percent * 100, "% for ", slow_duration, "s")

	if burn_on_hit:
		if "burn_on_hit" in player:
			player.burn_on_hit = true
			player.burn_damage_per_second = burn_damage_per_second
			player.burn_duration = burn_duration
			print("  Attacks apply burn (", burn_damage_per_second, " damage/sec for ", burn_duration, "s)")

func _duplicate_weapon(original_weapon: Node, weapon_manager: Node, count: int) -> void:
	"""Duplicate a weapon to spawn additional instances"""
	print("DEBUG: _duplicate_weapon called - duplicating ", count, " times")
	print("DEBUG: Original weapon: ", original_weapon.name)

	for i in range(count):
		# Get the weapon's scene path
		var weapon_scene_path = original_weapon.scene_file_path
		print("DEBUG: scene_file_path = ", weapon_scene_path)

		if weapon_scene_path.is_empty():
			push_warning("Cannot duplicate weapon: no scene_file_path")
			# Try alternative: duplicate the node directly
			print("DEBUG: Trying direct duplication instead")
			var new_weapon = original_weapon.duplicate()
			if new_weapon:
				weapon_manager.add_weapon_instance(new_weapon)
				print("DEBUG: Successfully duplicated weapon directly")
			return

		# Load and instantiate the weapon scene
		var weapon_scene = load(weapon_scene_path)
		if not weapon_scene:
			push_error("Failed to load weapon scene: ", weapon_scene_path)
			return

		var new_weapon = weapon_scene.instantiate()

		# Copy current stats from original weapon (including all upgrades)
		if "damage" in new_weapon:
			new_weapon.damage = original_weapon.damage
		if "orbit_speed" in new_weapon:
			new_weapon.orbit_speed = original_weapon.orbit_speed
		if "orbit_radius" in new_weapon:
			new_weapon.orbit_radius = original_weapon.orbit_radius

		# CRITICAL: Sync orbit_angle with existing weapons so they stay in sync
		if "orbit_angle" in new_weapon and "orbit_angle" in original_weapon:
			new_weapon.orbit_angle = original_weapon.orbit_angle
			print("DEBUG: Synced orbit_angle = ", new_weapon.orbit_angle)

		# Add to weapon manager first (so it's counted in redistribution)
		weapon_manager.add_weapon_instance(new_weapon)

	# REDISTRIBUTE ALL weapons of this type evenly
	_redistribute_weapons(original_weapon.weapon_data.weapon_name, weapon_manager)

func _redistribute_weapons(weapon_name: String, weapon_manager: Node) -> void:
	"""Redistribute all weapons of the same type evenly around the player"""
	print("DEBUG: _redistribute_weapons called for '", weapon_name, "'")
	print("DEBUG: Total equipped weapons: ", weapon_manager.equipped_weapons.size())

	# Find all weapons with this name
	var weapons_of_type: Array = []
	for weapon in weapon_manager.equipped_weapons:
		print("DEBUG: Checking weapon: ", weapon.name if weapon else "null")
		if "weapon_data" in weapon:
			if weapon.weapon_data:
				print("DEBUG:   Has weapon_data, name = ", weapon.weapon_data.weapon_name)
				if weapon.weapon_data.weapon_name == weapon_name:
					weapons_of_type.append(weapon)
					print("DEBUG:   MATCH! Added to redistribution list")
			else:
				print("DEBUG:   Has weapon_data property but it's null")
		else:
			print("DEBUG:   No weapon_data property")

	var total_count = weapons_of_type.size()
	print("DEBUG: Found ", total_count, " weapons to redistribute")

	if total_count == 0:
		print("DEBUG: ERROR - No weapons found for redistribution!")
		return

	print("🔄 REDISTRIBUTING ", total_count, " weapons of type '", weapon_name, "' evenly")

	# Distribute evenly around circle
	for i in range(total_count):
		var angle_offset = (TAU / total_count) * i
		print("  Setting weapon[", i, "].angle_offset = ", rad_to_deg(angle_offset), "°")
		if "angle_offset" in weapons_of_type[i]:
			var old_offset = weapons_of_type[i].angle_offset
			weapons_of_type[i].angle_offset = angle_offset
			print("    ✓ Changed from ", rad_to_deg(old_offset), "° to ", rad_to_deg(angle_offset), "°")
		else:
			print("    ✗ ERROR: Weapon doesn't have angle_offset property!")

func get_display_text() -> String:
	"""Get formatted text for UI display"""
	var text = "[b]" + upgrade_name + "[/b]\n"
	text += description
	if current_stacks > 0:
		text += "\n[i](Level " + str(current_stacks) + ")"
		if max_stacks > 0:
			text += "/" + str(max_stacks)
		text += "[/i]"
	return text
