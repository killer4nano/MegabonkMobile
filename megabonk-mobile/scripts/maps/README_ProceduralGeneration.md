# Procedural Map Generation System

## Overview

The Procedural Map Generation system creates unique, playable arenas for each game session, significantly improving replayability. Each run generates a fresh layout with randomized obstacles, colors, and arena sizes while maintaining balanced gameplay.

## Components

### ProceduralMapGenerator.gd
**Location:** `megabonk-mobile/scripts/maps/ProceduralMapGenerator.gd`

The core script that handles all procedural generation logic.

#### Key Features:
- **Random Arena Size:** 40-60m (configurable via exports)
- **Obstacle Placement:** 8-20 random obstacles with spacing validation
- **Color Themes:** 4 preset themes (Desert, Ice, Lava, Forest)
- **Navigation Mesh:** Runtime-generated for enemy pathfinding
- **Spawn Zones:** 8 enemy spawn points evenly distributed around perimeter
- **Pathfinding Validation:** Ensures all spawn zones are reachable
- **Seed Support:** Optional seed for reproducible maps (testing/debugging)

#### Export Parameters:

```gdscript
# Arena Size
@export var arena_size_min: int = 40
@export var arena_size_max: int = 60

# Obstacles
@export var obstacle_count_min: int = 8
@export var obstacle_count_max: int = 20
@export var min_obstacle_spacing: float = 2.0
@export var center_clearance_radius: float = 5.0

# Randomization
@export var use_seed: bool = false
@export var generation_seed: int = 0

# Visual Themes
@export var randomize_colors: bool = true
```

### ProceduralArena.tscn
**Location:** `megabonk-mobile/scenes/maps/ProceduralArena.tscn`

The scene that contains the ProceduralMapGenerator and all game systems.

#### Scene Hierarchy:
```
ProceduralArena (Node3D)
├── ProceduralMapGenerator (Node3D) - Generates map at runtime
├── GameManager (Node) - Game loop control
├── WaveManager (Node) - Enemy spawning
├── Player (CharacterBody3D) - Player character
├── TouchControls (Control) - Mobile input
├── HUD (Control) - User interface
└── UpgradeScreen (Control) - Level-up system
```

## Generation Pipeline

The map generation follows these steps in order:

1. **Initialize RNG** - Set up random number generator with seed or random
2. **Generate Arena Size** - Random size between min/max
3. **Select Color Theme** - Choose from 4 preset themes or random
4. **Create Floor** - Generate floor mesh with collision
5. **Create Boundary Walls** - 4 walls around perimeter
6. **Place Obstacles** - Random placement with spacing validation
7. **Create Navigation Mesh** - Runtime navmesh baking
8. **Calculate Spawn Zones** - 8 enemy spawn points around perimeter
9. **Validate Pathfinding** - Ensure all zones reachable from center
10. **Create Lighting** - Directional light with shadows
11. **Create Environment** - Sky color based on theme

## Obstacle Types

The system randomly selects from three obstacle types:

### Pillar (CSGCylinder3D)
- **Radius:** 0.5-1.2m
- **Height:** 3-5m
- **Best for:** Creating line-of-sight blockers

### Box/Wall (CSGBox3D)
- **Width:** 1.5-4.0m
- **Height:** 1.5-3.0m
- **Depth:** 1.5-4.0m
- **Best for:** Larger cover areas

### Rock (CSGSphere3D)
- **Radius:** 0.8-1.5m
- **Best for:** Natural-looking obstacles

## Color Themes

### Desert Theme
- **Floor:** Tan/Orange (0.85, 0.7, 0.4)
- **Obstacles:** Brown (0.6, 0.4, 0.2)
- **Sky:** Warm yellow (0.95, 0.8, 0.5)

### Ice Theme
- **Floor:** Light blue (0.7, 0.85, 0.95)
- **Obstacles:** Cyan (0.4, 0.6, 0.8)
- **Sky:** Cool blue (0.6, 0.75, 0.9)

### Lava Theme
- **Floor:** Dark red (0.3, 0.15, 0.15)
- **Obstacles:** Orange (0.8, 0.3, 0.1)
- **Sky:** Dark orange (0.4, 0.2, 0.15)

### Forest Theme (Default)
- **Floor:** Green (0.3, 0.5, 0.3)
- **Obstacles:** Brown (0.4, 0.3, 0.2)
- **Sky:** Blue sky (0.53, 0.73, 0.87)

## Validation & Safety

### Center Clearance
- **Radius:** 5m around center (Vector3.ZERO)
- **Purpose:** Ensures player spawns in safe area with no obstacles
- **Validation:** Every obstacle placement checks distance from center

