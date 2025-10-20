extends Control
class_name VirtualJoystick
## Virtual joystick for mobile touch controls
## Provides 2D directional input for player movement

@export var joystick_radius: float = 100.0
@export var deadzone: float = 0.2

var is_pressed: bool = false
var center_position: Vector2
var current_position: Vector2
var output: Vector2 = Vector2.ZERO

# Visual elements
var base: Control
var stick: Control

func _ready() -> void:
	# Set mouse filter to STOP input from passing through to camera control
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE  # Don't steal keyboard focus

	# Wait for size to be set
	await get_tree().process_frame

	center_position = size / 2
	current_position = center_position

	queue_redraw()

	print("VirtualJoystick ready. Size: ", size, " Center: ", center_position, " Z-Index: ", z_index)

func _draw() -> void:
	# Draw base circle (larger, semi-transparent)
	draw_circle(center_position, joystick_radius, Color(1, 1, 1, 0.3))
	draw_arc(center_position, joystick_radius, 0, TAU, 32, Color(1, 1, 1, 0.6), 3.0)

	# Draw stick (smaller, more opaque)
	draw_circle(current_position, joystick_radius * 0.4, Color(1, 1, 1, 0.7))
	draw_arc(current_position, joystick_radius * 0.4, 0, TAU, 32, Color(1, 1, 1, 0.9), 3.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			is_pressed = true
			update_joystick(event.position)
			accept_event()  # Consume event so camera doesn't rotate
		else:
			is_pressed = false
			reset_joystick()
			accept_event()

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_pressed:
			update_joystick(event.position)
			accept_event()  # Consume event

func update_joystick(touch_position: Vector2) -> void:
	# Calculate offset from center
	var offset := touch_position - center_position

	# Clamp to joystick radius
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius

	current_position = center_position + offset

	# Calculate output (-1 to 1 range)
	output = offset / joystick_radius

	# Apply deadzone
	if output.length() < deadzone:
		output = Vector2.ZERO

	queue_redraw()

func reset_joystick() -> void:
	current_position = center_position
	output = Vector2.ZERO
	queue_redraw()

func get_output() -> Vector2:
	return output
