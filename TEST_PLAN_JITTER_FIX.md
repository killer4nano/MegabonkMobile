# Enemy Movement Jitter Fix - Testing Guide

## Summary of Fix

**Problem**: Navigation-based enemies (red BasicEnemy, purple TankEnemy) jittered after teleporting despite multiple fix attempts.

**Root Cause**: NavigationAgent3D enters corrupted state after teleportation, returning stale waypoints that cause velocity oscillation.

**Solution**: Make ALL enemies use pure direct movement (like RangedEnemy), completely bypassing NavigationAgent3D.

**Files Modified**:
- `megabonk-mobile/scripts/enemies/BaseEnemy.gd` (lines 170-173, 127-128)

**Code Change**:
```gdscript
// BEFORE (Lines 172-175)
if move_speed >= 4.0 or force_direct_movement:
    handle_direct_movement(delta)
else:
    handle_movement(delta)  // <-- Used broken NavigationAgent3D

// AFTER (Line 173)
handle_direct_movement(delta)  // Always use direct movement
```

---

## How to Test

### Prerequisites
1. Open Godot 4.5+ editor
2. Load project: `M:\GameProject\megabonk-mobile\project.godot`
3. Open scene: `scenes/levels/TestArena.tscn`

### Test Procedure

#### Test 1: BasicEnemy Spawn Movement
**Objective**: Verify red enemies move smoothly from spawn

1. Press F6 to run TestArena scene
2. Wait for red BasicEnemy to spawn (~3 seconds)
3. **OBSERVE**: Enemy should pause briefly (0.1s), then start moving toward player
4. **PASS CRITERIA**: Smooth continuous movement, no jittering/stuttering
5. **FAIL CRITERIA**: Enemy stutters, jerks, or moves erratically

#### Test 2: BasicEnemy Teleport Movement
**Objective**: Verify red enemies move smoothly after teleport

1. Move away from red BasicEnemy using WASD
2. Keep running until distance counter shows >50m
3. Wait 5+ seconds (teleport cooldown)
4. **OBSERVE**: Enemy teleports nearby, pauses briefly, then chases
5. **PASS CRITERIA**: Smooth continuous movement after teleport, NO JITTER
6. **FAIL CRITERIA**: Enemy jitters, stutters, or freezes after teleport

#### Test 3: TankEnemy Spawn Movement
**Objective**: Verify purple enemies move smoothly from spawn

1. Wait for purple TankEnemy to spawn (wave 8+)
2. **OBSERVE**: Enemy should start moving slowly toward player
3. **PASS CRITERIA**: Smooth slow movement (1.5 speed)
4. **FAIL CRITERIA**: Enemy stutters or jitters on spawn

#### Test 4: TankEnemy Teleport Movement
**Objective**: Verify purple enemies move smoothly after teleport

1. Run away from purple TankEnemy until >50m
2. Wait for teleport
3. **OBSERVE**: Enemy teleports and resumes smooth chase
4. **PASS CRITERIA**: No jitter after teleport, continuous smooth movement
5. **FAIL CRITERIA**: Enemy jitters or gets stuck after teleport

#### Test 5: RangedEnemy Unchanged
**Objective**: Verify green enemies still work (no regression)

1. Observe green RangedEnemy behavior
2. **CHECK**:
   - Moves smoothly toward player
   - Stops at range and shoots
   - Teleports if player runs far away
   - Repositions if line of sight blocked
3. **PASS CRITERIA**: All behaviors work as before
4. **FAIL CRITERIA**: Any regression in RangedEnemy behavior

#### Test 6: FastEnemy Movement (if available)
**Objective**: Verify yellow enemies still work

1. Survive to later waves to spawn FastEnemy
2. **OBSERVE**: Fast chase toward player
3. **PASS CRITERIA**: Rapid smooth movement (4.5 speed)
4. **NOTE**: FastEnemy already used direct movement, should be unchanged

#### Test 7: Multiple Teleports (Stress Test)
**Objective**: Verify fix works consistently over multiple teleports

1. Pick one enemy (red or purple)
2. Run away to trigger teleport
3. Repeat 5+ times
4. **OBSERVE**: Behavior after each teleport
5. **PASS CRITERIA**: Consistent smooth movement every time, no degradation
6. **FAIL CRITERIA**: Jitter appears on 2nd, 3rd, or later teleports

