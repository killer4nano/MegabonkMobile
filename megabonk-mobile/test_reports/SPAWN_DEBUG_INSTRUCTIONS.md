# Spawn Position Bug - Debug Testing Instructions

## Issue
First enemy spawns directly under the player at game start.

## Testing Infrastructure Created

### 1. Automated Test Scene
**Location:** `scenes/testing/SpawnPositionTest.tscn`

This is a minimal test scene that runs automated spawn position verification tests.

**To run:**
- Open the scene in Godot 4.5+
- Press F6 (Run Current Scene)
- Check the console output for detailed test results

### 2. Test Script
**Location:** `scripts/testing/SpawnPositionTest.gd`

**Tests performed:**
1. **Spawn Position Calculation** - Verifies get_random_spawn_position() returns valid positions
2. **Multiple Spawns** - Tests 10 consecutive spawns to verify consistency
3. **Player Position Usage** - Confirms spawn positions follow player movement

**Success Criteria:**
- All spawns must be >= 15m from player
- Spawn distance should be ~20m (arena_radius)
- Spawns should update when player moves

### 3. Enhanced Debug Logging
**Location:** `scripts/managers/WaveManager.gd`

Added comprehensive debug logging to:
- `spawn_enemy()` - Lines 99-151
- `get_random_spawn_position()` - Lines 154-195

**Debug output includes:**
- Player position when spawn calculated
- Random angle generated
- Offset calculations
- Final spawn position
- Distance verification
- Error messages if spawn too close

## How to Debug

### Method 1: Play TestArena.tscn (Quickest)
1. Open `scenes/levels/TestArena.tscn` in Godot
2. Press F6 to run
3. Watch the console output carefully
4. Look for the debug section when first enemy spawns (~3 seconds after start)
5. Check the distance value

**Expected Console Output:**
```
============================================================
DEBUG: spawn_enemy() called
============================================================
DEBUG: Player found at: (0, 1, 0)
DEBUG: Calling get_random_spawn_position()...
  DEBUG: get_random_spawn_position() START
  DEBUG: Looking for player...
  DEBUG: Player found! Position: (0, 1, 0)
  DEBUG: Random angle: XXX degrees
  DEBUG: arena_radius: 20
  DEBUG: Offset from center: (X, 0, Z)
  DEBUG: Final spawn position: (X, 1, Z)
  DEBUG: get_random_spawn_position() END
DEBUG: Spawn position calculated: (X, 1, Z)
DEBUG: Player position: (0, 1, 0)
DEBUG: Spawn position: (X, 1, Z)
DEBUG: Distance: 20.00m
DEBUG: arena_radius = 20m
OK: Spawn distance acceptable
============================================================
```

**If distance shows < 15m:**
- Something is wrong with the spawn calculation
- Copy the console output and share it

**If distance shows ~20m but enemy still spawns under you:**
- The spawn position calculation is correct
- The bug is in how the enemy's position is being set
- We'll need to investigate enemy instantiation

### Method 2: Run Automated Tests
1. Open `scenes/testing/SpawnPositionTest.tscn`
2. Press F6
3. Read test results in console
4. Check user data folder for detailed report

**Report Location:**
```
Windows: C:\Users\[USERNAME]\AppData\Roaming\Godot\app_userdata\megabonk-mobile\
File: spawn_position_test_report.txt
```

### Method 3: Use Batch File (if Godot in PATH)
1. Run `RUN_SPAWN_TEST.bat`
2. Check output

## What to Report

Please copy and paste the **entire debug output** from the first enemy spawn, including:
- All DEBUG lines
- The distance calculation
- Any ERROR or WARNING messages
- What position you see the enemy spawn at in-game

This will help identify exactly where the spawn calculation is failing.

## Expected Fix

Once we identify the issue from the debug output, the fix will likely be one of:

1. **Timing issue** - Player not ready when spawn calculated
2. **Position setting issue** - enemy.global_position not being set correctly
3. **Scene structure issue** - Enemy being added to wrong parent node
4. **Calculation error** - Math error in spawn position formula

The detailed logging will reveal which one it is.
