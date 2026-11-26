# Story 007: Dive

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 9

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Space: dive in the direction you are moving…"):*

- [ ] Space dives in the direction the player is moving: a dash and leap, a fall until landing, a slide, then getting up.
- [ ] The dive can be started on the ground; it cannot be started again until the player has got up.
- [ ] The player can fire the equipped gun during the whole dive.
- [ ] Camera and body motion read as film-style: the view drops and tilts through the dive and settles on getting up.
- [ ] Control returns smoothly after getting up, with no stuck state if the dive ends against a wall or ledge.
- [ ] Dive speed, height, slide length and recovery time live in a data resource.

---

## Implementation Notes

- A state machine on the player controller (`dive_launch → airborne → slide → get_up`), moving with `CharacterBody3D`.
- With no movement input the brief does not say what Space does. Decide (do nothing or dive forward), note it and playtest: **dive forward** (the camera's horizontal facing, player -Z; comment in `DiveState.try_start`). Decided 2026-11-26 in the autonomous run; playtest whether a standing Space-dive feels right.
- Input: Space was `jump` (story 001). The brief has no jump, so `jump` was replaced by `dive` on physical Space and the jump code removed (decided 2026-11-26; the Unity input asset had both on Space).
- Substances and Shift stay usable during the dive.

---

## Out of Scope

- Story 004: viewmodel arm motion beyond keeping the gun visible. Story 006: Shift.

---

## Files

- `src/player/dive_state.gd` (`DiveState`, node `Player/DiveState`), `src/player/dive_data.gd` (`DiveData`)
- `assets/data/player/dive.tres` (Unity values + max_airborne_seconds, stall_speed, stall_frames, hop_frames, camera_smoothing)
- `src/player/player_controller.gd` (state hookup; jump removed), `src/player/player.tscn` (DiveState node)
- `project.godot` (`jump` action replaced by `dive` on physical Space)
- `src/player/test_range.gd` (debug_dive_after_frames / debug_dive_input / debug_fire_during_dive, DIVE phase print)
- `src/player/test_range_dive_launch.tscn`, `test_range_dive_airborne.tscn`, `test_range_dive_slide.tscn` (capture scenes: 18 / 30 / 46 frames)
- `production/session-logs/build-notes.md` (Story 007 section)
- tests: waived at `qa.level` minimal (probe `production/qa/evidence/story-007-dive/probe.txt`)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1/3/4**: Setup: test floor, walk in each direction, dive while firing. Verify: dash, fall, slide, get-up sequence and camera. Pass condition: no stuck states, shots land during the dive, motion reads as a dive.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/` (launch, airborne, slide) + sign-off in `production/qa/evidence/story-007-dive-evidence.md`

**Status**: [x] Screenshots retained in `production/qa/evidence/story-007-dive/` (01-launch, 02-airborne, 03-slide) + probe.txt; sign-off pending in `production/qa/evidence/story-007-dive-evidence.md`

---

## Dependencies

- Depends on: `production/epics/last-dose/story-001-weapons-pass.md`
- Unlocks: None
