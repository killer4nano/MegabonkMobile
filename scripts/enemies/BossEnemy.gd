extends BaseEnemy
class_name BossEnemy
## Boss enemy with multiple attack patterns: charge, ground slam, and minion summoning

# Attack pattern configuration
@export var charge_cooldown: float = 5.0
@export var charge_speed_multiplier: float = 2.5
@export var charge_duration: float = 1.5

@export var slam_radius: float = 3.0
@export var slam_damage: float = 25.0
@export var slam_cooldown: float = 7.0

@export var summon_cooldown: float = 10.0
@export var summons_per_cast: int = 2

# Attack state
enum AttackState { NORMAL, CHARGING, SLAMMING }
var current_attack_state: AttackState = AttackState.NORMAL

# Attack timers
var charge_timer: float = 0.0
var slam_timer: float = 0.0
var summon_timer: float = 0.0

var is_charging: bool = false
var charge_time: float = 0.0
var original_speed: float = 0.0

# Minion spawning
const BASIC_ENEMY_SCENE = preload("res://scenes/enemies/BasicEnemy.tscn")

func _ready() -> void:
	super._ready()

	# Set boss specific values
	max_health = 500.0
	current_health = max_health
	move_speed = 2.5
	damage = 30.0  # Contact damage
	xp_value = 100.0
	gold_value = 50
	original_speed = move_speed

	# Initialize attack cooldown timers
	charge_timer = charge_cooldown
	slam_timer = slam_cooldown
	summon_timer = summon_cooldown

	print("BossEnemy spawned - HP: ", max_health, " Speed: ", move_speed, " BOSS MODE ACTIVATED!")

func _should_update_navigation_path() -> bool:
	"""BossEnemy uses direct movement, not NavigationAgent3D"""
	return false

func _process_enemy_behavior(delta: float) -> void:
	"""Override base behavior to implement boss attack patterns"""
	# Update attack cooldowns
	_update_attack_cooldowns(delta)

	# Update current attack state
	_update_attack_state(delta)

	# Handle movement based on state
	if current_attack_state == AttackState.NORMAL:
		# Use base class direct movement (smooth, no jitter)
		if not navigation_ready:
			velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		else:
			handle_direct_movement(delta)
	elif current_attack_state == AttackState.CHARGING:
		# Charge directly at player at high speed
		_handle_charge_movement(delta)
	elif current_attack_state == AttackState.SLAMMING:
		# Stop and perform slam attack
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)

	# Rotate to face movement direction (or player if slamming)
	if current_attack_state == AttackState.SLAMMING and target_player:
		var direction_to_player = global_position.direction_to(target_player.global_position)
		direction_to_player.y = 0
		if direction_to_player.length() > 0.1:
			var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	elif velocity.length() > 0.1:
		var target_direction = velocity.normalized()
		var target_rotation = atan2(target_direction.x, target_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

func _update_attack_cooldowns(delta: float) -> void:
	"""Update all attack cooldown timers"""
	if current_attack_state == AttackState.NORMAL:
		charge_timer -= delta
		slam_timer -= delta
		summon_timer -= delta

func _update_attack_state(delta: float) -> void:
	"""Manage attack state machine and trigger attacks"""
	if current_attack_state == AttackState.NORMAL:
		# Check if we should trigger an attack
		var distance_to_player = global_position.distance_to(target_player.global_position)

		# Priority: Slam > Charge > Summon
		if slam_timer <= 0.0 and distance_to_player <= slam_radius + 2.0:
			_start_ground_slam()
		elif charge_timer <= 0.0:
			_start_charge_attack()
		elif summon_timer <= 0.0:
			_summon_minions()

	elif current_attack_state == AttackState.CHARGING:
		# Update charge duration
		charge_time += delta
		if charge_time >= charge_duration:
			_end_charge_attack()

	elif current_attack_state == AttackState.SLAMMING:
		# Slam animation/delay handled in _start_ground_slam()
		pass

func _start_charge_attack() -> void:
	"""Begin charge attack - rush at player at high speed"""
	current_attack_state = AttackState.CHARGING
	is_charging = true
	charge_time = 0.0
	move_speed = original_speed * charge_speed_multiplier
	charge_timer = charge_cooldown

	print("BOSS CHARGING! Speed boosted to ", move_speed)

func _end_charge_attack() -> void:
	"""End charge attack - return to normal movement"""
	current_attack_state = AttackState.NORMAL
	is_charging = false
	move_speed = original_speed

	print("Boss charge attack ended")

func _handle_charge_movement(delta: float) -> void:
	"""Direct movement during charge attack"""
	if not target_player or not is_instance_valid(target_player):
		velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
		return

	# Direct movement toward player - no pathfinding
	var direction = global_position.direction_to(target_player.global_position)
	direction.y = 0  # Keep on ground plane
	direction = direction.normalized()

	# Set velocity directly toward player
	var effective_speed = move_speed * slow_multiplier
	var target_velocity = direction * effective_speed
	velocity = velocity.lerp(target_velocity, acceleration * delta * 2.0)  # Faster acceleration during charge

func _start_ground_slam() -> void:
	"""Perform AOE ground slam attack"""
	current_attack_state = AttackState.SLAMMING
	slam_timer = slam_cooldown

	print("BOSS GROUND SLAM!")

	# Wait a brief moment (slam animation time)
	await get_tree().create_timer(0.3).timeout

	if not is_alive:
		return

	# Deal damage to player if in radius
	if target_player and is_instance_valid(target_player):
		var distance = global_position.distance_to(target_player.global_position)
		if distance <= slam_radius:
			if target_player.has_method("take_damage"):
				target_player.take_damage(slam_damage, self)
				print("Boss ground slam hit player for ", slam_damage, " damage!")

	# TODO: Visual effect (particle system, shockwave)

	# Return to normal state
	current_attack_state = AttackState.NORMAL

func _summon_minions() -> void:
	"""Summon BasicEnemy minions to assist boss"""
	summon_timer = summon_cooldown

	print("BOSS SUMMONING MINIONS!")

	for i in range(summons_per_cast):
		# Spawn minion near boss
		var minion = BASIC_ENEMY_SCENE.instantiate()

		# Random position around boss (1-3 meters away)
		var angle = randf() * TAU
		var distance = randf_range(1.5, 3.0)
		var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)

		# Add to scene
		get_parent().add_child(minion)
		minion.global_position = global_position + offset

		print("  Summoned minion at offset: ", offset)

func attack_player() -> void:
	"""Override base attack - boss has custom attack patterns"""
	if not is_alive or not target_player:
		return

	# Deal contact damage to player (still dangerous to touch)
	if target_player.has_method("take_damage"):
		target_player.take_damage(damage, self)
		print("BossEnemy dealt contact damage: ", damage)

func die() -> void:
	"""Override death to add boss-specific death behavior"""
	if not is_alive:
		return

	print("BOSS DEFEATED!")

	# Emit special boss death signal
	EventBus.mini_boss_spawned.emit()  # Reusing signal as boss_defeated notification

	# Call parent die() for standard death behavior
	super.die()
