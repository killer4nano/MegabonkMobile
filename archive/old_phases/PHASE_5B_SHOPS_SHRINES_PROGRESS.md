# 🎉 PHASE 5.2 - SHOPS & SHRINES (IN PROGRESS)

**Date:** 2025-10-19
**Status:** 75% COMPLETE (Gold Economy + Shrines ✅ | Shop System ⏳)
**Duration:** Single session
**Ready for:** User Testing (Gold & Shrines)

---

## ✅ What Was Built in Phase 5.2

Phase 5.2 adds **Gold Economy** and **Shrine System** to the game, implementing the "Run Progression (Lost on Death)" layer from the original plan.

### 5.2A: Gold Economy System ✅

**Complete gold drop and collection system.**

**Files Created:**
- `scripts/pickups/GoldCoin.gd` - Gold coin pickup controller
- `scenes/pickups/GoldCoin.tscn` - Gold coin scene with visual

**Files Modified:**
- `scripts/autoload/EventBus.gd` - Updated `gold_collected` signal
- `scripts/autoload/GlobalData.gd` - Already had `current_gold` tracking
- `scripts/enemies/BaseEnemy.gd` - Added gold dropping on death
- `scripts/ui/HUD.gd` - Added gold counter display
- `scenes/ui/HUD.tscn` - Added GoldLabel to UI

**Features Implemented:**
- ✅ Gold coins drop from enemies on death
  - BasicEnemy: 1 gold (default)
  - FastEnemy: 2 gold (potential)
  - TankEnemy: 3 gold (potential)
- ✅ Gold pickups with magnetic pull (5m range)
- ✅ Gold flies toward player like XP gems
- ✅ Gold tracked in GlobalData.current_gold
- ✅ Gold counter displayed on HUD (top-left, gold color)
- ✅ Gold is temporary (resets on death, not extracted)

**Technical Details:**
- Gold coins use same pickup system as XP gems
- Multiple coins spread out slightly for visual variety
- EventBus.gold_collected signal updates HUD in real-time
- Gold value exported per enemy type

---

### 5.2B: Shrine System ✅

**Complete interactable shrine system with 3 shrine types.**

**Files Created (11 files):**

**Base System (2 files):**
1. `scripts/interactables/BaseShrine.gd` - Base shrine controller
2. `scenes/interactables/BaseShrine.tscn` - Base shrine scene

**Health Shrine (2 files):**
3. `scripts/interactables/HealthShrine.gd` - Health shrine script
4. `scenes/interactables/HealthShrine.tscn` - Health shrine scene

**Damage Shrine (2 files):**
5. `scripts/interactables/DamageShrine.gd` - Damage shrine script
6. `scenes/interactables/DamageShrine.tscn` - Damage shrine scene

**Speed Shrine (2 files):**
7. `scripts/interactables/SpeedShrine.gd` - Speed shrine script
8. `scenes/interactables/SpeedShrine.tscn` - Speed shrine scene

**Files Modified (2 files):**
9. `scripts/player/PlayerController.gd` - Added buff tracking system
10. `scenes/levels/TestArena.tscn` - Placed 3 shrines in arena

---

### Shrine Types Implemented

#### 1. Health Shrine (Green) 💚
- **Cost:** 50 gold
- **Effect:** Restore 50% of max HP (instant)
- **Duration:** Instant (no buff timer)
- **Location:** (10, 0, 10) - Southeast corner
- **Use Case:** Emergency healing during tough waves

#### 2. Damage Shrine (Red) ❤️
- **Cost:** 100 gold
- **Effect:** +50% damage to all weapons
- **Duration:** 60 seconds
- **Location:** (-10, 0, 10) - Southwest corner
- **Use Case:** Offensive power spike for boss waves

#### 3. Speed Shrine (Blue) 💙
- **Cost:** 75 gold
- **Effect:** +30% move speed
- **Duration:** 60 seconds
- **Location:** (0, 0, -10) - North side
- **Use Case:** Kiting, dodging, repositioning

---

### Shrine Interaction System

**Base Shrine Features:**
- **Detection:** 2m radius Area3D detects player
- **Visual Feedback:**
  - Label changes color based on state:
    - WHITE: Default (out of range)
    - YELLOW: In range, can afford
    - RED: In range, can't afford
    - GREEN: Buff active
- **Activation:** Press SPACE key when in range (PC testing)
  - TODO: Add mobile UI button
- **Cost Display:** Shows gold cost on 3D label
- **Status Display:** Shows "[PRESS SPACE]" or "[NOT ENOUGH GOLD]" or "[ACTIVE]"
- **Cooldown:** Shrine becomes inactive during buff duration

