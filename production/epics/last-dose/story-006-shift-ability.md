# Story 006: Shift: slow motion and superspeed

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 8

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Shift: slow motion (10–60) or superspeed (100–190)…"):*

- [ ] Pressing Shift with heart rate in 10–60 starts slow motion: the world slows for a few seconds.
- [ ] Pressing Shift with heart rate in 100–190 starts superspeed: the player moves much faster for a few seconds.
- [ ] In any other zone Shift does nothing.
- [ ] The effect ends after its duration, then a cooldown runs; Shift cannot start another effect during the effect or the cooldown.
- [ ] Duration, cooldown, time scale and speed multiplier live in a data resource.
- [ ] Signals: `ability_started(kind)`, `ability_ended(kind)`, `cooldown_changed`.
- [ ] Time scale returns exactly to 1.0 when slow motion ends, when the run ends, and on restart.

---

## Implementation Notes

- Slow motion via `Engine.time_scale`. Whether the player moves at normal speed during slow motion (Max Payne style) is not stated in the brief: decide, note it here and playtest. Decision: **the player slows with the world** (plain `Engine.time_scale`, no compensation); story 016 later gives the player its own time scale. Playtest.
- If the heart rate leaves the zone mid-effect (the rate keeps falling), the brief does not say whether the effect stops. Decide and note: **the effect keeps running to its full duration** (Unity `end_when_leaving_zone = 0`). It ends early only when the run ends.
- Story 002's open question, the 5 s danger countdown under slow motion: **it counts real (unscaled) seconds**, so slow motion cannot stretch the 5 s grace. `HeartRate._tick_countdown` adds `delta / Engine.time_scale`; the rate fall itself stays on scaled time (it falls slower in slow motion). Effect durations and the cooldown are real seconds too.
- Check `Engine.time_scale` behaviour against `docs/engine-reference/godot/` before relying on it for physics and timers.

---

## Out of Scope

- Story 002: the zones and the availability flags. Story 005: a cooldown display.

---

## Files

- `src/player/shift_ability.gd`, `src/player/shift_ability_data.gd` (new: `ShiftAbility`, `ShiftAbilityData`)
- `assets/data/player/shift_ability.tres` (new; Unity values 0.3 / 7 s / 1.8x / 8 s / cooldown 8 s)
- `src/player/player.tscn` (`Player/ShiftAbility` node), `src/player/player_controller.gd` (superspeed speed multiplier)
- `src/heart/heart_rate.gd` (danger countdown counts real seconds under slow motion)
- `project.godot` (input action `shift_ability` = physical Shift)
- `src/ui/hud/hud.gd`, `src/ui/hud/hud_data.gd`, `assets/data/ui/hud.tres` (small SLOW / SPEED / COOLDOWN / SHIFT READY label in the heart box)
- `src/player/test_range.gd`, `src/player/test_range.tscn` (`debug_shift_after_frames`, HUD wiring), `src/player/test_range_shift_slow.tscn` (new capture scene)
- tests: waived at `qa.level` minimal

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: waived at `qa.level` minimal (advisory)

**Status**: [x] Waived (probe kept at `production/qa/evidence/story-006-shift-ability/probe.txt`; HUD label screenshot `01-slow-motion.png`)

---

## Dependencies

- Depends on: `production/epics/last-dose/story-002-heart-rate-and-zones.md`
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-26
**Criteria**: 7/7 covered (probe `production/qa/evidence/story-006-shift-ability/probe.txt`: 40 bpm -> slow motion, time_scale 0.3; 150 bpm -> superspeed, speed multiplier 1.8 (on top of the 1.3 zone multiplier); 5/80/200 bpm -> nothing; re-press refused during effect and cooldown, accepted when the cooldown is over; effect ends after 7 s / 8 s real time, then an 8 s cooldown; signals `ability_started`/`ability_ended`/`cooldown_changed` seen in order; `Engine.time_scale == 1.0` exactly after effect end, run end (pass-out during slow motion) and node exit/new scene `_ready` (restart); data checked in `assets/data/player/shift_ability.tres`; HUD "SLOW 5.6" in `01-slow-motion.png`) · deferred to play: how slow motion and superspeed feel with real Shift input and movement (player slowed with the world)
**Deviations**: `src/heart/heart_rate.gd` (story 002, Complete) changed: danger countdown counts real seconds, as this story was asked to decide. HUD label added in `src/ui/hud/` (story 005 files), small and data-driven. No gameplay literals in code.
**Test Evidence**: waived at qa.level minimal; probe and screenshot kept in `production/qa/evidence/story-006-shift-ability/`
**Run result**: OBSERVED — test_range_shift_slow (40 bpm, Shift fired on frame 10) shows the HUD heart box at 38 BPM SLOW with "SLOW 5.6" counting down in real seconds (`production/qa/evidence/story-006-shift-ability/01-slow-motion.png`)
**Reviewed by**: self, no independent review (engine check by godot-specialist: no API or criterion issues; minor notes left open: no null-check on `data`, HUD empty-format fallback, superspeed stacks with the 1.3 zone multiplier, ECG strip scrolls on scaled time, colour override set every frame)

## Calls beyond the design
- Player slows with the world in slow motion (no compensation; story 016 owns the player's own time scale) · kept 2026-11-26
- Effect keeps running when the heart rate leaves the zone (Unity `end_when_leaving_zone` 0) · kept 2026-11-26
- Danger countdown (story 002) counts real seconds under slow motion; the rate fall stays on scaled time · kept 2026-11-26
- Effect durations and cooldown count real seconds (`delta / Engine.time_scale` in `_process`; public `tick(real_delta)`) · kept 2026-11-26
- Unity values: time scale 0.3, slow 7 s, superspeed 1.8x for 8 s, cooldown 8 s; Unity `player_time_scale` 0.7 not used (story 016) · kept 2026-11-26
- Superspeed multiplies on top of the fast-zone 1.3x (effective 2.34x) · kept 2026-11-26
- Run end ends the effect at once, emits `ability_ended`, starts no cooldown, and Shift is refused after the run ended · kept 2026-11-26
- `cooldown_changed(seconds_left)` fires at cooldown start, every tick, and with 0.0 when ready · kept 2026-11-26
- `Engine.time_scale` set to 1.0 in `_ready`, `_exit_tree`, effect end and run end (covers restart) · kept 2026-11-26
- Input action `shift_ability` on physical Shift (left and right) · kept 2026-11-26
- HUD label under the heart trace: "SLOW x.x" / "SPEED x.x" (highlight colour), "COOLDOWN x.x" (dim), "SHIFT READY"; strings in HudData · kept 2026-11-26
- Capture scene `src/player/test_range_shift_slow.tscn` (40 bpm, Shift on physics frame 10) · kept 2026-11-26
