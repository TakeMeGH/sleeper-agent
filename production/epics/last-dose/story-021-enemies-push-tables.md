# Story 021: Enemies push tables aside

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 21
*(Unity reference: story 051.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Enemies push tables aside and never pass through them"):*

- [ ] A melee enemy, a ranged enemy and the boss that walk into a table push it ahead or aside and never visibly overlap it (at least 20 walk-ins at different angles: head-on, at a corner, along a side).
- [ ] The push looks like a push: the table slides and turns at about the enemy's walking speed, does not launch, spin wildly or jitter, and comes to rest on its own.
- [ ] A table pinned against a wall, a bench, another table or the player stops the enemy instead of letting it through; the enemy finds another way within a set time (data) and never stands still against it.
- [ ] Each table's collider covers its top and legs footprint.
- [ ] Everything else enemies do is unchanged: melee chase, firing spots and line of fire, the boss's walk and armour, spawning at the doors.
- [ ] The player's own movement and dive against tables are unchanged (the player does not push tables here).
- [ ] The plaza's loose props follow the same rule: enemies do not clip through them.
- [ ] No visible frame drop in the canteen with a full wave on the tables.

---

## Implementation Notes

- Tables as `RigidBody3D` (Jolt) with damping so they come to rest; enemies as `CharacterBody3D` pushing via `get_slide_collision` impulses, or navigation obstacles. Check `docs/engine-reference/godot/modules/physics.md` and `navigation.md` first.
- Table mass and collider settings live on the table scenes.

---

## Out of Scope

- Story 017: the player's dive over tables. Story 022: final table art.

---

## Files

- `src/levels/table.gd` (PushableProp, new)
- `src/levels/pushable_prop_data.gd` (PushablePropData, new)
- `src/ai/enemy_push_data.gd` (EnemyPushData, new)
- `src/ai/enemy_base.gd` (push, stuck, two-waypoint detour, back-off)
- `src/ai/enemy_data.gd` (optional `push` override)
- `src/levels/level_base.gd` (runtime conversion of tables/bins to PushableProp, excluded from nav bake)
- `src/run/level_rotation.gd` (debug exports `debug_spawn_kinds`, `debug_spawn_positions`)
- `src/levels/test_canteen_push_table.tscn` (launch scene)
- `assets/data/levels/table_push.tres`, `assets/data/levels/loose_prop_push.tres`
- `assets/data/enemies/enemy_push.tres`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: playtest doc OR integration test (waived at `qa.level` minimal)

**Status**: [ ] Waived

---

## Dependencies

- Depends on: `story-008-enemies-and-waves.md`, `story-009-levels-and-rotation.md` (same folder)
- Unlocks: None

---

## Completion Notes

**Completed**: 2026-11-26
**Criteria**: 5/8 covered, 3 deferred, 0 fail. Deferred (playtest): (2) the push *looks* like a push (numbers in probe.txt: table speed 0.5-0.74 x walk speed on average, yaw capped 45 deg/s, no vertical motion, at rest after pushes stop; boss pushes show 5-9 stop-go restarts in a 10 s trial, judge by eye); (5) everything else unchanged (melee reaches 1.6 m, ranged reaches its spot, boss holds its 12 m band in the sweep; spawning at doors, line of fire and boss armour not re-probed); (8) no visible frame drop (headless only: 13 enemies, physics 2.9 ms avg / 13.7 ms max, process 2.2 ms; rendering not measured).
**Covered**: (1) 38 canteen walk-ins (melee 14, pistol 14, boss 10; head-on, corner, along side, graze, side-on) + 4 plaza bin walk-ins: max capsule/footprint overlap 0.014 m; (3) pinned tables (against player, bench, other table) stop the enemy; it starts a detour within stuck_seconds (stuck_max 0.98 s); (4) box collider 1.17 x 0.84 x 2.91 m = table mesh AABB (top + legs footprint); (6) player walking into tables from 4 sides moves them 0.000 m; canteen dive sweep: 276 common starts, 0 endpoints changed, 0 through geometry; (7) plaza: 11/11 props have colliders, the 2 bins are pushable and are pushed without overlap.
**Known gap (outside the table code)**: side-on walk-ins from the east (side_from_e, side_from_e_off; melee and pistol) never reach a lure behind the bench: after the table detour the nav path runs over the bench end/seat (navmesh treats seats as walkable, agent_max_climb 1.0, story 009 bake). The enemy cycles detour/back-off and does not stand still, but does not get there. Not checked against a no-table baseline. Story 017 capture `test_canteen_dive_over_table` now lands on the table top at frame 47 (was the far edge at 53) because the box top covers the whole footprint; still ends on the bench.
**Deviations**: tables are kinematic CharacterBody3D (move_and_collide), not RigidBody3D as the implementation note suggested (player must not push; no launch/spin); files beyond the story's list: `pushable_prop_data.gd`, `enemy_push_data.gd`, `enemy_data.gd`, `level_base.gd`, `level_rotation.gd` (debug exports, story 009 file), test scene; no hardcoded gameplay numbers (only epsilons).
**Test Evidence**: waived (qa.level minimal); probes in `production/qa/evidence/story-021-enemies-push-tables/probe.txt` (+ scripts), screenshots `01-enemy-pushing-table.png`, `02-table-before-after-push.png`, `03-push-frame70.png`, stamp `stamp.txt`.
**Run result**: OBSERVED — in the canteen a melee enemy pushes a table down the column toward the camera; frame 40 vs 90 shows the table slid and turned with the enemy at its end (production/qa/evidence/story-021-enemies-push-tables/02-table-before-after-push.png, 03-push-frame70.png)
**Probe finding**: one sweep run (pistol head-on from the south) hung about 2.5 h: the player was placed inside a table, the enemy never registered, and the probe's early return skipped its frame cap. Fixed in the probe (hard frame cap, 120 s wall-clock quit, `timeout 300` on every run); rerun passed.
**Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- Kinematic pushable (CharacterBody3D on layer 1, mask 1|2) instead of RigidBody3D: the player is blocked but cannot push; tables stop on walls, benches, other tables, the player and enemies · kept 2026-11-26
- Navigation policy: tables/bins excluded from the bake (static-collider parse), so their spots are walkable and no re-bake is ever needed; enemies push or detour · kept 2026-11-26
- Conversion at runtime in LevelBase by scene token (`dynamic_table`, `dynamic_bin`); canteen.tscn / gen_levels.py untouched · kept 2026-11-26
- Push speed = desired speed along the contact x 0.9 (enemy) x 0.9 (table; bin 1.0); strongest single request per frame, cap 4 m/s; accel 20, decel 14 m/s2 · kept 2026-11-26
- Yaw from lever arm, 0.2 m deadzone, cap 45 deg/s (bin 90); turn only if a box shrunk 0.015 m is clear · kept 2026-11-26
- Stuck = average speed < 0.6 m/s over 0.4 s while wanting >= 1 m/s, for 1.0 s, prop touched within 2.0 s -> two-waypoint detour (near corner, far corner, clearance 0.4, pass 1.0), other side, then back off 1.5 m; timeout 4.0 s · kept 2026-11-26
- Plaza: only the 2 bins pushable; pillars/debris stay static and baked; canteen benches static · kept 2026-11-26
- Boss pushes with the same factor as other enemies (boss_push_factor 1.0) · kept 2026-11-26
- Box collider from mesh AABB, floor + 0.02 m to top, pivot at the horizontal AABB centre · kept 2026-11-26
- Debug exports on LevelRotation (`debug_spawn_kinds`, `debug_spawn_positions`) for the launch scene · kept 2026-11-26
