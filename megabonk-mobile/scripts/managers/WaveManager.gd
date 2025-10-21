extends Node
## WaveManager - Handles enemy wave spawning and difficulty progression

# Signals
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal enemy_spawned(enemy: Node3D)

# Configuration
@export var arena_radius: float = 20.0  # Spawn distance from center
@export var base_spawn_interval: float = 3.0  # Base time between spawns
@export var enemies_per_wave: int = 10  # Base enemies per wave (increases with wave)
@export var wave_duration: float = 30.0  # Time between wave difficulty increases

# Wave state
var current_wave: int = 1
var enemies_spawned_this_wave: int = 0
var is_spawning: bool = false

# Timers
var spawn_timer: Timer
var wave_timer: Timer

# Enemy scene paths
const BASIC_ENEMY = "res://scenes/enemies/BasicEnemy.tscn"
const FAST_ENEMY = "res://scenes/enemies/FastEnemy.tscn"
const TANK_ENEMY = "res://scenes/enemies/TankEnemy.tscn"
const RANGED_ENEMY = "res://scenes/enemies/RangedEnemy.tscn"
const BOSS_ENEMY = "res://scenes/enemies/BossEnemy.tscn"

# Spawn point configuration
const NUM_SPAWN_POINTS: int = 12  # Number of potential spawn points around arena

# Procedural map support
var procedural_map_generator: Node3D = null


func _ready() -> void:
	# Add to wave_manager group for HUD access
	add_to_group("wave_manager")

	# BUG FIX: Create timers FIRST (before await) to prevent race condition
	# Issue: GameManager calls start_waves() after its await, but if WaveManager's
	# await hasn't completed yet, timers don't exist = crash!
	# Fix: Create timers synchronously before any await
	# Date: 2025-10-20

	# Create spawn timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	# Create wave progression timer
	wave_timer = Timer.new()
	wave_timer.one_shot = false
	wave_timer.wait_time = wave_duration
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	add_child(wave_timer)

	# Try to find procedural map generator (can wait since it's optional)
	await get_tree().process_frame  # Wait for scene to be ready
	_find_procedural_map_generator()

	print("WaveManager initialized")


## Start the wave spawning system
func start_waves() -> void:
	if is_spawning:
		return

	is_spawning = true
	current_wave = 1
	enemies_spawned_this_wave = 0

	# Calculate initial spawn interval
	var spawn_interval = _get_spawn_interval()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

	# Start wave progression
	wave_timer.start()

	wave_started.emit(current_wave)
	EventBus.wave_started.emit(current_wave)
	print("Wave ", current_wave, " started! Spawn interval: ", spawn_interval, "s")


## Stop the wave spawning system
func stop_waves() -> void:
	is_spawning = false
	spawn_timer.stop()
	wave_timer.stop()
	print("Wave spawning stopped")


## Spawn a specific enemy type at a random spawn point
func spawn_enemy(enemy_scene_path: String) -> void:
	var spawn_pos = get_random_spawn_position()

	var enemy_scene = load(enemy_scene_path)
	if not enemy_scene:
		push_error("Failed to load enemy scene: ", enemy_scene_path)
		return

	var enemy = enemy_scene.instantiate()

	# BUG FIX: Set position property BEFORE adding to tree
	# Reason: BaseEnemy._ready() uses global_position, so position must be set first
	# Date: 2025-10-21
	enemy.position = spawn_pos

	# Add enemy to the scene (this triggers _ready())
	get_tree().current_scene.add_child(enemy)

	enemy_spawned.emit(enemy)
	enemies_spawned_this_wave += 1

	# Optional: Connect to enemy death signal if needed
	# enemy.died.connect(_on_enemy_died)


## Get a random spawn position around the arena perimeter
func get_random_spawn_position() -> Vector3:
	# If procedural map exists, use its spawn zones
	if procedural_map_generator and procedural_map_generator.has_method("get_random_spawn_zone"):
		var spawn_pos = procedural_map_generator.get_random_spawn_zone()
		if spawn_pos != Vector3.ZERO:
			return spawn_pos

	# BUG FIX: Spawn relative to player position, not world origin
	# This ensures enemies always spawn at arena_radius distance from player
	# Date: 2025-10-21
	var player = get_tree().get_first_node_in_group("player")
	var center_point = Vector3.ZERO

	if player:
		center_point = player.global_position
	else:
		push_warning("WaveManager: No player found! Spawning relative to world origin")

	# Random angle around the circle
	var angle = randf() * TAU  # TAU = 2 * PI

	# Calculate position using sin/cos, relative to center_point (player or origin)
	var x = center_point.x + (cos(angle) * arena_radius)
	var z = center_point.z + (sin(angle) * arena_radius)
	var y = center_point.y

	return Vector3(x, y, z)


