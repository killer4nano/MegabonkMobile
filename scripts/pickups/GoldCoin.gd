extends Area3D
class_name GoldCoin
## Gold coin pickup that flies toward player when nearby

# Gold value
@export var gold_value: int = 1

# Movement settings
@export var magnet_range: float = 5.0  # Distance at which coin starts moving toward player
@export var move_speed: float = 8.0
@export var acceleration: float = 20.0

# State
var is_collected: bool = false
var player: Node3D = null
var velocity: Vector3 = Vector3.ZERO

# Visual
@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	# Set collision layers (layer 4 for pickups, detect layer 1 for player)
	collision_layer = 8  # Layer 4
	collision_mask = 1   # Layer 1 (player)

	# Connect to body entered signal
	body_entered.connect(_on_body_entered)

	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	# Get fresh player reference if needed
	if not player or not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return

	# Check distance to player
	var distance = global_position.distance_to(player.global_position)

	# If within magnet range, fly toward player
	if distance < magnet_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = velocity.move_toward(direction * move_speed, acceleration * delta)
		global_position += velocity * delta

		# Rotate coin for visual effect
		if mesh:
			mesh.rotate_y(5.0 * delta)

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return

	if body.is_in_group("player"):
		collect()

func collect() -> void:
	"""Collect the gold coin"""
	if is_collected:
		return

	is_collected = true

	# Get fresh player reference
	var target_player = player
	if not target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]

	if target_player:
		# Add gold to player/global
		GlobalData.current_gold += gold_value
		EventBus.gold_collected.emit(gold_value, GlobalData.current_gold)

		# Visual/audio feedback here (optional)
		# TODO: Play coin pickup sound

		# Remove coin
		queue_free()
	else:
		push_error("GoldCoin: No player found to collect gold!")
