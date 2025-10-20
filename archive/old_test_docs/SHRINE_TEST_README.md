# Shrine System Automated Test

**Test Script:** `scripts/testing/ShrineSystemTest.gd`
**Test Scene:** `scenes/testing/ShrineSystemTest.tscn`
**Run Script:** `run_shrine_tests.bat` (Windows)

---

## What This Test Does

This automated test verifies the **Shrine System** implementation from Phase 5.2:

### Tests Performed:

**Test 1: Gold System**
- ✅ Verifies initial gold is 0
- ✅ Verifies gold can be added to GlobalData
- ✅ Verifies gold tracking works

**Test 2: Health Shrine**
- ✅ Verifies shrine cost (50 gold)
- ✅ Verifies player detection in range
- ✅ Verifies gold is spent on activation
- ✅ Verifies player is healed 50% HP
- ✅ Verifies shrine activation logic

**Test 3: Damage Shrine**
- ✅ Verifies shrine cost (100 gold)
- ✅ Verifies initial damage multiplier (1.0x)
- ✅ Verifies gold is spent on activation
- ✅ Verifies damage buff is applied (1.5x = +50%)
- ✅ Verifies shrine is marked as active

**Test 4: Speed Shrine**
- ✅ Verifies shrine cost (75 gold)
- ✅ Verifies initial speed multiplier (1.0x)
- ✅ Verifies gold is spent on activation
- ✅ Verifies speed buff is applied (1.3x = +30%)
- ✅ Verifies shrine is marked as active

**Test 5: Buff Expiration**
- ✅ Verifies remove_damage_buff() method exists
- ✅ Verifies remove_speed_buff() method exists
- ✅ Verifies buffs can be removed manually
- ✅ Verifies multipliers return to 1.0x

---

## How to Run Tests

### Option 1: Run via Batch Script (Easiest)

1. **Edit the batch script if needed:**
   - Open `run_shrine_tests.bat` in a text editor
   - Update the `GODOT_PATH` variable if your Godot installation is in a different location
   - Common paths:
     - `C:\Program Files\Godot\Godot_v4.3-stable_win64.exe`
     - `C:\Godot\Godot_v4.3-stable_win64.exe`
     - Just `godot` if it's in your system PATH

2. **Run the script:**
   - Double-click `run_shrine_tests.bat`
   - Or run from command line: `run_shrine_tests.bat`

3. **View results:**
   - The test will run headless (no window)
   - Console output will show all test results
   - The window will pause at the end so you can read results

### Option 2: Run via Godot Editor

1. **Open the Godot project**
2. **Navigate to the test scene:**
   - `scenes/testing/ShrineSystemTest.tscn`
3. **Run the scene (F6)**
   - Tests will execute automatically
   - Console will show results
   - Game will quit after tests complete

### Option 3: Run via Command Line

```bash
cd megabonk-mobile
godot --headless --path . res://scenes/testing/ShrineSystemTest.tscn
```

---

## Understanding Test Output

### Example Output:

```
================================================================================
AUTOMATED SHRINE SYSTEM TEST - PHASE 5.2
================================================================================

[SETUP] Finding test objects...
  [PASS] Player found
  [PASS] Health Shrine found
  [PASS] Damage Shrine found
  [PASS] Speed Shrine found

[TEST 1] Gold System
  [PASS] Initial gold is 0
  [PASS] Gold added successfully (500 gold)

[TEST 2] Health Shrine
  [PASS] Player health reduced to 30.0 (30% of max)
  [PASS] Health Shrine cost is 50 gold
  [PASS] Player detected in shrine range
  [PASS] Gold spent correctly (50 gold)
  [PASS] Player healed correctly (80.0 HP)

[TEST 3] Damage Shrine
  [PASS] Damage Shrine cost is 100 gold
  [PASS] Initial damage multiplier is 1.0x
  [PASS] Gold spent correctly (100 gold)
  [PASS] Damage buff applied (1.5x = +50%)
  [PASS] Damage Shrine is marked as active

[TEST 4] Speed Shrine
  [PASS] Speed Shrine cost is 75 gold
  [PASS] Initial speed multiplier is 1.0x
  [PASS] Gold spent correctly (75 gold)
  [PASS] Speed buff applied (1.3x = +30%)
  [PASS] Speed Shrine is marked as active

[TEST 5] Buff Expiration
  [PASS] Player has remove_damage_buff() method
  [PASS] Player has remove_speed_buff() method
  [PASS] Damage buff removed (multiplier back to 1.0x)
  [PASS] Speed buff removed (multiplier back to 1.0x)

================================================================================
TEST RESULTS SUMMARY
================================================================================
Total Tests: 24
Passed: 24
Failed: 0
Success Rate: 100.0%
================================================================================

✅ ALL TESTS PASSED! Shrine system is working correctly.
```

