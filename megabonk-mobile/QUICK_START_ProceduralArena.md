# Quick Start: Procedural Arena Testing

## How to Run the Procedural Map Generator

### Option 1: Run in Godot Editor (Recommended for Testing)

1. **Open Godot 4.5+**
   ```
   Open: M:\GameProject\megabonk-mobile\project.godot
   ```

2. **Open ProceduralArena Scene**
   ```
   Navigate to: res://scenes/maps/ProceduralArena.tscn
   ```

3. **Run the Scene**
   ```
   Press: F6 (or click "Play Scene" button)
   ```

4. **Observe Console Output**
   Look for generation logs:
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
   Pathfinding validation PASSED
   === PROCEDURAL MAP GENERATION COMPLETE ===
   ```

5. **Play the Game**
   - Use WASD to move (keyboard)
   - Use virtual joystick (on-screen, bottom-left)
   - Enemies spawn from random zones around perimeter
   - Each restart generates a NEW map!

### Option 2: Compare with Static Arena

**Test Static Arena (Original):**
```
Open: res://scenes/levels/TestArena.tscn
Press: F6
```
- This arena is ALWAYS THE SAME
- Good for testing baseline gameplay

**Test Procedural Arena:**
```
Open: res://scenes/maps/ProceduralArena.tscn
Press: F6
```
- This arena is DIFFERENT EVERY TIME
- Restart multiple times to see variety

## What to Look For

### Visual Indicators

✅ **Different Floor Colors Each Run**
- Desert: Tan/orange floor
- Ice: Light blue floor
- Lava: Dark red floor
- Forest: Green floor

✅ **Random Obstacle Placement**
- Pillars (cylinders)
- Boxes/walls (rectangles)
- Rocks (spheres)
- Different positions each run

✅ **Various Arena Sizes**
- Small: ~40x40m
- Medium: ~50x50m
- Large: ~60x60m

### Console Output Checklist

✅ "ProceduralMapGenerator: Using random seed"
✅ "Arena size: X x X" (40-60 range)
✅ "Color theme: [desert/ice/lava/forest]"
✅ "Obstacles placed: X / Y" (should match)
✅ "Pathfinding validation: 8 / 8 spawn zones reachable"
✅ "WaveManager: Found ProceduralMapGenerator"

### Gameplay Verification

✅ Player spawns in center (clear area)
✅ Enemies spawn from perimeter
✅ Enemies can navigate around obstacles
✅ Weapons hit enemies
✅ XP gems drop and collect
✅ Game runs smoothly (60 FPS)

## Testing Different Configurations

### Test Maximum Complexity

1. Open ProceduralArena.tscn
2. Select ProceduralMapGenerator node
3. In Inspector, set:
   - `arena_size_max = 60`
   - `obstacle_count_max = 20`
4. Run scene (F6)
5. Check performance - should still be smooth

### Test Minimum Complexity

1. Select ProceduralMapGenerator node
2. In Inspector, set:
   - `arena_size_min = 40`
   - `arena_size_max = 40`
   - `obstacle_count_min = 8`
   - `obstacle_count_max = 8`
3. Run scene (F6)
4. Map will always be 40x40 with exactly 8 obstacles

### Test Reproducible Maps (Seeds)

1. Select ProceduralMapGenerator node
2. In Inspector, set:
   - `use_seed = true`
   - `generation_seed = 12345`
3. Run scene (F6)
4. Note the exact layout
5. Restart scene
6. Layout should be IDENTICAL
7. Change `generation_seed` to different number
8. Layout should be DIFFERENT

### Test Color Theme Variety

Run the scene 10 times and track themes:
- Run 1: desert
- Run 2: ice
- Run 3: forest
- Run 4: lava
- Run 5: ice (can repeat)
- ... etc.

Should see all 4 themes appear multiple times.

## Common Issues & Solutions

### Issue: Map looks the same every time

**Check:**
- Is `use_seed` set to `true`? → Set to `false` for random
- Are min/max values the same? → Increase range for variety

### Issue: Enemies not spawning

**Check Console for:**
- "WaveManager: Found ProceduralMapGenerator" ✅
  - If NOT found → Check node name and script path
- "WaveManager: No ProceduralMapGenerator found" ❌
  - Means using fallback circular spawn (still works)

### Issue: "Obstacles placed: 10 / 15"

**Meaning:**
- Requested 15 obstacles, only placed 10
- Not enough space to place all obstacles
- **This is OK** - map still playable

**Fix (if needed):**
- Increase `arena_size_max`
- Decrease `obstacle_count_max`
- Decrease `min_obstacle_spacing`

### Issue: "Pathfinding validation FAILED"

**Meaning:**
- Some spawn zones unreachable from center
- Rare but can happen with dense obstacle placement
- **Map still playable** - just a warning

**Fix (if needed):**
- Restart scene for new generation
- Decrease `obstacle_count_max`
- Increase `min_obstacle_spacing`

## Performance Benchmarks

**Expected Frame Times:**
- Generation: <100ms (one-time at startup)
- Gameplay: <16ms (60 FPS during play)

**Check Performance:**
1. Run ProceduralArena.tscn
2. Click Debug → Show Monitors
3. Check FPS counter
4. Should be 60 FPS or higher

**On Low-End Devices:**
- Reduce `obstacle_count_max` to 12
- Reduce `arena_size_max` to 50
- Should improve performance

## Integration Testing

### Test Full Game Loop

1. Open ProceduralArena.tscn
2. Run scene (F6)
3. Play until level 2 (collect XP)
4. Verify upgrade screen appears
5. Choose upgrade
6. Continue playing
7. Verify all systems work:
   - ✅ Player movement
   - ✅ Weapon attacks
   - ✅ Enemy pathfinding
   - ✅ XP collection
   - ✅ Leveling system
   - ✅ Upgrade screen
   - ✅ Wave progression

### Test Extraction System (if implemented)

1. Run ProceduralArena.tscn
2. Wait 3 minutes (extraction zone spawns)
3. Navigate to extraction zone
4. Stand in zone for 5 seconds
5. Verify extraction succeeds
6. Check ExtractionSuccessScreen shows stats

## Customization Examples

### Create a "Nightmare Mode" Map

```gdscript
# In ProceduralMapGenerator node Inspector:
arena_size_min = 40
arena_size_max = 45  # Smaller arena
obstacle_count_min = 18
obstacle_count_max = 20  # Many obstacles
min_obstacle_spacing = 1.5  # Tighter spacing
center_clearance_radius = 3.0  # Less safe space
```

Result: Cramped, challenging arena with lots of obstacles

### Create a "Wide Open" Map

```gdscript
# In ProceduralMapGenerator node Inspector:
arena_size_min = 55
arena_size_max = 60  # Larger arena
obstacle_count_min = 8
obstacle_count_max = 10  # Few obstacles
min_obstacle_spacing = 4.0  # Wide spacing
center_clearance_radius = 8.0  # Lots of safe space
```

Result: Open, spacious arena with room to maneuver

### Create a "Ice Level" Only Map

```gdscript
# In ProceduralMapGenerator.gd, modify _select_color_theme():
func _select_color_theme() -> void:
    current_theme = color_themes["ice"]  # Force ice theme
    print("Color theme: ice (forced)")
```

Result: Every run uses ice theme colors

## Next Steps After Testing

Once you verify procedural generation works:

1. **Set as Main Scene (Optional):**
   - Project → Project Settings → General → Run
   - Set Main Scene: `res://scenes/maps/ProceduralArena.tscn`

2. **Update MainMenu (if exists):**
   - Point "Start Game" to ProceduralArena instead of TestArena

3. **Export to Mobile:**
   - Test generation time on real device
   - Verify performance acceptable
   - Adjust obstacle counts if needed

4. **Share with Testers:**
   - Get feedback on variety
   - Check if maps feel balanced
   - Collect favorite seeds

## Quick Reference: Key Nodes & Paths

**Scene:** `res://scenes/maps/ProceduralArena.tscn`
**Script:** `res://scripts/maps/ProceduralMapGenerator.gd`
**Docs:** `res://scripts/maps/README_ProceduralGeneration.md`

**Node to Configure:**
```
ProceduralArena
└── ProceduralMapGenerator <-- Select this in scene tree
    └── Inspector shows export parameters
```

**Files to Check:**
- Console output during generation
- Debugger profiler for performance
- Scene tree for generated geometry

---

**Ready to Test?** Open `ProceduralArena.tscn` and press F6! 🎮
