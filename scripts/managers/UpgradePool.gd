extends Node
class_name UpgradePool
## Manages the pool of available upgrades and selects random options for player

# ============================================================================
# DEBUG TESTING MODE - Force specific upgrades to appear
# ============================================================================
const DEBUG_TEST_MODE: bool = false  # Set to false for random upgrades
# Specify upgrade IDs to force (empty array = random)
const DEBUG_FORCED_UPGRADES: Array[String] = [
	"passive_hp_regen",    # Regeneration (1 HP/s)
	"passive_xp_magnet",   # XP Magnet (+2m range)
	"passive_knockback"    # Knockback (push enemies on hit)
]

# Pool of all upgrade definitions
var all_upgrades: Array[UpgradeData] = []

# Upgrades that have been unlocked (can appear in pool)
var unlocked_upgrades: Array[UpgradeData] = []

# Upgrades currently applied to player
var active_upgrades: Dictionary = {}  # upgrade_id: UpgradeData

func _ready() -> void:
	# Load all upgrade definitions
	_initialize_upgrade_pool()
	print("UpgradePool initialized with ", all_upgrades.size(), " upgrades")

	# DEBUG: Print all upgrade IDs
	print("DEBUG: Available upgrade IDs:")
	for upgrade in all_upgrades:
		print("  - ", upgrade.upgrade_id, " (", upgrade.upgrade_name, ")")

func _initialize_upgrade_pool() -> void:
	"""Load all upgrade .tres files from resources/upgrades/"""
	# For now, create upgrades programmatically
	# In the future, load from .tres files in resources/upgrades/
	_create_default_upgrades()

