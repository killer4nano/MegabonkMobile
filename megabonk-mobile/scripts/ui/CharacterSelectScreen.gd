extends CanvasLayer
## Character Selection Screen
## Allows player to select or unlock characters

# Character list
const CHARACTERS = [
	"res://resources/characters/warrior.tres",
	"res://resources/characters/ranger.tres",
	"res://resources/characters/tank.tres",
	"res://resources/characters/assassin.tres",
	"res://resources/characters/mage.tres"
]

# UI References
@onready var character_grid: GridContainer = $ColorRect/MarginContainer/VBoxContainer/MainContent/CharacterGridScroll/CharacterGrid
@onready var info_panel: VBoxContainer = $ColorRect/MarginContainer/VBoxContainer/MainContent/InfoPanel
@onready var character_name_label: Label = $ColorRect/MarginContainer/VBoxContainer/MainContent/InfoPanel/CharacterName
@onready var stats_label: Label = $ColorRect/MarginContainer/VBoxContainer/MainContent/InfoPanel/StatsLabel
@onready var passive_label: RichTextLabel = $ColorRect/MarginContainer/VBoxContainer/MainContent/InfoPanel/PassiveLabel
@onready var action_button: Button = $ColorRect/MarginContainer/VBoxContainer/MainContent/InfoPanel/ActionButton
@onready var essence_label: Label = $ColorRect/MarginContainer/VBoxContainer/BottomBar/EssenceLabel
@onready var back_button: Button = $ColorRect/MarginContainer/VBoxContainer/BottomBar/BackButton

# State
var selected_character_data: CharacterData = null
var character_cards: Array = []

