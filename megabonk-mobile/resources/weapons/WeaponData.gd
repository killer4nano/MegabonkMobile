extends Resource
class_name WeaponData
## Resource for weapon stats and configuration
## Used by BaseWeapon to configure weapon behavior

@export var weapon_name: String = "Weapon"
@export_multiline var weapon_description: String = "A powerful weapon"
@export var base_damage: float = 10.0
@export var attack_cooldown: float = 1.0  # Time between attacks in seconds
@export var attack_range: float = 5.0
@export var projectile_count: int = 1  # For upgrades
@export var level: int = 1  # Starts at 1, upgradeable

func _init(
	p_name: String = "Weapon",
	p_description: String = "A powerful weapon",
	p_damage: float = 10.0,
	p_cooldown: float = 1.0,
	p_range: float = 5.0,
	p_projectile_count: int = 1,
	p_level: int = 1
) -> void:
	weapon_name = p_name
	weapon_description = p_description
	base_damage = p_damage
	attack_cooldown = p_cooldown
	attack_range = p_range
	projectile_count = p_projectile_count
	level = p_level

func upgrade() -> void:
	"""Upgrade the weapon to the next level"""
	level += 1
	# Scale damage by 15% per level
	base_damage *= 1.15
	# Reduce cooldown by 5% per level (faster attacks)
	attack_cooldown *= 0.95
	# Increase range by 10% per level
	attack_range *= 1.10
