# Enemy Collision Precision Fix

## Bug Description
Enemies were dealing damage to the player **before actual visual contact occurred**. There was approximately a **1-meter gap** between the enemy's visual mesh and when damage would trigger, making combat feel unfair and preventing skillful dodging.

## Root Cause
Enemy attack ranges used large spherical detection zones that extended far beyond their visual meshes:

| Enemy | Visual Radius | OLD Attack Radius | Damage Gap |
|-------|--------------|-------------------|------------|
| BasicEnemy | 0.5m | **1.5m sphere** | **1.0m before contact!** |
| FastEnemy | 0.35m | **1.5m sphere** | **1.15m before contact!** |
| TankEnemy | 0.7m | **1.5m sphere** | **0.8m before contact!** |
| BossEnemy | 1.0m | **2.0m sphere** | **1.0m before contact!** |

**Result:** Player took damage while enemies were still visually far away, making dodging impossible and combat frustrating.

## Fix Applied

### 1. Attack Ranges Now Use Tight Capsules with Small Buffer

Changed attack detection from large spheres to precise capsules with just a 0.1m buffer:

| Enemy | Visual Shape | NEW Attack Shape | Buffer |
|-------|-------------|------------------|--------|
| BasicEnemy | Capsule 0.5m × 2.0m | Capsule 0.6m × 2.0m | **0.1m** |
| FastEnemy | Capsule 0.35m × 1.6m | Capsule 0.45m × 1.6m | **0.1m** |
| TankEnemy | Capsule 0.7m × 2.5m | Capsule 0.8m × 2.5m | **0.1m** |
| BossEnemy | Capsule 1.0m × 4.0m | Capsule 1.1m × 4.0m | **0.1m** |

**Benefits:**
- ✅ Damage occurs on **near-visual contact** (0.1m buffer covers edge cases)
- ✅ Extremely tight collision detection (60-70% tighter than before!)
- ✅ Enables skillful dodging and weaving through enemies
- ✅ Visual feedback closely matches gameplay mechanics
- ✅ Small buffer ensures enemies can actually hit you

### 2. Added Attack Cooldown System

Added 1-second cooldown between enemy attacks to prevent instant death on contact:

**New Variables in BaseEnemy.gd:**
```gdscript
var attack_cooldown: float = 1.0  # 1 second between attacks
var attack_timer: float = 0.0
```

**How it works:**
- Enemy deals damage on first contact
- Must wait 1 second before attacking again
- Allows player to briefly touch enemies without taking continuous damage
- Makes combat more skill-based and less punishing

## Files Modified

**Enemy Scenes (Attack Range Changed):**
1. `scenes/enemies/BaseEnemy.tscn` - Sphere 1.5m → Capsule 0.5m × 2.0m
2. `scenes/enemies/BasicEnemy.tscn` - Sphere 1.5m → Capsule 0.5m × 2.0m
3. `scenes/enemies/FastEnemy.tscn` - Sphere 1.5m → Capsule 0.35m × 1.6m
4. `scenes/enemies/TankEnemy.tscn` - Sphere 1.5m → Capsule 0.7m × 2.5m
5. `scenes/enemies/BossEnemy.tscn` - Sphere 2.0m → Capsule 1.0m × 4.0m

**Enemy Script (Cooldown System Added):**
- `scripts/enemies/BaseEnemy.gd`
  - Added `attack_cooldown` and `attack_timer` variables
  - Updated `_physics_process()` to tick down attack timer
  - Modified `attack_player()` to check cooldown before dealing damage
  - Updated `_on_attack_range_entered()` to respect cooldown

## Automated Test

### Test Suite: EnemyCollisionPrecisionTest.tscn

**Test Coverage (5 tests):**

1. ✅ **BasicEnemy Attack Range Buffer**
   - Verifies attack range has 0.1m buffer over collision
   - Checks buffer is within tolerance (0.05m - 0.15m)

2. ✅ **FastEnemy Attack Range Buffer**
   - Verifies attack range has 0.1m buffer over collision
   - Ensures smaller enemy has proportional detection

3. ✅ **TankEnemy Attack Range Buffer**
   - Verifies attack range has 0.1m buffer over collision
   - Ensures larger enemy has proportional detection

4. ✅ **No Damage Outside Attack Buffer**
   - Places player 1.2m away from 0.6m attack range enemy
   - Waits 2 seconds
   - Verifies NO damage occurs (outside attack buffer)

5. ✅ **1-Second Attack Cooldown**
   - Places player in contact with enemy
   - Verifies first attack deals damage
   - Waits 1 second
   - Confirms NO second attack during cooldown period

### Running the Test

#### Option 1: Godot Editor
1. Open scene: `res://scenes/testing/EnemyCollisionPrecisionTest.tscn`
2. Press **F6** (Run Current Scene)
3. Check Output console for results

#### Option 2: Command Line
```bash
godot --headless --path "M:\GameProject\megabonk-mobile" res://scenes/testing/EnemyCollisionPrecisionTest.tscn
```

