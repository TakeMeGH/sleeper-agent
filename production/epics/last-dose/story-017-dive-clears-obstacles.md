# Story 017: The dive clears obstacles

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 18
*(Unity reference: story 050.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("The dive clears obstacles…"):*

- [ ] A dive aimed at a canteen table from a natural run-up carries the player over it and lands on the far side; the run-up range is found in play and written in Implementation Notes.
- [ ] The same holds for the canteen's fixed benches.
- [ ] A dive that comes down on a table top lands there: the player lies, slides, runs off the edge, falls and lands again, and never gets up in mid-air.
- [ ] Touching the top edge of a table or bench during the leap or the fall lifts the player over it and the dive continues; an obstacle too tall to clear (a wall, a counter) still stops the horizontal movement.
- [ ] The higher leap never passes through a ceiling or wall and never puts the player on a spot meant to be out of reach, in the canteen and in the plaza.
- [ ] The rest of the dive is unchanged: phases, shooting through the dive, the slow-motion hang (story 016), cooldown.
- [ ] Every new or changed number is in the dive's data resource.

---

## Implementation Notes

- Edge-lift: a short upward ray or `test_move` near the player's feet during the leap and fall.
- Run-up range found in play (headless probe p017c, speed factor 1, player centre to near edge, dive across x): table 0.4–2.2 m carries the player onto or over the table (ends on the bench seat behind it, or on the bench divider top at 0.8–1.1 m; 2.3 m+ falls short); bench 0.4–1.5 m and 1.8 m clears it to open floor (1.6–1.7 and 1.9–2.2 m stop on the seat; 2.3 m+ short). To be confirmed in play.
- Table and bench bodies come from story 022 (blockout tables from story 009 work until then).

---

## Out of Scope

- Story 007: the base dive. Story 021: enemies pushing tables.

---

## Files

- `src/player/dive_state.gd`, `src/player/dive_data.gd`
- `assets/data/player/dive.tres`
- `src/run/level_rotation.gd` (debug exports for capture scenes)
- `src/levels/test_canteen_dive_over_table.tscn`, `src/levels/test_canteen_dive_far_side.tscn`, `src/levels/test_canteen_dive_on_table.tscn`
- `production/session-logs/build-notes.md` (Story 017 section)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1..5**: Setup: the canteen, tables and benches. Verify: dive at tables and benches from several distances, onto a table top, at a wall and a counter. Pass condition: clears or lands as described, no passing through walls.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/`: mid-leap above a table, landing on the far side, a landing on a table top + sign-off in `production/qa/evidence/story-017-dive-obstacles-evidence.md`

**Status**: [x] Created — production/qa/evidence/story-017-dive-clears-obstacles-evidence.md (sign-off pending)

---

## Dependencies

- Depends on: `story-007-dive.md`, `story-009-levels-and-rotation.md`, `story-016-slow-motion-player-edge.md` (same folder)
- Unlocks: None
