# Story 004: Two-handed viewmodel and consuming in first person

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-25

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 2

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("The gun is held in the right hand and the substance in the left…"):*

- [ ] The gun is held in the right hand, visible in first person, and changes with the selected gun (placeholder low-poly models are fine).
- [ ] The left hand holds the substance in use; holding coffee or cigarette plays a visible consume animation that follows the hold (starts on `consume_started`, ends on `consume_ended`).
- [ ] Coffee and cigarette look different from each other.
- [ ] Firing and reloading show on the gun (recoil, reload motion).
- [ ] The viewmodel never clips through nearby walls badly enough to hide the gun.
- [ ] Style matches the brief's art direction: gritty low-poly, desaturated.

---

## Implementation Notes

- Render the viewmodel so it does not clip into geometry (separate `SubViewport` or a depth-handling material); check `docs/engine-reference/godot/modules/rendering.md` first.
- Drive animation from the signals of stories 001 and 003; the viewmodel never changes ammo or heart rate itself.

---

## Out of Scope

- Story 001: gun logic. Story 003: substance logic. Story 007: dive camera motion.

---

## Files

- `src/viewmodel/viewmodel.gd`, `viewmodel.tscn`, `viewmodel_data.gd`, `viewmodel_gun_data.gd`, `viewmodel_substance_data.gd`
- `assets/data/viewmodel/viewmodel.tres`
- `src/player/player.tscn` (Viewmodel under Head/Camera3D; placeholder gun removed), `src/player/test_range.gd` (debug exports)
- `src/player/test_range_reload.tscn`, `src/player/test_range_wall.tscn` (capture scenes)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1/2**: Setup: start a run, switch each gun, hold each substance. Verify: right-hand gun and left-hand substance read clearly. Pass condition: both visible, consume animation runs for the whole hold.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/` (gun only, consuming coffee, consuming cigarette, mid-reload) + sign-off in `production/qa/evidence/story-004-viewmodel-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `story-001-weapons-pass.md`, `story-003-substances.md` (same folder)
- Unlocks: None
