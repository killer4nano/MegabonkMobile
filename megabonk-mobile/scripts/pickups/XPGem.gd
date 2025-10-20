extends Area3D
class_name XPGem
## XP Gem pickup - Vampire Survivors style magnetic pickup
## Floats at spawn location, pulls toward player when in range

# XP Properties
@export var xp_value: float = 10.0

# Magnet behavior
@export var magnet_range: float = 5.0
@export var move_speed: float = 8.0

# Visual properties
@export var gem_color: Color = Color.CYAN

# Internal state
var is_being_pulled: bool = false
var player: CharacterBody3D = null
var float_offset: float = 0.0
var initial_y: float = 0.0

# Signals
signal xp_collected(xp_value: float)

# References
@onready var gem_visual: MeshInstance3D = $GemVisual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	# Add to xp_gems group
	add_to_group("xp_gems")

	# Store initial Y position for floating effect
	initial_y = global_position.y

	# Random starting offset for floating animation
	float_offset = randf() * TAU

	# Set gem color based on XP value
	set_gem_color_by_value()

	# Set collision layers
	# Layer 3 for pickups, Mask 1 for player detection
	collision_layer = 4  # Layer 3 (bit 2)
	collision_mask = 1   # Layer 1 (bit 0)

	# Connect area signals for collection
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_gem_color_by_value() -> void:
	"""Set gem color based on XP value (small=blue, medium=green, large=yellow)"""
	if gem_visual:
		var material: StandardMaterial3D = gem_visual.get_active_material(0)
		if material:
			if xp_value < 15:
				# Small gem - Cyan/Blue
				gem_color = Color(0.2, 0.6, 1.0)
				material.emission = Color(0.4, 0.8, 1.0)
			elif xp_value < 30:
				# Medium gem - Green
				gem_color = Color(0.2, 1.0, 0.4)
				material.emission = Color(0.4, 1.0, 0.6)
			else:
				# Large gem - Yellow/Gold
				gem_color = Color(1.0, 0.9, 0.2)
				material.emission = Color(1.0, 1.0, 0.4)

			material.albedo_color = gem_color
			material.emission_enabled = true
			material.emission_energy_multiplier = 2.0

func _physics_process(delta: float) -> void:
	# Find player if not already found
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# Check if within magnet range
	if distance <= magnet_range:
		is_being_pulled = true

		# Pull toward player
		var direction = (player.global_position - global_position).normalized()
		# Aim for center of player (slightly above ground)
		var target_pos = player.global_position + Vector3(0, 0.5, 0)
		direction = (target_pos - global_position).normalized()

		# Move faster as we get closer
		var speed_multiplier = 1.0 + (1.0 - distance / magnet_range)
		global_position += direction * move_speed * speed_multiplier * delta
	else:
		# Floating animation when not being pulled
		is_being_pulled = false
		float_offset += delta * 2.0
		position.y = initial_y + sin(float_offset) * 0.15

func _on_body_entered(body: Node3D) -> void:
	"""Called when a body enters the gem's area"""
	if body.is_in_group("player"):
		collect()

func _on_area_entered(area: Area3D) -> void:
	"""Called when an area enters the gem's area (for PlayerPickupArea)"""
	if area.get_parent() and area.get_parent().is_in_group("player"):
		collect()

func collect() -> void:
	"""Collect this XP gem"""
	if not is_instance_valid(self):
		return

	print("XP Gem collected! Value: ", xp_value, " XP")

	# Emit signal
	xp_collected.emit(xp_value)

	# Get fresh player reference (in case collect() called before _physics_process)
	var target_player = player
	if not target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]

	print("DEBUG XPGem: Player found: ", target_player != null)

	# Notify player directly if possible
	if target_player and target_player.has_method("collect_xp"):
		print("DEBUG XPGem: Calling player.collect_xp(", xp_value, ")")
		target_player.collect_xp(xp_value)
	else:
		print("DEBUG XPGem: ERROR - Player or collect_xp method not found!")

	# Optional: Play collection sound/effect here

	# Remove gem
	queue_free()
