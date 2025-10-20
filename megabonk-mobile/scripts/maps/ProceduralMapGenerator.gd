extends Node3D
## ProceduralMapGenerator - Generates unique, playable arenas each game session
##
## This script creates procedurally generated maps with random layouts, obstacles,
## and visual themes. Each run provides a fresh experience with validated pathfinding.

# Generation Parameters
@export_category("Arena Size")
@export var arena_size_min: int = 600
@export var arena_size_max: int = 1000

@export_category("Obstacles")
@export var obstacle_count_min: int = 80
@export var obstacle_count_max: int = 180
@export var min_obstacle_spacing: float = 10.0
@export var center_clearance_radius: float = 30.0  # Safe spawn area (bigger for larger maps)

@export_category("Randomization")
@export var use_seed: bool = false
@export var generation_seed: int = 0

@export_category("Visual Themes")
@export var randomize_colors: bool = true

# Color theme presets
var color_themes = {
	"desert": {
		"floor": Color(0.85, 0.7, 0.4),
		"obstacles": Color(0.6, 0.4, 0.2),
		"sky": Color(0.95, 0.8, 0.5)
	},
	"ice": {
		"floor": Color(0.7, 0.85, 0.95),
		"obstacles": Color(0.4, 0.6, 0.8),
		"sky": Color(0.6, 0.75, 0.9)
	},
	"lava": {
		"floor": Color(0.3, 0.15, 0.15),
		"obstacles": Color(0.8, 0.3, 0.1),
		"sky": Color(0.4, 0.2, 0.15)
	},
	"forest": {
		"floor": Color(0.3, 0.5, 0.3),
		"obstacles": Color(0.4, 0.3, 0.2),
		"sky": Color(0.53, 0.73, 0.87)
	}
}

# Runtime variables
var rng: RandomNumberGenerator
var nav_region: NavigationRegion3D
var arena_size: int
var obstacle_count: int
var current_theme: Dictionary
var placed_obstacles: Array[Vector3] = []
var enemy_spawn_zones: Array[Vector3] = []

# Signals
signal map_generated(size: int, obstacles: int, theme_name: String)

func _ready() -> void:
	_initialize_rng()
	_generate_arena()

func _initialize_rng() -> void:
	"""Initialize random number generator with seed or random"""
	rng = RandomNumberGenerator.new()
	if use_seed:
		rng.seed = generation_seed
		print("ProceduralMapGenerator: Using seed %d" % generation_seed)
	else:
		rng.randomize()
		print("ProceduralMapGenerator: Using random seed")

func _generate_arena() -> void:
	"""Main generation pipeline - orchestrates all generation steps"""
	print("\n=== PROCEDURAL MAP GENERATION STARTED ===")

	# Step 1: Generate arena size
	arena_size = rng.randi_range(arena_size_min, arena_size_max)
	print("Arena size: %d x %d" % [arena_size, arena_size])

	# Step 2: Choose color theme
	_select_color_theme()

	# Step 3: Create floor
	_create_floor()

	# Step 4: Create boundary walls
	_create_walls()

	# Step 5: Place obstacles
	obstacle_count = rng.randi_range(obstacle_count_min, obstacle_count_max)
	_place_obstacles()

	# Step 6: Create navigation mesh
	_create_navigation_mesh()

	# Step 7: Calculate enemy spawn zones
	_calculate_spawn_zones()

	# Step 8: Validate pathfinding
	await _validate_pathfinding()

	# Step 9: Apply lighting
	_create_lighting()

	# Step 10: Create environment
	_create_environment()

	print("=== PROCEDURAL MAP GENERATION COMPLETE ===")
	print("Total obstacles placed: %d" % placed_obstacles.size())
	print("Enemy spawn zones: %d" % enemy_spawn_zones.size())

	# Emit completion signal
	var theme_name = "random"
	for key in color_themes.keys():
		if color_themes[key] == current_theme:
			theme_name = key
			break

	map_generated.emit(arena_size, placed_obstacles.size(), theme_name)