func _create_default_upgrades() -> void:
	"""Create default upgrade set (will be replaced by .tres files)"""

	# === STAT BOOSTS ===

	# Max Health +20
	var health_upgrade = UpgradeData.new()
	health_upgrade.upgrade_id = "stat_max_health"
	health_upgrade.upgrade_name = "Vitality Boost"
	health_upgrade.description = "Increase maximum health by 20"
	health_upgrade.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	health_upgrade.rarity = UpgradeData.UpgradeRarity.COMMON
	health_upgrade.max_stacks = 5
	health_upgrade.max_health_bonus = 20.0
	health_upgrade.health_bonus = 20.0  # Also heal on pickup
	all_upgrades.append(health_upgrade)

	# Move Speed +10%
	var speed_upgrade = UpgradeData.new()
	speed_upgrade.upgrade_id = "stat_move_speed"
	speed_upgrade.upgrade_name = "Swift Feet"
	speed_upgrade.description = "Increase movement speed by 10%"
	speed_upgrade.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	speed_upgrade.rarity = UpgradeData.UpgradeRarity.COMMON
	speed_upgrade.max_stacks = 3
	speed_upgrade.move_speed_multiplier = 1.1  # +10%
	all_upgrades.append(speed_upgrade)

	# Pickup Range +1m
	var range_upgrade = UpgradeData.new()
	range_upgrade.upgrade_id = "stat_pickup_range"
	range_upgrade.upgrade_name = "Magnet Field"
	range_upgrade.description = "Increase XP pickup range by 1 meter"
	range_upgrade.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	range_upgrade.rarity = UpgradeData.UpgradeRarity.COMMON
	range_upgrade.max_stacks = 4
	range_upgrade.pickup_range_bonus = 1.0
	all_upgrades.append(range_upgrade)

	# Base Damage +5
	var damage_upgrade = UpgradeData.new()
	damage_upgrade.upgrade_id = "stat_base_damage"
	damage_upgrade.upgrade_name = "Power Up"
	damage_upgrade.description = "Increase base damage by 5"
	damage_upgrade.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	damage_upgrade.rarity = UpgradeData.UpgradeRarity.RARE
	damage_upgrade.max_stacks = 5
	damage_upgrade.base_damage_bonus = 5.0
	all_upgrades.append(damage_upgrade)

	# === NEW STAT BOOSTS (MVP Phase) ===

	# 1. Thick Skin (+25 Max HP)
	var thick_skin = UpgradeData.new()
	thick_skin.upgrade_id = "stat_thick_skin"
	thick_skin.upgrade_name = "Thick Skin"
	thick_skin.description = "Increase maximum health by 25"
	thick_skin.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	thick_skin.rarity = UpgradeData.UpgradeRarity.COMMON
	thick_skin.max_stacks = 5
	thick_skin.max_health_bonus = 25.0
	all_upgrades.append(thick_skin)

	# 2. Speed Boots (+15% Movement Speed)
	var speed_boots = UpgradeData.new()
	speed_boots.upgrade_id = "stat_speed_boots"
	speed_boots.upgrade_name = "Speed Boots"
	speed_boots.description = "Increase movement speed by 15%"
	speed_boots.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	speed_boots.rarity = UpgradeData.UpgradeRarity.COMMON
	speed_boots.max_stacks = 3
	speed_boots.move_speed_multiplier = 1.15  # +15%
	all_upgrades.append(speed_boots)

	# 3. Eagle Eye (+10% Crit Chance)
	var eagle_eye = UpgradeData.new()
	eagle_eye.upgrade_id = "stat_eagle_eye"
	eagle_eye.upgrade_name = "Eagle Eye"
	eagle_eye.description = "Increase critical hit chance by 10%"
	eagle_eye.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	eagle_eye.rarity = UpgradeData.UpgradeRarity.RARE
	eagle_eye.max_stacks = 3
	eagle_eye.crit_chance_bonus = 0.10  # +10%
	all_upgrades.append(eagle_eye)

	# 4. Heavy Hitter (+20% Base Damage to all weapons)
	var heavy_hitter = UpgradeData.new()
	heavy_hitter.upgrade_id = "stat_heavy_hitter"
	heavy_hitter.upgrade_name = "Heavy Hitter"
	heavy_hitter.description = "All weapons deal 20% more damage"
	heavy_hitter.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	heavy_hitter.rarity = UpgradeData.UpgradeRarity.EPIC
	heavy_hitter.max_stacks = 3
	heavy_hitter.base_damage_multiplier = 1.20  # +20%
	all_upgrades.append(heavy_hitter)

	# 5. Quick Reflexes (+20% Attack Speed)
	var quick_reflexes = UpgradeData.new()
	quick_reflexes.upgrade_id = "stat_quick_reflexes"
	quick_reflexes.upgrade_name = "Quick Reflexes"
	quick_reflexes.description = "Attack 20% faster (reduced cooldowns)"
	quick_reflexes.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	quick_reflexes.rarity = UpgradeData.UpgradeRarity.RARE
	quick_reflexes.max_stacks = 3
	quick_reflexes.attack_speed_multiplier = 1.20  # +20% attack speed
	all_upgrades.append(quick_reflexes)

	# 6. Magnetism (+30% XP Pickup Range)
	var magnetism = UpgradeData.new()
	magnetism.upgrade_id = "stat_magnetism"
	magnetism.upgrade_name = "Magnetism"
	magnetism.description = "Increase XP pickup range by 30%"
	magnetism.upgrade_type = UpgradeData.UpgradeType.STAT_BOOST
	magnetism.rarity = UpgradeData.UpgradeRarity.COMMON
	magnetism.max_stacks = 4
	magnetism.pickup_range_bonus = 1.5  # +1.5m (roughly 30% of base 5m)
	all_upgrades.append(magnetism)

	# === BONK HAMMER UPGRADES ===

	# Bonk Hammer Damage +25%
	var bonk_damage = UpgradeData.new()
	bonk_damage.upgrade_id = "bonk_damage"
	bonk_damage.upgrade_name = "Heavier Bonk"
	bonk_damage.description = "Bonk Hammer deals 25% more damage"
	bonk_damage.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	bonk_damage.rarity = UpgradeData.UpgradeRarity.COMMON
	bonk_damage.max_stacks = 4
	bonk_damage.target_weapon_id = "Bonk Hammer"
	bonk_damage.weapon_damage_multiplier = 1.25
	all_upgrades.append(bonk_damage)

	# Bonk Hammer Speed +15%
	var bonk_speed = UpgradeData.new()
	bonk_speed.upgrade_id = "bonk_speed"
	bonk_speed.upgrade_name = "Faster Bonk"
	bonk_speed.description = "Bonk Hammer orbits 15% faster"
	bonk_speed.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	bonk_speed.rarity = UpgradeData.UpgradeRarity.COMMON
	bonk_speed.max_stacks = 3
	bonk_speed.target_weapon_id = "Bonk Hammer"
	bonk_speed.weapon_speed_multiplier = 1.15
	all_upgrades.append(bonk_speed)

	# Bonk Hammer Size +30%
	var bonk_size = UpgradeData.new()
	bonk_size.upgrade_id = "bonk_size"
	bonk_size.upgrade_name = "Bigger Bonk"
	bonk_size.description = "Bonk Hammer is 30% larger"
	bonk_size.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	bonk_size.rarity = UpgradeData.UpgradeRarity.RARE
	bonk_size.max_stacks = 3
	bonk_size.target_weapon_id = "Bonk Hammer"
	bonk_size.weapon_size_multiplier = 1.3
	all_upgrades.append(bonk_size)

	# Additional Bonk Hammer
	var bonk_count = UpgradeData.new()
	bonk_count.upgrade_id = "bonk_count"
	bonk_count.upgrade_name = "Double Bonk"
	bonk_count.description = "Add another Bonk Hammer orbiting you"
	bonk_count.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	bonk_count.rarity = UpgradeData.UpgradeRarity.EPIC
	bonk_count.max_stacks = 2
	bonk_count.target_weapon_id = "Bonk Hammer"
	bonk_count.weapon_count_bonus = 1
	all_upgrades.append(bonk_count)

	# === MAGIC MISSILE UPGRADES ===

	# Magic Missile Damage +25%
	var missile_damage = UpgradeData.new()
	missile_damage.upgrade_id = "missile_damage"
	missile_damage.upgrade_name = "Power Missile"
	missile_damage.description = "Magic Missile deals 25% more damage"
	missile_damage.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	missile_damage.rarity = UpgradeData.UpgradeRarity.COMMON
	missile_damage.max_stacks = 4
	missile_damage.target_weapon_id = "Magic Missile"
	missile_damage.weapon_damage_multiplier = 1.25
	all_upgrades.append(missile_damage)

	# Magic Missile Cooldown -20%
	var missile_cooldown = UpgradeData.new()
	missile_cooldown.upgrade_id = "missile_cooldown"
	missile_cooldown.upgrade_name = "Rapid Fire"
	missile_cooldown.description = "Magic Missile fires 20% faster"
	missile_cooldown.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	missile_cooldown.rarity = UpgradeData.UpgradeRarity.COMMON
	missile_cooldown.max_stacks = 3
	missile_cooldown.target_weapon_id = "Magic Missile"
	missile_cooldown.weapon_cooldown_multiplier = 0.8  # 0.8 = -20%
	all_upgrades.append(missile_cooldown)

	# Magic Missile Projectile Count +1
	var missile_count = UpgradeData.new()
	missile_count.upgrade_id = "missile_projectile_count"
	missile_count.upgrade_name = "Multi-Missile"
	missile_count.description = "Fire an additional projectile"
	missile_count.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	missile_count.rarity = UpgradeData.UpgradeRarity.EPIC
	missile_count.max_stacks = 2
	missile_count.target_weapon_id = "Magic Missile"
	missile_count.weapon_projectile_count_bonus = 1
	all_upgrades.append(missile_count)

	# Magic Missile Range +30%
	var missile_range = UpgradeData.new()
	missile_range.upgrade_id = "missile_range"
	missile_range.upgrade_name = "Long Range Missile"
	missile_range.description = "Increase Magic Missile range by 30%"
	missile_range.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	missile_range.rarity = UpgradeData.UpgradeRarity.RARE
	missile_range.max_stacks = 2
	missile_range.target_weapon_id = "Magic Missile"
	missile_range.weapon_range_multiplier = 1.3
	all_upgrades.append(missile_range)

	# === SPINNING BLADE UPGRADES ===

	# Spinning Blade Damage +25%
	var blade_damage = UpgradeData.new()
	blade_damage.upgrade_id = "blade_damage"
	blade_damage.upgrade_name = "Sharper Blade"
	blade_damage.description = "Spinning Blade deals 25% more damage"
	blade_damage.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	blade_damage.rarity = UpgradeData.UpgradeRarity.COMMON
	blade_damage.max_stacks = 4
	blade_damage.target_weapon_id = "Spinning Blade"
	blade_damage.weapon_damage_multiplier = 1.25
	all_upgrades.append(blade_damage)

	# Spinning Blade Speed +20%
	var blade_speed = UpgradeData.new()
	blade_speed.upgrade_id = "blade_speed"
	blade_speed.upgrade_name = "Faster Spin"
	blade_speed.description = "Spinning Blade orbits 20% faster"
	blade_speed.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	blade_speed.rarity = UpgradeData.UpgradeRarity.COMMON
	blade_speed.max_stacks = 3
	blade_speed.target_weapon_id = "Spinning Blade"
	blade_speed.weapon_speed_multiplier = 1.2
	all_upgrades.append(blade_speed)

	# Spinning Blade Size +30%
	var blade_size = UpgradeData.new()
	blade_size.upgrade_id = "blade_size"
	blade_size.upgrade_name = "Bigger Blade"
	blade_size.description = "Spinning Blade is 30% larger"
	blade_size.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	blade_size.rarity = UpgradeData.UpgradeRarity.RARE
	blade_size.max_stacks = 3
	blade_size.target_weapon_id = "Spinning Blade"
	blade_size.weapon_size_multiplier = 1.3
	all_upgrades.append(blade_size)

	# Additional Spinning Blade
	var blade_count = UpgradeData.new()
	blade_count.upgrade_id = "blade_count"
	blade_count.upgrade_name = "Double Blade"
	blade_count.description = "Add another Spinning Blade orbiting you"
	blade_count.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	blade_count.rarity = UpgradeData.UpgradeRarity.EPIC
	blade_count.max_stacks = 2
	blade_count.target_weapon_id = "Spinning Blade"
	blade_count.weapon_count_bonus = 1
	all_upgrades.append(blade_count)

	# === NEW WEAPON UPGRADES (MVP Phase) ===

	# 7. Multishot (+1 Projectile for ranged weapons)
	var multishot = UpgradeData.new()
	multishot.upgrade_id = "weapon_multishot"
	multishot.upgrade_name = "Multishot"
	multishot.description = "All ranged weapons fire +1 additional projectile"
	multishot.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	multishot.rarity = UpgradeData.UpgradeRarity.EPIC
	multishot.max_stacks = 2
	multishot.global_projectile_bonus = 1
	all_upgrades.append(multishot)

	# 8. Piercing Rounds (projectiles pierce enemies)
	var piercing = UpgradeData.new()
	piercing.upgrade_id = "weapon_piercing"
	piercing.upgrade_name = "Piercing Rounds"
	piercing.description = "Projectiles pierce through enemies"
	piercing.upgrade_type = UpgradeData.UpgradeType.WEAPON_UPGRADE
	piercing.rarity = UpgradeData.UpgradeRarity.LEGENDARY
	piercing.max_stacks = 0  # One-time unlock
	piercing.weapon_pierce = true
	all_upgrades.append(piercing)

	# 9. Explosive Finale (enemies explode on death)
	var explosive = UpgradeData.new()
	explosive.upgrade_id = "passive_explosive"
	explosive.upgrade_name = "Explosive Finale"
	explosive.description = "Enemies explode on death, dealing area damage"
	explosive.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	explosive.rarity = UpgradeData.UpgradeRarity.EPIC
	explosive.max_stacks = 2
	explosive.explosion_on_kill = true
	explosive.explosion_damage = 15.0
	explosive.explosion_radius = 3.0
	all_upgrades.append(explosive)

	# 10. Vampiric Weapons (5% lifesteal)
	var vampiric = UpgradeData.new()
	vampiric.upgrade_id = "passive_vampiric"
	vampiric.upgrade_name = "Vampiric Weapons"
	vampiric.description = "Heal for 5% of damage dealt"
	vampiric.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	vampiric.rarity = UpgradeData.UpgradeRarity.LEGENDARY
	vampiric.max_stacks = 2
	vampiric.lifesteal_percent = 0.05  # 5%
	all_upgrades.append(vampiric)

	# 11. Freezing Touch (attacks slow enemies)
	var freezing = UpgradeData.new()
	freezing.upgrade_id = "passive_freezing"
	freezing.upgrade_name = "Freezing Touch"
	freezing.description = "Attacks slow enemies by 30% for 1.5 seconds"
	freezing.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	freezing.rarity = UpgradeData.UpgradeRarity.RARE
	freezing.max_stacks = 2
	freezing.slow_on_hit = true
	freezing.slow_percent = 0.30  # 30%
	freezing.slow_duration = 1.5
	all_upgrades.append(freezing)

	# 12. Burning Passion (attacks apply burn DoT)
	var burning = UpgradeData.new()
	burning.upgrade_id = "passive_burning"
	burning.upgrade_name = "Burning Passion"
	burning.description = "Attacks apply burn: 5 damage/sec for 3 seconds"
	burning.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	burning.rarity = UpgradeData.UpgradeRarity.RARE
	burning.max_stacks = 3
	burning.burn_on_hit = true
	burning.burn_damage_per_second = 5.0
	burning.burn_duration = 3.0
	all_upgrades.append(burning)

	# === NEW WEAPONS ===

	# Magic Missile (will be created in Phase 3C)
	var magic_missile = UpgradeData.new()
	magic_missile.upgrade_id = "weapon_magic_missile"
	magic_missile.upgrade_name = "Magic Missile"
	magic_missile.description = "Unlock Magic Missile - homing projectiles that track enemies"
	magic_missile.upgrade_type = UpgradeData.UpgradeType.NEW_WEAPON
	magic_missile.rarity = UpgradeData.UpgradeRarity.RARE
	magic_missile.max_stacks = 0  # One-time unlock
	magic_missile.weapon_scene_path = "res://scenes/weapons/MagicMissile.tscn"
	all_upgrades.append(magic_missile)

	# Spinning Blade (will be created in Phase 3C)
	var spinning_blade = UpgradeData.new()
	spinning_blade.upgrade_id = "weapon_spinning_blade"
	spinning_blade.upgrade_name = "Spinning Blade"
	spinning_blade.description = "Unlock Spinning Blade - fast orbital weapon with wide reach"
	spinning_blade.upgrade_type = UpgradeData.UpgradeType.NEW_WEAPON
	spinning_blade.rarity = UpgradeData.UpgradeRarity.RARE
	spinning_blade.max_stacks = 0  # One-time unlock
	spinning_blade.weapon_scene_path = "res://scenes/weapons/SpinningBlade.tscn"
	all_upgrades.append(spinning_blade)

	# === PASSIVE ABILITIES ===

	# HP Regeneration
	var hp_regen = UpgradeData.new()
	hp_regen.upgrade_id = "passive_hp_regen"
	hp_regen.upgrade_name = "Regeneration"
	hp_regen.description = "Recover 1 HP per second"
	hp_regen.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	hp_regen.rarity = UpgradeData.UpgradeRarity.RARE
	hp_regen.max_stacks = 3
	hp_regen.hp_regen_per_second = 1.0
	all_upgrades.append(hp_regen)

	# XP Magnet Range
	var xp_magnet = UpgradeData.new()
	xp_magnet.upgrade_id = "passive_xp_magnet"
	xp_magnet.upgrade_name = "XP Magnet"
	xp_magnet.description = "Increase XP magnet range by 2 meters"
	xp_magnet.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	xp_magnet.rarity = UpgradeData.UpgradeRarity.COMMON
	xp_magnet.max_stacks = 4
	xp_magnet.xp_magnet_range_bonus = 2.0
	all_upgrades.append(xp_magnet)

	# Knockback on Hit
	var knockback = UpgradeData.new()
	knockback.upgrade_id = "passive_knockback"
	knockback.upgrade_name = "Knockback"
	knockback.description = "Enemies are pushed back when you hit them"
	knockback.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	knockback.rarity = UpgradeData.UpgradeRarity.EPIC
	knockback.max_stacks = 0  # One-time unlock
	knockback.knockback_on_hit = true
	knockback.knockback_force = 5.0
	all_upgrades.append(knockback)

	# === NEW PASSIVE ABILITIES (MVP Phase) ===

	# 13. Thorns (reflect 10% damage)
	var thorns = UpgradeData.new()
	thorns.upgrade_id = "passive_thorns"
	thorns.upgrade_name = "Thorns"
	thorns.description = "Reflect 10% of received damage back to attacker"
	thorns.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	thorns.rarity = UpgradeData.UpgradeRarity.RARE
	thorns.max_stacks = 3
	thorns.thorns_damage_percent = 0.10  # 10%
	all_upgrades.append(thorns)

	# 14. Second Wind (revive once at 50% HP)
	var second_wind = UpgradeData.new()
	second_wind.upgrade_id = "passive_second_wind"
	second_wind.upgrade_name = "Second Wind"
	second_wind.description = "Revive once per run at 50% health"
	second_wind.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	second_wind.rarity = UpgradeData.UpgradeRarity.LEGENDARY
	second_wind.max_stacks = 0  # One-time unlock
	second_wind.second_wind = true
	all_upgrades.append(second_wind)

	# 15. Lucky Charm (+50% gold/essence drops)
	var lucky_charm = UpgradeData.new()
	lucky_charm.upgrade_id = "passive_lucky_charm"
	lucky_charm.upgrade_name = "Lucky Charm"
	lucky_charm.description = "Increase gold and essence drops by 50%"
	lucky_charm.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	lucky_charm.rarity = UpgradeData.UpgradeRarity.EPIC
	lucky_charm.max_stacks = 2
	lucky_charm.gold_drop_multiplier = 1.50  # +50%
	all_upgrades.append(lucky_charm)

	# 16. Experience Boost (+25% XP gain)
	var xp_boost = UpgradeData.new()
	xp_boost.upgrade_id = "passive_xp_boost"
	xp_boost.upgrade_name = "Experience Boost"
	xp_boost.description = "Gain 25% more XP from all sources"
	xp_boost.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	xp_boost.rarity = UpgradeData.UpgradeRarity.RARE
	xp_boost.max_stacks = 3
	xp_boost.xp_gain_multiplier = 1.25  # +25%
	all_upgrades.append(xp_boost)

	# 17. Dodge Master (10% dodge chance)
	var dodge_master = UpgradeData.new()
	dodge_master.upgrade_id = "passive_dodge"
	dodge_master.upgrade_name = "Dodge Master"
	dodge_master.description = "10% chance to dodge incoming damage"
	dodge_master.upgrade_type = UpgradeData.UpgradeType.PASSIVE_ABILITY
	dodge_master.rarity = UpgradeData.UpgradeRarity.EPIC
	dodge_master.max_stacks = 2
	dodge_master.dodge_chance = 0.10  # 10%
	all_upgrades.append(dodge_master)

	# All upgrades start unlocked for MVP
	unlocked_upgrades = all_upgrades.duplicate()