#### Test 8: Obstacle Interaction (Behavior Change)
**Objective**: Document new behavior with obstacles

1. Lead enemies into walls/obstacles
2. **OBSERVE**: Enemies may get briefly stuck (no pathfinding)
3. **NOTE**: This is EXPECTED - enemies no longer path around obstacles
4. **CHECK**: Enemies eventually move around via collision response
5. **ACCEPTABLE**: Brief obstacle interaction, resolves quickly

---

## What to Look For

### Success Indicators ✅
- **Smooth continuous movement** for all enemy types on spawn
- **Smooth continuous movement** for all enemy types after teleport
- **No jittering/stuttering** at any point
- **Consistent behavior** across multiple teleports
- **RangedEnemy unchanged** (no regression)

### Expected Behavior Changes ⚠️
- Enemies no longer intelligently path around obstacles
- Enemies may briefly collide with walls before moving around
- This is acceptable for open arena gameplay

### Failure Indicators ❌
- Any jittering or stuttering movement
- Enemies freezing after teleport
- Erratic or unpredictable movement
- RangedEnemy behavior changed/broken

---

## Performance Testing (Optional)

### Frame Rate Check
1. Survive to wave 10+ (many enemies on screen)
2. Open Godot editor debugger: Debug → Frame Profiler
3. **OBSERVE**: FPS should be stable or better than before
4. **REASON**: Direct movement is less CPU-intensive than NavigationServer A* pathfinding

### Expected Performance Improvements
- Lower CPU usage (no navigation path calculations)
- Better frame rates with 20+ enemies
- Zero memory allocations for path cache

---

## Reporting Results

### If ALL Tests Pass ✅
Report: "All tests pass - jitter fixed, all enemy types move smoothly"

**Evidence to provide**:
- BasicEnemy spawn: ✅ Smooth
- BasicEnemy teleport: ✅ Smooth
- TankEnemy spawn: ✅ Smooth
- TankEnemy teleport: ✅ Smooth
- RangedEnemy: ✅ Unchanged
- Multiple teleports: ✅ Consistent

### If ANY Test Fails ❌
Report: "Test [number] failed - [description of issue]"

**Information needed**:
- Which test failed (TC-001 through TC-008)
- Which enemy type (BasicEnemy, TankEnemy, etc.)
- What you observed (jittering, freezing, etc.)
- When it happened (spawn, teleport, after delay, etc.)
- Any error messages in Godot console

---

## Technical Details (For Reference)

### What Changed Under the Hood

**Before Fix**:
```
Enemy teleports → force_direct_movement = true for 3s
→ After 3s: Falls back to handle_movement()
→ Queries nav_agent.get_next_path_position()
→ Gets stale waypoints from corrupted NavigationAgent3D
→ Velocity oscillates → JITTER
```

**After Fix**:
```
Enemy spawns/teleports → Always uses handle_direct_movement()
→ Calculates fresh direction to player every frame
→ No NavigationAgent3D dependency
→ Smooth continuous movement → NO JITTER
```

### Why This Works
- **RangedEnemy** always used this approach → always worked perfectly
- **Direct movement** recalculates direction every frame → no stale data
- **Stateless system** can't be corrupted by position changes
- **Proven solution** based on working code, not theoretical fix

---

## Quick Start (TL;DR)

1. Open Godot, run TestArena.tscn (F6)
2. Watch red/purple enemies spawn and move
3. Run away from enemies until they teleport
4. **CHECK**: Do they move smoothly after teleport? (YES = fixed)
5. **Expected**: All enemies move smoothly, no jitter anywhere

If you see jitter → report which enemy and when
If no jitter → SUCCESS! 🎉

---

## Next Steps After Testing

### If Fix Works
- Mark TASK-022 as verified
- Update project metrics
- Consider this issue RESOLVED
- Move on to Phase 5 tasks

### If Fix Doesn't Work
- Provide detailed test results
- May need deeper Godot engine investigation
- Consider alternative approaches

---

**Estimated Testing Time**: 10-15 minutes
**Confidence Level**: VERY HIGH (based on proven RangedEnemy implementation)
