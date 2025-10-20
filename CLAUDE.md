# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MegabonkMobile** is a 3D mobile roguelite extraction game built with Godot 4.5 for iOS/Android. It combines Vampire Survivors-style auto-attack gameplay with extraction mechanics, where players survive enemy waves, collect XP/loot, and choose when to extract (risk vs reward).

**Current Status:** Phase 4 Complete (Extraction & Meta-Progression functional)

## Running the Project

### Open in Godot
```bash
# Open Godot 4.5+ and import the project at:
M:\GameProject\megabonk-mobile\project.godot

# Or launch directly if Godot is in PATH:
godot --editor "M:\GameProject\megabonk-mobile\project.godot"
```

### Run the Game
- **In Godot Editor:** Press F6 or click "Run Current Scene" (loads TestArena.tscn)
- **Main Scene:** `scenes/levels/TestArena.tscn`

### Testing Controls
- **PC/Desktop:** WASD to move, mouse drag to rotate camera
- **Mobile Touch:** Virtual joystick (bottom-left) to move, drag anywhere else to rotate camera

### Debug Mode
To enable god mode and 1-hit kills for testing:
- Set `DEBUG_MODE = true` in `scripts/player/PlayerController.gd` (line 9)
- Set `DEBUG_MODE = true` in `scripts/weapons/BonkHammer.gd` (line 9)
- Currently **disabled** for production

## Architecture

### Autoload Singletons (Global State)
Four autoload scripts provide global access throughout the game:

1. **EventBus** (`scripts/autoload/EventBus.gd`)
   - Signal hub for decoupled communication
   - Key signals: `player_leveled_up`, `enemy_killed`, `xp_collected`, `weapon_equipped`
   - Usage: `EventBus.player_leveled_up.emit(new_level)`

2. **GlobalData** (`scripts/autoload/GlobalData.gd`)
   - Game state and persistent data (unlocks, settings, progression)
   - Run data: current_gold, current_xp, enemies_killed
   - Methods: `reset_run_data()`, `unlock_weapon()`, `unlock_character()`

3. **SaveSystem** (`scripts/autoload/SaveSystem.gd`)
   - Save/load to `user://save_data.json`
   - JSON-based serialization for unlocks and settings

4. **ExtractionManager** (`scripts/managers/ExtractionManager.gd`)
   - Spawns extraction zones every 3 minutes
   - Calculates time-based multipliers (1.0x → 1.5x → 2.0x → 3.0x)
   - Handles extraction success → rewards → save → ExtractionSuccessScreen
   - Handles player death → statistics → DeathScreen
   - Usage: Automatic, listens for `EventBus.game_started` signal

### Core Systems Architecture

#### Movement System (Camera-Relative)
**Critical Implementation:** Player movement is camera-relative, not world-relative.

```gdscript
# In PlayerController.gd handle_movement():
var camera_forward = -camera_pivot.global_transform.basis.z
var camera_right = camera_pivot.global_transform.basis.x
# Input transforms based on camera orientation
input_dir = (camera_right * input.x + camera_forward * (-input.y)).normalized()
```

- **Body rotation:** Only the visual "Body" mesh rotates to face movement direction
- **Camera independence:** CameraArm (SpringArm3D) rotation is independent of player body
- **Input handling:** GameManager processes both keyboard and virtual joystick inputs

#### Enemy AI System (Dual Movement Modes)
Enemies use **speed-based movement** selection in `BaseEnemy.gd`:

```gdscript
# Fast enemies (move_speed >= 4.0) use direct movement
if move_speed >= 4.0:
    handle_direct_movement(delta)  # Simple vector chase, no jittering
else:
    handle_movement(delta)  # NavigationAgent3D pathfinding
```

- **FastEnemy (4.5 speed):** Direct beeline to player, bypasses navigation
- **BasicEnemy/TankEnemy (<4.0 speed):** Uses NavigationAgent3D for pathfinding
- **Why:** NavigationAgent3D causes jittering at high speeds (>4.0)

**Enemy Stats:**
- BasicEnemy: 50 HP, 3.0 speed, red capsule
- FastEnemy: 25 HP, 4.5 speed, yellow capsule (direct movement)
- TankEnemy: 150 HP, 1.5 speed, purple capsule

