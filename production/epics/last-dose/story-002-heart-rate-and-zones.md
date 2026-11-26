# Story 002: Heart rate, five zones, passing out and heart attack

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-25

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP features 5 and 6 (no health; heart rate with five zones). One system, so one story.

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list and Player goal & fail state:*

- [ ] There is no health. Heart rate is the only player vital; a run starts at 80.
- [ ] The rate falls by 3 bpm per second at every rate, continuously.
- [ ] Five zones: under 10, 10–60, 60–100, 100–190, over 190. Each boundary value (10, 60, 100, 190) belongs to exactly one zone; the choice is written in Implementation Notes.
- [ ] Zone 10–60: steadier aim (an aim-spread multiplier below 1) and slow motion becomes available (flag read by story 006).
- [ ] Zone 100–190: faster movement (a speed multiplier above 1), aim tremor, and superspeed becomes available (flag read by story 006).
- [ ] Zone 60–100 applies no modifier.
- [ ] Heart rate under 10 for 5 seconds in a row ends the run as "passed out"; over 190 for 5 seconds in a row ends it as "heart attack". Leaving the zone resets the 5-second countdown.
- [ ] `apply_hit(damage)` lowers the rate by an amount set by the hit's damage (a tunable factor in data). The player's `take_hit` calls it.
- [ ] A public `change_rate(delta)` raises or lowers the rate (used by substances, story 003).
- [ ] The run ends once; further changes after it are ignored. Signals: `heart_rate_changed`, `zone_changed`, `danger_countdown_changed`, `run_ended(reason)`.
- [ ] All numbers (start 80, fall 3/s, thresholds, 5 s, hit factor, modifiers) live in a data resource.

---

## Implementation Notes

- A `HeartRate` node owned by the player, with no direct references to weapons or UI: other systems read its signals and modifier getters.
- Record the boundary-value choice here when decided: lower bound inclusive for 10, 60, 100 (below 10 = passed-out zone; 10 is in 10-60; 60 is in 60-100; 100 is in 100-190); 190 belongs to 100-190 (heart attack is strictly above 190, matching the Unity `heart_attack_above`). Autonomous decision.
- Pass the aim modifier to the gun story's spread/tremor; the speed multiplier to the player controller.

---

## Out of Scope

- Story 003: substances. Story 006: slow motion and superspeed themselves. Story 005: showing any of this. Story 010: the run-end screen.

---

## Files

- `src/heart/heart_rate.gd`, `src/heart/heart_rate_data.gd`
- `assets/data/heart/heart_rate.tres`
- `src/player/player_controller.gd`, `src/player/player.tscn` (HeartRate node, take_hit hook, speed multiplier, aim values to WeaponHolder)
- `src/weapons/weapon_holder.gd`, `src/weapons/gun.gd` (spread multiplier and tremor per shot)
- `src/player/test_range.gd`, `src/player/test_range.tscn` (debug heart-rate label)
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

- Depends on: None
- Unlocks: `story-003`, `story-005`, `story-006`, `story-008`, `story-010`

## Completion Notes
**Completed**: 2026-11-25
**Criteria**: 11/11 covered (all by headless probe `production/qa/evidence/story-002-heart-rate-and-zones/probe.txt`; the rate fall, zone label and pass-out countdown also seen in `01-heart-label.png` / `02-pass-out-countdown.png`; data checked in `assets/data/heart/heart_rate.tres`) · deferred to play: how the steadier aim, aim tremor and 1.3x speed feel with real input
**Deviations**: None (no gameplay literals in code; no files outside scope)
**Test Evidence**: waived at qa.level minimal; probe kept at `production/qa/evidence/story-002-heart-rate-and-zones/probe.txt`
**Run result**: OBSERVED — test range shows "HR 78 | zone 60-100" after 0.75 s, and after 26 s "HR 2 | zone under 10 / passed out in 2.3 s" (`production/qa/evidence/story-002-heart-rate-and-zones/01-heart-label.png`, `02-pass-out-countdown.png`)
**Reviewed by**: self, no independent review (engine check by godot-specialist: 1 criterion-breaking bug (aim values never reached the gun) and 1 countdown-reset edge case found and fixed)

## Calls beyond the design
- Zone boundaries: <10 passed-out zone, [10,60), [60,100), [100,190], >190 heart attack (matches Unity `heart_attack_above`) · kept 2026-11-25
- Rate clamped to 0–250 (Unity min/max); bpm lost per damage 1.0 · kept 2026-11-25
- 10–60 spread multiplier 0.5; 100–190 speed multiplier 1.3; tremor 0.15–1.0° amplitude, 2–8 Hz, rising across 100–190, pitch phase ratio 1.3; pistol (0 spread) unaffected by the spread multiplier · kept 2026-11-25
- Unity's slow-zone speed 0.6, recoil scale and 0.5 s effect blend not ported (not in the story) · kept 2026-11-25
- After the run ends the rate freezes and changes are ignored; movement and shooting still work until story 010 · kept 2026-11-25
- `danger_countdown_changed` fires every physics frame while counting, and once with (0, "") on reset; countdowns use scaled physics time (story 006 to decide under slow motion) · kept 2026-11-25
- Hit pushback in `take_hit` ignored for the player for now · kept 2026-11-25
- Debug label `Hud/HeartLabel` top-left in the test range: "HR 80 | zone 60-100", second line "passed out in 3.2 s" / "RUN ENDED: …" · kept 2026-11-25
