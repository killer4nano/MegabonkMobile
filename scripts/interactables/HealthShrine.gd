extends BaseShrine
class_name HealthShrine
## Health Shrine - Restores 50% of max HP

func _ready() -> void:
	shrine_name = "Health Shrine"
	cost = 50
	buff_duration = 0.0  # Instant effect, no duration
	shrine_color = Color(0, 1, 0, 1)  # Green
	super._ready()

func apply_effect(player: Node3D) -> void:
	"""Restore 50% of player's max HP"""
	if player.has_method("heal"):
		var heal_amount = player.max_health * 0.5
		player.heal(heal_amount)
		print("Health Shrine: Healed player for ", heal_amount, " HP")

		# Visual feedback (TODO: particles, sound)
		# For now, instantly mark as not active since it's instant
		is_active = false
		update_label()

func remove_effect(player: Node3D) -> void:
	"""No effect to remove for health shrine (instant heal)"""
	pass
