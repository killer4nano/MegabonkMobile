# Phase 3 Master Plan - Weapons & Upgrades

**Project Manager:** Claude
**Status:** In Progress
**Estimated Total Time:** 18-24 hours
**Approach:** Sequential (A → B → C)

---

## Phase 3A: HUD (Heads-Up Display)

**Time Estimate:** 4-6 hours
**Status:** ⚪ Not Started
**Priority:** HIGH - Essential visual feedback

### Deliverables:
- [⚪] HUD.tscn scene with UI elements
- [⚪] Health bar (ProgressBar) - top-left
- [⚪] XP bar (ProgressBar) - top-center
- [⚪] Level display (Label) - near XP bar
- [⚪] Wave counter (Label) - top-right
- [⚪] Kill counter (Label) - bottom-right
- [⚪] HUD.gd script connecting to EventBus signals

### Sub-Agent Delegation:
- **Agent 1:** Create HUD.tscn layout with all UI elements
- **Agent 2:** Create HUD.gd script and connect signals

### Acceptance Criteria:
- [ ] Health bar updates when player takes damage
- [ ] XP bar fills as XP is collected
- [ ] XP bar resets on level up
- [ ] Level number increments on level up
- [ ] Wave counter updates every 30 seconds
- [ ] Kill counter increments on enemy death
- [ ] All UI elements are mobile-friendly (readable on phone)

---

## Phase 3B: Upgrade System

**Time Estimate:** 8-10 hours
**Status:** ⚪ Not Started
**Priority:** HIGH - Makes leveling meaningful

### Deliverables:
- [⚪] UpgradeData.gd (Resource script for upgrade definitions)
- [⚪] UpgradePool.gd (Manager for selecting random upgrades)
- [⚪] 10-15 upgrade definitions (.tres files)
- [⚪] UpgradeScreen.tscn (UI for selection)
- [⚪] UpgradeCard.tscn (Individual upgrade card component)
- [⚪] Upgrade application logic in PlayerController/WeaponManager

### Upgrade Categories:
1. **Stat Boosts:**
   - Max Health +20
   - Move Speed +10%
   - Pickup Range +1m
   - Base Damage +5

2. **Weapon Upgrades:**
   - Bonk Hammer Damage +25%
   - Bonk Hammer Speed +15% (faster orbit)
   - Bonk Hammer Size +30% (larger hitbox)
   - Additional Bonk Hammer (+1 hammer orbiting)

3. **New Weapons:**
   - Unlock Magic Missile
   - Unlock Spinning Blade

4. **Passive Abilities:**
   - HP Regeneration (1 HP/sec)
   - XP Magnet Range +2m
   - Enemy Knockback on Hit

### Sub-Agent Delegation:
- **Agent 1:** Create UpgradeData resource and 10-15 upgrade pool
- **Agent 2:** Create UpgradeScreen UI with card selection
- **Agent 3:** Integrate upgrade application to PlayerController

### Acceptance Criteria:
- [ ] Game pauses when player levels up
- [ ] UpgradeScreen shows 3 random upgrades
- [ ] Upgrades are touch-friendly (large tap targets)
- [ ] Selecting upgrade applies effect immediately
- [ ] Game resumes after selection
- [ ] Upgrades persist for the run
- [ ] Stat upgrades stack (multiple selections)
- [ ] Can't get duplicate weapon unlocks

---

## Phase 3C: Additional Weapons

**Time Estimate:** 6-8 hours (2-3 hours per weapon)
**Status:** ⚪ Not Started
**Priority:** MEDIUM - Expands combat variety

### Weapon 1: Magic Missile (Homing Projectile)
**Type:** Ranged
**Behavior:** Shoots homing projectiles at nearest enemy every 2 seconds

**Stats:**
- Damage: 20
- Attack Cooldown: 2.0s
- Range: 15m
- Projectile Speed: 10 m/s
- Homing Strength: 5.0

**Implementation:**
- [⚪] MagicMissile.gd (extends BaseWeapon)
- [⚪] MagicMissile.tscn (weapon scene)
- [⚪] MissileProjectile.tscn (projectile with Area3D)
- [⚪] Projectile homing behavior
- [⚪] Projectile despawn on hit or timeout

---

### Weapon 2: Spinning Blade (Orbit Weapon)
**Type:** Orbital
**Behavior:** Orbits player like Bonk Hammer but faster and farther

**Stats:**
- Damage: 12
- Orbit Radius: 2.5m (larger than Bonk Hammer)
- Orbit Speed: 3.0 rad/s (faster than Bonk Hammer)
- Hit Cooldown: 0.3s per enemy

**Implementation:**
- [⚪] SpinningBlade.gd (extends BaseWeapon, similar to BonkHammer)
- [⚪] SpinningBlade.tscn (weapon scene)
- [⚪] Collision-based damage
- [⚪] Visual: Spinning disc/blade mesh

---

### Sub-Agent Delegation:
- **Agent 1:** Create Magic Missile weapon (projectile system)
- **Agent 2:** Create Spinning Blade weapon (orbital variant)
- **Agent 3:** Test and balance both weapons

### Acceptance Criteria:
- [ ] Magic Missile shoots projectiles automatically
- [ ] Projectiles home in on enemies smoothly
- [ ] Projectiles deal damage on hit and despawn
- [ ] Spinning Blade orbits at correct radius/speed
- [ ] Spinning Blade damages on collision
- [ ] Both weapons can be equipped simultaneously
- [ ] Both weapons appear in upgrade pool
- [ ] Weapons don't interfere with each other

---

## Testing Checklist (Full Phase 3)

### HUD Testing:
- [ ] All bars/counters display correctly
- [ ] Values update in real-time
- [ ] UI is readable on mobile resolution
- [ ] No performance impact

### Upgrade System Testing:
- [ ] Level up triggers upgrade screen
- [ ] 3 random upgrades displayed
- [ ] Selecting upgrade applies effect
- [ ] Stat upgrades stack correctly
- [ ] Weapon unlocks add new weapons
- [ ] No duplicate weapon unlocks
- [ ] Game resumes smoothly after selection

### Weapon Testing:
- [ ] Magic Missile fires automatically
- [ ] Projectiles track enemies
- [ ] Spinning Blade orbits correctly
- [ ] Both weapons work with Bonk Hammer
- [ ] No collision conflicts
- [ ] Balanced damage output

---

## Documentation Updates

After Phase 3 completion:
- [ ] Update TaskList.txt - Mark Phase 3 complete
- [ ] Update CLAUDE.md - Document upgrade and weapon systems
- [ ] Create PHASE3_COMPLETE.md summary
- [ ] Commit and push to GitHub

---

## Timeline

**Day 1:** Phase 3A - HUD (4-6 hours)
**Day 2:** Phase 3B - Upgrades (8-10 hours)
**Day 3:** Phase 3C - Weapons (6-8 hours)

**Total:** 18-24 hours estimated

---

## Current Progress: 0% (0/3 sub-phases complete)

Let's begin with Phase 3A - HUD!
