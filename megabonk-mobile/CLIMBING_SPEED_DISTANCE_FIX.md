# Climbing Speed & Distance Fix

**Issues Fixed:**
1. Enemies climbing too fast (unrealistic speed)
2. Enemies only climbing when player is close to obstacles

**Date:** 2025-10-20
**Status:** FIXED ✅

---

## Speed Adjustments

### Base Climb Speed
- **Before:** 8.0 m/s (way too fast!)
- **After:** 3.0 m/s (realistic climbing pace)

### Speed Multipliers for Tall Walls
| Wall Height | Old Multiplier | New Multiplier | Final Speed |
|-------------|---------------|----------------|-------------|
| <10m | 1.0x | 1.0x | 3.0 m/s |
| 10-20m | 1.5x | 1.2x | 3.6 m/s |
| >20m | 2.0x | 1.4x | 4.2 m/s |

### Edge Clearing Speed
- **Before:** 4.0x move speed (too aggressive)
- **After:** 2.5x move speed (strong but realistic)

### Vertical Push During Edge Clear
- **Before:** 2.0 m/s upward
- **After:** 1.5 m/s upward

---

## Distance Fixes

### Detection Range Changes

| System | Old Distance | New Distance | Impact |
|--------|--------------|--------------|---------|
| **Proximity Check** | 5.0m | 20.0m (detection_range) | Climbs from far away |
| **Stuck Detection** | >3.0m only | >1.5m | Works at most distances |
| **Proactive Check** | No limit | Within detection_range | Consistent with AI range |

### Key Changes

1. **Proximity Climbing Check**
   - Now uses `detection_range` (20.0m) instead of hardcoded 5.0m
   - Enemies will attempt to climb when player is elevated anywhere within their detection range

2. **Stuck Detection Distance**
   - Reduced from 3.0m to 1.5m minimum distance
   - Now detects stuck state even when close to player

3. **Proactive Climbing**
   - Added explicit distance check using detection_range
   - Ensures consistent behavior across all detection systems

---

## Result

### Before
- Enemies zoomed up walls at superhuman speed
- Only climbed when player was within 5m of obstacle
- Looked unnatural and game-breaking

### After
- Realistic climbing speed (3 m/s base)
- Climbs from anywhere within detection range (20m)
- Natural-looking vertical movement
- Consistent behavior at all distances

---

## Testing

Run TestArena.tscn and observe:

1. **Speed**: Enemies climb at a steady, realistic pace (not super-fast)
2. **Distance**: Stand far from walls (15-20m) - enemies still climb to reach you
3. **Consistency**: Works whether you're close or far from obstacles

---

## Technical Summary

The fixes ensure that:
- Climbing speed is realistic and proportional to wall height
- Distance limitations have been removed/expanded to match AI detection range
- All climbing systems (proximity, stuck, proactive) use consistent distance checks
- The system works naturally at any distance within enemy detection range

**Enemies now climb at a realistic speed and will do so from any distance within their detection range (20m).**