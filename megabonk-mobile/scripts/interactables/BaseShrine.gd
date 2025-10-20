extends StaticBody3D
class_name BaseShrine
## Base class for interactable shrines that provide temporary buffs

# Shrine settings
@export var shrine_name: String = "Shrine"
@export var cost: int = 50
@export var buff_duration: float = 60.0  # Duration in seconds
@export var shrine_color: Color = Color.CYAN

# State
var player_in_range: bool = false
var is_active: bool = false  # If buff is currently active
var current_player: Node3D = null

# UI
@onready var label_3d: Label3D = $Label3D
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	# Connect interaction signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)

	# Set visual color
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = shrine_color
		mat.emission_enabled = true
		mat.emission = shrine_color
		mat.emission_energy_multiplier = 0.5
		mesh.material_override = mat

	# Update label
	update_label()

func _process(delta: float) -> void:
	# Check for interaction input when player is in range
	if player_in_range and not is_active:
		# Mobile: Could add UI button, for now check spacebar for PC testing
		if Input.is_key_pressed(KEY_SPACE):
			attempt_activate()

func _on_player_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		update_label()
		print("Player entered shrine range: ", shrine_name)

func _on_player_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		current_player = null
		update_label()
		print("Player exited shrine range: ", shrine_name)

func attempt_activate() -> void:
	"""Try to activate the shrine (spend gold and apply effect)"""
	if is_active:
		print("Shrine is already active!")
		return

	if not current_player:
		print("No player in range!")
		return

	# Check if player has enough gold
	if GlobalData.current_gold >= cost:
		# Spend gold
		GlobalData.current_gold -= cost
		EventBus.gold_collected.emit(0, GlobalData.current_gold)  # Update HUD

		print("Shrine activated: ", shrine_name, " | Cost: ", cost, " gold")

		# Apply the shrine effect (override in subclass)
		apply_effect(current_player)

		# Mark as active
		is_active = true
		update_label()

		# Start cooldown timer
		await get_tree().create_timer(buff_duration).timeout
		remove_effect(current_player)
		is_active = false
		update_label()
	else:
		print("Not enough gold! Need ", cost, ", have ", GlobalData.current_gold)
		# TODO: Play error sound or visual feedback

func apply_effect(player: Node3D) -> void:
	"""Override this in subclasses to apply shrine-specific effects"""
	print("BaseShrine: apply_effect() - should be overridden!")

func remove_effect(player: Node3D) -> void:
	"""Override this in subclasses to remove shrine-specific effects"""
	print("BaseShrine: remove_effect() - should be overridden!")

func update_label() -> void:
	"""Update the 3D label above the shrine"""
	if not label_3d:
		return

	if is_active:
		label_3d.text = "%s\n[ACTIVE]" % shrine_name
		label_3d.modulate = Color.GREEN
	elif player_in_range:
		if GlobalData.current_gold >= cost:
			label_3d.text = "%s\n[PRESS SPACE]\n%d gold" % [shrine_name, cost]
			label_3d.modulate = Color.YELLOW
		else:
			label_3d.text = "%s\n[NOT ENOUGH GOLD]\n%d gold" % [shrine_name, cost]
			label_3d.modulate = Color.RED
	else:
		label_3d.text = "%s\n%d gold" % [shrine_name, cost]
		label_3d.modulate = Color.WHITE