func _select_color_theme() -> void:
	"""Choose a random color theme or use default"""
	if randomize_colors:
		var theme_keys = color_themes.keys()
		var random_theme = theme_keys[rng.randi_range(0, theme_keys.size() - 1)]
		current_theme = color_themes[random_theme]
		print("Color theme: %s" % random_theme)
	else:
		current_theme = color_themes["forest"]
		print("Color theme: forest (default)")

func _create_floor() -> void:
	"""Create the arena floor plane"""
	# Create NavigationRegion3D first (it will contain the floor)
	nav_region = NavigationRegion3D.new()
	nav_region.name = "NavigationRegion3D"
	add_child(nav_region)

	# Create floor StaticBody3D
	var floor_body = StaticBody3D.new()
	floor_body.name = "Ground"
	nav_region.add_child(floor_body)

	# Create floor mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "FloorMesh"
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(arena_size, arena_size)
	mesh_instance.mesh = plane_mesh

	# Apply material with theme color
	var material = StandardMaterial3D.new()
	material.albedo_color = current_theme["floor"]
	mesh_instance.set_surface_override_material(0, material)

	floor_body.add_child(mesh_instance)

	# Create floor collision
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(arena_size, 0.1, arena_size)
	collision_shape.shape = box_shape
	floor_body.add_child(collision_shape)

	print("Floor created: %d x %d" % [arena_size, arena_size])

func _create_walls() -> void:
	"""Create boundary walls around the arena perimeter"""
	var wall_height = 5.0
	var wall_thickness = 1.0
	var half_size = arena_size / 2.0

	# Wall positions: North, South, East, West
	var wall_configs = [
		{"pos": Vector3(0, wall_height/2, -half_size), "size": Vector3(arena_size, wall_height, wall_thickness)},  # North
		{"pos": Vector3(0, wall_height/2, half_size), "size": Vector3(arena_size, wall_height, wall_thickness)},   # South
		{"pos": Vector3(-half_size, wall_height/2, 0), "size": Vector3(wall_thickness, wall_height, arena_size)},  # West
		{"pos": Vector3(half_size, wall_height/2, 0), "size": Vector3(wall_thickness, wall_height, arena_size)}    # East
	]

	for config in wall_configs:
		var wall = _create_wall(config["pos"], config["size"])
		nav_region.add_child(wall)

	print("Boundary walls created")

func _create_wall(pos: Vector3, size: Vector3) -> StaticBody3D:
	"""Create a single wall segment"""
	var wall_body = StaticBody3D.new()
	wall_body.position = pos

	# Create CSG box for visual
	var csg_box = CSGBox3D.new()
	csg_box.size = size

	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = current_theme["obstacles"].darkened(0.2)
	csg_box.material = material

	wall_body.add_child(csg_box)

	# Create collision
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	wall_body.add_child(collision_shape)

	return wall_body

func _place_obstacles() -> void:
	"""Place obstacles using grid-based random placement with spacing validation"""
	placed_obstacles.clear()
	var attempts_per_obstacle = 20  # Max attempts to find valid position
	var obstacles_placed = 0

	for i in range(obstacle_count):
		var position_found = false

		for attempt in range(attempts_per_obstacle):
			var pos = _generate_random_position()

			# Validate position
			if _is_valid_obstacle_position(pos):
				_create_obstacle(pos, i)
				placed_obstacles.append(pos)
				obstacles_placed += 1
				position_found = true
				break

		if not position_found:
			print("Warning: Could not place obstacle %d after %d attempts" % [i, attempts_per_obstacle])

	print("Obstacles placed: %d / %d requested" % [obstacles_placed, obstacle_count])

func _generate_random_position() -> Vector3:
	"""Generate a random 2D position within arena bounds"""
	var half_size = arena_size / 2.0
	var margin = 3.0  # Distance from walls

	var x = rng.randf_range(-half_size + margin, half_size - margin)
	var z = rng.randf_range(-half_size + margin, half_size - margin)

	return Vector3(x, 0, z)

func _is_valid_obstacle_position(pos: Vector3) -> bool:
	"""Validate if position is suitable for obstacle placement"""
	# Check distance from center (player spawn)
	if pos.distance_to(Vector3.ZERO) < center_clearance_radius:
		return false

	# Check distance from other obstacles
	for existing_pos in placed_obstacles:
		if pos.distance_to(existing_pos) < min_obstacle_spacing:
			return false

	return true

