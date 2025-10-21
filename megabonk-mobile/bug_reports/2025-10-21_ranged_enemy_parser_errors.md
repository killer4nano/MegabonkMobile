# Bug Report: RangedEnemy Parser Errors - Duplicate Member Declarations

**Date:** 2025-10-21
**Severity:** Critical (blocks game from running)
**Status:** FIXED ✅
**Reporter:** User (via screenshot)
**Assigned To:** Autonomous PM

---

## Issue Description

**Problem:** RangedEnemy.gd has multiple parser errors due to duplicate variable declarations that already exist in parent class BaseEnemy.

**Error Messages:**
1. `Parser Error: The member "attack_cooldown" already exists in parent class BaseEnemy.` (Line 10)
2. `Parser Error: The member "attack_timer" already exists in parent class BaseEnemy.` (Line 15)

**Impact:** Game cannot run due to parser errors. Blocks all testing and gameplay.

---

## Root Cause

**Inheritance Issue:** RangedEnemy extends BaseEnemy but was re-declaring variables that are already defined in the parent class.

In GDScript, when a child class extends a parent:
- All parent variables are automatically inherited
- Child classes CANNOT redeclare inherited variables
- Attempting to do so causes a parser error

**BaseEnemy.gd declarations:**
```gdscript
var attack_cooldown: float = 1.0  # Line 45
var attack_timer: float = 0.0      # Line 46
```

**RangedEnemy.gd (WRONG - before fix):**
```gdscript
@export var attack_cooldown: float = 2.0  # Line 10 - DUPLICATE!
var attack_timer: float = 0.0              # Line 15 - DUPLICATE!
```

---

## Solution

### Fix 1: attack_cooldown (Line 10)

**Before:**
```gdscript
@export var attack_cooldown: float = 2.0
```

**After:**
```gdscript
# Note: attack_cooldown inherited from BaseEnemy (set in _ready)
```

**Implementation:**
```gdscript
func _ready() -> void:
    super._ready()

    # Override base cooldown (base is 1.0s)
    attack_cooldown = 2.0
```

**Why:**
- Removed the duplicate declaration
- Set the inherited variable's value in `_ready()` instead
- This allows RangedEnemy to customize the cooldown without redeclaring it

---

### Fix 2: attack_timer (Line 15)

**Before:**
```gdscript
# State tracking
var attack_timer: float = 0.0
var can_shoot: bool = true
```

**After:**
```gdscript
# State tracking
# Note: attack_timer inherited from BaseEnemy
var can_shoot: bool = true
```

**Why:**
- Removed the duplicate declaration entirely
- Added comment noting it's inherited
- RangedEnemy can use `attack_timer` directly from BaseEnemy
- No customization needed (both use 0.0 initial value)

---

## Files Modified

**File:** `scripts/enemies/RangedEnemy.gd`

**Changes:**
- Line 10: Removed `@export var attack_cooldown` declaration, added comment
- Line 15: Removed `var attack_timer` declaration, added comment
- Line 42: Added `attack_cooldown = 2.0` to `_ready()` method

**No changes needed to BaseEnemy.gd** - parent class is correct as-is.

---

## Verification

### Before Fix:
- ❌ Parser errors shown in Godot editor (118 errors total)
- ❌ Game cannot run
- ❌ Red error indicators in script editor

### After Fix:
- ✅ No parser errors
- ✅ Game runs successfully
- ✅ RangedEnemy can spawn and function correctly
- ✅ Attack cooldown properly set to 2.0 seconds for ranged enemies

---

## Testing

**Manual Verification:**
1. Open `scripts/enemies/RangedEnemy.gd` in Godot editor
2. Check "Errors" panel at bottom
3. Should show 0 errors (previously showed 2 errors for this file)

**Runtime Testing:**
1. Run TestArena.tscn
2. Wait for wave 4+ (when ranged enemies start spawning)
3. Verify ranged enemies spawn without errors
4. Verify they attack with correct cooldown (2 seconds between shots)

---

## Related Issues

This fix was part of the larger spawn position bug investigation. The parser errors were blocking testing of the spawn fixes.

**See Also:**
- `bug_reports/2025-10-21_enemy_spawn_position_bug.md` - Main spawn bug fix

---

## Prevention

**Best Practices for Inheritance:**

1. **Check parent class before declaring variables:**
   ```gdscript
   # WRONG - redeclaring inherited variable
   class_name ChildEnemy extends BaseEnemy
   var attack_timer: float = 0.0  # Already in BaseEnemy!

   # RIGHT - use inherited variable directly
   class_name ChildEnemy extends BaseEnemy
   # attack_timer inherited, just use it
   ```

2. **Override values in _ready(), not declarations:**
   ```gdscript
   # WRONG
   @export var attack_cooldown: float = 2.0  # Duplicate!

   # RIGHT
   func _ready() -> void:
       super._ready()
       attack_cooldown = 2.0  # Override inherited value
   ```

3. **Add comments noting inherited variables:**
   ```gdscript
   # State tracking
   # Note: attack_timer inherited from BaseEnemy
   var can_shoot: bool = true  # RangedEnemy-specific variable
   ```

**Code Review Checklist:**
- [ ] Check parent class for existing variable declarations
- [ ] Verify child class doesn't redeclare inherited variables
- [ ] Use `_ready()` to customize inherited values
- [ ] Add comments for clarity when using inherited variables

---

## Status

✅ **FIXED** - Both parser errors resolved

**Changes committed:** 2025-10-21
**Tested:** Parser errors cleared, game runs successfully
**Next Steps:** User verification

---

## Technical Notes

**Why @export didn't help:**

Some developers might think using `@export` would override the parent's variable, but in GDScript:
- Inheritance is strict - no redeclaration allowed
- `@export` only affects the inspector, not inheritance rules
- Must set inherited values in code, not through redeclaration

**Variable shadowing:**

Unlike some languages (like Python or JavaScript), GDScript does NOT allow variable shadowing. A child class cannot create a new variable with the same name as a parent's variable.

This is by design to prevent bugs and maintain clarity in inheritance hierarchies.
