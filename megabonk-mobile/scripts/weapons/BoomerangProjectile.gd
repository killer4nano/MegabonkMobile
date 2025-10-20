extends Area3D
class_name BoomerangProjectile
## Boomerang projectile - flies out, then returns to player, damaging enemies twice

# Projectile stats
var damage: float = 20.0
var speed: float = 15.0
var max_distance: float = 8.0
var return_speed_multiplier: float = 1.2

# Movement
var velocity: Vector3 = Vector3.ZERO
var start_position: Vector3 = Vector3.ZERO
var player_position: Vector3 = Vector3.ZERO

# State
enum State { OUTBOUND, RETURNING }
var current_state: State = State.OUTBOUND
var hit_enemies: Dictionary = {}  # Track which enemies we've hit (enemy: state_when_hit)
var hit_cooldown: float = 0.3  # Cooldown per enemy between outbound and return hits

func _ready() -> void:
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)

	# Set collision layers
	collision_layer = 0  # Projectile doesn't block anything
	collision_mask = 2   # Detect enemies (layer 2)

	DebugLogger.log("boomerang_projectile", "Boomerang spawned - damage: " + str(damage) + ", speed: " + str(speed))

func _physics_process(delta: float) -> void:
	match current_state:
		State.OUTBOUND:
			_handle_outbound(delta)
		State.RETURNING:
			_handle_returning(delta)

	# Rotate visual for spin effect
	rotation.y += delta * 10.0

	# Clean up old hit tracking
	var current_time = Time.get_ticks_msec() / 1000.0
	var enemies_to_remove = []
	for enemy in hit_enemies:
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
	for enemy in enemies_to_remove:
		hit_enemies.erase(enemy)

func _handle_outbound(delta: float) -> void:
	"""Move outbound until max distance reached"""
	# Move forward
	global_position += velocity * delta

	# Check if we've traveled max distance
	var distance_traveled = start_position.distance_to(global_position)
	if distance_traveled >= max_distance:
		# Switch to return mode
		current_state = State.RETURNING
		speed *= return_speed_multiplier
		DebugLogger.log("boomerang_projectile", "Switching to RETURNING state")

func _handle_returning(delta: float) -> void:
	"""Return to player position"""
	# Update player position (in case player moved)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_position = players[0].global_position + Vector3.UP * 1.0

	# Move toward player
	var direction_to_player = global_position.direction_to(player_position)
	velocity = direction_to_player * speed
	global_position += velocity * delta

	# Check if we've reached player
	var distance_to_player = global_position.distance_to(player_position)
	if distance_to_player < 0.5:
		DebugLogger.log("boomerang_projectile", "Returned to player, despawning")
		despawn()

func _on_body_entered(body: Node3D) -> void:
	"""Handle collision with enemy"""
	DebugLogger.log("boomerang_projectile", "body_entered - " + body.name + " (state: " + str(current_state) + ")")

	# Check if it's an enemy
	if not body.is_in_group("enemies"):
		DebugLogger.log("boomerang_projectile", "Not an enemy, ignoring")
		return

	# Check if we've already hit this enemy in the current state
	if hit_enemies.has(body):
		var hit_state = hit_enemies[body]
		if hit_state == current_state:
			DebugLogger.log("boomerang_projectile", "Already hit in this state, ignoring")
			return

	# Deal damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
		hit_enemies[body] = current_state
		var state_name = "OUTBOUND" if current_state == State.OUTBOUND else "RETURNING"
		DebugLogger.log("boomerang_projectile", "HIT (" + state_name + ")! Dealing " + str(damage) + " damage to " + body.name)

func despawn() -> void:
	"""Remove the projectile"""
	DebugLogger.log("boomerang_projectile", "queue_free() called - despawning")
	queue_free()

func initialize(start_pos: Vector3, initial_direction: Vector3, projectile_damage: float, projectile_speed: float, max_dist: float, return_multiplier: float, player_pos: Vector3) -> void:
	"""Initialize projectile with starting parameters"""
	DebugLogger.log("boomerang_projectile", "initialize() called")
	DebugLogger.log("boomerang_projectile", "  start_position: " + str(start_pos))
	DebugLogger.log("boomerang_projectile", "  initial_direction: " + str(initial_direction))
	DebugLogger.log("boomerang_projectile", "  damage: " + str(projectile_damage))
	DebugLogger.log("boomerang_projectile", "  speed: " + str(projectile_speed))

	global_position = start_pos
	start_position = start_pos
	player_position = player_pos
	velocity = initial_direction.normalized() * projectile_speed
	damage = projectile_damage
	speed = projectile_speed
	max_distance = max_dist
	return_speed_multiplier = return_multiplier
	current_state = State.OUTBOUND

	DebugLogger.log("boomerang_projectile", "Initialized at " + str(global_position) + " moving at " + str(velocity))