func _create_obstacle(pos: Vector3, index: int) -> void:
	"""Create a single obstacle with random type and size"""
	var obstacle_body = StaticBody3D.new()
	obstacle_body.name = "Obstacle_%d" % index
	obstacle_body.position = pos

	# Random obstacle type
	var obstacle_type = rng.randi_range(0, 2)
	var csg_node: CSGPrimitive3D

	match obstacle_type:
		0:  # Pillar (cylinder) - REDUCED height for climbing
			var cylinder = CSGCylinder3D.new()
			cylinder.radius = rng.randf_range(0.5, 1.2)
			cylinder.height = rng.randf_range(1.0, 2.5)  # Reduced from 3.0-5.0 to 1.0-2.5
			cylinder.sides = 8
			csg_node = cylinder
			obstacle_body.position.y = cylinder.height / 2.0

		1:  # Box/Wall - REDUCED height for climbing
			var box = CSGBox3D.new()
			box.size = Vector3(
				rng.randf_range(1.5, 4.0),  # width
				rng.randf_range(1.0, 2.0),  # height - Reduced from 1.5-3.0 to 1.0-2.0
				rng.randf_range(1.5, 4.0)   # depth
			)
			csg_node = box
			obstacle_body.position.y = box.size.y / 2.0

		2:  # Rock (sphere) - REDUCED height for climbing
			var sphere = CSGSphere3D.new()
			sphere.radius = rng.randf_range(0.6, 1.2)  # Reduced from 0.8-1.5 to 0.6-1.2
			sphere.radial_segments = 8
			sphere.rings = 6
			csg_node = sphere
			obstacle_body.position.y = sphere.radius

	# Apply random material color (variation of theme)
	var material = StandardMaterial3D.new()
	var base_color = current_theme["obstacles"]
	# Add slight color variation
	var variation = rng.randf_range(-0.1, 0.1)
	material.albedo_color = Color(
		clamp(base_color.r + variation, 0, 1),
		clamp(base_color.g + variation, 0, 1),
		clamp(base_color.b + variation, 0, 1)
	)
	csg_node.material = material

	obstacle_body.add_child(csg_node)

	# Create collision shape matching the CSG
	var collision_shape = CollisionShape3D.new()
	var shape: Shape3D

	if csg_node is CSGCylinder3D:
		var cylinder_shape = CylinderShape3D.new()
		cylinder_shape.radius = csg_node.radius
		cylinder_shape.height = csg_node.height
		shape = cylinder_shape
	elif csg_node is CSGBox3D:
		var box_shape = BoxShape3D.new()
		box_shape.size = csg_node.size
		shape = box_shape
	elif csg_node is CSGSphere3D:
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = csg_node.radius
		shape = sphere_shape

	collision_shape.shape = shape
	obstacle_body.add_child(collision_shape)

	# Add to navigation region so it affects navmesh
	nav_region.add_child(obstacle_body)

func _create_navigation_mesh() -> void:
	"""Create and bake navigation mesh at runtime"""
	# BUG FIX: TASK-012 - Explicitly bake NavigationMesh for runtime generation
	# Issue: Godot 4.x requires manual bake_navigation_mesh() call for procedural geometry
	# The automatic baking only works for pre-built scenes, not runtime generation
	# Date: 2025-10-20

	var nav_mesh = NavigationMesh.new()

	# Configure navigation mesh parameters
	# BUG FIX: TASK-015 - Allow enemies to climb over obstacles (reduced obstacle heights)
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 3.0  # Climb over obstacles up to 2.5 units (max obstacle height)
	nav_mesh.agent_max_slope = 45.0  # Allow climbing slopes
	nav_mesh.cell_size = 0.3
	nav_mesh.cell_height = 0.2  # Standard value for good accuracy

	# Set the navigation mesh
	nav_region.navigation_mesh = nav_mesh

	# Wait for geometry to be ready (all obstacles placed)
	await get_tree().process_frame
	await get_tree().process_frame

	# BUG FIX: Explicitly bake the navigation mesh for runtime procedural generation
	# In Godot 4.x, runtime-generated geometry requires explicit baking
	nav_region.bake_navigation_mesh()

	# Wait for bake to complete (baking is async)
	await get_tree().create_timer(0.5).timeout

	print("Navigation mesh explicitly baked for procedural geometry")