func get_random_upgrades(count: int = 3, player: Node = null) -> Array[UpgradeData]:
	"""Get random upgrades that can be offered to player"""

	# DEBUG TEST MODE - Force specific upgrades
	if DEBUG_TEST_MODE and DEBUG_FORCED_UPGRADES.size() > 0:
		print("🔧 DEBUG TEST MODE: Forcing specific upgrades")
		var result: Array[UpgradeData] = []
		for upgrade_id in DEBUG_FORCED_UPGRADES:
			var upgrade = _find_upgrade_by_id(upgrade_id)
			if upgrade and upgrade.can_be_offered(player):
				result.append(upgrade)
				print("  ✓ Forced upgrade: ", upgrade.upgrade_name)
			else:
				print("  ✗ Cannot offer: ", upgrade_id, " (not found or maxed out)")

		# Fill remaining slots with random upgrades if needed
		while result.size() < count:
			var random_upgrade = _get_random_available_upgrade(result, player)
			if random_upgrade:
				result.append(random_upgrade)
			else:
				break

		return result

	# NORMAL MODE - Random upgrades
	var available_upgrades: Array[UpgradeData] = []

	# Filter upgrades that can be offered
	for upgrade in unlocked_upgrades:
		if upgrade.can_be_offered(player):
			available_upgrades.append(upgrade)

	if available_upgrades.size() == 0:
		push_warning("No upgrades available!")
		return []

	# Shuffle and take first N
	available_upgrades.shuffle()

	var result: Array[UpgradeData] = []
	var actual_count = mini(count, available_upgrades.size())
	for i in range(actual_count):
		result.append(available_upgrades[i])

	return result