func _ready() -> void:
	# Load all characters and create cards
	create_character_cards()

	# Update essence display
	update_essence_display()

	# Connect buttons
	action_button.pressed.connect(_on_action_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	# Don't auto-select - player must choose each time
	# This ensures intentional character selection
	print("Character selection ready - player must select a character")

	# Set initial info panel message
	character_name_label.text = "Select a Character"
	stats_label.text = "Click any character card to view details"
	passive_label.text = "Character abilities will be shown here"
	action_button.text = "..."
	action_button.disabled = true

func create_character_cards() -> void:
	"""Create UI cards for each character"""
	for char_path in CHARACTERS:
		var char_data: CharacterData = load(char_path)
		if not char_data:
			push_error("Failed to load character: " + char_path)
			continue

		# Create character card
		var card = create_card(char_data)
		character_grid.add_child(card)
		character_cards.append(card)

func create_card(char_data: CharacterData) -> PanelContainer:
	"""Create a character card UI element"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 200)
	card.set_meta("character_data", char_data)

	# Make the entire card clickable with hover effect
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select_character(char_data)
	)

	# Add hover effect
	card.mouse_entered.connect(func():
		card.modulate = Color(1.2, 1.2, 1.2)  # Brighten on hover
	)
	card.mouse_exited.connect(func():
		card.modulate = Color(1.0, 1.0, 1.0)  # Normal
	)

	# Add style based on unlock status
	var is_unlocked = GlobalData.is_character_unlocked(char_data.character_id)

	# Create card content
	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	card.add_child(vbox)

	# Character color indicator (colored bar at top)
	var color_rect = ColorRect.new()
	color_rect.custom_minimum_size = Vector2(0, 20)
	color_rect.color = char_data.character_color
	color_rect.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(color_rect)

	# Character name
	var name_label = Label.new()
	name_label.text = char_data.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(name_label)

	# Stats preview
	var stats_preview = Label.new()
	stats_preview.text = "HP: %d\nSpeed: %.1f" % [char_data.max_health, char_data.move_speed]
	stats_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_preview.add_theme_font_size_override("font_size", 12)
	stats_preview.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(stats_preview)

	# Lock icon or status (NO selection state on initial load)
	var status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	if is_unlocked:
		status_label.text = "UNLOCKED"
		status_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		status_label.text = "🔒 %d Essence" % char_data.unlock_cost
		status_label.add_theme_color_override("font_color", Color.DARK_GRAY)
	vbox.add_child(status_label)

	# No longer need a separate button - entire card is clickable
	# Add a visual hint that it's clickable
	var hint_label = Label.new()
	hint_label.text = "Click to select"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Don't block clicks
	vbox.add_child(hint_label)

	return card

func select_character(char_data: CharacterData) -> void:
	"""Select a character and display its info"""
	selected_character_data = char_data
	update_info_panel()
	update_card_selection_visual()

func select_character_by_id(char_id: String) -> void:
	"""Select character by ID"""
	for char_path in CHARACTERS:
		var char_data: CharacterData = load(char_path)
		if char_data and char_data.character_id == char_id:
			select_character(char_data)
			return

	# Fallback to warrior if not found
	var warrior: CharacterData = load(CHARACTERS[0])
	select_character(warrior)

func update_info_panel() -> void:
	"""Update the info panel with selected character details"""
	if not selected_character_data:
		return

	var char = selected_character_data

	# Character name
	character_name_label.text = char.character_name

	# Stats
	var stats_text = "HP: %d\nSpeed: %.1f\nDamage: %d\nPickup Range: %.1fm" % [
		char.max_health,
		char.move_speed,
		char.base_damage,
		char.pickup_range
	]
	stats_label.text = stats_text

	# Passive ability
	var passive_text = "[b]%s[/b]\n%s" % [char.passive_name, char.passive_description]
	passive_label.text = passive_text

	# Action button (PLAY or UNLOCK)
	var is_unlocked = GlobalData.is_character_unlocked(char.character_id)

	if is_unlocked:
		action_button.text = "PLAY"
		action_button.disabled = false
	else:
		var can_afford = GlobalData.extraction_currency >= char.unlock_cost
		action_button.text = "UNLOCK (%d Essence)" % char.unlock_cost
		action_button.disabled = not can_afford

func _on_action_button_pressed() -> void:
	"""Handle PLAY or UNLOCK button press"""
	if not selected_character_data:
		print("No character selected!")
		return

	var char = selected_character_data
	var is_unlocked = GlobalData.is_character_unlocked(char.character_id)

	if is_unlocked:
		# PLAY - Start game with selected character
		GlobalData.current_character = char.character_id
		print("Starting game with character: ", char.character_name)

		# Reset run data before starting game
		GlobalData.reset_run_data()

		# BUG FIX: TASK-011 - Load ProceduralArena instead of TestArena
		# User reported procedural map not loading (was hardcoded to TestArena)
		# Date: 2025-10-20
		# Go to game (use ProceduralArena for infinite replayability!)
		get_tree().change_scene_to_file("res://scenes/maps/ProceduralArena.tscn")
	else:
		# UNLOCK character
		if GlobalData.spend_extraction_currency(char.unlock_cost):
			GlobalData.unlock_character(char.character_id)
			SaveSystem.save_game()
			print("Character unlocked: ", char.character_name)

			# Refresh UI
			refresh_all_cards()
			update_info_panel()
			update_essence_display()

func refresh_all_cards() -> void:
	"""Refresh all character cards (rebuild them)"""
	# Clear existing cards
	for card in character_cards:
		card.queue_free()
	character_cards.clear()

	# Recreate cards
	create_character_cards()

func update_essence_display() -> void:
	"""Update the essence counter"""
	essence_label.text = "Essence: %d" % GlobalData.extraction_currency

func update_card_selection_visual() -> void:
	"""Update visual indicators to show which card is selected"""
	if not selected_character_data:
		return

	# Update all cards to show/hide selection indicator
	for card in character_cards:
		var card_data = card.get_meta("character_data") as CharacterData
		if not card_data:
			continue

		# Find the status label in this card
		var vbox = card.get_child(0) as VBoxContainer
		if not vbox:
			continue

		# Look for the status label (4th child - after color bar, name, stats)
		if vbox.get_child_count() > 3:
			var status_label = vbox.get_child(3) as Label
			if status_label:
				var is_this_selected = (card_data.character_id == selected_character_data.character_id)
				var is_unlocked = GlobalData.is_character_unlocked(card_data.character_id)

				if is_this_selected:
					# Highlight selected card
					status_label.text = ">>> SELECTED <<<"
					status_label.add_theme_color_override("font_color", Color.GREEN)
					card.modulate = Color(1.1, 1.1, 1.1)  # Slight glow
				elif is_unlocked:
					status_label.text = "UNLOCKED"
					status_label.add_theme_color_override("font_color", Color.WHITE)
					card.modulate = Color(1.0, 1.0, 1.0)
				else:
					status_label.text = "🔒 %d Essence" % card_data.unlock_cost
					status_label.add_theme_color_override("font_color", Color.DARK_GRAY)
					card.modulate = Color(1.0, 1.0, 1.0)

func _on_back_button_pressed() -> void:
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