**Buff Tracking System:**
- Added to PlayerController:
  - `shrine_damage_multiplier: float = 1.0`
  - `shrine_speed_multiplier: float = 1.0`
  - `apply_damage_buff(multiplier)` method
  - `remove_damage_buff()` method
  - `apply_speed_buff(multiplier)` method
  - `remove_speed_buff()` method
  - `get_effective_damage()` method
  - `get_effective_speed()` method

**Buff Duration:**
- Shrine activates → Apply buff immediately
- Timer starts (60 seconds for damage/speed)
- Timer expires → Remove buff automatically
- Shrine becomes available again

---

## 📊 Complete Feature List (Phase 5.2 Partial)

**Gold System:** ✅ COMPLETE
- Gold coins (pickup collectible)
- Gold dropping from enemies
- Gold counter on HUD
- Gold tracking in GlobalData

**Shrine System:** ✅ COMPLETE
- BaseShrine (reusable system)
- Health Shrine (instant heal)
- Damage Shrine (60s +50% damage buff)
- Speed Shrine (60s +30% speed buff)
- Buff tracking in PlayerController
- 3D interaction labels
- Cost checking & gold spending

**Shop System:** ⏳ TODO
- Shop UI
- Shop items (weapons, health potion, reroll token)
- Shop placement in arena

---

## 🔧 System Architecture

### Gold Pickup Flow

```
Enemy dies
    ↓
BaseEnemy.spawn_gold()
    ↓
For each gold_value (1-3 coins):
    Instantiate GoldCoin
    Set random offset position
    Add to scene
    ↓
GoldCoin._physics_process():
    Check distance to player
    If within magnet_range (5m):
        Fly toward player
    ↓
GoldCoin collision with player
    ↓
collect():
    GlobalData.current_gold += gold_value
    EventBus.gold_collected.emit(amount, total)
    queue_free()
    ↓
HUD._on_gold_collected():
    Update gold_label.text
```

### Shrine Activation Flow

```
Player enters InteractionArea (2m radius)
    ↓
BaseShrine._on_player_entered()
    player_in_range = true
    update_label() → Show "[PRESS SPACE]"
    ↓
Player presses SPACE
    ↓
BaseShrine.attempt_activate():
    Check: is_active? → Abort
    Check: GlobalData.current_gold >= cost?
        If NO → Print error, abort
        If YES → Continue
    ↓
    Spend gold:
        GlobalData.current_gold -= cost
        EventBus.gold_collected.emit(0, total)
    ↓
    Apply effect (override in subclass):
        HealthShrine: player.heal(max_health * 0.5)
        DamageShrine: player.apply_damage_buff(1.5)
        SpeedShrine: player.apply_speed_buff(1.3)
    ↓
    Set is_active = true
    update_label() → Show "[ACTIVE]"
    ↓
    await buff_duration seconds
    ↓
    Remove effect (override in subclass):
        DamageShrine: player.remove_damage_buff()
        SpeedShrine: player.remove_speed_buff()
    ↓
    Set is_active = false
    update_label() → Show cost again
```

---

## 🎮 Complete Gameplay Loop (With Phase 5.2)

1. Player spawns with starting weapon
2. Enemies spawn and attack
3. **Enemies drop gold coins on death**
4. **Player collects gold (magnetic pull)**
5. **Gold counter increases on HUD**
6. Player takes damage from enemies
7. **Player walks near Health Shrine → [PRESS SPACE]**
8. **Player activates Health Shrine → Spend 50 gold, heal 50% HP**
9. Wave difficulty increases
10. **Player activates Damage Shrine → Spend 100 gold, +50% damage for 60s**
11. **Player melts enemies with boosted damage**
12. **Buff expires after 60 seconds**
13. Player collects XP, levels up, chooses upgrades
14. Continue surviving, use shrines tactically

---

## 🧪 Testing Checklist

