extends Node
## EventBus - Central event system for decoupled communication
## Use signals to communicate between systems without tight coupling

# Player events
signal player_damaged(damage: float)
signal player_healed(amount: float)
signal player_died()
signal player_leveled_up(new_level: int)

# Enemy events
signal enemy_spawned(enemy: Node3D)
signal enemy_killed(enemy: Node3D, xp_value: float)

# Loot events
signal xp_collected(amount: float, total_xp: float, xp_needed: float)
signal gold_collected(amount: int, total_gold: int)

# Weapon events
signal weapon_unlocked(weapon_id: String)
signal weapon_equipped(weapon: Node)

# Game state events
signal game_started()
signal game_paused()
signal game_resumed()
signal extraction_started()
signal extraction_success()
signal extraction_failed()

# Wave events
signal wave_started(wave_number: int)
signal mini_boss_spawned()

# UI events
signal upgrade_selected(upgrade_data: Resource)
signal show_upgrade_screen(upgrades: Array)
