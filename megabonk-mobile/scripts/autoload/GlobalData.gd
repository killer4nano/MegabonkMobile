extends Node
## GlobalData - Stores global game state, settings, and unlocks

# Game state
var is_game_running: bool = false
var current_run_time: float = 0.0
var game_paused: bool = false

# Extraction/Death results (for UI screens)
var last_extraction_results: Dictionary = {}
var last_death_results: Dictionary = {}

# Player stats (persistent between runs)
var account_level: int = 1
var account_xp: int = 0
var extraction_currency: int = 0  # "Essence" or whatever we call it

# Current run data (reset each run)
var current_gold: int = 0
var current_xp: float = 0.0
var current_level: int = 1
var enemies_killed: int = 0
var current_character: String = "warrior"

# Unlocks (persistent)
var unlocked_characters: Array = ["warrior"]  # Start with one character
var unlocked_weapons: Array = ["bonk_hammer", "magic_missile", "spinning_blade", "fireball", "ground_slam"]
var unlocked_upgrades: Array = []
var unlocked_maps: Array = ["arena_01"]

# Settings
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var graphics_quality: int = 1  # 0 = Low, 1 = Medium, 2 = High
var show_fps: bool = false
var control_scheme: int = 0  # 0 = Virtual Joystick, 1 = Tap to Move

# Statistics (persistent)
var total_runs: int = 0
var successful_extractions: int = 0
var total_enemies_killed: int = 0
var total_playtime: float = 0.0
var longest_run: float = 0.0

func _ready() -> void:
	print("GlobalData initialized")

func _process(delta: float) -> void:
	# Track run time while game is running
	if is_game_running:
		current_run_time += delta

func reset_run_data() -> void:
	"""Reset all data specific to the current run"""
	current_gold = 0
	current_xp = 0.0
	current_level = 1
	enemies_killed = 0
	current_run_time = 0.0
	# Note: is_game_running is set by start_run(), not here

func add_extraction_currency(amount: int) -> void:
	"""Add extraction currency (from successful extractions)"""
	extraction_currency += amount
	print("Extraction currency gained: ", amount, " | Total: ", extraction_currency)

func spend_extraction_currency(amount: int) -> bool:
	"""Spend extraction currency. Returns true if successful"""
	if extraction_currency >= amount:
		extraction_currency -= amount
		return true
	return false

func unlock_character(character_id: String) -> void:
	"""Unlock a new character"""
	if character_id not in unlocked_characters:
		unlocked_characters.append(character_id)
		print("Character unlocked: ", character_id)

func unlock_weapon(weapon_id: String) -> void:
	"""Unlock a new weapon to appear in runs"""
	if weapon_id not in unlocked_weapons:
		unlocked_weapons.append(weapon_id)
		EventBus.weapon_unlocked.emit(weapon_id)
		print("Weapon unlocked: ", weapon_id)

func unlock_upgrade(upgrade_id: String) -> void:
	"""Unlock a new upgrade to appear in runs"""
	if upgrade_id not in unlocked_upgrades:
		unlocked_upgrades.append(upgrade_id)
		print("Upgrade unlocked: ", upgrade_id)

func is_character_unlocked(character_id: String) -> bool:
	return character_id in unlocked_characters

func is_weapon_unlocked(weapon_id: String) -> bool:
	return weapon_id in unlocked_weapons

func start_run() -> void:
	"""Start a new run"""
	reset_run_data()
	is_game_running = true
	print("Run started!")

func end_run() -> void:
	"""End the current run"""
	is_game_running = false
	print("Run ended! Time: ", current_run_time, "s")
