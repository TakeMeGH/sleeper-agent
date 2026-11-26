# Story 003: Coffee and cigarette, held to consume

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-25

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 7

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Two substances…"):*

- [ ] Coffee raises heart rate and cigarette lowers it, through story 002's `change_rate`.
- [ ] Each has its own input, consumed by **holding** the button: hold Q for coffee, hold E for a cigarette (input actions, not hardcoded keys).
- [ ] The effect is slow at first and gets faster the longer the button is held; releasing resets the ramp.
- [ ] One coffee or cigarette is used up after a few seconds of holding (accumulated hold time, value in data); the count then drops by one.
- [ ] With a count of 0 the input does nothing.
- [ ] Each run starts with a few of each (data); a public `add_substance(kind, amount)` adds more (enemies call it when they drop one, story 008).
- [ ] Holding a substance does not stop the player firing, moving or diving.
- [ ] Signals: `count_changed(kind, count)`, `consume_started(kind)`, `consume_ended(kind)`; the viewmodel (004) and HUD (005) listen to them.
- [ ] Ramp curve, per-unit hold time and starting counts live in a data resource.

---

## Implementation Notes

- The brief gives no numbers for the ramp or the hold time: pick tunable defaults, note them here, and playtest them (the brief calls this the riskiest part).
- Defaults chosen (Unity values, `assets/data/dosing/*.tres`): 3 s of held time per unit; coffee ramp 3 → 10 → 60 bpm/s at 0 / 1 / 3 s held, cigarette -2 → -8 → -30 bpm/s (linear between points, last value held); start 7 coffee / 3 cigarettes, caps 9 / 5. Playtest pending.

---

## Out of Scope

- Story 004: showing the hands and the consume animation. Story 005: counts on the HUD. Story 008: dropping substances.

---

## Files

- `src/dosing/substance_data.gd`, `src/dosing/substance_inventory.gd`
- `assets/data/dosing/coffee.tres`, `cigarette.tres`
- `src/player/player.tscn` (SubstanceInventory node), `project.godot` (dose_coffee Q, dose_cigarette E)
- `src/player/test_range.gd`, `src/player/test_range.tscn` (debug `Hud/SubstanceLabel`, debug hold export), `src/player/test_range_hold_coffee.tscn`, `src/player/test_range_hold_cigarette.tscn` (capture scenes)
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

- Depends on: `production/epics/last-dose/story-002-heart-rate-and-zones.md`
- Unlocks: `story-004`, `story-005`

## Completion Notes
**Completed**: 2026-11-25
**Criteria**: 9/9 covered (AC-1, 3, 4, 5, 6, 8 by probe `production/qa/evidence/story-003-substances/probe.txt`; AC-2 by the `dose_coffee`/`dose_cigarette` entries in `project.godot` plus a live `Input.action_press` run; AC-7 firing (12 SMG shots), moving (5 m) and jumping while holding coffee, by the windowed live part of the probe; AC-9 by reading the data files; counts and hold progress seen in the PNGs) · deferred: dive while holding (no dive until story 007); how the ramp and 3 s per unit feel with real Q/E input (playtest)
**Deviations**: None (no gameplay literals in code). Two debug capture scenes added beyond the listed Files (`test_range_hold_coffee.tscn`, `test_range_hold_cigarette.tscn`)
**Test Evidence**: waived at qa.level minimal; probe kept at `production/qa/evidence/story-003-substances/probe.txt`
**Run result**: OBSERVED — idle "Coffee 7 | Cigarette 3"; after 4 s holding coffee "Coffee 6 (hold 33%)" with HR 204 and the heart-attack countdown; after 2 s holding a cigarette "Cigarette 3 (hold 67%)" with HR 56 (`production/qa/evidence/story-003-substances/01-idle-counts.png`, `02-hold-coffee.png`, `03-hold-cigarette.png`)
**Reviewed by**: self, no independent review (engine check by godot-specialist: no criterion-breaking or runtime bugs; 11 minor notes, not sent back)

## Calls beyond the design
- Unity values as defaults: 3 s per unit, ramps 3/10/60 and -2/-8/-30 bpm/s at 0/1/3 s, start 7/3, max 9/5 (`max_count` caps `add_substance`) · kept 2026-11-25
- Ramp stored as two parallel arrays (linear, last value held), not a Curve · kept 2026-11-25
- Ramp keeps growing across units while held, resets on release; partial unit progress kept on release · kept 2026-11-25
- Both held: first pressed wins, coffee wins a same-frame tie · kept 2026-11-25
- After the run ends, consuming stops and input is ignored · kept 2026-11-25
- `add_substance` returns the amount actually added (0 for unknown kind, amount <= 0 or full) · kept 2026-11-25
- No `count_changed` for the starting counts; listeners (004/005) read `get_count()` at start · kept 2026-11-25
- After running out while held, a drop via `add_substance` resumes consuming without a re-press · kept 2026-11-25
- Debug label `Hud/SubstanceLabel` "Coffee 7 (hold 42%) | Cigarette 3"; debug hold scenes for captures · kept 2026-11-25
