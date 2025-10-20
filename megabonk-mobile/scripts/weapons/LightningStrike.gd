extends BaseWeapon
class_name LightningStrike
## Lightning Strike weapon - Calls down lightning that chains between enemies

# Chain lightning settings
@export var chain_count: int = 3  # How many enemies it can chain to
@export var chain_range: float = 5.0  # Max distance for chain jumps
@export var chain_damage_falloff: float = 0.7  # Damage multiplier per chain (70% of previous)

# Visual
var visual_node: Node3D

# References
var player: Node3D

func _ready() -> void:
	# Set weapon type to ranged (uses auto-attack system)
	weapon_type = "ranged"

	# Call parent ready
	super._ready()

	# Find visual node
	visual_node = get_node_or_null("Visual")

	# Find player reference
	player = get_parent().get_parent() if get_parent() else null
	if not player:
		push_warning("LightningStrike: Could not find player!")

	DebugLogger.log("lightning_strike", "Lightning Strike ready! Damage: " + str(damage) + ", Cooldown: " + str(attack_cooldown) + "s, Chains: " + str(chain_count))

func _process(delta: float) -> void:
	"""Keep weapon positioned near player"""
	# Position at a fixed local offset (above player)
	var offset = Vector3(0.0, 1.5, 0.0)
	position = offset

func attack(target: Node3D) -> void:
	"""Strike target with lightning that chains to nearby enemies"""
	DebugLogger.log("lightning_strike", "attack() called! Target: " + (target.name if target else "null"))

	if not target or not is_instance_valid(target):
		DebugLogger.log("lightning_strike", "Invalid target, aborting")
		return

	# Start the chain lightning sequence
	var current_damage = damage
	var hit_enemies: Array[Node3D] = []
	var current_target = target

	# Chain through multiple enemies
	for chain_index in range(chain_count + 1):  # +1 for initial target
		if not current_target or not is_instance_valid(current_target):
			DebugLogger.log("lightning_strike", "Chain " + str(chain_index) + " - No valid target, ending chain")
			break

		# Don't hit the same enemy twice
		if current_target in hit_enemies:
			DebugLogger.log("lightning_strike", "Chain " + str(chain_index) + " - Already hit this enemy, ending chain")
			break

		# Deal damage to current target
		if current_target.has_method("take_damage"):
			current_target.take_damage(current_damage)
			hit_enemies.append(current_target)
			DebugLogger.log("lightning_strike", "Chain " + str(chain_index) + " - Hit " + current_target.name + " for " + str(current_damage) + " damage")

		# Find next target for chain
		var next_target = find_next_chain_target(current_target, hit_enemies)
		if next_target:
			# Reduce damage for next chain
			current_damage *= chain_damage_falloff
			current_target = next_target
		else:
			DebugLogger.log("lightning_strike", "Chain " + str(chain_index) + " - No more enemies in range, ending chain")
			break

	# Emit signal
	weapon_hit.emit(target)

	# Visual feedback
	if visual_node:
		_do_strike_animation()

	# Start cooldown timer
	can_attack = false
	attack_timer.start(attack_cooldown)
	DebugLogger.log("lightning_strike", "Lightning chain completed! Hit " + str(hit_enemies.size()) + " enemies. Cooldown: " + str(attack_cooldown) + "s")

func find_next_chain_target(from_enemy: Node3D, already_hit: Array[Node3D]) -> Node3D:
	"""Find the nearest enemy within chain range that hasn't been hit yet"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node3D = null
	var nearest_distance: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		# Skip if already hit
		if enemy in already_hit:
			continue

		# Check if in chain range
		var distance = from_enemy.global_position.distance_to(enemy.global_position)
		if distance <= chain_range and distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	return nearest_enemy

func _do_strike_animation() -> void:
	"""Visual feedback when striking"""
	if not visual_node:
		return

	# Scale pulse
	var original_scale = visual_node.scale
	visual_node.scale = original_scale * 1.5

	# Reset after delay
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(visual_node):
		visual_node.scale = original_scale
