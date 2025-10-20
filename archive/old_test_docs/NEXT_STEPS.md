# Next Steps for MegabonkMobile Development

## Current Project Status

**Phase 4 COMPLETE** - Extraction & Meta-Progression System Fully Functional

The game now has a complete core gameplay loop:
- Player spawns → Fight enemies → Level up → Choose upgrades → Extract for rewards OR Die and lose everything

### What's Working
- ✅ Player movement (camera-relative, virtual joystick)
- ✅ Enemy AI (3 types: Basic, Fast, Tank) with wave spawning
- ✅ Combat system with XP and leveling
- ✅ Weapon system (5 weapons: BonkHammer, Magic Missile, Spinning Blade, Fireball, Ground Slam)
- ✅ Upgrade system with random selections
- ✅ Extraction zones with 5-second countdown
- ✅ Risk/reward multipliers (1.0x → 3.0x based on time)
- ✅ Meta-progression currency (Essence) persists between runs
- ✅ Main menu, death screen, extraction success screen
- ✅ Save/load system

---

## Critical Bugs Fixed in Phase 4

### Bug #1: GlobalData Variable Storage
**Problem:** Using `.set()` and `.get()` for dynamic data storage returned `null`

**Root Cause:** `.set()`/`.get()` are Node methods for declared properties, not for dynamic dictionary-style storage

**Solution:**
```gdscript
// WRONG:
GlobalData.set("last_extraction_results", {...})
var results = GlobalData.get("last_extraction_results")  // Returns null!

// CORRECT:
// In GlobalData.gd:
var last_extraction_results: Dictionary = {}
var last_death_results: Dictionary = {}

// In other scripts:
GlobalData.last_extraction_results = {...}
var results = GlobalData.last_extraction_results  // Works!
```

### Bug #2: UI Node Paths Missing MarginContainer
**Problem:** All `@onready` node references returned `null`, buttons didn't work, labels didn't update

**Root Cause:** Scene hierarchy had `MarginContainer` between `PanelContainer` and `VBoxContainer`, but scripts omitted it

**Solution:**
```gdscript
// WRONG:
@onready var label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel

// CORRECT:
@onready var label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
```

**Lesson:** Always verify scene hierarchy matches `@onready` paths. Use Godot's "Copy Node Path" feature.

### Bug #3: Mouse Input Blocked by Background UI
**Problem:** Buttons not responding to clicks

**Solution:** Add `mouse_filter = 2` (MOUSE_FILTER_IGNORE) to background ColorRect and CenterContainer nodes

---

## Phase 5 Roadmap - UI/UX Polish & Settings

### Priority 1: Settings Menu Implementation
Currently, the Settings button is a placeholder. Implement full settings screen:

**Settings to Include:**
1. **Audio Settings**
   - Master Volume slider (0-100%)
   - Music Volume slider (0-100%)
   - SFX Volume slider (0-100%)
   - Mute all checkbox

2. **Graphics Settings**
   - Quality preset dropdown (Low / Medium / High)
   - FPS counter toggle
   - VSync toggle (if needed for performance)

3. **Controls Settings**
   - Control scheme selector:
     - Virtual Joystick (current default)
     - Tap to Move (future feature)
   - Camera sensitivity slider
   - Joystick size/opacity adjusters

4. **Gameplay Settings**
   - Damage numbers toggle
   - Screen shake toggle
   - Auto-pause on focus loss

**Implementation Notes:**
- Create `scenes/ui/SettingsMenu.tscn`
- Create `scripts/ui/SettingsMenu.gd`
- Settings should modify GlobalData variables
- Call SaveSystem.save_game() when settings change
- Add "Apply" and "Cancel" buttons
- Test that settings persist across game restarts

### Priority 2: Visual Effects Polish

**VFX Needed:**
1. **Combat Effects**
   - Enemy hit particles (red flash + particles)
   - Player damage flash (red vignette)
   - XP gem collection trail effect
   - Weapon impact effects per weapon type

2. **UI Effects**
   - Level-up flash/animation
   - Upgrade selection highlight effect
   - Button hover/press animations
   - Screen transitions (fade in/out)

