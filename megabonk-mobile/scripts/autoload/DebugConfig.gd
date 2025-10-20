extends Node
## Centralized Debug Configuration System
## Controls all debug features from one location
## Add as autoload: Project Settings > Autoload > DebugConfig

# ============================================================================
# MASTER DEBUG TOGGLE
# ============================================================================
const DEBUG_MODE: bool = false  # Set to true to enable ALL debug features

# ============================================================================
# INDIVIDUAL DEBUG FEATURES (only work if DEBUG_MODE is true)
# ============================================================================

# Combat & Damage
const GOD_MODE: bool = false  # Player takes no damage
const ONE_HIT_KILLS: bool = false  # Enemies die in one hit
const INFINITE_AMMO: bool = false  # Unlimited ammo/resources

# Movement & Speed
const SPEED_MULTIPLIER: float = 1.0  # Player speed multiplier (1.0 = normal)
const NO_GRAVITY: bool = false  # Disable gravity for player
const FLIGHT_MODE: bool = false  # Allow flying

# Resources
const INFINITE_GOLD: bool = false  # Unlimited gold
const INFINITE_XP: bool = false  # Unlimited XP
const INSTANT_LEVEL_UP: bool = false  # Level up with one XP

# Enemy Behavior
const ENEMIES_DONT_ATTACK: bool = false  # Enemies won't damage player
const ENEMIES_DONT_MOVE: bool = false  # Enemies stand still
const SHOW_ENEMY_PATHS: bool = false  # Visualize enemy pathfinding

# Visual Debug
const SHOW_HITBOXES: bool = false  # Show collision shapes
const SHOW_FPS: bool = true  # Display FPS counter
const SHOW_DEBUG_INFO: bool = false  # Show additional debug overlay
const SHOW_RAYCASTS: bool = false  # Visualize raycasts

# Spawn & Wave Settings
const FAST_SPAWNING: bool = false  # Enemies spawn faster
const SPAWN_MULTIPLIER: float = 1.0  # Enemy spawn rate multiplier
const START_WAVE: int = 1  # Starting wave number

# Unlocks
const UNLOCK_ALL_WEAPONS: bool = false  # All weapons available
const UNLOCK_ALL_UPGRADES: bool = false  # All upgrades available
const UNLOCK_ALL_CHARACTERS: bool = false  # All characters available

# Logging
const LOG_COMBAT: bool = false  # Log combat events
const LOG_SPAWNING: bool = false  # Log spawn events
const LOG_CLIMBING: bool = false  # Log climbing events
const LOG_PICKUPS: bool = false  # Log pickup events

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func is_debug_enabled() -> bool:
	"""Check if debug mode is active"""
	return DEBUG_MODE

func is_feature_enabled(feature: String) -> bool:
	"""Check if a specific debug feature is enabled"""
	if not DEBUG_MODE:
		return false

	match feature:
		"god_mode": return GOD_MODE
		"one_hit_kills": return ONE_HIT_KILLS
		"infinite_ammo": return INFINITE_AMMO
		"speed_multiplier": return SPEED_MULTIPLIER != 1.0
		"no_gravity": return NO_GRAVITY
		"flight_mode": return FLIGHT_MODE
		"infinite_gold": return INFINITE_GOLD
		"infinite_xp": return INFINITE_XP
		"instant_level_up": return INSTANT_LEVEL_UP
		"enemies_dont_attack": return ENEMIES_DONT_ATTACK
		"enemies_dont_move": return ENEMIES_DONT_MOVE
		"show_enemy_paths": return SHOW_ENEMY_PATHS
		"show_hitboxes": return SHOW_HITBOXES
		"show_fps": return SHOW_FPS
		"show_debug_info": return SHOW_DEBUG_INFO
		"show_raycasts": return SHOW_RAYCASTS
		"fast_spawning": return FAST_SPAWNING
		"unlock_all_weapons": return UNLOCK_ALL_WEAPONS
		"unlock_all_upgrades": return UNLOCK_ALL_UPGRADES
		"unlock_all_characters": return UNLOCK_ALL_CHARACTERS
		"log_combat": return LOG_COMBAT
		"log_spawning": return LOG_SPAWNING
		"log_climbing": return LOG_CLIMBING
		"log_pickups": return LOG_PICKUPS
		_: return false

func get_player_speed_multiplier() -> float:
	"""Get the debug speed multiplier for player movement"""
	if DEBUG_MODE:
		return SPEED_MULTIPLIER
	return 1.0

func get_spawn_rate_multiplier() -> float:
	"""Get the debug spawn rate multiplier"""
	if DEBUG_MODE:
		return SPAWN_MULTIPLIER
	return 1.0

func should_log(category: String) -> bool:
	"""Check if a log category should output"""
	if not DEBUG_MODE:
		return false

	match category:
		"combat": return LOG_COMBAT
		"spawning": return LOG_SPAWNING
		"climbing": return LOG_CLIMBING
		"pickups": return LOG_PICKUPS
		_: return false

func debug_print(category: String, message: String) -> void:
	"""Print debug message if category is enabled"""
	if should_log(category):
		print("[DEBUG-", category.to_upper(), "] ", message)

func _ready():
	if DEBUG_MODE:
		print("========================================")
		print("DEBUG MODE ACTIVE")
		print("========================================")
		print("Active debug features:")

		if GOD_MODE: print("  - God Mode")
		if ONE_HIT_KILLS: print("  - One Hit Kills")
		if INFINITE_AMMO: print("  - Infinite Ammo")
		if SPEED_MULTIPLIER != 1.0: print("  - Speed Multiplier: ", SPEED_MULTIPLIER)
		if NO_GRAVITY: print("  - No Gravity")
		if FLIGHT_MODE: print("  - Flight Mode")
		if INFINITE_GOLD: print("  - Infinite Gold")
		if INFINITE_XP: print("  - Infinite XP")
		if INSTANT_LEVEL_UP: print("  - Instant Level Up")
		if ENEMIES_DONT_ATTACK: print("  - Enemies Don't Attack")
		if ENEMIES_DONT_MOVE: print("  - Enemies Don't Move")
		if SHOW_ENEMY_PATHS: print("  - Show Enemy Paths")
		if SHOW_HITBOXES: print("  - Show Hitboxes")
		if SHOW_FPS: print("  - Show FPS")
		if SHOW_DEBUG_INFO: print("  - Show Debug Info")
		if SHOW_RAYCASTS: print("  - Show Raycasts")
		if FAST_SPAWNING: print("  - Fast Spawning")
		if SPAWN_MULTIPLIER != 1.0: print("  - Spawn Multiplier: ", SPAWN_MULTIPLIER)
		if START_WAVE != 1: print("  - Start Wave: ", START_WAVE)
		if UNLOCK_ALL_WEAPONS: print("  - All Weapons Unlocked")
		if UNLOCK_ALL_UPGRADES: print("  - All Upgrades Unlocked")
		if UNLOCK_ALL_CHARACTERS: print("  - All Characters Unlocked")

		print("========================================")
	else:
		print("Debug mode disabled. Production build active.")