func _find_upgrade_by_id(upgrade_id: String) -> UpgradeData:
	"""Find an upgrade by its ID"""
	for upgrade in all_upgrades:
		if upgrade.upgrade_id == upgrade_id:
			return upgrade
	return null

func _get_random_available_upgrade(exclude_list: Array[UpgradeData], player: Node = null) -> UpgradeData:
	"""Get a random upgrade not in the exclude list"""
	var available: Array[UpgradeData] = []
	for upgrade in unlocked_upgrades:
		if upgrade.can_be_offered(player) and not upgrade in exclude_list:
			available.append(upgrade)

	if available.size() == 0:
		return null

	available.shuffle()
	return available[0]

func apply_upgrade(upgrade_id: String, player: Node) -> void:
	"""Apply an upgrade to the player"""
	# Find the upgrade
	var upgrade: UpgradeData = null
	for u in all_upgrades:
		if u.upgrade_id == upgrade_id:
			upgrade = u
			break

	if not upgrade:
		push_error("Upgrade not found: ", upgrade_id)
		return

	# Apply the upgrade
	upgrade.apply_upgrade(player)

	# Track active upgrades
	active_upgrades[upgrade_id] = upgrade

	# Emit signal
	EventBus.upgrade_selected.emit(upgrade)

func reset_run() -> void:
	"""Reset upgrade state for new run"""
	for upgrade in all_upgrades:
		upgrade.current_stacks = 0
	active_upgrades.clear()
	print("UpgradePool reset for new run")
