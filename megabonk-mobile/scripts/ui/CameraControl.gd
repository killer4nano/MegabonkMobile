extends Control
class_name CameraControl
## Camera rotation control for mobile
## Drag anywhere on screen to rotate camera around player

@export var rotation_sensitivity: float = 0.3
@export var min_distance: float = 5.0
@export var max_distance: float = 15.0
@export var zoom_sensitivity: float = 0.5

var is_dragging: bool = false
var last_drag_position: Vector2 = Vector2.ZERO
var camera_pivot: Node3D  # Reference to player's CameraArm
var current_rotation: Vector2 = Vector2(-45, 0)  # X = vertical angle, Y = horizontal angle

func _ready() -> void:
	# Make this control cover the whole screen but DON'T steal keyboard focus
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE  # Critical: Don't steal keyboard focus!

	print("CameraControl ready")

func set_camera_pivot(pivot: Node3D) -> void:
	"""Set the camera pivot to control"""
	camera_pivot = pivot
	if camera_pivot:
		print("Camera pivot set successfully")

func _gui_input(event: InputEvent) -> void:
	# Ignore all keyboard events
	if event is InputEventKey:
		return

	# Touch/Mouse press
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			is_dragging = true
			last_drag_position = event.position
		else:
			is_dragging = false

	# Touch/Mouse drag
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging and camera_pivot:
			var drag_delta: Vector2 = event.position - last_drag_position
			last_drag_position = event.position

			# Update rotation based on drag
			current_rotation.y -= drag_delta.x * rotation_sensitivity  # Horizontal rotation
			current_rotation.x = clamp(current_rotation.x - drag_delta.y * rotation_sensitivity, -89, -10)  # Vertical rotation (limited)

			# Apply rotation to camera pivot
			update_camera_rotation()

func update_camera_rotation() -> void:
	if not camera_pivot:
		return

	# Rotate the camera pivot around the player
	# Horizontal rotation (Y axis)
	camera_pivot.rotation.y = deg_to_rad(current_rotation.y)

	# Vertical rotation (X axis) - tilting up/down
	camera_pivot.rotation.x = deg_to_rad(current_rotation.x)

func _process(_delta: float) -> void:
	# Optional: Add zoom with mouse wheel or pinch gesture
	pass
