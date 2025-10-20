extends Node3D
class_name ExtractionZone
## Extraction Zone - Player can extract here to end run and keep loot

# Configuration
@export var extraction_time: float = 5.0  # Seconds required to extract
@export var pulse_speed: float = 2.0  # Visual pulse effect speed
@export var pulse_scale: float = 1.2  # Max pulse scale

# Internal state
var player_in_zone: bool = false
var extraction_progress: float = 0.0
var is_extracting: bool = false
var player: Node3D = null

# References
@onready var area: Area3D = $Area3D
@onready var visual_mesh: MeshInstance3D = $VisualMesh
@onready var countdown_label: Label3D = $CountdownLabel

# Visual effects
var base_scale: Vector3
var pulse_time: float = 0.0

func _ready() -> void:
	# Store base scale for pulse effect
	if visual_mesh:
		base_scale = visual_mesh.scale

	# Connect Area3D signals
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	# Hide countdown initially
	if countdown_label:
		countdown_label.visible = false

	print("ExtractionZone spawned at ", global_position)

func _process(delta: float) -> void:
	# Pulse visual effect
	if visual_mesh:
		pulse_time += delta * pulse_speed
		var pulse_factor = (sin(pulse_time) + 1.0) / 2.0  # 0.0 to 1.0
		var scale_multiplier = 1.0 + (pulse_factor * (pulse_scale - 1.0))
		visual_mesh.scale = base_scale * scale_multiplier

	# Handle extraction countdown
	if player_in_zone and player and is_instance_valid(player):
		extraction_progress += delta

		# Update countdown label
		if countdown_label:
			countdown_label.visible = true
			var time_remaining = extraction_time - extraction_progress
			countdown_label.text = "Extracting... %.1f" % max(0.0, time_remaining)

		# Check if extraction complete
		if extraction_progress >= extraction_time:
			_complete_extraction()
	else:
		# Reset progress if player leaves or dies
		extraction_progress = 0.0
		if countdown_label:
			countdown_label.visible = false

func _on_body_entered(body: Node3D) -> void:
	"""Called when something enters the extraction zone"""
	if body.is_in_group("player"):
		player = body
		player_in_zone = true
		extraction_progress = 0.0
		print("Player entered extraction zone - starting countdown")

func _on_body_exited(body: Node3D) -> void:
	"""Called when something exits the extraction zone"""
	if body == player:
		player_in_zone = false
		extraction_progress = 0.0
		if countdown_label:
			countdown_label.visible = false
		print("Player left extraction zone - countdown cancelled")

func _complete_extraction() -> void:
	"""Called when extraction countdown completes"""
	if is_extracting:
		return  # Already extracting

	is_extracting = true
	print("Extraction complete! Player successfully extracted.")

	# Emit extraction success signal
	EventBus.extraction_success.emit()

	# ExtractionManager will handle the rest (rewards, scene transition)
