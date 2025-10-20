extends Node
## Automated test controller for Phase 3 testing
## Runs tests autonomously without user input

# Test configuration
@export var test_duration: float = 45.0  # How long to run test (BATCH 1: 45s)
@export var xp_per_second: float = 100.0  # Auto-give XP to level up quickly (BATCH 1: 100/s)
@export var auto_select_upgrades: bool = true  # Auto-select forced upgrades

# Test state
var test_time: float = 0.0
var player: Node = null
var upgrade_screen: Node = null

func _ready() -> void:
	DebugLogger.log("automated_test", "=== AUTOMATED TEST STARTED ===")
	DebugLogger.log("automated_test", "Duration: %s seconds" % test_duration)
	DebugLogger.log("automated_test", "XP rate: %s per second" % xp_per_second)

	# Find player
	player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null
	if not player:
		push_error("AutomatedTest: No player found!")
		return

	# Find upgrade screen
	upgrade_screen = get_tree().current_scene.get_node_or_null("UpgradeScreen")

	# Connect to level up events
	EventBus.player_leveled_up.connect(_on_player_leveled_up)

	print("AutomatedTest: Ready - will run for ", test_duration, " seconds")

func _process(delta: float) -> void:
	if not player or not player.is_alive:
		return

	test_time += delta

	# Auto-give XP
	if player.has_method("collect_xp"):
		player.collect_xp(xp_per_second * delta)

	# Check if test duration complete
	if test_time >= test_duration:
		_end_test()

func _on_player_leveled_up(level: int) -> void:
	DebugLogger.log("automated_test", "Player leveled up to %s - waiting for upgrade screen" % level)

	if auto_select_upgrades:
		# Wait a frame for upgrade screen to appear
		await get_tree().process_frame
		await get_tree().process_frame

		# Auto-select first upgrade (the forced one from DEBUG_FORCED_UPGRADES)
		_auto_select_upgrade()

func _auto_select_upgrade() -> void:
	"""Automatically select the first upgrade option"""
	if not upgrade_screen:
		upgrade_screen = get_tree().current_scene.get_node_or_null("UpgradeScreen")

	if not upgrade_screen:
		DebugLogger.log("automated_test", "ERROR: Upgrade screen not found!")
		return

	# Find the first upgrade button and click it
	# This assumes UpgradeScreen has child buttons for upgrades
	var buttons = _find_buttons_recursive(upgrade_screen)

	if buttons.size() > 0:
		DebugLogger.log("automated_test", "Auto-selecting upgrade: %s" % buttons[0].name)
		# Simulate button press
		if buttons[0].has_signal("pressed"):
			buttons[0].pressed.emit()
		elif buttons[0].has_method("_on_pressed"):
			buttons[0]._on_pressed()
		else:
			DebugLogger.log("automated_test", "ERROR: Cannot trigger button press")
	else:
		DebugLogger.log("automated_test", "ERROR: No upgrade buttons found")

func _find_buttons_recursive(node: Node) -> Array:
	"""Recursively find all Button nodes"""
	var buttons = []

	if node is Button:
		buttons.append(node)

	for child in node.get_children():
		buttons.append_array(_find_buttons_recursive(child))

	return buttons

func _end_test() -> void:
	DebugLogger.log("automated_test", "=== TEST COMPLETE ===")
	DebugLogger.log("automated_test", "Total test time: %s seconds" % test_time)
	DebugLogger.log("automated_test", "Player level: %s" % player.current_level)
	DebugLogger.log("automated_test", "Exiting in 2 seconds...")

	await get_tree().create_timer(2.0).timeout

	# Quit the game
	get_tree().quit()