#### Weapon System (Type-Based Behavior)
BaseWeapon supports three weapon types via `weapon_type` enum:

```gdscript
@export_enum("ranged", "orbital", "aura") var weapon_type: String = "ranged"
```

- **"ranged":** Auto-attacks all enemies in range every cooldown (future projectile weapons)
- **"orbital":** Collision-based damage (BonkHammer) - no auto-attack, uses Area3D signals
- **"aura":** Passive AOE damage (future feature)

**BonkHammer Implementation:**
- Orbits player at 1.8m radius using sin/cos calculations
- Damages enemies on **physical collision** (Area3D.body_entered signal)
- Per-enemy cooldown: 0.5s (tracked in `hit_enemies` dictionary)
- Collision radius: 0.5m (tight hitbox)

#### XP & Leveling System
**Critical Flow:** XP collection requires fresh player lookup:

```gdscript
# In XPGem.gd collect():
# Get fresh player reference (in case collect() called before _physics_process)
var target_player = player
if not target_player:
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        target_player = players[0]
```

- **Why:** Collision signals can fire before `_physics_process()` sets the cached player reference
- **Leveling curve:** Exponential with 1.5x multiplier (100 → 150 → 225 → 337.5 XP)
- **XP Gems:** Magnetic pull at 5m range, fly to player, auto-collect on contact

### Scene Tree Structure (Input Priority)

**Critical:** Scene tree order determines input priority. Children listed **later** receive input **first**.

```
TouchControls.tscn hierarchy (CORRECT ORDER):
├── CameraControl (listed first, receives input LAST)
└── VirtualJoystick (listed second, receives input FIRST)
```

- VirtualJoystick has `mouse_filter = STOP` to consume touch events
- CameraControl has `mouse_filter = PASS` and ignores keyboard events
- Both have `focus_mode = FOCUS_NONE` to prevent stealing keyboard focus

### Wave Spawning System

**WaveManager.gd** (scene-based, not autoload):
- Spawns enemies in circular pattern around arena (20m radius)
- Difficulty scaling: spawn interval decreases from 3s to 1s minimum
- Enemy mix based on wave:
  - Waves 1-3: 100% BasicEnemy
  - Waves 4-7: 70% Basic, 30% Fast
  - Wave 8+: 50% Basic, 30% Fast, 20% Tank

## Key Design Patterns

### Resource-Based Data
- **WeaponData.gd:** Stores weapon stats (damage, cooldown, range, level)
- Usage: Create `.tres` files in `resources/weapons/` for each weapon variant
- Allows designer-friendly stat tweaking without code changes

### Signal-Based Events
All major game events use EventBus signals for loose coupling:
```gdscript
EventBus.enemy_killed.emit(enemy, xp_value)
EventBus.player_leveled_up.emit(new_level)
EventBus.xp_collected.emit(amount, total_xp, xp_needed)
```

### Group-Based Entity Detection
- Players: `add_to_group("player")` for enemy targeting
- Enemies: `add_to_group("enemies")` for weapon targeting
- XP Gems: `add_to_group("xp_gems")` for identification

### Material Uniqueness for Visual Feedback
**Critical:** Each enemy needs unique material instance to prevent shared visual effects:

```gdscript
# In BaseEnemy.gd _ready():
var body = get_node_or_null("Body")
if body and body is MeshInstance3D:
    var mat = body.mesh.surface_get_material(0).duplicate()
    body.set_surface_override_material(0, mat)
```

Without this, damage flash affects ALL enemies simultaneously.

#### Extraction System (Phase 4)

**ExtractionZone.gd** (timed extraction points):
- 5-second countdown when player enters zone
- Cancels if player leaves early
- Emits `EventBus.extraction_success` on completion
- Visual feedback via Label3D countdown

**ExtractionManager.gd** (autoload):
- Spawns zones every 3 minutes starting at 3:00
- Time-based multipliers:
  - < 3 min: 1.0x
  - 3-6 min: 1.5x
  - 6-9 min: 2.0x
  - 9+ min: 3.0x
- Essence formula: `(enemies * 10 + time / 10) * multiplier`
- Handles both extraction success and player death