3. **Extraction Effects**
   - Extraction zone pulsing glow animation
   - Countdown urgency effect (flash faster as timer decreases)
   - Success celebration particle burst

**Tools:**
- Use Godot's GPUParticles3D for 3D effects
- Use GPUParticles2D for UI effects
- Consider AnimationPlayer for UI transitions

### Priority 3: Audio Implementation

**Sound Effects Needed:**
1. **Combat Sounds**
   - Weapon hit sounds (per weapon type)
   - Enemy death sound
   - Player hurt sound
   - Player death sound

2. **UI Sounds**
   - Button click
   - Hover sound
   - Level up fanfare
   - Upgrade selection confirm
   - Extraction countdown beep
   - Extraction success/failure

3. **Ambient Sounds**
   - Background music (menu theme)
   - Battle music (game theme)
   - Extraction zone ambience
   - Enemy spawn/wave start

**Implementation:**
- Use AudioStreamPlayer for UI sounds (2D)
- Use AudioStreamPlayer3D for game sounds (positional)
- Music manager for crossfading between tracks
- All controlled by GlobalData volume settings

### Priority 4: Tutorial/Onboarding

**First-Time Player Experience:**
1. **Tutorial Popup Sequence** (closable, one-time per install)
   - Welcome message
   - Movement controls explanation
   - Combat basics (auto-attack, leveling)
   - Extraction mechanics explanation
   - Risk/reward multiplier system

2. **In-Game Hints**
   - First extraction zone spawn: "Extraction zone available! Stand in the zone for 5 seconds."
   - First level-up: "Choose an upgrade to power up!"
   - 3-minute mark: "Higher multipliers if you extract later!"

**Implementation:**
- Store `tutorial_completed` flag in GlobalData
- Create tutorial popup UI
- Add tooltip system for hover hints

### Priority 5: UI Improvements

**Main Menu:**
- Add character select screen (for unlocked characters)
- Add "How to Play" button → tutorial screen
- Add stats breakdown screen (detailed lifetime statistics)

**HUD Improvements:**
- Health bar visual improvement (gradient, outline)
- XP bar animation on gain
- Wave announcement popup (center screen, fades out)
- Boss health bar (if bosses are added later)
- Minimap (optional, low priority)

**Pause Menu:**
- Currently missing! Add pause menu:
  - Resume button
  - Settings button
  - Quit to menu button (with confirmation)
  - Stats summary (current run)

---

## Phase 6 Roadmap - Testing & Balance

### Balance Tuning Needed

**Extraction Rewards:**
- Current formula: `(enemies * 10 + time / 10) * multiplier`
- May need adjustment based on playtest feedback
- Multipliers may be too low/high for meaningful choices

**Enemy Difficulty:**
- Wave scaling may ramp too fast/slow
- Enemy health/damage may need tuning
- Fast enemy speed may be too difficult for mobile

**Weapon Balance:**
- Some weapons may be stronger than others
- Upgrade effectiveness needs testing
- Stacking limits may need adjusting

### Performance Optimization

**Known Issues:**
- Object pooling not implemented (enemies/projectiles are instantiated/freed every time)
- Many background Godot processes running (check task manager)

**Optimizations Needed:**
1. **Enemy Pooling**
   - Create enemy pool manager
   - Reuse enemy instances instead of queue_free()
   - Significant performance boost for mobile

2. **Projectile Pooling**
   - Pool Magic Missile and Fireball projectiles
   - Prevents stuttering on high attack speed

3. **Particle Cleanup**
   - Ensure particles auto-delete after lifetime
   - Check for particle leaks

4. **Scene Optimization**
   - Reduce mesh complexity if needed
   - Use LOD for distant enemies
   - Occlusion culling for off-screen enemies

---

## Phase 7 Roadmap - Mobile Export

### Android Export
1. Install Android export templates in Godot
2. Configure Android export settings
   - Minimum API level
   - Permissions (storage for saves)
   - Icons and splash screen
