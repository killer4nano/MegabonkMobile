extends Control
## Mobile jump button for touch controls

signal jump_pressed

# Visual settings
@export var button_size: float = 100.0
@export var button_color: Color = Color(1, 1, 1, 0.3)
@export var button_pressed_color: Color = Color(1, 1, 1, 0.6)
@export var button_text: String = "JUMP"

# State
var is_pressed: bool = false
var touch_index: int = -1

func _ready() -> void:
	# Set minimum size
	custom_minimum_size = Vector2(button_size, button_size)

	# Add to group for easy access
	add_to_group("jump_button")

	print("Jump button initialized")

func _draw() -> void:
	# Draw button background
	var rect = Rect2(Vector2.ZERO, Vector2(button_size, button_size))
	var color = button_pressed_color if is_pressed else button_color

	# Draw circle button
	draw_circle(Vector2(button_size / 2, button_size / 2), button_size / 2, color)

	# Draw button border
	draw_arc(Vector2(button_size / 2, button_size / 2), button_size / 2, 0, TAU, 64, Color(1, 1, 1, 0.5), 3.0)

	# Draw text
	var font = ThemeDB.fallback_font
	var font_size = 20
	var text_size = font.get_string_size(button_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = Vector2(button_size / 2 - text_size.x / 2, button_size / 2 + text_size.y / 4)
	draw_string(font, text_pos, button_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _gui_input(event: InputEvent) -> void:
	# Handle touch/mouse input
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			# Button pressed
			is_pressed = true
			touch_index = event.index
			jump_pressed.emit()
			queue_redraw()
			print("Jump button pressed")
		elif not event.pressed and event.index == touch_index:
			# Button released
			is_pressed = false
			touch_index = -1
			queue_redraw()
			print("Jump button released")

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_index == -1:
				# Button pressed
				is_pressed = true
				touch_index = 0
				jump_pressed.emit()
				queue_redraw()
				print("Jump button pressed (mouse)")
			elif not event.pressed and touch_index == 0:
				# Button released
				is_pressed = false
				touch_index = -1
				queue_redraw()
				print("Jump button released (mouse)")