### Expected Output
```
============================================================
ENEMY COLLISION PRECISION TEST
============================================================

[TEST 1] BasicEnemy Attack Range Buffer
  ✅ PASS: Attack range has 0.10m buffer (good)
    Collision: 0.50m radius
    Attack: 0.60m radius

[TEST 2] FastEnemy Attack Range Buffer
  ✅ PASS: Attack range has 0.10m buffer (good)
    Collision: 0.35m radius
    Attack: 0.45m radius

[TEST 3] TankEnemy Attack Range Buffer
  ✅ PASS: Attack range has 0.10m buffer (good)
    Collision: 0.70m radius
    Attack: 0.80m radius

[TEST 4] No Damage Outside Attack Buffer
  ✅ PASS: No damage when 1.2m away (outside 1.0m range)
    Player health unchanged: 100

[TEST 5] 1-Second Attack Cooldown
    First hit: 10 damage
  ✅ PASS: No second attack within 1 second
    Health stayed at 90 for 1 second

------------------------------------------------------------
TEST REPORT - ENEMY COLLISION PRECISION
------------------------------------------------------------
✅ BasicEnemy Attack Range Buffer: PASS
✅ FastEnemy Attack Range Buffer: PASS
✅ TankEnemy Attack Range Buffer: PASS
✅ No Damage Outside Attack Buffer: PASS
✅ 1-Second Attack Cooldown: PASS

------------------------------------------------------------
SUMMARY: 5/5 tests passed (0 failed)
============================================================

🎉 ALL TESTS PASSED! Collision precision verified.
✅ Enemies only damage on actual mesh contact
✅ No phantom damage outside visual range
✅ 1-second attack cooldown prevents spam
```

## Manual Testing Guide

To verify the fix in-game:

1. **Launch TestArena.tscn** (F6)

2. **Approach enemies closely:**
   - ✅ You can get **very close** without taking damage
   - ✅ Damage occurs when within **~0.1m of enemy surface**
   - ✅ Nearly-visual contact = gameplay contact (tiny 0.1m buffer)

3. **Test dodging:**
   - ✅ Weave between enemies without taking damage
   - ✅ Brief contact deals damage once, then 1-second immunity
   - ✅ Can dash past enemies without continuous damage

4. **Compare enemy sizes:**
   - BasicEnemy (medium) - 0.5m collision
   - FastEnemy (small) - 0.35m collision (easier to dodge)
   - TankEnemy (large) - 0.7m collision (harder to dodge)
   - Boss (huge) - 1.0m collision (challenging to avoid)

## Gameplay Impact

### Before (Broken):
- ❌ Damage triggers 1m before visual contact
- ❌ Impossible to dodge through enemy groups
- ❌ Combat feels unfair and unresponsive
- ❌ No skill expression in positioning
- ❌ Continuous damage on contact (instant death)

### After (Fixed):
- ✅ Damage on **near-visual contact** (0.1m buffer)
- ✅ Can skillfully dodge and weave through enemies
- ✅ Combat feels responsive and fair
- ✅ Rewards precise player positioning
- ✅ 1-second attack cooldown enables hit-and-run tactics
- ✅ Visual clarity closely matches gameplay mechanics
- ✅ Enemies can actually reach and damage you

## Technical Details

### Attack Range Configuration

**Before (SphereShape3D):**
```gdscript
[sub_resource type="SphereShape3D" id="SphereShape3D_attack"]
radius = 1.5  # Large sphere, extends far beyond mesh
```

**After (CapsuleShape3D with 0.1m buffer):**
```gdscript
[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_attack"]
radius = 0.6   # Visual is 0.5m, +0.1m buffer for edge cases
height = 2.0   # Matches visual height
```

### Cooldown Implementation

**Timer Update (_physics_process):**
```gdscript
if attack_timer > 0:
    attack_timer -= delta
```

**Attack Logic (attack_player):**
```gdscript
func attack_player() -> void:
    if attack_timer > 0.0:
        return  # Still on cooldown

    target_player.take_damage(damage, self)
    attack_timer = attack_cooldown  # Start 1-second cooldown
```

### Collision Layer Setup
- **Enemy Body:** Layer 2, Mask 5
- **Enemy AttackRange:** Layer 0, Mask 4 (detects player only)
- **Player Body:** Layer 3 (bit value 4)

The AttackRange Area3D detects when player enters the capsule zone, but now that zone is **exactly the same size** as the visual mesh, so damage occurs on visual contact.

## Balance Considerations

### Attack Cooldown Tuning
The 1-second cooldown can be adjusted per enemy type if needed:

**Example for faster attacks (aggressive enemies):**
```gdscript
# In FastEnemy.gd or BasicEnemy.gd
func _ready():
    super._ready()
    attack_cooldown = 0.5  # Attack twice per second
```

**Example for slower attacks (tanky enemies):**
```gdscript
# In TankEnemy.gd
func _ready():
    super._ready()
    attack_cooldown = 2.0  # Attack every 2 seconds (more forgiving)
```

Currently all enemies use the base 1.0 second cooldown for consistency.

## Performance Impact

**Minimal:** Changed from SphereShape3D to CapsuleShape3D - both are primitive shapes with negligible performance difference. The collision detection is equally fast.

## Success Criteria

- ✅ All 5 automated tests pass
- ✅ Attack ranges have small 0.1m buffer over visual meshes
- ✅ Player can get very close without damage (60-70% tighter than before)
- ✅ Damage occurs on near-visual contact (0.1m buffer)
- ✅ Enemies can successfully reach and damage player
- ✅ 1-second cooldown between attacks
- ✅ Combat feels fair and skill-based
- ✅ Can weave through enemy groups

## Status
**READY FOR USER TESTING** - All changes implemented and tested.