3. Test on multiple Android devices
4. Optimize touch controls for different screen sizes
5. Performance testing on low-end devices

### iOS Export
1. Requires macOS with Xcode
2. Install iOS export templates
3. Configure iOS export settings
   - Bundle identifier
   - Signing certificate
   - Icons and launch screens
4. Test on iPhone and iPad
5. Submit to TestFlight for beta testing
6. App Store submission

---

## Known Technical Debt

1. **No Pause Menu** - Players can't pause the game
2. **No Object Pooling** - Performance issue on mobile
3. **No Audio System** - Game is currently silent
4. **Settings Menu Placeholder** - Button exists but doesn't work
5. **No Tutorial** - New players have no guidance
6. **Test Scenes in Production** - Remove scenes/testing/ from final export

---

## Architecture Notes for Future Developers

### Critical Patterns to Follow

**1. Autoload Singletons**
- EventBus - Signal hub, never store state
- GlobalData - Game state, persistent data
- SaveSystem - Save/load only
- ExtractionManager - Extraction logic only

**2. Scene Node Paths**
- ALWAYS verify `@onready var` paths match exact scene hierarchy
- Use Godot's "Copy Node Path" feature
- Add `push_error()` checks in `_ready()` for critical nodes

**3. Data Storage**
- Use declared variables in GlobalData, NOT `.set()/.get()`
- Save/load uses JSON serialization
- Dictionary keys must be exact matches

**4. Camera-Relative Movement**
- Player visual rotates independently of camera
- Input is transformed based on camera orientation
- DO NOT rotate the CharacterBody3D, rotate the visual mesh

**5. Enemy Movement**
- Fast enemies (≥4.0 speed): Direct movement to avoid jittering
- Slow enemies (<4.0 speed): NavigationAgent3D for pathfinding

**6. Weapon System**
- `weapon_type`: "ranged", "orbital", or "aura"
- Orbital weapons use collision detection, not auto-attack
- WeaponData resources store all stats

### Common Pitfalls

❌ **DON'T:**
- Use `.set()/.get()` for dynamic data storage
- Forget `MarginContainer` in UI node paths
- Block mouse input with background UI elements
- Modify camera during player rotation
- Use NavigationAgent3D for fast enemies

✅ **DO:**
- Declare variables in GlobalData for cross-scene data
- Verify full scene hierarchy for @onready paths
- Set `mouse_filter = 2` on decorative UI elements
- Use camera basis vectors for movement transformation
- Use direct movement for speed ≥ 4.0

---

## Testing Checklist Before Next Phase

- [ ] Full playthrough (spawn → level 5 → extract at 6+ min)
- [ ] Death flow test (die → death screen → return to menu → play again)
- [ ] Essence persistence test (extract → close game → reopen → verify Essence)
- [ ] All weapons tested (unlock via upgrade selection)
- [ ] All upgrade types tested (damage, speed, count, stats)
- [ ] Button functionality in all UI screens
- [ ] Settings button shows "not implemented" message
- [ ] No console errors during normal gameplay

---

## Resources for Future Reference

**Godot 4.5 Documentation:**
- https://docs.godotengine.org/en/4.5/

**Key Systems Documentation:**
- See `CLAUDE.md` for detailed architecture notes
- See `README.md` for project overview
- See commit history for Phase 1-4 implementation details

**External Assets Needed (Phase 5+):**
- Sound effects (freesound.org, mixkit.co)
- Music tracks (incompetech.com, purple-planet.com)
- Particle textures (kenney.nl)

---

## Contact & Contribution

**Repository:** https://github.com/killer4nano/megabonk-mobile

**For Future Claude Code Sessions:**
- Read `CLAUDE.md` first for architecture overview
- Check this file for current status and next priorities
- Review recent commit messages for context
- Test before implementing to understand current behavior

**For Human Contributors:**
- Follow existing code style and patterns
- Test on both PC and mobile (if possible)
- Update documentation when adding new systems
- Create issues for bugs, not direct commits

---

**Last Updated:** October 19, 2025 (End of Phase 4)
**Next Milestone:** Phase 5 - Settings Menu Implementation
