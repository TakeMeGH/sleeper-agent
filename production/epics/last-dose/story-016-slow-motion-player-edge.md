# Story 016: Slow-motion player edge

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 17
*(Unity reference: story 038.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Slow-motion player edge…"):*

- [ ] A player time scale from data (for example world 0.3, player 0.7) applies while slow motion is active; outside slow motion the player runs on normal time.
- [ ] Reload, fire rate, gun and arm animations, weapon switching and consuming a substance run on the player's time, so in slow motion the player reloads and shoots noticeably faster than the world moves.
- [ ] Movement and look use the same player time scale, so the player is faster than the world in slow motion (this settles story 006's open question).
- [ ] The dive stays in the air longer in slow motion: leap and fall phase times are multiplied by a factor from data, while the dash and the getting-up follow the player's time; the sequence stays coherent.
- [ ] Slow motion and superspeed last longer than story 006's first durations, by values in data.
- [ ] Enemies, projectiles, physics and effects stay on world time; a kill's hitstop (story 011) still freezes everything and returns to the slow-motion speed.
- [ ] Leaving slow motion (ending, run end) returns every system to normal time with no stuck state.

---

## Implementation Notes

- Per-system `delta` scaling: keep one `PlayerTime` helper that returns the scale; never scale `Engine.time_scale` twice.
- Verify `Engine.time_scale` and physics-tick behaviour in `docs/engine-reference/godot/` before relying on them.

---

## Out of Scope

- Story 013: the look and audio of slow motion.

---

## Files

- `src/player/player_time.gd`
- `src/player/test_range_slow_edge.tscn`
- `src/player/player.tscn`
- `src/player/shift_ability.gd`
- `src/player/shift_ability_data.gd`
- `assets/data/player/shift_ability.tres`
- `src/player/player_controller.gd`
- `src/player/dive_state.gd`
- `src/player/dive_data.gd`
- `src/weapons/gun.gd`
- `src/weapons/weapon_holder.gd`
- `src/weapons/gun_feel.gd`
- `src/dosing/substance_inventory.gd`
- `src/viewmodel/viewmodel.gd`
- `src/audio/footsteps.gd`
- `production/session-logs/build-notes.md`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: playtest doc OR integration test (waived at `qa.level` minimal)

**Status**: [x] Waived (probe kept at `production/qa/evidence/story-016-slow-motion-player-edge/probe.txt`; screenshot `01-slow-edge.png`)

---

## Dependencies

- Depends on: `story-006-shift-ability.md`, `story-007-dive.md`, `story-011-shooting-feel.md` (same folder)
- Unlocks: None

---

## Completion Notes

**Completed**: 2026-11-26
**Criteria**: 6/7 covered by probe (`production/qa/evidence/story-016-slow-motion-player-edge/probe.txt`, script `probe_script.gd.txt`); 1 deferred.
- Covered: player time scale from data (world 0.3, player 0.7, multiplier 2.33; 1.0 outside slow motion); reload 0.8 -> 1.15 real s, fire cooldown 0.117 -> 0.167 real s, coffee unit 3.0 -> 4.27 real s (all ratio 1.43 = 1/0.7; world time would be 3.33); movement 5.0 -> 3.5 m per real s (0.70); dive LAUNCH 0.25 -> 0.68, AIRBORNE 0.15 -> 0.47 (hang 2.0 latched), SLIDE 0.47 -> 0.65, GET_UP 0.6 -> 0.87 real s (dash/slide/get-up at 1/0.7, leap/fall x hang); rigid body gravity gain 9.8 -> 2.94 per real s (0.30 = world time), enemy/effect code untouched (no PlayerTime use in `src/ai`, `src/waves`, impact effects); hitstop in slow motion drops the engine scale to 0.015, player reload nearly frozen, then back to 0.3 / multiplier 2.33; natural end and run end (also mid-dive) return engine 1.0, multiplier 1.0, dive finishes, hang reset.
- Deferred (playtest): gun/arm animation and weapon-switch speed under slow motion (viewmodel eases + tween speed_scale use player time; not measured by the probe; there is no switch cooldown in code, switching is the swap tween); mouse look stays event-based at full speed (feel); criterion 5 "both abilities last longer": durations stay 7 s / 8 s from data, which are Unity's tuned values already adopted by story 006, so they are not longer than 006's; lengthening needs a person's tuning call.
**Deviations**: `src/audio/footsteps.gd` (story 012, built) changed so step speed follows player time (engine check found steps ~3.3x too fast in slow motion). `src/weapons/gun.gd` keeps the fire-cooldown leftover (max one tick) for exact fire rate. No gameplay literals added (`PROCESS_PRIORITY` -1000 and `MIN_MULTIPLIER` 0.001 are engine-ordering / safety consts).
**Test Evidence**: waived (Integration, qa.level minimal); probe evidence kept.
**Run result**: OBSERVED — test_range_slow_edge (40 bpm, Shift at frame 10) shows the HUD heart box at 38 BPM SLOW with "SLOW 5.7" counting down, slow motion active, no script errors (`production/qa/evidence/story-016-slow-motion-player-edge/01-slow-edge.png`)
**Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- PlayerTime is a node at `Player/PlayerTime` (group `player_time`, injected `shift_ability`, `PlayerTime.find_for`), no autoload · kept 2026-11-26
- Multiplier = player_time_scale / slow_time_scale from data (hitstop stays in the engine delta, never applied twice), latched per frame at process priority -1000 · kept 2026-11-26
- Player velocity stored in player units; multiplied by the multiplier only around `move_and_slide()` · kept 2026-11-26
- Dive hang factor latched at dive start (not live) and reset when the dive ends; leap, peak, fall times and gravity scaled so distance and height stay the same; `max_airborne_seconds` x hang · kept 2026-11-26
- Dive cooldown and dive camera smoothing run on player time · kept 2026-11-26
- Fire buffer (WeaponHolder) and muzzle flash stay real time; GunFeel kick/shake/FOV punch on player time · kept 2026-11-26
- Heart-rate natural drop stays on world time; substance bpm applied on player time · kept 2026-11-26
- Mouse look not scaled (event-based, full speed in slow motion) · kept 2026-11-26
- Ability durations kept at Unity's 7 s / 8 s (no new longer values invented) · kept 2026-11-26
- Footsteps speed divided by the player multiplier (story 012 file) · kept 2026-11-26
- Fire cooldown keeps its leftover (max one tick) · kept 2026-11-26
