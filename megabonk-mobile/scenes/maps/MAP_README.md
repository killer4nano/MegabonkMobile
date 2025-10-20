# Megabonk Mobile - Maps

This directory contains the playable arena maps for Megabonk Mobile.

## Available Maps

### Map01_TestArena.tscn
- **Theme:** Grassland/Forest
- **Size:** 50x50m
- **Color Scheme:** Green ground (0.3, 0.5, 0.3), blue sky
- **Layout:** Open arena with shrines positioned at corners and edges
- **Obstacles:** 3 shrines (Health, Damage, Speed)
- **Visual Style:** Natural, peaceful environment

### Map02_VolcanoArena.tscn
- **Theme:** Volcano/Lava
- **Size:** 60x60m (larger than Map01)
- **Color Scheme:** Dark red/brown ground, orange ambient lighting
- **Layout:** Arena with volcanic rock obstacles
- **Obstacles:** 6 large lava rocks positioned strategically, 3 shrines
- **Visual Style:** Dangerous, heated environment with glow effects
- **Unique Features:**
  - Warm orange/red ambient lighting
  - Glow enabled for atmospheric effect
  - Larger arena size for more tactical gameplay
  - Rock obstacles provide cover and tactical positioning

## IMPORTANT: NavMesh Baking Required

**CRITICAL:** NavigationRegion3D nodes in these maps have navigation meshes defined, but they **MUST be baked manually** in the Godot editor before the maps will function properly with enemy pathfinding.

### How to Bake NavMesh:

1. Open the map scene in Godot editor (e.g., `Map02_VolcanoArena.tscn`)
2. Select the `NavigationRegion3D` node in the scene tree
3. In the top toolbar, click the **"Bake NavigationMesh"** button
4. Wait for the baking process to complete (should be instant for these simple arenas)
5. Save the scene (Ctrl+S)
6. The NavMesh is now ready for runtime pathfinding

**Without baking:** Enemies using NavigationAgent3D will not be able to pathfind properly and may get stuck or behave erratically.

## Map Structure

All maps follow this standard structure:

```
MapXX_ThemeName.tscn
├── GameManager (Node) - Controls game loop
├── WaveManager (Node) - Spawns enemy waves
├── NavigationRegion3D
│   ├── Ground (StaticBody3D with mesh + collision)
│   └── Obstacles (Node3D container for rocks/obstacles)
├── Player (instance)
├── DirectionalLight3D
├── WorldEnvironment
├── TouchControls (instance)
├── HUD (instance)
├── UpgradeScreen (instance)
└── Shrines (Health, Damage, Speed instances)
```

## Design Guidelines for New Maps

When creating additional maps:

1. **Size:** 40x60m range for tactical variety
2. **Spawn Point:** Player always spawns at center (0, 1, 0)
3. **Enemy Spawning:** WaveManager spawns enemies in 20m radius circle
4. **NavigationRegion3D:** Must encompass entire playable area
5. **Obstacles:** Optional but recommended for tactical gameplay
6. **Visual Theme:** Use distinct color schemes and lighting
7. **Shrines:** Position at 10-15m from center for risk/reward
8. **Collision:** All obstacles need StaticBody3D + CollisionShape3D
9. **NavMesh:** Remember to bake in editor after creation!

## Map Selection

Currently, maps are loaded individually by opening their scene. Future implementations may include:
- Map selection UI in main menu
- Random map selection at game start
- Progressive unlock system
- Map-specific challenges or modifiers

## Technical Details

### NavigationMesh Parameters
- Agent radius: Default (0.5m)
- Agent height: Default (2.0m)
- Cell size: Default (0.25m)
- Coverage: Full arena bounds

### Lighting
- Map01: Neutral white light, cool blue sky
- Map02: Warm orange light, reddish atmosphere

### Performance
- Both maps are optimized for mobile
- Low poly count for obstacles
- Simple materials with minimal textures
- Efficient collision shapes

## Testing Maps

To test a map:
```bash
# In Godot editor
godot --path "M:\GameProject\megabonk-mobile" res://scenes/maps/Map02_VolcanoArena.tscn

# Or open in editor and press F6 to run current scene
```

Verify:
- Player spawns at center
- Movement works correctly
- Enemies spawn and pathfind properly (after NavMesh bake!)
- Shrines are interactive
- Obstacles block movement
- Camera controls work