func _calculate_spawn_zones() -> void:
	"""Calculate enemy spawn zones around the player (15m radius)"""
	enemy_spawn_zones.clear()
	var spawn_count = 8  # Evenly distributed spawn points
	var spawn_radius = 15.0  # FIXED: Spawn 15m from player for close combat

	for i in range(spawn_count):
		var angle = (2.0 * PI / spawn_count) * i
		var x = cos(angle) * spawn_radius
		var z = sin(angle) * spawn_radius
		var spawn_pos = Vector3(x, 0, z)
		enemy_spawn_zones.append(spawn_pos)

	print("Enemy spawn zones calculated: %d zones at 15m radius" % spawn_count)

func _create_lighting() -> void:
	"""Create directional light for the arena"""
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.transform = Transform3D(
		Vector3(1, 0, 0),
		Vector3(0, 0.707107, 0.707107),
		Vector3(0, -0.707107, 0.707107),
		Vector3(0, 10, 0)
	)
	light.shadow_enabled = true
	add_child(light)

	print("Lighting created")

func _create_environment() -> void:
	"""Create world environment with theme-appropriate sky color"""
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = current_theme["sky"]
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE

	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = environment
	add_child(world_env)

	print("Environment created")

func _validate_pathfinding() -> void:
	"""Validate that all spawn zones are reachable from center"""
	print("\n=== VALIDATING PATHFINDING ===")

	# Wait for navigation mesh to fully bake
	await get_tree().process_frame
	await get_tree().process_frame

	if not nav_region or not nav_region.navigation_mesh:
		push_error("Navigation mesh not found! Pathfinding validation failed.")
		return

	var center_pos = Vector3.ZERO
	var validation_passed = true
	var reachable_zones = 0

	# Test pathfinding from center to each spawn zone
	for i in range(enemy_spawn_zones.size()):
		var spawn_pos = enemy_spawn_zones[i]

		# Use NavigationServer3D to check if path exists
		var map_rid = nav_region.get_navigation_map()
		var path = NavigationServer3D.map_get_path(map_rid, center_pos, spawn_pos, true)

		if path.size() > 0:
			reachable_zones += 1
		else:
			push_warning("Spawn zone %d at %v is NOT reachable from center!" % [i, spawn_pos])
			validation_passed = false

	print("Pathfinding validation: %d / %d spawn zones reachable" % [reachable_zones, enemy_spawn_zones.size()])

	if validation_passed:
		print("Pathfinding validation PASSED - all zones reachable")
	else:
		push_warning("Pathfinding validation FAILED - some zones unreachable")
		print("Map may have gameplay issues, but generation continues")

# Public API for external systems

func get_player_spawn_position() -> Vector3:
	"""Returns the safe player spawn position (always center)"""
	return Vector3(0, 1, 0)

func get_enemy_spawn_zones() -> Array[Vector3]:
	"""Returns array of enemy spawn positions around perimeter"""
	return enemy_spawn_zones

func get_random_spawn_zone() -> Vector3:
	"""Returns a random enemy spawn zone"""
	if enemy_spawn_zones.is_empty():
		return Vector3.ZERO
	return enemy_spawn_zones[rng.randi_range(0, enemy_spawn_zones.size() - 1)]

func regenerate_map() -> void:
	"""Regenerate the entire map with new random layout"""
	# Clear existing children
	for child in get_children():
		child.queue_free()

	# Reset state
	placed_obstacles.clear()
	enemy_spawn_zones.clear()

	# Regenerate
	_initialize_rng()
	await get_tree().process_frame  # Wait for cleanup
	_generate_arena()

func get_arena_size() -> int:
	"""Returns the current arena size"""
	return arena_size

func get_navigation_region() -> NavigationRegion3D:
	"""Returns the navigation region for pathfinding"""
	return nav_region