### If Tests Fail:

- **[FAIL] messages** will show what went wrong
- Check the error message for details
- Common issues:
  - Missing shrine scenes (check file paths)
  - Player not in "player" group
  - Shrine scripts not attached correctly
  - Buff methods not implemented

---

## Test Coverage

### What's Tested:
- ✅ Gold economy (add, spend, track)
- ✅ Shrine detection (player in range)
- ✅ Shrine activation (gold spending)
- ✅ Health shrine healing (50% HP restoration)
- ✅ Damage shrine buff (+50% damage)
- ✅ Speed shrine buff (+30% speed)
- ✅ Buff removal (return to 1.0x multipliers)

### What's NOT Tested (Manual Testing Required):
- ⏳ 60-second buff duration (automated test can't wait that long)
- ⏳ Shrine visual feedback (3D labels, colors)
- ⏳ Shrine audio feedback (sounds)
- ⏳ Multiple shrine activations in sequence
- ⏳ Player movement with speed buff
- ⏳ Weapon damage with damage buff
- ⏳ Gold coin pickup from enemies (requires enemy system)

---

## Modifying the Tests

To add new tests, edit `scripts/testing/ShrineSystemTest.gd`:

1. **Add a new test function:**
   ```gdscript
   func test_my_feature() -> void:
       print("[TEST X] My Feature")
       current_test = "My Feature"

       # Your test logic here
       if condition:
           log_pass("Feature works!")
       else:
           log_fail("Feature broken!")

       print("")
   ```

2. **Add it to the test phases:**
   - Add new enum value to `TestPhase`
   - Add new case to `_process()` match statement
   - Call your test function

3. **Run tests again to verify**

---

## Troubleshooting

### "Could not find Godot installation"
- Edit `run_shrine_tests.bat`
- Set the correct path to your Godot executable
- Or add Godot to your system PATH

### "Player NOT found"
- Verify Player scene is in the test scene
- Check that Player has "player" group assigned
- Open `ShrineSystemTest.tscn` in Godot to verify

### "Shrine NOT found"
- Verify shrine scenes exist in `scenes/interactables/`
- Check that shrine scripts are attached correctly
- Verify UIDs match in .tscn files

### Tests hang or don't complete
- Check console for errors
- Verify all `await` statements complete
- Check that `get_tree().quit()` is called at end

---

## Next Steps

After running tests successfully:

1. **Review console output** - Verify all tests pass
2. **Manual testing** - Test features not covered by automation
3. **Balance tuning** - Adjust shrine costs/effects based on gameplay
4. **Add more tests** - Expand coverage as needed

---

## Files Involved

```
M:\GameProject\
├── run_shrine_tests.bat                     (Run script)
├── SHRINE_TEST_README.md                    (This file)
└── megabonk-mobile\
    ├── scripts\testing\
    │   └── ShrineSystemTest.gd              (Test controller)
    └── scenes\testing\
        └── ShrineSystemTest.tscn            (Test scene)
```

---

**Last Updated:** 2025-10-19
**Phase:** 5.2 - Shops & Shrines
**Status:** Automated tests implemented ✅
