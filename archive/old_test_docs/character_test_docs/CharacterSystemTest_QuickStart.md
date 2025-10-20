# Character System Test - Quick Start Guide

## Files Created

1. **Test Script:** `scripts/testing/CharacterSystemTest.gd` (640 lines, 20KB)
2. **Test Scene:** `scenes/testing/CharacterSystemTest.tscn`
3. **Documentation:** `docs/CharacterSystemTest_Summary.md`

## Running the Test

### Method 1: Godot Editor (Recommended)

1. Open Godot 4.5+
2. Load project: `M:\GameProject\megabonk-mobile\project.godot`
3. In FileSystem panel, navigate to: `scenes/testing/CharacterSystemTest.tscn`
4. Double-click to open the scene
5. Press **F6** or click the "Play Scene" button
6. Watch console output for test results
7. Game will automatically quit when tests complete

### Method 2: Command Line

```bash
cd M:\GameProject\megabonk-mobile
godot scenes/testing/CharacterSystemTest.tscn
```

### Method 3: Headless (CI/CD)

```bash
godot --headless --path "M:\GameProject\megabonk-mobile" scenes/testing/CharacterSystemTest.tscn
```

## Expected Results

### Success Output
```
================================================================================
AUTOMATED CHARACTER SYSTEM TEST - PHASE 5A
================================================================================

[SETUP] Finding test objects...
  [PASS] Player found
  [PASS] GameManager found

[TEST 1] Character Loading
  [PASS] Warrior character loaded
  [PASS] Warrior name correct: 'Warrior'
  ...
  (47 total tests)

================================================================================
TEST RESULTS SUMMARY
================================================================================
Total Tests: 47
Passed: 47
Failed: 0
Success Rate: 100.0%
================================================================================

ALL TESTS PASSED! Character system is working correctly.
```

### Failure Output
If any tests fail, you'll see:
```
  [FAIL] Warrior max health is 120 (expected 100)
```

And at the end:
```
SOME TESTS FAILED. Review failures above.

Failed Tests:
  - Warrior Character: Warrior max health is 120 (expected 100)
```

## Test Breakdown

### Total Tests: 47

1. **Character Loading** (11 tests) - Load all .tres files
2. **Warrior Tests** (6 tests) - Melee Mastery passive
3. **Ranger Tests** (6 tests) - Sharpshooter passive
4. **Tank Tests** (6 tests) - Fortified passive + damage reduction
5. **Assassin Tests** (6 tests) - Deadly Precision passive
6. **Mage Tests** (7 tests) - Arcane Mastery passive + XP multiplier
7. **Unlock System** (11 tests) - Character unlocks and costs

## What Gets Tested

### For Each Character:
- ✓ Character resource loads correctly
- ✓ Name and description are correct
- ✓ Base stats (HP, speed, damage, pickup range)
- ✓ Passive ability values
- ✓ Passive ability calculations (damage reduction, XP multiplier, etc.)
- ✓ Starting weapon assignment
- ✓ Unlock cost
- ✓ Character color

### System Tests:
- ✓ GlobalData character selection
- ✓ Character unlock system
- ✓ PlayerController.apply_character_data()
- ✓ Stat application and persistence

## Troubleshooting

### "Player NOT found"
- Ensure Player.tscn is in the scene
- Check Player has "player" group assigned

### "Failed to load character data"
- Verify .tres files exist in `resources/characters/`
- Check file names are lowercase: warrior.tres, ranger.tres, etc.

### Tests timing out
- Increase `phase_timer` delays in test script
- Check for infinite loops in character application

### Unexpected values
- Compare against actual .tres file values
- Character stats may have been updated
- Update test expected values to match

## Modifying Tests

To add new tests:

1. Open `scripts/testing/CharacterSystemTest.gd`
2. Add new test function:
```gdscript
func test_new_feature() -> void:
    print("[TEST X] New Feature")
    current_test = "New Feature"

    # Your test logic
    if condition:
        log_pass("Test passed")
    else:
        log_fail("Test failed")

    print("")
```

3. Add to test phase in `_process()`:
```gdscript
TestPhase.TEST_NEW_FEATURE:
    if phase_timer > 0.5:
        test_new_feature()
        current_phase = TestPhase.COMPLETE
        phase_timer = 0.0
```

## Character Stats Reference

| Character | HP  | Speed | Damage | Unlock Cost |
|-----------|-----|-------|--------|-------------|
| Warrior   | 100 | 5.0   | 10     | 0 (Free)    |
| Ranger    | 75  | 6.5   | 8      | 500         |
| Tank      | 150 | 3.5   | 12     | 750         |
| Assassin  | 60  | 7.0   | 10     | 1000        |
| Mage      | 70  | 5.0   | 8      | 1500        |

## Passive Abilities

1. **Warrior - Melee Mastery:** +20% damage with orbital weapons
2. **Ranger - Sharpshooter:** +30% ranged damage, +2m pickup range
3. **Tank - Fortified:** -15% damage taken
4. **Assassin - Deadly Precision:** +25% crit chance, +50% crit damage
5. **Mage - Arcane Mastery:** +15% XP gain, start with 2 weapons

## Next Steps

After running tests successfully:

1. Review `docs/CharacterSystemTest_Summary.md` for detailed breakdown
2. Integrate into CI/CD pipeline if needed
3. Update tests when character stats change
4. Add weapon integration tests (future enhancement)
5. Add UI character selection tests (future enhancement)

## Support

If tests fail unexpectedly:
1. Check console output for specific failures
2. Review character .tres files for stat changes
3. Verify PlayerController.gd hasn't been modified
4. Check GlobalData.gd for character selection logic
5. Ensure all character resources are present

For questions or issues, refer to `docs/CharacterSystemTest_Summary.md` for detailed implementation notes.