**Critical Implementation Details:**
```gdscript
# In ExtractionSuccessScreen.gd and DeathScreen.gd
# WRONG: Using .set()/.get() for dynamic data
var results = GlobalData.get("last_extraction_results")  # Returns null!

# CORRECT: Use declared variables
var last_extraction_results: Dictionary = {}  # In GlobalData.gd
extraction_results = GlobalData.last_extraction_results  # Direct access
```

**UI Screen Node Paths:**
- **CRITICAL**: Always verify scene hierarchy matches @onready paths
- Common mistake: Missing intermediate nodes like `MarginContainer`
- Example error:
  ```gdscript
  # WRONG - Missing MarginContainer
  @onready var label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel

  # CORRECT - Includes all parent nodes
  @onready var label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
  ```
- If nodes appear `null` at runtime, check full hierarchy in .tscn file
- Use `push_error()` to debug missing nodes in _ready()

## Common Issues & Solutions

### Input Not Working
- Check scene tree order in TouchControls.tscn (VirtualJoystick after CameraControl)
- Verify `mouse_filter` and `focus_mode` settings on UI controls
- For keyboard: Use `Input.is_physical_key_pressed()` not input actions

### Enemy Jittering at High Speed
- Use direct movement (`handle_direct_movement()`) for speeds >= 4.0
- NavigationAgent3D `path_max_distance` must be large enough for lookahead
- Disable `avoidance_enabled` for fast enemies

### XP Not Collecting
- Player must be in "player" group
- XPGem must get fresh player reference in `collect()`
- Check collision layers: XPGem layer 3, mask 1 (player)

### Weapon Not Hitting
- Orbital weapons: Ensure weapon_type = "orbital" and collision signals connected
- Check enemy is in "enemies" group
- Verify collision layer/mask configuration

### UI Nodes Returning Null
- Verify `@onready var` node paths match exact scene hierarchy
- Check for missing intermediate nodes (MarginContainer, PanelContainer, etc.)
- Use Godot's "Copy Node Path" feature for accuracy
- Add debug prints in `_ready()` to verify nodes are found

### GlobalData Variables Not Persisting
- Use declared variables (`var name: Type = default`) not `.set()/.get()`
- `.set()`/`.get()` are Node methods for properties, not dynamic data storage
- For data passed between scenes, declare explicit variables in GlobalData.gd

## File Organization

```
megabonk-mobile/
├── scenes/
│   ├── player/Player.tscn (CharacterBody3D + CameraArm + WeaponManager)
│   ├── enemies/ (BaseEnemy + 3 variants)
│   ├── weapons/ (BonkHammer.tscn)
│   ├── pickups/ (XPGem.tscn)
│   ├── levels/ (TestArena.tscn - main test scene)
│   └── ui/ (TouchControls.tscn)
├── scripts/
│   ├── autoload/ (EventBus, GlobalData, SaveSystem)
│   ├── managers/ (GameManager, WaveManager, WeaponManager)
│   ├── player/ (PlayerController.gd)
│   ├── enemies/ (BaseEnemy.gd)
│   ├── weapons/ (BaseWeapon.gd, BonkHammer.gd)
│   ├── pickups/ (XPGem.gd)
│   └── ui/ (VirtualJoystick.gd, CameraControl.gd)
└── resources/
    └── weapons/ (WeaponData.gd resource script)
```

## Development Roadmap

See `TaskList.txt` for detailed phase breakdown.

**Phase 1:** ✅ Complete (Foundation & Movement)
**Phase 2:** ✅ Complete (Enemy System & Combat)
**Phase 3:** ✅ Complete (Weapons & Upgrades)
**Phase 4:** ✅ Complete (Extraction & Meta-Progression)
**Phase 5:** Planned (UI/UX Polish & Settings)
**Phase 6:** Planned (Testing & Balance)
**Phase 7:** Planned (Mobile Export)

## Mobile Export Notes

- **Target:** iOS & Android (landscape orientation)
- **Resolution:** 1920x1080 with canvas_items stretch mode
- **Input:** Dual system (virtual joystick + camera touch drag)
- **Performance:** Object pooling planned for enemies/projectiles
- **Android Export:** Requires Android export templates for Godot 4.5
- **iOS Export:** Requires macOS with Xcode and iOS export templates
