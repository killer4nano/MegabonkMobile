extends Node3D
class_name WeaponManager
## Manages all equipped weapons for the player
## Handles weapon spawning, upgrades, and removal

# Equipped weapons
var equipped_weapons: Array[Node3D] = []

# References
var player: Node3D

func _ready() -> void:
	# Get player reference (parent should be player)
	player = get_parent()
	if not player:
		push_warning("WeaponManager: No player found!")

	print("WeaponManager initialized")

	# Connect to EventBus for weapon events
	EventBus.weapon_equipped.connect(_on_weapon_equipped_event)

	# Register any weapons that are already children (from scene setup)
	for child in get_children():
		if child is Node3D:
			equipped_weapons.append(child)
			print("WeaponManager: Registered existing weapon - ", child.name)
			# Connect weapon signals
			if child.has_signal("weapon_hit"):
				child.weapon_hit.connect(_on_weapon_hit)

func add_weapon(weapon_scene: PackedScene) -> Node3D:
	"""Equip a new weapon from a scene"""
	if not weapon_scene:
		push_error("WeaponManager: Invalid weapon scene!")
		return null

	# Instantiate weapon
	var weapon = weapon_scene.instantiate()
	if not weapon is Node3D:
		push_error("WeaponManager: Weapon must be a Node3D!")
		weapon.queue_free()
		return null

	# Add as child
	add_child(weapon)
	equipped_weapons.append(weapon)

	print("WeaponManager: Equipped weapon - ", weapon.name)

	# Emit event
	EventBus.weapon_equipped.emit(weapon)

	# Connect weapon signals
	if weapon.has_signal("weapon_hit"):
		weapon.weapon_hit.connect(_on_weapon_hit)

	return weapon

func add_weapon_instance(weapon: Node3D) -> void:
	"""Add an already-instantiated weapon"""
	if not weapon:
		push_error("WeaponManager: Invalid weapon instance!")
		return

	# Add as child if not already
	if weapon.get_parent() != self:
		add_child(weapon)

	equipped_weapons.append(weapon)
	print("WeaponManager: Added weapon instance - ", weapon.name)

	# Emit event
	EventBus.weapon_equipped.emit(weapon)

	# Connect weapon signals
	if weapon.has_signal("weapon_hit"):
		weapon.weapon_hit.connect(_on_weapon_hit)

func equip_weapon(weapon) -> void:
	"""Equip a weapon - accepts either String (weapon ID) or Node3D (instance)"""
	if weapon is String:
		# Load and equip weapon by ID
		equip_weapon_by_id(weapon)
	elif weapon is Node3D:
		# Equip weapon instance directly
		add_weapon_instance(weapon)
	else:
		push_error("WeaponManager: equip_weapon() expects String or Node3D, got: ", typeof(weapon))

func remove_weapon(weapon: Node3D) -> void:
	"""Remove a weapon from the player"""
	if not weapon in equipped_weapons:
		push_warning("WeaponManager: Weapon not found in equipped list!")
		return

	equipped_weapons.erase(weapon)
	weapon.queue_free()
	print("WeaponManager: Removed weapon - ", weapon.name)

func upgrade_weapon(weapon: Node3D) -> void:
	"""Upgrade a weapon to the next level"""
	if not weapon in equipped_weapons:
		push_warning("WeaponManager: Cannot upgrade weapon not in equipped list!")
		return

	if weapon.has_method("upgrade"):
		weapon.upgrade()
		print("WeaponManager: Upgraded weapon - ", weapon.name)
	else:
		push_warning("WeaponManager: Weapon does not have upgrade method!")

func get_weapon_count() -> int:
	"""Return the number of equipped weapons"""
	return equipped_weapons.size()

func get_all_weapons() -> Array[Node3D]:
	"""Return all equipped weapons"""
	return equipped_weapons

func clear_all_weapons() -> void:
	"""Remove all weapons (useful for reset/death)"""
	for weapon in equipped_weapons:
		if is_instance_valid(weapon):
			weapon.queue_free()
	equipped_weapons.clear()
	print("WeaponManager: All weapons cleared")

func equip_starting_weapon(weapon_id: String) -> void:
	"""Equip the starting weapon by ID (clears existing weapons first)"""
	# Clear any existing weapons
	clear_all_weapons()

	# Equip the starting weapon
	equip_weapon_by_id(weapon_id)

func equip_weapon_by_id(weapon_id: String) -> Node3D:
	"""Load and equip a weapon by its ID"""
	# Map weapon IDs to scene paths
	const WEAPON_SCENES = {
		"bonk_hammer": "res://scenes/weapons/BonkHammer.tscn",
		"magic_missile": "res://scenes/weapons/MagicMissile.tscn",
		"spinning_blade": "res://scenes/weapons/SpinningBlade.tscn",
		"fireball": "res://scenes/weapons/Fireball.tscn",
		"lightning_strike": "res://scenes/weapons/LightningStrike.tscn",
		"laser_beam": "res://scenes/weapons/LaserBeam.tscn",
		"boomerang": "res://scenes/weapons/Boomerang.tscn",
		"poison_cloud": "res://scenes/weapons/PoisonCloud.tscn",
		"shield_ring": "res://scenes/weapons/ShieldRing.tscn",
		"ice_beam": "res://scenes/weapons/IceBeam.tscn",
		"ground_slam": "res://scenes/weapons/GroundSlam.tscn"
	}

	if not weapon_id in WEAPON_SCENES:
		push_error("WeaponManager: Unknown weapon ID: ", weapon_id)
		return null

	var weapon_path = WEAPON_SCENES[weapon_id]
	var weapon_scene: PackedScene = load(weapon_path)

	if not weapon_scene:
		push_error("WeaponManager: Failed to load weapon scene: ", weapon_path)
		return null

	return add_weapon(weapon_scene)

func _on_weapon_hit(target: Node3D) -> void:
	"""Called when any weapon hits an enemy"""
	# This can be used for global effects, sounds, etc.
	pass

func _on_weapon_equipped_event(weapon: Node) -> void:
	"""Handle weapon equipped event from EventBus"""
	# This allows other systems to react to weapon changes
	pass
