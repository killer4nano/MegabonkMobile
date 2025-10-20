# 🎮 CONTENT CREATOR AGENT

**Role:** Game Content Creation (Weapons, Enemies, Upgrades, Characters)
**Activation:** After core bugs fixed, when content < MVP requirements
**Priority:** HIGH (content needed for MVP)

---

## 🎯 CORE RESPONSIBILITIES

1. **Create new weapons** with unique mechanics
2. **Design upgrades** with interesting synergies
3. **Add enemy variants** with different behaviors
4. **Implement new characters** with unique abilities
5. **Balance all content** for fun gameplay

---

## 📋 MVP CONTENT REQUIREMENTS

Current vs Target (from PROJECT_STATUS.md):

| Content Type | Current | Target | Needed | Priority |
|--------------|---------|--------|--------|----------|
| Weapons | 3 | 10 | **7** | CRITICAL |
| Upgrades | 13 | 30 | **17** | CRITICAL |
| Enemies | 3 | 5 | **2** | HIGH |
| Characters | 5 | 5 | **0** | COMPLETE |
| Maps | 1 | 2 | **1** | MEDIUM |

**Focus: Add 7 weapons and 17 upgrades ASAP!**

---

## 🗡️ WEAPON CREATION GUIDE

### Weapon Types & Templates

#### 1. Orbital Weapons (Circle Player)
```gdscript
extends BaseWeapon

func _ready() -> void:
    weapon_type = "orbital"
    damage = 20.0
    cooldown = 0.5
    range = 2.0  # Orbit radius

    # Set up collision
    var area = Area3D.new()
    var collision = CollisionShape3D.new()
    collision.shape = SphereShape3D.new()
    collision.shape.radius = 0.5
    area.add_child(collision)
    add_child(area)

    area.body_entered.connect(_on_body_entered)
    area.add_to_group("weapons")

func _process(delta: float) -> void:
    # Orbit around player
    orbit_angle += orbit_speed * delta
    var offset = Vector3(
        cos(orbit_angle) * range,
        0,
        sin(orbit_angle) * range
    )
    global_position = player.global_position + offset
```

#### 2. Projectile Weapons (Auto-Fire)
```gdscript
extends BaseWeapon

func _ready() -> void:
    weapon_type = "ranged"
    damage = 15.0
    cooldown = 1.0
    range = 10.0
    projectile_speed = 20.0

func attack() -> void:
    var projectile = preload("res://scenes/weapons/Projectile.tscn").instantiate()
    projectile.damage = damage * damage_multiplier
    projectile.velocity = direction_to_target * projectile_speed
    get_tree().root.add_child(projectile)
    projectile.global_position = global_position
```

#### 3. Area Weapons (Periodic Damage)
```gdscript
extends BaseWeapon

func _ready() -> void:
    weapon_type = "aura"
    damage = 30.0
    cooldown = 2.0
    range = 5.0  # AOE radius

func attack() -> void:
    # Create damage zone
    var explosion = preload("res://scenes/effects/Explosion.tscn").instantiate()
    explosion.damage = damage * damage_multiplier
    explosion.radius = range
    get_tree().root.add_child(explosion)
    explosion.global_position = target_position
```

### New Weapons to Create

1. **Fireball** (Projectile)
   - Type: Projectile with AOE on impact
   - Damage: 25
   - Speed: Medium
   - Special: Explosion damages multiple enemies

2. **Lightning Strike** (Area)
   - Type: Periodic AOE
   - Damage: 40
   - Cooldown: 3s
   - Special: Chain lightning between enemies

3. **Laser Beam** (Beam)
   - Type: Continuous damage
   - Damage: 10/sec
   - Range: 15m
   - Special: Pierces through enemies

4. **Boomerang** (Projectile)
   - Type: Returning projectile
   - Damage: 20
   - Speed: Fast
   - Special: Hits twice (out and back)

5. **Poison Cloud** (Zone)
   - Type: Damage over time zone
   - Damage: 5/sec
   - Duration: 10s
   - Special: Slows enemies

6. **Shield Ring** (Orbital)
   - Type: Large orbital
   - Damage: 35
   - Radius: 3m
   - Special: Blocks projectiles

7. **Ice Beam** (Beam)
   - Type: Slowing beam
   - Damage: 8/sec
   - Range: 12m
   - Special: Slows by 50%

---

## ⬆️ UPGRADE CREATION GUIDE

### Upgrade Categories

#### Stat Boosts
```gdscript
# UpgradeData Resource
@export var upgrade_type: String = "stat_boost"
@export var stat_name: String = "max_health"
@export var value: float = 20.0
@export var is_percentage: bool = false
```

#### Weapon Enhancements
```gdscript
@export var upgrade_type: String = "weapon_upgrade"
@export var weapon_name: String = "BonkHammer"
@export var property: String = "damage"
@export var multiplier: float = 1.5
```

#### Passive Abilities
```gdscript
@export var upgrade_type: String = "passive"
@export var ability: String = "lifesteal"
@export var value: float = 0.05  # 5% lifesteal
```

### New Upgrades Needed (17)

**Stat Boosts (6):**
1. Thick Skin (+25 HP)
2. Speed Boots (+15% movement)
3. Eagle Eye (+10% crit chance)
4. Heavy Hitter (+20% damage)
5. Quick Reflexes (+20% attack speed)
6. Magnetism (+30% pickup range)

**Weapon Upgrades (6):**
7. Multishot (+1 projectile)
8. Piercing Rounds (projectiles pierce)
9. Explosive Finale (enemies explode on death)
10. Vampiric Weapons (5% lifesteal)
11. Freezing Touch (attacks slow)
12. Burning Passion (attacks ignite)

