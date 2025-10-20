# MegabonkMobile

A mobile roguelite extraction game inspired by Megabonk and Vampire Survivors.

## Platform
- iOS & Android
- Built with Godot 4.5

## Game Concept
3D third-person auto-shooter roguelite with extraction mechanics. Survive waves of enemies, collect loot, and choose when to extract for risk vs reward gameplay.

## Current Status

**Phase 1: COMPLETE ✅**
- Player movement with camera-relative controls
- Virtual joystick for mobile
- Camera rotation system
- Save/Load foundation
- Event bus architecture

**Phase 2: COMPLETE ✅**
- Enemy AI system (3 enemy types: Basic, Fast, Tank)
- Wave spawning with difficulty scaling
- Combat mechanics
- XP collection and leveling

**Phase 3: COMPLETE ✅**
- Weapon system (BonkHammer, Magic Missile, Spinning Blade, Fireball, Ground Slam)
- Upgrade system with random selections
- Weapon unlocks via gameplay
- Stat boosts and passive abilities

**Phase 4: COMPLETE ✅**
- Extraction system with timed zones
- Risk/reward multipliers (1.0x - 3.0x)
- Meta-progression currency (Essence)
- Death and extraction success screens
- Main menu with persistent stats
- Save/load integration

**Next: Phase 5** - UI/UX Polish & Settings Menu

## How to Play

### Controls
- **Mobile**: Virtual joystick (bottom-left) to move, drag screen to rotate camera
- **PC Testing**: WASD to move, mouse drag to rotate camera

### Gameplay Loop
1. Start from Main Menu → Click PLAY
2. Survive enemy waves, collect XP, level up
3. Choose weapon upgrades as you level
4. Wait for extraction zone to spawn (3 minutes)
5. Extract for guaranteed rewards OR keep fighting for higher multipliers
6. Use Essence to unlock new content (future phases)

### Extraction Multipliers
- < 3 min: 1.0x (safe early extraction)
- 3-6 min: 1.5x (moderate risk)
- 6-9 min: 2.0x (high risk)
- 9+ min: 3.0x (maximum challenge)

## Development

### Running the Project
Open in Godot 4.5+ and run `scenes/ui/MainMenu.tscn` (or press F5).

### Project Structure
```
megabonk-mobile/
├── scenes/
│   ├── player/ - Player character with weapons
│   ├── enemies/ - Enemy variants
│   ├── weapons/ - Weapon scenes
│   ├── levels/ - Game arenas and extraction zones
│   └── ui/ - Menus, HUD, screens
├── scripts/
│   ├── autoload/ - Global singletons (EventBus, GlobalData, SaveSystem, ExtractionManager)
│   ├── managers/ - Game systems
│   ├── player/ - Player controller
│   ├── enemies/ - Enemy AI
│   ├── weapons/ - Weapon logic
│   └── ui/ - UI controllers
└── resources/ - Weapon data resources
```

### Key Systems
- **Autoload Singletons**: EventBus, GlobalData, SaveSystem, ExtractionManager
- **Camera-Relative Movement**: Player rotates independently of camera
- **Dual-Mode Enemy AI**: Navigation for slow enemies, direct movement for fast
- **Extraction Risk/Reward**: Time-based multipliers incentivize longer runs
- **Meta-Progression**: Essence currency persists between runs

See `CLAUDE.md` for detailed architecture and development notes.

## Roadmap

**Phase 5**: UI/UX Polish (Planned)
- Settings menu implementation
- Visual effects polish
- Sound effects and music
- Tutorial/onboarding

**Phase 6**: Testing & Balance (Planned)
- Weapon balance tuning
- Enemy difficulty scaling
- Essence economy balance
- Performance optimization

**Phase 7**: Mobile Export (Planned)
- Android APK build
- iOS IPA build
- Touch control refinement
- Performance testing on devices