### Obstacle Spacing
- **Minimum Distance:** 2m between any two obstacles
- **Purpose:** Prevents clustering and ensures navigation paths
- **Validation:** Each new obstacle checks all existing obstacles

### Pathfinding Validation
- **Test:** Path from center to all 8 spawn zones
- **Method:** NavigationServer3D.map_get_path()
- **Result:** Warnings if any zone unreachable (generation continues)

## Integration with Existing Systems

### WaveManager Integration
The WaveManager has been updated to support procedural spawn zones:

```gdscript
# In WaveManager.gd
func get_random_spawn_position() -> Vector3:
    # If procedural map exists, use its spawn zones
    if procedural_map_generator and procedural_map_generator.has_method("get_random_spawn_zone"):
        return procedural_map_generator.get_random_spawn_zone()

    # Fallback: circular spawn pattern (static maps)
    # ...
```

This ensures backward compatibility with static maps (TestArena, Map01) while supporting procedural generation.

### GameManager Compatibility
No changes needed - GameManager automatically discovers player, controls, and managers through groups and node paths.

## Public API

### get_player_spawn_position() -> Vector3
Returns the safe player spawn position (always center at y=1)

### get_enemy_spawn_zones() -> Array[Vector3]
Returns array of all 8 enemy spawn positions

### get_random_spawn_zone() -> Vector3
Returns a random enemy spawn zone (used by WaveManager)

### regenerate_map() -> void
Clears and regenerates the entire map with new random layout

### get_arena_size() -> int
Returns current arena size in meters

### get_navigation_region() -> NavigationRegion3D
Returns the navigation region for pathfinding access

## Testing & Debugging

### Using Seeds for Reproducible Maps
To test specific layouts, enable seed mode:

1. Open ProceduralArena.tscn
2. Select ProceduralMapGenerator node
3. Set `use_seed = true`
4. Set `generation_seed` to desired value (e.g., 12345)
5. Run scene

Same seed will always generate the same map.

### Performance Monitoring
The generator prints detailed logs during generation:

```
=== PROCEDURAL MAP GENERATION STARTED ===
Arena size: 52 x 52
Color theme: ice
Floor created: 52 x 52
Boundary walls created
Obstacles placed: 15 / 15 requested
Navigation mesh created and baked
Enemy spawn zones calculated: 8 zones
=== VALIDATING PATHFINDING ===
Pathfinding validation: 8 / 8 spawn zones reachable
Pathfinding validation PASSED - all zones reachable
Lighting created
Environment created
=== PROCEDURAL MAP GENERATION COMPLETE ===
Total obstacles placed: 15
Enemy spawn zones: 8
```

### Common Issues

**Issue:** Obstacles placed: X / Y (X < Y)
- **Cause:** Not enough space to place all requested obstacles
- **Solution:** Increase arena size or decrease obstacle count

**Issue:** Pathfinding validation FAILED
- **Cause:** Obstacles blocking paths to spawn zones
- **Solution:** This is a warning, not critical. Map still playable but some zones may be unreachable

**Issue:** No enemies spawning
- **Cause:** WaveManager not finding ProceduralMapGenerator
- **Solution:** Check console for "WaveManager: Found ProceduralMapGenerator" message

## Mobile Performance

The system is optimized for mobile devices:

- **CSG Nodes:** Fast procedural geometry (no separate mesh files)
- **Obstacle Limit:** Max 20 obstacles
- **Simple Shapes:** Only boxes, cylinders, spheres
- **Static Geometry:** No physics calculations after generation
- **Single Navmesh Bake:** Only baked once at startup

**Performance Target:** <100ms total generation time

## Future Enhancements

Potential improvements for post-MVP:

1. **Organic Shapes:** Non-rectangular arena boundaries
2. **Hazard Zones:** Lava pools, ice patches
3. **Multi-Level Terrain:** Hills and valleys
4. **Destructible Obstacles:** Break walls during combat
5. **Themed Obstacle Sets:** Desert rocks, ice crystals, etc.
6. **Difficulty-Based Generation:** Harder waves = more obstacles
7. **Save Favorite Seeds:** Let players replay good maps

## Files Modified

- **Created:** `megabonk-mobile/scripts/maps/ProceduralMapGenerator.gd`
- **Created:** `megabonk-mobile/scenes/maps/ProceduralArena.tscn`
- **Modified:** `megabonk-mobile/scripts/managers/WaveManager.gd` (procedural spawn zone support)

## Credits

Implemented for TASK-005 to add massive replayability value to Megabonk Mobile.
Each run now provides a unique experience while maintaining balanced gameplay.
