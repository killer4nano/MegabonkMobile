# RangedEnemy Projectile Collision Test

## Bug Description
Rangers were not shooting visible projectiles that could be dodged. Two issues discovered:

### Bug #1: Projectiles passed through player (FIXED)
Projectiles spawned and flew but didn't collide with player.

### Bug #2: Instant damage on range entry (FIXED)
Player took damage immediately when entering 8m range, before projectile fired.

## Root Causes

### Bug #1: Collision Layer Mismatch
**Problem:** EnemyProjectile had `collision_mask = 1` (detects Layer 1) but Player is on Layer 3 (`collision_layer = 4`).

**Result:** Projectiles spawned and moved but passed through player without collision detection.

**Fix Applied:**
- `collision_layer = 4` (Layer 3 - enemy projectile)
- `collision_mask = 4` (detects Layer 3 - player) ✅ FIXED

**Files modified:**
- `scripts/enemies/EnemyProjectile.gd:19`
- `scenes/enemies/EnemyProjectile.tscn:19-20`

### Bug #2: Instant Contact Damage
**Problem:** BaseEnemy.gd automatically calls `attack_player()` when player enters AttackRange. For RangedEnemy (8m range), this caused instant contact damage before projectile fired.

**Result:** Player took 10 damage immediately when entering 8m range, defeating the purpose of dodgeable projectiles.

**Fix Applied:**
RangedEnemy now overrides:
- `_on_attack_range_entered()` - Does NOT call attack_player()
- `attack_player()` - Empty method (no contact damage)

**Files modified:**
- `scripts/enemies/RangedEnemy.gd:235-252`

## Automated Test

### Test Coverage
The automated test (`RangedEnemyProjectileTest.tscn`) verifies:

1. ✅ **Collision Layer Configuration**
   - Validates projectile has correct `collision_layer = 4`
   - Validates projectile has correct `collision_mask = 4`

2. ✅ **No Instant Damage on Range Entry** (NEW)
   - Creates RangedEnemy within 8m of player
   - Waits 1.5 seconds for range detection
   - Verifies player takes NO damage from contact
   - Ensures only projectiles can damage player

3. ✅ **Projectile Spawning**
   - Creates RangedEnemy near test player
   - Waits for enemy to charge (0.8s telegraph)
   - Verifies projectile is spawned after charge completes

4. ✅ **Projectile Collision Detection**
   - Monitors player health
   - Verifies NO damage before projectile hits
   - Confirms projectile deals damage on collision
   - Validates proper collision detection

### Running the Automated Test

#### Option 1: Batch File (Headless)
```bash
cd M:\GameProject\megabonk-mobile\scripts\testing
run_projectile_test.bat
```

**Note:** You may need to edit the batch file to set your Godot installation path.

#### Option 2: Godot Editor
1. Open Godot and load the project
2. Open scene: `res://scenes/testing/RangedEnemyProjectileTest.tscn`
3. Press **F6** (Run Current Scene)
4. Check the Output console for test results

#### Option 3: Command Line
```bash
godot --headless --path "M:\GameProject\megabonk-mobile" res://scenes/testing/RangedEnemyProjectileTest.tscn
```

### Expected Output
```
============================================================
RANGED ENEMY PROJECTILE COLLISION TEST
============================================================

[TEST 1] Projectile Collision Layers Configuration
  ✅ PASS: Collision layer=4 (expected 4)
  ✅ PASS: Collision mask=4 (expected 4)

[TEST 2] No Instant Damage on Range Entry
  Created test player at (5, 0, 0)
  Created RangedEnemy at (0, 0, 0)
  ✅ PASS: No instant damage when entering attack range
  ✅ Player health unchanged: 100

[TEST 3] RangedEnemy Projectile Spawning
  Created test player at (5, 0, 0)
  Created RangedEnemy at (0, 0, 0)
  ✅ PASS: Projectile spawned after 2.1s

[TEST 4] Projectile Hits Player
  Created test player at (5, 0, 0)
  Created RangedEnemy at (0, 0, 0)
  ✅ PASS: No instant damage on range entry
  ✅ PASS: Projectile hit player after 2.8s
  ✅ Player took 8 damage (health: 100 -> 92)

============================================================
TEST REPORT - RANGED ENEMY PROJECTILE COLLISION
============================================================
✅ Projectile Collision Layers Configuration: PASS
✅ No Instant Damage on Range Entry: PASS
✅ RangedEnemy Projectile Spawning: PASS
✅ Projectile Hits Player: PASS

------------------------------------------------------------
SUMMARY: 4/4 tests passed (0 failed)
============================================================

🎉 ALL TESTS PASSED! Projectile collision fix verified.
```

## Manual Testing Guide

If you prefer to verify manually:

1. **Launch the game**
   - Open `TestArena.tscn`
   - Press F6 to run

2. **Wait for RangedEnemies to spawn**
   - Green capsule enemies with 8m attack range
   - They stay back and shoot from distance

3. **Observe the attack sequence:**
   - ✅ Orange/yellow charge indicator appears (0.8s telegraph)
   - ✅ Green glowing projectile fires toward player
   - ✅ Projectile travels at 7.0 m/s (dodgeable)
   - ✅ Projectile hits player and deals 8 damage
   - ✅ Player health decreases

4. **Test dodging:**
   - Move perpendicular to projectile path
   - Projectile should miss and despawn after 5 seconds

## Technical Details

### Collision Layer Setup
| Entity | Collision Layer | Collision Mask | Purpose |
|--------|----------------|----------------|---------|
| Player | 4 (Layer 3) | 3 (Layers 1+2) | Character body |
| Enemy | 2 (Layer 2) | 5 (Layers 1+3) | Enemy body |
| EnemyProjectile | 4 (Layer 3) | 4 (Layer 3) | Hits player ✅ |
| PlayerProjectile | 16 (Layer 5) | 2 (Layer 2) | Hits enemies |

### RangedEnemy Attack Flow
1. **Detection:** Player enters 8m range
2. **Line of Sight:** Raycast check (prevents shooting through walls)
3. **Charge Telegraph:** 0.8s with orange sphere indicator
4. **Fire Projectile:** Spawns at enemy position + (0, 1.5, 0)
5. **Travel:** Projectile moves at 7.0 m/s toward player
6. **Collision:** Area3D detects player and calls `take_damage(8.0)`
7. **Cooldown:** 2.0s before next shot

### Projectile Properties
- **Speed:** 7.0 m/s (reduced from 10.0 for dodgeability)
- **Damage:** 8.0
- **Lifetime:** 5 seconds (auto-despawn)
- **Visual:** Green glowing sphere (0.2m radius)
- **Collision:** 0.2m radius sphere

## Success Criteria
- ✅ All 4 automated tests pass
- ✅ Projectiles are visible in-game
- ✅ Projectiles can be dodged by moving
- ✅ Projectiles deal 8 damage on contact
- ✅ NO instant damage when entering range
- ✅ NO instant damage when charge completes
- ✅ Only projectile collision deals damage

## Fixes Summary

### Before:
1. ❌ Projectiles passed through player (wrong collision mask)
2. ❌ Instant 10 damage when entering 8m range (auto attack_player call)
3. ❌ Projectiles visible but non-functional

### After:
1. ✅ Projectiles detect and collide with player (correct collision mask)
2. ✅ No instant damage - only projectiles damage player
3. ✅ Fully functional dodgeable projectile system
4. ✅ 0.8s charge telegraph before firing
5. ✅ 7.0 m/s projectile speed (balanced for dodging)

## Status
**READY FOR USER TESTING** - Both bugs fixed, automated tests updated to catch both issues.