## Select enemy type based on current wave number
func select_enemy_type_for_wave() -> String:
	var roll = randf()

	if current_wave <= 3:
		# Waves 1-3: Only basic enemies
		return BASIC_ENEMY
	elif current_wave <= 4:
		# Wave 4: Mix of Basic (70%) and Fast (30%)
		if roll < 0.7:
			return BASIC_ENEMY
		else:
			return FAST_ENEMY
	elif current_wave <= 7:
		# Waves 5-7: Basic (50%), Fast (30%), Ranged (20%)
		if roll < 0.5:
			return BASIC_ENEMY
		elif roll < 0.8:
			return FAST_ENEMY
		else:
			return RANGED_ENEMY
	else:
		# Wave 8+: All five types (Basic, Fast, Tank, Ranged, Boss)
		if roll < 0.35:
			return BASIC_ENEMY
		elif roll < 0.6:
			return FAST_ENEMY
		elif roll < 0.8:
			return TANK_ENEMY
		else:
			return RANGED_ENEMY


## Calculate spawn interval based on current wave (gets faster over time)
func _get_spawn_interval() -> float:
	# Decrease spawn interval as waves progress
	# Wave 1: 3.0s, Wave 5: 2.25s, Wave 10: 1.5s, etc.
	var interval_reduction = (current_wave - 1) * 0.15
	var min_interval = 1.0
	return max(base_spawn_interval - interval_reduction, min_interval)


## Calculate how many enemies should spawn this wave
func _get_enemies_for_wave() -> int:
	# Increase enemy count each wave
	return enemies_per_wave + (current_wave - 1) * 2


## Called when spawn timer times out
func _on_spawn_timer_timeout() -> void:
	if not is_spawning:
		return

	# Select and spawn enemy
	var enemy_type = select_enemy_type_for_wave()
	spawn_enemy(enemy_type)


## Called when wave timer times out (advance to next wave)
func _on_wave_timer_timeout() -> void:
	if not is_spawning:
		return

	# Complete current wave
	wave_completed.emit(current_wave)
	print("Wave ", current_wave, " completed! Enemies spawned: ", enemies_spawned_this_wave)

	# Advance to next wave
	current_wave += 1
	enemies_spawned_this_wave = 0

	# Check if this is a boss wave (every 10 waves)
	if current_wave % 10 == 0:
		_spawn_boss()

	# Update spawn interval for new wave
	var new_spawn_interval = _get_spawn_interval()
	spawn_timer.wait_time = new_spawn_interval

	wave_started.emit(current_wave)
	EventBus.wave_started.emit(current_wave)
	print("Wave ", current_wave, " started! Spawn interval: ", new_spawn_interval, "s")


## Spawn a boss enemy at the start of boss waves
func _spawn_boss() -> void:
	print("BOSS WAVE! Wave ", current_wave, " - Spawning Boss Enemy!")

	var boss_scene = load(BOSS_ENEMY)
	if not boss_scene:
		push_error("Failed to load boss enemy scene: ", BOSS_ENEMY)
		return

	var boss = boss_scene.instantiate()
	var spawn_pos = get_random_spawn_position()

	# Add boss to the scene
	get_tree().current_scene.add_child(boss)
	boss.global_position = spawn_pos

	# Emit boss spawned signal
	EventBus.mini_boss_spawned.emit()
	enemy_spawned.emit(boss)

	print("Boss spawned at position: ", spawn_pos)


## Optional: Track enemy deaths if needed
func _on_enemy_died() -> void:
	# Could track kills, adjust difficulty, etc.
	pass


## Find the procedural map generator in the scene
func _find_procedural_map_generator() -> void:
	# Search for ProceduralMapGenerator in the scene tree
	var root = get_tree().current_scene
	if not root:
		return

	# Search all children
	for child in root.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("ProceduralMapGenerator.gd"):
			procedural_map_generator = child
			print("WaveManager: Found ProceduralMapGenerator - using procedural spawn zones")
			return

	# If not found, we'll use the fallback circular spawn pattern
	print("WaveManager: No ProceduralMapGenerator found - using circular spawn pattern")
