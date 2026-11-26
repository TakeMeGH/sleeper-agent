# Story 014: Heart-rate vignette and field of view

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 15
*(Unity reference: stories 037, 039 and the vignette pulse in 046.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Heart-rate vignette and field of view…"):*

- [ ] A heart rate above the normal band shows a white vignette that grows with the rate; below it a black vignette that grows as the rate falls; in the normal band (60–100, an assumption: Unity used a "resting" rate) there is none. Curve and colours come from data.
- [ ] A high rate widens the camera's field of view, up to +20° at 190 bpm; a low rate narrows it (−8° at 10 in Unity). The change is continuous with the rate, not a switch at zone edges.
- [ ] Vignette and field of view follow the rate smoothly (a response time from data), with no pop when a coffee, a cigarette or a hit moves the rate.
- [ ] The vignette pulses near the danger limits: within a band above 10 and below 190 its intensity rises and falls, deeper toward the limit, and harder while the 5-second countdown runs. No pulse rate in data may exceed 3 per second (photosensitivity); a larger value fails when the data loads.
- [ ] The effects stack with the gun's field-of-view punch, the dive's camera offsets and story 013's ability look without fighting them (the larger vignette shows, or they blend: data says which).
- [ ] A camera-motion scale in data (0 to 1) scales the field-of-view change; at 0 the field of view does not change.
- [ ] The effects stop when the run ends, and use unscaled time so slow motion does not stretch them.
- [ ] The gun and arms do not clip the near plane at the widest combined field of view.

---

## Implementation Notes

- Vignette as a full-screen shader on a `CanvasLayer` (or a Compositor effect: check `docs/engine-reference/godot/modules/rendering.md`); FOV via `Camera3D.fov`.
- Decide and note: game time or unscaled time for the smoothing: **unscaled (real) time** via `RealClock` for easing and pulse (decided 2026-11-26, story 014 dev-story).

---

## Out of Scope

- Story 013: ability looks. Story 015: hit arcs and the countdown number.

---

## Files

- `src/ui/screen_effects/heart_rate_screen.gd` (new, `HeartRateScreen`)
- `src/ui/screen_effects/heart_rate_screen_data.gd` (new, `HeartRateScreenData`)
- `src/ui/screen_effects/heart_rate_vignette.gdshader` (new)
- `assets/data/heart/heart_rate_screen.tres` (new)
- `src/player/test_range.tscn`, `src/waves/test_arena.tscn`, `src/run/game.tscn` (HeartRateScreen node wired)
- `src/player/test_range.gd` (`debug_hold_heart_rate`)
- `src/player/test_range_hr_screen_{low,normal,high,high_speed}.tscn` (new capture scenes)
- `src/ui/hud/hud.gd`, `src/viewmodel/viewmodel.gd` (`sync_camera()` + group `camera_mirrors`, so the visible cameras drop the FOV offset at run end while paused)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1..5**: Setup: use coffee and cigarettes to move through the whole range. Verify: vignette colours, FOV change, pulse near both limits, no pop on a hit. Pass condition: smooth, readable, no pulse above 3 per second.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/` from the same spot at low, normal, high (190) and high with superspeed + sign-off in `production/qa/evidence/story-014-heart-rate-screen-evidence.md`

**Status**: [x] Created — `production/qa/evidence/story-014-heart-rate-screen-evidence.md` (screenshots + probe), sign-off pending

---

## Dependencies

- Depends on: `production/epics/last-dose/story-002-heart-rate-and-zones.md`
- Unlocks: None
