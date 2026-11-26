# Story 019: Enemy variety: group spawns and ranged gun variants

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 19
*(Unity reference: stories 034 and 053.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Enemy variety…"):*

- [ ] A wave spawns in groups: each group takes one spawn point and all its enemies spawn there; the group size comes from data.
- [ ] A wave's total count does not change: it is split into groups of the set size and the last group takes the rest (a wave of 7 with size 3 spawns 3, 3, 1).
- [ ] Within a group enemies spawn one after another a set time apart; groups use the spawn points in turn, so a run is deterministic. A group size of 1 spawns one enemy per point as before.
- [ ] Ranged enemies come in three kinds, pistol, shotgun and SMG, each with its own gun prop and attack, and each firing its own way from data: pistol single shots; shotgun several pellets in a spread, slow rate, shorter preferred distance (so it picks closer firing spots); SMG bursts.
- [ ] Every hit lowers the heart rate as story 002 sets and shows story 015's hit arc; each pellet of a shotgun blast that hits counts.
- [ ] The wave mix lists the three ranged kinds separately, each with its own first wave, counts and scaling, so later waves can bring more.
- [ ] Each kind has its own drop table; the pistol kind drops no ammo (the player's pistol has endless ammo).
- [ ] The firing spot, line-of-fire check and reload work for all three kinds, and at fighting range the player can tell which gun an enemy carries from its look and its sound.
- [ ] Every number is in data.

---

## Implementation Notes

- Extends story 008's spawner and ranged enemy; do not fork them.
- The gun props arrive with story 020's models; use placeholder meshes until then.

---

## Out of Scope

- Story 020: models and animation. Story 012: enemy gun sounds beyond the existing shot sounds.

---

## Files

- `src/ai/ranged_gun_data.gd`
- `src/ai/ranged_enemy.gd`
- `src/ai/enemy_base.gd`
- `src/ai/enemy_data.gd`
- `src/waves/wave_spawner.gd`
- `src/waves/test_arena.gd`
- `src/waves/test_arena_ranged_mix.tscn`
- `assets/data/enemies/ranged_pistol.tres`
- `assets/data/enemies/ranged_shotgun.tres`
- `assets/data/enemies/ranged_smg.tres`
- `assets/data/waves/default_waves.tres`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: waived at `qa.level` minimal (advisory)

**Status**: [ ] Waived

---

## Dependencies

- Depends on: `story-008-enemies-and-waves.md`, `story-009-levels-and-rotation.md` (same folder)
- Unlocks: None

## Completion Notes

- **Completed**: 2026-11-26
- **Criteria**: 9/9 checked, 7 covered fully, 2 partly deferred to playtest: gun prop look (placeholder FBX props are small at range; story 020 owns models) and telling the gun by look AND sound at fighting range (tint/size differ in the capture; sound needs a listen). No failures.
- **Deviations**: the pellet sunflower angle and the spawn jitter ring angle use the golden angle 2.399963 rad as a geometric constant in code (not a tuning value). `enemy_base.gd`, `enemy_data.gd`, `test_arena.gd` were edited (extending story 008, not forked). Old `assets/data/enemies/ranged.tres` kept but no longer in the wave table. Spawner `rng`/`rng_seed` kept but unused.
- **Test Evidence**: waived at qa.level minimal (Logic). Probes `.scratch/probes/p019c.gd`, `p019d.gd`, `p019e.gd`; output in `production/qa/evidence/story-019-enemy-variety/probe.txt`; capture `production/qa/evidence/story-019-enemy-variety/01-three-ranged-kinds.png`; stamp `stamp.txt`.
- **Run result**: OBSERVED — test_arena_ranged_mix shows pistol (blue), SMG (yellow, smaller) and shotgun (red, larger) enemies side by side facing the player; gun props barely visible at that range (production/qa/evidence/story-019-enemy-variety/01-three-ranged-kinds.png)
- **Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- Spawn order follows the wave table (melee, pistol, shotgun, SMG), no shuffle · kept 2026-11-26
- Spawn points sorted by natural node-path order, round-robin per group; counter carries across waves, reset in `start()` · kept 2026-11-26
- Next group starts `spawn_interval` (0.75 s) after the previous group's last member; members `group_spawn_interval` (0.4 s) apart · kept 2026-11-26
- Deterministic jitter: member 0 on the marker, later members on a `spawn_jitter` ring at k x golden angle · kept 2026-11-26
- Gun data is a `RangedGunData` sub-resource on `EnemyData.gun` · kept 2026-11-26
- Shotgun: 7 pellets x 4 dmg in 8 deg, 0.6/s, mag 2, reload 2.8 s, band 3-9 m, preferred 6 m, 50 hp, red, scale 1.1 · kept 2026-11-26
- Pistol: 35 hp, 6 dmg, 1.6/s, mag 6, band 8-15 m, preferred 11 m, blue, no ammo drops · kept 2026-11-26
- SMG: 30 hp, 3 dmg, bursts of 4 at 0.09 s, 1.1 s pause, mag 24, reload 2.4 s, band 9-16 m, preferred 12 m, yellow, scale 0.95 · kept 2026-11-26
- Spot choice: in-band spot whose distance to the player is closest to `preferred_distance` · kept 2026-11-26
- Each pellet that hits = one `take_hit` (one `hit_taken`, arcs from one source merge) · kept 2026-11-26
- Drops: per-kind drop fields in each EnemyData; shotgun/SMG ammo 0.35 (weights 1:3 / 3:1), dose 0.5 for all · kept 2026-11-26
- Sounds: existing pistol/shotgun/smg.wav, positional on SFX bus (shotgun +3 dB pitch 0.85, SMG pitch 1.15), polyphony 2/2/4 · kept 2026-11-26
- Props: enemy_*.fbx at (0.3, 1.05, -0.45), scale 1.4/1.0/1.6 (placeholder placement) · kept 2026-11-26
- Wave mix: pistol from wave 2 (2 +1, max 6), shotgun from 3 (1 +1, max 4), SMG from 5 (1 +1, max 4); boss escort melee 4, pistol 1, shotgun 1 · kept 2026-11-26
