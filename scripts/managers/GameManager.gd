extends Node
## GameManager - Controls the main game loop and connects systems

var player: PlayerController
var virtual_joystick: VirtualJoystick
var camera_control: CameraControl
var wave_manager: Node
var jump_button: Control
var space_was_pressed: bool = false  # Track previous frame's spacebar state

func _ready() -> void:
	# Find player and joystick in the scene
	await get_tree().process_frame  # Wait one frame for scene to fully load

	player = get_tree().get_first_node_in_group("player")
	virtual_joystick = get_tree().get_first_node_in_group("virtual_joystick")
	camera_control = get_tree().get_first_node_in_group("camera_control")
	jump_button = get_tree().get_first_node_in_group("jump_button")
	wave_manager = get_node_or_null("../WaveManager")

	if not player:
		push_warning("No player found in scene!")

	if not virtual_joystick:
		push_warning("No virtual joystick found in scene!")

	if not camera_control:
		push_warning("No camera control found in scene!")

	if not jump_button:
		push_warning("No jump button found in scene!")

	if not wave_manager:
		push_warning("No wave manager found in scene!")

	# Connect camera control to player's camera pivot
	if camera_control and player:
		var camera_pivot = player.get_node_or_null("CameraArm")
		if camera_pivot:
			camera_control.set_camera_pivot(camera_pivot)

	# Connect jump button to player
	if jump_button and player:
		jump_button.jump_pressed.connect(func(): player.set_jump_input(true))
		print("Jump button connected to player")

	# Apply character data to player
	if player:
		apply_character_to_player()

	# Start wave spawning
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_completed.connect(_on_wave_completed)
		wave_manager.start_waves()

	print("GameManager initialized")
	print("Player found: ", player != null)
	print("Virtual joystick found: ", virtual_joystick != null)
	print("Camera control found: ", camera_control != null)
	print("Jump button found: ", jump_button != null)
	print("Wave manager found: ", wave_manager != null)

	# Start the run (enables run time tracking and extraction system)
	GlobalData.start_run()
	EventBus.game_started.emit()
	print("Game started! Run time tracking and extraction system enabled.")

func _process(_delta: float) -> void:
	if not player:
		return

	# Virtual joystick input (PRIORITY)
	var joystick_input := Vector2.ZERO
	if virtual_joystick:
		joystick_input = virtual_joystick.get_output()

	# TEMPORARY: Keyboard input for testing (WASD) - only if no joystick input
	var keyboard_input := Vector2.ZERO
	if joystick_input.length() == 0:
		# Use raw key detection instead of input actions
		if Input.is_physical_key_pressed(KEY_W):
			keyboard_input.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S):
			keyboard_input.y += 1.0
		if Input.is_physical_key_pressed(KEY_A):
			keyboard_input.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			keyboard_input.x += 1.0

		keyboard_input = keyboard_input.normalized() if keyboard_input.length() > 0 else Vector2.ZERO

	# Use joystick first, fallback to keyboard
	var final_input := joystick_input if joystick_input.length() > 0 else keyboard_input

	player.set_movement_input(final_input)

	# Handle jump input (Spacebar for keyboard) - Only trigger on key press, not hold
	var space_pressed = Input.is_physical_key_pressed(KEY_SPACE)
	if space_pressed and not space_was_pressed:  # Just pressed this frame
		player.set_jump_input(true)
	space_was_pressed = space_pressed


# Wave callbacks for displaying progress
func _on_wave_started(wave_number: int) -> void:
	print("=== WAVE ", wave_number, " STARTED ===")


func _on_wave_completed(wave_number: int) -> void:
	print("=== WAVE ", wave_number, " COMPLETED ===")

func apply_character_to_player() -> void:
	"""Load and apply character data to the player"""
	if not player:
		push_error("Cannot apply character: No player found!")
		return

	# Get current character ID from GlobalData
	var character_id = GlobalData.current_character
	if character_id == "":
		character_id = "warrior"  # Default fallback

	# Load character data
	var character_path = "res://resources/characters/%s.tres" % character_id
	var character_data: CharacterData = load(character_path)

	if not character_data:
		push_error("Failed to load character data: " + character_path)
		# Fallback to warrior
		character_data = load("res://resources/characters/warrior.tres")

	if not character_data:
		push_error("CRITICAL: Failed to load warrior fallback!")
		return

	# Apply character stats and abilities
	player.apply_character_data(character_data)

	# Apply starting weapon(s)
	var weapon_manager = player.get_node_or_null("WeaponManager")
	if weapon_manager:
		# Equip starting weapon
		weapon_manager.equip_starting_weapon(character_data.starting_weapon_id)

		# Equip extra weapons for Mage (or other characters with extra_starting_weapons)
		if character_data.extra_starting_weapons > 0:
			# For now, give Magic Missile + Fireball for multi-weapon start
			var extra_weapons = ["fireball", "ground_slam"]  # Can customize per character
			for i in range(min(character_data.extra_starting_weapons, extra_weapons.size())):
				weapon_manager.equip_weapon(extra_weapons[i])

	print("Character successfully applied: ", character_data.character_name)
