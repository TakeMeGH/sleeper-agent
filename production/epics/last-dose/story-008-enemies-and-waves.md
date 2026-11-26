# Story 008: Human enemies (melee, ranged, boss) and the wave mix

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 4

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Three human enemy types in escalating waves…"):*

- [ ] Melee enemy: chases the player with a baseball bat and swings when close; a hit calls the player's `take_hit(damage)`.
- [ ] Ranged enemy: runs to a firing spot, shoots only with a clear line of fire, and reloads when empty.
- [ ] Boss: walks around with an SMG in heavy armour; armour absorbs part of each hit until it breaks, after which hits do full damage.
- [ ] All enemies take damage through `take_hit(damage, direction)` from the player's guns (story 001) and die at 0, including shotgun pushback.
- [ ] A dying enemy can drop SMG/shotgun spare ammo and coffee or cigarettes (through stories 001's and 003's public add methods).
- [ ] A wave spawner runs waves of a growing mix of the three types; wave number and difficulty increase each wave.
- [ ] Signals: `wave_started(n)`, `wave_cleared(n)`, `enemies_left_changed(count)`, `enemy_killed`.
- [ ] Enemy stats, drop chances and the wave mix table live in data resources.
- [ ] Placeholder low-poly human models are acceptable.

---

## Implementation Notes

- Navigation with `NavigationAgent3D`; look up the 4.7 navigation API in `docs/engine-reference/godot/modules/navigation.md` first.
- Ranged enemies pick from `Marker3D` firing spots placed in the level (story 009).
- Prefer a simple state machine per enemy (`chase / attack`, `move_to_spot / shoot / reload`).
- Feed the run-state stub from story 005 with wave number and enemies left.

---

## Out of Scope

- Story 009: levels, firing spot placement, the exit. Story 010: the run-end screen.

---

## Files

- `src/ai/enemy_data.gd`, `src/ai/enemy_base.gd`, `src/ai/melee_enemy.gd`, `src/ai/ranged_enemy.gd`, `src/ai/boss_enemy.gd` (enemies; bodies built in code, no per-enemy .tscn)
- `src/ai/drop_data.gd`, `src/ai/drop_roller.gd`, `src/ai/drop_pickup.gd` (drops and pickups)
- `src/waves/wave_enemy_entry.gd`, `src/waves/wave_data.gd`, `src/waves/wave_spawner.gd`
- `src/waves/test_arena.gd`, `src/waves/test_arena.tscn` (launchable arena test scene, runtime nav bake), `src/waves/test_arena_wave2.tscn`, `src/waves/test_arena_boss.tscn` (capture scenes)
- `assets/data/enemies/melee.tres`, `ranged.tres`, `boss.tres`; `assets/data/waves/default_waves.tres`; `assets/data/drops/drops.tres`
- `production/session-logs/build-notes.md` (Story 008 section)
- tests: waived at `qa.level` minimal

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: waived at `qa.level` minimal (advisory)

**Status**: [ ] Waived

---

## Dependencies

- Depends on: `production/epics/last-dose/story-001-weapons-pass.md`, `production/epics/last-dose/story-002-heart-rate-and-zones.md`
- Unlocks: `story-009`, `story-010`

## Completion Notes

**Completed**: 2026-11-26
**Criteria**: 9/9 covered (probe or retained screenshot); deferred to playtest: boss orbit/burst feel and how often ranged enemies get to shoot (see notes).
- Melee: chases, windup -> swing -> recover; a swing lands on the player through `take_hit` (heart -15 at frames 154 and 264). Ranged: goes to firing spots; 13 shots across two runs, 0 without a clear line; reload seen; line check false behind CoverC, true in the open. Boss: 40-damage hit -> armour -28, health -12 until armour 0 (hit 11), plates 5 -> 0, then full 40 damage. Pushback (8,0,0) -> knockback (4.8,0,0); kill -> `enemy_killed`, `enemies_left_changed`, RunState updated. Drops: roller numbers and all four pickups call `add_spare_ammo` / `add_substance` (smg spare 120, shotgun 30, coffee 7->8, cigarette 3->4); boss death spawns 2 of each. Waves: mix grows 6 / 8+2 / 10+3 / boss+4+2 / 14+5 ..., scaling +10% health per wave; `wave_started` / `wave_cleared` 1 and 2 observed.
- Note: with the player at (0,0,6), ranged enemies fired only 1 shot in 12 s, because most firing spots have no clear line from there and they keep repositioning. At (0,0,0) they fired 12. Story 009 spot placement and playtest own this.
- Boss capture (`02-boss-wave.png`) shows the wave 4 escort and HUD, but the boss itself is not in frame.

**Deviations**: hardcoded AI numbers in code (advisory): melee stop distance 0.8 x reach and hit tolerance 1.25 x reach (`melee_enemy.gd:42,76`), turn rate 12 (`enemy_base.gd:202`), player chest aim height 1.0 m (`enemy_base.gd:161`), hit flash 0.12 s, boss orbit radius = middle of the band (`boss_enemy.gd:123`). No files outside the story's scope changed. Unity pose, flash, tracer, sound and stagger fields were not ported.
**Test Evidence**: Logic, waived at qa.level minimal. Probes kept at `production/qa/evidence/story-008-enemies-and-waves/probe.txt` (scripts `probe_script.gd.txt`, `probe_melee.gd.txt`, `probe_waves.gd.txt`). Screenshots: `01-wave2.png`, `02-boss-wave.png`. Stamp: `stamp.txt`.
**Run result**: OBSERVED. The wave 2 arena shows a blue ranged enemy and an orange melee enemy with a bat between the cover boxes. The HUD reads ENEMIES 10, WAVE 2, TIME 0:04, with no script errors (`production/qa/evidence/story-008-enemies-and-waves/01-wave2.png`).
**Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- Boss wave = boss + escort (melee 4, ranged 2) only, no regular mix · kept 2026-11-26
- Scaling 1 + per_wave x (wave - 1) for every type including escort · kept 2026-11-26
- Boss drops guaranteed 2 each of smg/shotgun/coffee/cigarette (random chances 0) · kept 2026-11-26
- Knockback: scale 0.6 (boss 0.15), decay 8/s, cap 10 m/s, horizontal only · kept 2026-11-26
- Enemies on layer 2, collide with world + each other; player walks through them; enemy rays use layer 1 · kept 2026-11-26
- Spawn jitter 1.0 m around each spawn marker · kept 2026-11-26
- Ranged fire_rate = shots per second; aim 0.6 s; spot choice: in band with clear line > in band > others within shot_range, nearest, reserved by metadata · kept 2026-11-26
- Boss: orbit 22 deg steps at band middle, flip 4.5 s or 0.8 s no line; aim 0.7 s, burst 6 x 0.1 s, pause 1.5 s; one SMG · kept 2026-11-26
- Boss armour absorbs min(armour, damage x 0.7); plates freed at 0 · kept 2026-11-26
- Melee hit needs line of sight and distance <= 1.25 x reach; recover = attack_interval - windup - swing · kept 2026-11-26
- Colours: melee orange, ranged blue, boss grey with dark plates; pickups use imported props fitted to 0.4 m with emissive tint · kept 2026-11-26
- Pickup stays when nothing can be added; cap 12 per family, oldest freed · kept 2026-11-26
- Spawn groups of 3, 0.4 s inside a group, 0.75 s between groups, 5 s between waves (Unity values); shuffled order, random marker · kept 2026-11-26
- Runtime nav bake in test_arena `_ready` (not stored in .tscn); `debug_keep_heart_rate` export for captures · kept 2026-11-26
