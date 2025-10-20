extends BaseShrine
class_name SpeedShrine
## Speed Shrine - Grants +30% move speed for 60 seconds

func _ready() -> void:
	shrine_name = "Speed Shrine"
	cost = 75
	buff_duration = 60.0
	shrine_color = Color(0, 0.5, 1, 1)  # Blue
	super._ready()

func apply_effect(player: Node3D) -> void:
	"""Apply +30% speed buff to player"""
	if player.has_method("apply_speed_buff"):
		player.apply_speed_buff(1.3)  # 130% = +30% speed
		print("Speed Shrine: Applied +30% speed buff for ", buff_duration, " seconds")

func remove_effect(player: Node3D) -> void:
	"""Remove speed buff from player"""
	if player and is_instance_valid(player) and player.has_method("remove_speed_buff"):
		player.remove_speed_buff()
		print("Speed Shrine: Buff expired")
