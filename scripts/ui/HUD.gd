extends CanvasLayer
class_name HUD
## Heads-Up Display - Shows player stats and game info

# UI element references
@onready var health_bar: ProgressBar = $MarginContainer/TopBar/LeftPanel/HealthBar
@onready var health_label: Label = $MarginContainer/TopBar/LeftPanel/HealthLabel
@onready var gold_label: Label = $MarginContainer/TopBar/LeftPanel/GoldLabel
@onready var xp_bar: ProgressBar = $MarginContainer/TopBar/CenterPanel/XPBar
@onready var xp_label: Label = $MarginContainer/TopBar/CenterPanel/XPLabel
@onready var level_label: Label = $MarginContainer/TopBar/CenterPanel/LevelLabel
@onready var wave_label: Label = $MarginContainer/TopBar/RightPanel/WaveLabel
@onready var kill_label: Label = $MarginContainer/TopBar/RightPanel/KillLabel
@onready var timer_label: Label = $MarginContainer/TopBar/RightPanel/TimerLabel

# Cached values
var current_health: float = 100.0
var max_health: float = 100.0
var current_gold: int = 0
var current_xp: float = 0.0
var xp_needed: float = 100.0
var current_level: int = 1
var current_wave: int = 1
var kill_count: int = 0
var run_time: float = 0.0

func _ready() -> void:
	# Connect to EventBus signals
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.gold_collected.connect(_on_gold_collected)
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_started.connect(_on_wave_started)

	# Find player to get initial stats
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		max_health = player.max_health
		current_health = player.current_health
		current_level = player.current_level
		current_xp = player.current_xp
		xp_needed = player.xp_to_next_level

	# Find WaveManager to get wave info
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		current_wave = wave_manager.current_wave

	# Initial update
	update_health_bar()
	update_gold_label()
	update_xp_bar()
	update_level_label()
	update_wave_label()
	update_kill_label()
	update_timer_label()

	print("HUD initialized")

func _process(delta: float) -> void:
	# Update run timer from GlobalData
	run_time = GlobalData.current_run_time
	update_timer_label()

# ============================================================================
# Health Bar Updates
# ============================================================================

func _on_player_damaged(damage: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		current_health = player.current_health
		update_health_bar()

func _on_player_healed(amount: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		current_health = player.current_health
		update_health_bar()

func update_health_bar() -> void:
	if not health_bar:
		return

	health_bar.max_value = max_health
	health_bar.value = current_health

	# Update label with current/max HP
	if health_label:
		health_label.text = "HP: %d/%d" % [int(current_health), int(max_health)]

# ============================================================================
# Gold Counter Updates
# ============================================================================

func _on_gold_collected(amount: int, total_gold: int) -> void:
	current_gold = total_gold
	update_gold_label()

func update_gold_label() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % current_gold

# ============================================================================
# XP Bar Updates
# ============================================================================

func _on_xp_collected(amount: float, total_xp: float, xp_needed_param: float) -> void:
	current_xp = total_xp
	xp_needed = xp_needed_param
	update_xp_bar()

func _on_player_leveled_up(new_level: int) -> void:
	current_level = new_level

	# Get updated XP values from player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		current_xp = player.current_xp
		xp_needed = player.xp_to_next_level

	update_level_label()
	update_xp_bar()

func update_xp_bar() -> void:
	if not xp_bar:
		return

	xp_bar.max_value = xp_needed
	xp_bar.value = current_xp

	# Update XP label with current/max XP
	if xp_label:
		xp_label.text = "%d/%d XP" % [int(current_xp), int(xp_needed)]

func update_level_label() -> void:
	if level_label:
		level_label.text = "Level %d" % current_level

# ============================================================================
# Wave & Kill Counter Updates
# ============================================================================

func _on_wave_started(wave_number: int) -> void:
	current_wave = wave_number
	update_wave_label()

func _on_enemy_killed(enemy: Node3D, xp_value: float) -> void:
	kill_count += 1
	GlobalData.enemies_killed = kill_count  # Sync with GlobalData
	update_kill_label()

func update_wave_label() -> void:
	if wave_label:
		wave_label.text = "Wave %d" % current_wave

func update_kill_label() -> void:
	if kill_label:
		kill_label.text = "Kills: %d" % kill_count

# ============================================================================
# Timer Updates
# ============================================================================

func update_timer_label() -> void:
	if timer_label:
		var minutes = int(run_time) / 60
		var seconds = int(run_time) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]
