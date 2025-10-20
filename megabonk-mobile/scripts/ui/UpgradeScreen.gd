extends CanvasLayer
class_name UpgradeScreen
## Upgrade selection screen shown when player levels up
## Displays 3 random upgrade options for player to choose from

# UI References
@onready var upgrade_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/UpgradeContainer
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var level_label: Label = $Panel/MarginContainer/VBoxContainer/LevelLabel

# Upgrade cards (will be created dynamically)
var upgrade_cards: Array = []

# Currently offered upgrades
var current_upgrades: Array[UpgradeData] = []

# Reference to player
var player: Node = null

# Reference to upgrade pool
var upgrade_pool: UpgradePool = null

func _ready() -> void:
	# Hide initially
	hide()

	# Connect to level up signal
	EventBus.player_leveled_up.connect(_on_player_leveled_up)

	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	# Find or create upgrade pool
	upgrade_pool = get_tree().get_first_node_in_group("upgrade_pool")
	if not upgrade_pool:
		# Create upgrade pool if it doesn't exist
		upgrade_pool = UpgradePool.new()
		upgrade_pool.name = "UpgradePool"
		upgrade_pool.add_to_group("upgrade_pool")
		get_tree().root.add_child(upgrade_pool)
		print("UpgradeScreen: Created UpgradePool instance")

func _on_player_leveled_up(new_level: int) -> void:
	"""Show upgrade screen when player levels up"""
	print("UpgradeScreen: Player leveled up to ", new_level)
	show_upgrade_options(new_level)

func show_upgrade_options(level: int) -> void:
	"""Display upgrade options to player"""
	if not upgrade_pool:
		push_error("No UpgradePool found!")
		return

	# Pause the game
	get_tree().paused = true

	# Get random upgrades (pass player so weapon-specific upgrades are filtered)
	current_upgrades = upgrade_pool.get_random_upgrades(3, player)

	if current_upgrades.size() == 0:
		push_warning("No upgrades available!")
		get_tree().paused = false
		return

	# Update title
	title_label.text = "LEVEL UP!"
	level_label.text = "Level " + str(level)

	# DEBUG: Print offered upgrades
	print("========== UPGRADE OPTIONS ==========")
	for upgrade in current_upgrades:
		print("  - ", upgrade.upgrade_name, " (", upgrade.upgrade_type, ", ", upgrade.rarity, ")")
	print("=====================================")

	# Clear existing cards
	_clear_upgrade_cards()

	# Create upgrade cards
	for i in range(current_upgrades.size()):
		var upgrade = current_upgrades[i]
		_create_upgrade_card(upgrade, i)

	# Show the screen
	show()

	print("UpgradeScreen: Showing ", current_upgrades.size(), " upgrade options")

func _create_upgrade_card(upgrade: UpgradeData, index: int) -> void:
	"""Create an upgrade card UI element"""
	# Create card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 400)  # Mobile-friendly size
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Make the entire card clickable with hover effect
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_upgrade_selected(index)
	)

	# Add hover effect
	card.mouse_entered.connect(func():
		card.modulate = Color(1.2, 1.2, 1.2)  # Brighten on hover
	)
	card.mouse_exited.connect(func():
		card.modulate = Color(1.0, 1.0, 1.0)  # Normal
	)

	# Card background style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.3, 0.95)
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = _get_rarity_color(upgrade.rarity)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", style_box)

	# Card content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	card.add_child(margin)
	margin.add_child(vbox)

	# Upgrade name
	var name_label = Label.new()
	name_label.text = upgrade.upgrade_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", _get_rarity_color(upgrade.rarity))
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(name_label)

	# Rarity badge
	var rarity_label = Label.new()
	rarity_label.text = _get_rarity_text(upgrade.rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 18)
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(upgrade.rarity))
	rarity_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(rarity_label)

	# Separator
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 10)
	separator.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(separator)

	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 22)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(desc_label)

	# Stack indicator
	if upgrade.max_stacks > 0:
		var stack_label = Label.new()
		stack_label.text = "Level: " + str(upgrade.current_stacks) + "/" + str(upgrade.max_stacks)
		stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack_label.add_theme_font_size_override("font_size", 18)
		stack_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stack_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
		vbox.add_child(stack_label)

	# No longer need a separate button - entire card is clickable
	# Add a visual hint at the bottom
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(spacer)

	var hint_label = Label.new()
	hint_label.text = "✓ CLICK TO SELECT"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 20)
	hint_label.add_theme_color_override("font_color", _get_rarity_color(upgrade.rarity))
	hint_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(hint_label)

	# Add to container
	upgrade_container.add_child(card)
	upgrade_cards.append(card)

func _clear_upgrade_cards() -> void:
	"""Clear existing upgrade cards"""
	for card in upgrade_cards:
		card.queue_free()
	upgrade_cards.clear()

func _on_upgrade_selected(index: int) -> void:
	"""Handle upgrade selection"""
	if index < 0 or index >= current_upgrades.size():
		push_error("Invalid upgrade index: ", index)
		return

	var selected_upgrade = current_upgrades[index]
	print("Player selected upgrade: ", selected_upgrade.upgrade_name)

	# Apply the upgrade
	if player and upgrade_pool:
		upgrade_pool.apply_upgrade(selected_upgrade.upgrade_id, player)

	# Hide screen and resume game
	hide()
	get_tree().paused = false

	# Clear current upgrades
	current_upgrades.clear()

func _get_rarity_color(rarity: UpgradeData.UpgradeRarity) -> Color:
	"""Get color based on rarity"""
	match rarity:
		UpgradeData.UpgradeRarity.COMMON:
			return Color(0.7, 0.7, 0.7)  # Gray
		UpgradeData.UpgradeRarity.RARE:
			return Color(0.3, 0.6, 1.0)  # Blue
		UpgradeData.UpgradeRarity.EPIC:
			return Color(0.7, 0.3, 1.0)  # Purple
		UpgradeData.UpgradeRarity.LEGENDARY:
			return Color(1.0, 0.7, 0.2)  # Gold
	return Color.WHITE

func _get_rarity_text(rarity: UpgradeData.UpgradeRarity) -> String:
	"""Get rarity name as string"""
	match rarity:
		UpgradeData.UpgradeRarity.COMMON:
			return "COMMON"
		UpgradeData.UpgradeRarity.RARE:
			return "RARE"
		UpgradeData.UpgradeRarity.EPIC:
			return "EPIC"
		UpgradeData.UpgradeRarity.LEGENDARY:
			return "LEGENDARY"
	return "UNKNOWN"
