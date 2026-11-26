# Story 009: Canteen and plaza levels, three waves, exit and rotation

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 3

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Two levels, the canteen and the plaza, in rotation…"):*

- [ ] Two playable level scenes exist: the canteen and the plaza, each with a player spawn, walkable navigation, cover and firing spots for ranged enemies.
- [ ] A level visit runs three waves (story 008's spawner), then an exit opens.
- [ ] Walking into the open exit loads the next level; levels rotate canteen → plaza → canteen and so on.
- [ ] The wave count and difficulty carry across levels: the first wave of the second visit continues from where the last visit ended.
- [ ] Heart rate, ammo and substance counts carry across the level change, and are not reset by it.
- [ ] The exit stays closed until the third wave is cleared.
- [ ] Gritty, desaturated low-poly look; blockout with placeholder art is acceptable.

---

## Implementation Notes

- Persist run state across scene changes with an autoload or a run node that survives `change_scene_to_packed`; verify the 4.7 scene-change API in `docs/engine-reference/godot/` first.
- Bake navigation per level (`NavigationRegion3D`).
- Level geometry and art live under `assets/art/levels/`; layout can start as a blockout.

---

## Out of Scope

- Story 008: enemy and wave logic. Story 010: the run-end screen and restart.

---

## Files

- `src/run/game.tscn` (main scene, `run/main_scene` in `project.godot`), `src/run/level_rotation.gd` (`LevelRotation`), `src/run/level_rotation_data.gd`, `src/run/level_notice_data.gd`; `src/run/run_state.gd` reused unchanged (persists because game.tscn is never freed)
- `src/levels/canteen.tscn`, `src/levels/plaza.tscn`, `src/levels/level_base.gd`, `src/levels/level_exit.gd`
- `src/waves/wave_spawner.gd` (`start(first_wave, wave_limit)`, `_alive` pruned on start/stop)
- `assets/data/levels/levels.tres`, `assets/data/levels/level_notice.tres`
- Geometry: imported `assets/art/levels/canteen/canteen_main.fbx`, `assets/art/levels/plaza/plaza_main.fbx` + props, runtime trimesh collision (no blockout files)
- `project.godot` (`run/main_scene`), `production/session-logs/build-notes.md` (Story 009 section)
- tests: waived at `qa.level` minimal

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: playtest doc OR integration test (waived at `qa.level` minimal)

**Status**: [x] Waived (qa.level minimal); probe kept in `production/qa/evidence/story-009-levels-and-rotation/probe.txt`

---

## Dependencies

- Depends on: `production/epics/last-dose/story-008-enemies-and-waves.md`
- Unlocks: `story-010`

## Completion Notes

**Completed**: 2026-11-26
**Criteria**: 7/7 covered (probe or retained screenshot); deferred to playtest: walking into the exit with real input (the probe teleports the player into the trigger), fight flow and ranged-enemy pressure in both levels, and how the look reads in motion.
- Levels: canteen and plaza load from the real FBX models with runtime trimesh collision and a runtime navmesh bake. All 9 plaza spawn points have a nav path to the player start. All 7 plaza firing spots have a clear ray (layer 1) to the player start, (0,0), (0,-10) and (0,10). In the plaza, melee enemies reached the player and swung, and the boss aimed.
- Waves and exit: visit 1 cleared waves 1-3. The exit was closed after waves 1 and 2 and open after wave 3, with no 4th wave (spawner wave 3, 0 enemies). Walking into the closed exit did nothing (level stayed canteen).
- Rotation: teleporting the player into the open exit loaded the plaza (visit 1, first wave 4 = boss wave, exit closed again). Clearing waves 4-6 and walking in loaded the canteen again (visit 2, first wave 7).
- Carry-over: heart 133 went to 128.4 after a 1.5 s travel (normal drift, not reset). SMG 5/77, shotgun 6/11, current gun index 1 and coffee 8 / cigarettes 3 were unchanged. Time survived 26.6 went to 28.1 (kept counting). The second travel kept everything too.
- Look: both captures show desaturated grey geometry with the HUD. It is placeholder art (story 022 owns final materials).

**Deviations**:
- Advisory hardcoded numbers in code:
  - debug kill damage 1e6 (`level_rotation.gd:113`)
  - player start lift 0.05 m (`:156`)
  - notice label height 1.4 x font size (`:221`)
  - outline width x 4 (`:227`)
- Exit look and trigger size are node exports, not `.tres` (`level_exit.gd:10-15`).
- Unity positions are used without negating z. This differs from the brief: the imported FBX geometry already matches the Unity numbers, verified by raycast.
- The imported level meshes have inverted winding. `LevelBase` duplicates their materials with culling off.
- `wave_spawner.gd` (story 008's file) got the `wave_limit` argument and an `_alive` prune. test_arena still runs clean.
- No other files outside scope.

**Test Evidence**: Integration, waived at qa.level minimal. Probe: `production/qa/evidence/story-009-levels-and-rotation/probe.txt` (script `probe_script.gd.txt`). Screenshots: `01-canteen.png`, `02-plaza.png`. Stamp: `stamp.txt`.
**Run result**: OBSERVED. The canteen (main scene) shows dark grey benches and pillars, the red closed exit at the far end, enemies, and the HUD reading ENEMIES 6, WAVE 1, TIME 0:02. The plaza shows the grey courtyard with walkways, enemies, the red exit box and the HUD. No script errors in either (`production/qa/evidence/story-009-levels-and-rotation/01-canteen.png`, `02-plaza.png`).
**Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- A persistent `game.tscn` holds the Player, HUD, RunState and spawner, and levels swap under `LevelHolder`. Run state carries over without copying, and there is no autoload · kept 2026-11-26
- The real FBX level models are used with runtime trimesh collision and a navmesh bake (no blockout) · kept 2026-11-26
- Unity layout positions are used as-is (z not negated), because the imported geometry matches them (raycast-checked) · kept 2026-11-26
- Plaza firing spots (7) are our own picks, because the Unity layouts have none. Canteen uses the Unity spots plus two mid-wall spots (+-8,0,0) · kept 2026-11-26
- Plaza upper-floor spawn points were moved to connected ground positions · kept 2026-11-26
- Next visit's first wave = last cleared wave + 1. The spawner stops after 3 cleared waves per visit (`wave_limit`) · kept 2026-11-26
- The exit is a red box with light and monitoring off while closed. When open it turns green (energy 2.5, range 8) with a 3x3x3 m trigger · kept 2026-11-26
- Travel fades out in 0.6 s and in over 0.5 s (Unity). Enemies and pickups are freed before the fade-out. The first wave starts 1.5 s after a level loads · kept 2026-11-26
- Notices: "LEVEL CLEARED" for 2.5 s, then "EXIT OPEN: WALK INTO THE GREEN LIGHT" stays until travel (Unity level_notice values) · kept 2026-11-26
- Level look: materials are double-sided and darkened. Canteen ambient 0.35 with lights 0.9; plaza ambient 0.9 with lights 1.2-1.3; saturation 0.7 · kept 2026-11-26
- Opening a level scene on its own wraps it in game.tscn at that level (`start_level_id`) · kept 2026-11-26