### Gold System Testing:
- [ ] Enemies drop gold coins on death
- [ ] Gold coins have magnetic pull (5m range)
- [ ] Gold coins fly smoothly toward player
- [ ] Gold counter on HUD updates correctly
- [ ] Multiple coins spread out visually
- [ ] Gold persists during run (doesn't reset on level up)

### Health Shrine Testing:
- [ ] Green shrine visible at (10, 0, 10)
- [ ] Label shows "Health Shrine | 50 gold"
- [ ] Walking close shows "[PRESS SPACE]"
- [ ] Label turns RED if gold < 50
- [ ] Label turns YELLOW if gold >= 50
- [ ] Pressing SPACE activates shrine (if affordable)
- [ ] Player heals 50% HP instantly
- [ ] Gold is spent (50 gold deducted)
- [ ] Label shows "[ACTIVE]" briefly (instant effect)
- [ ] Can activate multiple times

### Damage Shrine Testing:
- [ ] Red shrine visible at (-10, 0, 10)
- [ ] Label shows "Damage Shrine | 100 gold"
- [ ] Activation costs 100 gold
- [ ] Player weapons deal +50% damage
- [ ] Console prints "Damage buff applied: 150% damage"
- [ ] Buff lasts 60 seconds
- [ ] Console prints "Damage buff expired" after 60s
- [ ] Label shows "[ACTIVE]" during buff
- [ ] Can't reactivate while buff is active
- [ ] Can reactivate after buff expires

### Speed Shrine Testing:
- [ ] Blue shrine visible at (0, 0, -10)
- [ ] Label shows "Speed Shrine | 75 gold"
- [ ] Activation costs 75 gold
- [ ] Player moves +30% faster (noticeably faster)
- [ ] Console prints "Speed buff applied: 130% speed"
- [ ] Buff lasts 60 seconds
- [ ] Console prints "Speed buff expired" after 60s
- [ ] Movement returns to normal after expiry
- [ ] Can't reactivate while buff is active

### Integration Testing:
- [ ] Can use multiple shrines in single run
- [ ] Damage buff affects all weapons
- [ ] Speed buff affects movement in all directions
- [ ] Buffs stack with character passives (Warrior damage, Ranger speed, etc.)
- [ ] Gold is lost on player death (not extracted)
- [ ] No crashes or errors when activating shrines

---

## 📁 Files Summary

### NEW Files (11 total):
1. scripts/pickups/GoldCoin.gd
2. scenes/pickups/GoldCoin.tscn
3. scripts/interactables/BaseShrine.gd
4. scenes/interactables/BaseShrine.tscn
5. scripts/interactables/HealthShrine.gd
6. scenes/interactables/HealthShrine.tscn
7. scripts/interactables/DamageShrine.gd
8. scenes/interactables/DamageShrine.tscn
9. scripts/interactables/SpeedShrine.gd
10. scenes/interactables/SpeedShrine.tscn
11. PHASE_5B_SHOPS_SHRINES_PROGRESS.md (this file)

### MODIFIED Files (5 total):
1. scripts/autoload/EventBus.gd (gold_collected signal)
2. scripts/enemies/BaseEnemy.gd (gold dropping)
3. scripts/ui/HUD.gd (gold counter)
4. scenes/ui/HUD.tscn (GoldLabel UI)
5. scripts/player/PlayerController.gd (buff tracking)
6. scenes/levels/TestArena.tscn (shrine placement)

---

## 🚀 Ready for Testing

**Gold System:** ✅ READY
**Shrine System:** ✅ READY
**Shop System:** ❌ NOT IMPLEMENTED YET

**Testing Instructions:**
1. Open Godot project
2. Run TestArena scene (F6)
3. Kill enemies to collect gold
4. Walk to shrines to see labels
5. Press SPACE to activate shrines (when in range and can afford)
6. Verify buffs work correctly
7. Report any bugs or balance issues

---

## 📈 Phase 5.2 Progress

**Completed:**
- ✅ Gold economy (drops, pickups, HUD)
- ✅ Shrine system (base + 3 shrine types)
- ✅ Buff tracking (damage, speed)
- ✅ Shrine placement in TestArena

**Remaining (Phase 5.2):**
- ⏳ Shop system (UI + purchase logic)
- ⏳ Shop items (weapons, health potion, reroll token)
- ⏳ Shop placement in TestArena

**Estimated Completion:** 75% (3 of 4 major features)

---

## 🎯 Next Steps

### Immediate (User Testing):
1. Test gold economy (enemies drop coins, pickup works)
2. Test all 3 shrines (activation, effects, duration)
3. Verify buffs work as expected
4. Check for bugs or balance issues

### Short Term (Complete Phase 5.2):
1. **Create Shop System:**
   - Shop UI (panel with item list)
   - Purchase logic (spend gold, receive item)
   - Item types:
     - Specific weapons (200-300 gold)
     - Health potion (100 gold, restore 50 HP)
     - Reroll token (150 gold, reroll next upgrade screen)
2. **Place Shop in TestArena**
3. **Test shop interactions**

### After Phase 5.2:
- Phase 6: Content Creation (more weapons, maps, enemies)
- Phase 7: Polish & Optimization
- Phase 8: Mobile export

---

## 🎉 Achievements Unlocked

✅ **Gold Economy System** - Enemies drop currency during runs
✅ **Temporary vs Permanent Currency** - Gold (lost) vs Essence (kept)
✅ **Shrine System** - Tactical mid-run power-ups
✅ **Health Shrine** - Emergency healing option
✅ **Damage Shrine** - Offensive power spike
✅ **Speed Shrine** - Mobility boost
✅ **Buff Tracking** - Temporary stat multipliers
✅ **Interactive 3D UI** - Label3D shows costs and status
✅ **Risk/Reward Decisions** - Spend gold now or save for later?

**Phase 5.2 Core Systems - 75% COMPLETE!** 💰

Ready for Phase 5.2 completion: Shop System! 🛒
