extends BaseShrine
class_name DamageShrine
## Damage Shrine - Grants +50% damage for 60 seconds

func _ready() -> void:
	shrine_name = "Damage Shrine"
	cost = 100
	buff_duration = 60.0
	shrine_color = Color(1, 0, 0, 1)  # Red
	super._ready()

func apply_effect(player: Node3D) -> void:
	"""Apply +50% damage buff to player"""
	if player.has_method("apply_damage_buff"):
		player.apply_damage_buff(1.5)  # 150% = +50% damage
		print("Damage Shrine: Applied +50% damage buff for ", buff_duration, " seconds")

func remove_effect(player: Node3D) -> void:
	"""Remove damage buff from player"""
	if player and is_instance_valid(player) and player.has_method("remove_damage_buff"):
		player.remove_damage_buff()
		print("Damage Shrine: Buff expired")