**Passive Abilities (5):**
13. Thorns (reflect 10% damage)
14. Second Wind (revive once at 50% HP)
15. Lucky Charm (+50% gold drops)
16. Experience Boost (+25% XP)
17. Dodge Master (10% dodge chance)

---

## 👾 ENEMY CREATION GUIDE

### Enemy Template
```gdscript
extends BaseEnemy

func _ready() -> void:
    max_health = 100
    current_health = max_health
    move_speed = 2.5
    contact_damage = 15
    xp_value = 20
    gold_value = 2

    # Special behavior
    attack_pattern = "ranged"  # or "charge", "summon", etc.
```

### New Enemies Needed (2)

1. **Ranged Enemy**
   - HP: 40
   - Speed: 2.0
   - Attack: Shoots projectiles
   - Gold: 2
   - XP: 15

2. **Boss Enemy**
   - HP: 500
   - Speed: 2.5
   - Attack: Multiple patterns
   - Gold: 50
   - XP: 100

---

## 📁 FILE ORGANIZATION

### Resources
```
resources/
├── weapons/
│   ├── fireball.tres
│   ├── lightning_strike.tres
│   └── [weapon_name].tres
├── upgrades/
│   ├── thick_skin.tres
│   ├── multishot.tres
│   └── [upgrade_name].tres
└── enemies/
    ├── ranged_enemy.tres
    └── boss_enemy.tres
```

### Scripts
```
scripts/
├── weapons/
│   ├── Fireball.gd
│   └── [WeaponName].gd
├── upgrades/
│   └── UpgradeEffects.gd
└── enemies/
    ├── RangedEnemy.gd
    └── BossEnemy.gd
```

### Scenes
```
scenes/
├── weapons/
│   ├── Fireball.tscn
│   └── [WeaponName].tscn
├── enemies/
│   ├── RangedEnemy.tscn
│   └── BossEnemy.tscn
└── effects/
    └── [Effects].tscn
```

---

## ⚖️ BALANCE GUIDELINES

### Weapon Balance
- **DPS Range:** 10-40 damage per second
- **Orbital:** High damage, limited range
- **Projectile:** Medium damage, good range
- **Area:** High damage, long cooldown

### Upgrade Balance
- **Common:** +10-20% improvement
- **Rare:** +25-40% improvement
- **Epic:** +50-75% improvement
- **Legendary:** +100% or new ability

### Enemy Balance
- **Basic:** Easy for new players
- **Elite:** Challenge for mid-game
- **Boss:** Requires good build

---

## 🧪 TESTING REQUIREMENTS

For each content addition:

1. **Create content files**
2. **Add to spawn pools**
3. **Create unit test**
4. **Test in-game**
5. **Balance based on feel**
6. **Document in wiki**

### Test Template
```gdscript
func test_new_weapon() -> void:
    var weapon = preload("res://resources/weapons/new_weapon.tres")
    assert(weapon.damage > 0, "Damage must be positive")
    assert(weapon.cooldown > 0, "Cooldown required")
    # More assertions...
```

---

## 🔄 CONTENT CREATION WORKFLOW

### 1. Check Prerequisites
```bash
# Ensure bugs fixed
./AUTOMATION/run_all_tests.bat
# Check quality gates
python AUTOMATION/check_quality_gates.py
```

### 2. Create Content
- Design stats/mechanics
- Create .tres resource
- Write .gd script
- Build .tscn scene
- Add visual effects

### 3. Integrate
- Add to spawn pools
- Update UI icons
- Connect signals
- Add to save system

### 4. Test & Balance
- Spawn in test arena
- Check damage numbers
- Verify special effects
- Adjust for fun factor

### 5. Document
```markdown
## New Content: [Name]

### Stats
- Damage: X
- Cooldown: Y
- Special: Z

### Usage
- Good against: [Enemy types]
- Synergizes with: [Other content]

### Balance Notes
- [Any concerns or tweaks]
```

---

## 🎯 IMMEDIATE PRIORITIES

### Week 1: Weapons (7 needed)
1. Day 1-2: Create Fireball, Lightning Strike
2. Day 3-4: Create Laser Beam, Boomerang
3. Day 5-6: Create Poison Cloud, Shield Ring, Ice Beam
4. Day 7: Balance testing and polish

### Week 2: Upgrades (17 needed)
1. Day 1-3: Create stat boosts (6)
2. Day 4-6: Create weapon upgrades (6)
3. Day 7-9: Create passive abilities (5)
4. Day 10: Integration and balance

### Week 3: Enemies & Polish
1. Day 1-2: Create Ranged Enemy
2. Day 3-5: Create Boss Enemy
3. Day 6-7: Final balance pass

---

## 🤝 HANDOFF PROTOCOL

When completing content:

```json
{
  "content_type": "weapon",
  "name": "Fireball",
  "stats": {
    "damage": 25,
    "cooldown": 1.5,
    "range": 10
  },
  "files_created": [
    "resources/weapons/fireball.tres",
    "scripts/weapons/Fireball.gd",
    "scenes/weapons/Fireball.tscn"
  ],
  "tests_added": ["test_fireball_damage", "test_fireball_aoe"],
  "balance_notes": "Slightly OP in early game, consider damage nerf",
  "time_spent": 3.5
}
```

---

## ⚠️ CRITICAL NOTES

- **Wait for WEAPON-001 fix** before starting (upgrades broken)
- **Test each addition thoroughly**
- **Maintain game balance**
- **Keep mobile performance in mind**
- **Ensure save compatibility**
- **Add variety, not just more**

---

**Agent Status:** WAITING
**Blocked By:** WEAPON-001 bug fix
**Ready To:** Create 7 weapons + 17 upgrades