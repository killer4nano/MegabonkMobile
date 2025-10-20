extends Resource
class_name CharacterData
## Resource defining a playable character's stats and abilities

# Identity
@export var character_id: String = "warrior"
@export var character_name: String = "Warrior"
@export_multiline var description: String = "A balanced fighter with melee expertise."
@export var character_color: Color = Color.RED

# Base Stats
@export_group("Base Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var base_damage: float = 10.0
@export var pickup_range: float = 3.0

# Passive Abilities
@export_group("Passive Abilities")
@export var passive_name: String = "Melee Mastery"
@export_multiline var passive_description: String = "+20% damage with melee weapons"

@export_range(0.0, 1.0) var damage_reduction: float = 0.0  # 0.15 = 15% reduction
@export var melee_damage_bonus: float = 0.2  # 0.2 = +20% melee damage
@export var ranged_damage_bonus: float = 0.0  # 0.0 = no bonus
@export var crit_chance_bonus: float = 0.0  # 0.25 = +25% crit chance
@export var crit_damage_bonus: float = 0.0  # 0.5 = +50% crit damage
@export var xp_multiplier: float = 1.0  # 1.15 = +15% XP gain
@export var extra_starting_weapons: int = 0  # 1 = start with 2 weapons instead of 1

# Starting Equipment
@export_group("Starting Equipment")
@export var starting_weapon_id: String = "bonk_hammer"

# Unlock Cost
@export_group("Unlock")
@export var unlock_cost: int = 0  # 0 = free (starting character)
@export var is_starter: bool = true

func get_summary() -> Dictionary:
	"""Return a dictionary summary of this character"""
	return {
		"id": character_id,
		"name": character_name,
		"description": description,
		"hp": max_health,
		"speed": move_speed,
		"damage": base_damage,
		"passive_name": passive_name,
		"passive_desc": passive_description,
		"unlock_cost": unlock_cost,
		"is_starter": is_starter
	}
