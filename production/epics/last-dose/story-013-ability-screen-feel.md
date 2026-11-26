# Story 013: Ability screen feel: slow-motion and superspeed look

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 14
*(Unity reference: story 036.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Ability screen feel…"):*

- [ ] While slow motion is active the screen shows a strong GTA-style grade: clearly desaturated and cool, with a vignette.
- [ ] While superspeed is active the screen shows a warm, high-contrast grade, a wider field of view (about +12° in Unity) and a touch of chromatic aberration.
- [ ] Each look eases in when the ability starts and eases out when it ends; the run ending or the ability ending early restores the normal look with no snap.
- [ ] During slow motion the audio is muffled (low-pass) and its pitch drops; during superspeed it is slightly brighter or higher; both ease in and out and return to normal.
- [ ] The look is its own layer and stacks with story 014's heart-rate vignette and field of view without fighting it; the result is stable with both on, and the order of the layers is written in Implementation Notes.
- [ ] Every value (saturation, tint, contrast, vignette, field-of-view delta, filter cutoff, pitch, ease times) is in data.

---

## Implementation Notes

- A `WorldEnvironment` adjustment or a full-screen post-process shader (`CanvasLayer` + `ColorRect`); Godot 4.7 has a Compositor: check `docs/engine-reference/godot/modules/rendering.md` before choosing.
- Audio via `AudioEffectLowPassFilter` and pitch shift on the buses from story 012.
- Order of layers chosen (CanvasLayer.layer, explicit numbers, not tree order): world SubViewportContainer -1 → viewmodel overlay 0 → ability look 1 (`AbilityLookData.layer`) → story 014 heart-rate vignette 2 (reserved: `AbilityLookData.heart_vignette_layer`; use its own CanvasLayer, not a second screen-reading rect on layer 1 without a BackBufferCopy) → HUD bar + crosshair 3 (`hud.tscn` BarLayer, `Hud` CanvasLayer in test_range/test_arena/game) → run-end screen 30. The look grades world + viewmodel; the heart vignette will sit on top of the grade; the HUD is never graded. FOV: additive offsets on the player Camera3D, GunFeel (priority 50) and AbilityLook (55) each add/remove only their own part; story 014 should do the same; Hud/viewmodel mirror cameras (100) copy the sum.
- Approach: canvas_item screen-texture shader on a ColorRect (one pass over world + viewmodel), not a Compositor effect (the Compositor would grade only the world SubViewport camera, not the viewmodel overlay).

---

## Out of Scope

- Story 014: the heart-rate vignette and field of view. Story 016: slow-motion player timing.

---

## Files

- `src/ui/screen_effects/ability_look.gd` (AbilityLook), `ability_look_data.gd` (AbilityLookData), `ability_look_profile.gd` (AbilityLookProfile), `ability_look.gdshader`
- `assets/data/player/ability_look.tres`
- Wiring: `src/player/test_range.tscn`, `src/waves/test_arena.tscn`, `src/run/game.tscn` (AbilityLook node; Hud CanvasLayer layer 1 -> 3), `src/ui/hud/hud.tscn` (BarLayer 1 -> 3)
- Capture scenes: `src/player/test_range_look_normal.tscn`, `test_range_look_slow.tscn`, `test_range_look_speed.tscn`
- `production/session-logs/build-notes.md` (Story 013 section)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1..5**: Setup: start a run, reach 10–60 and 100–190, press Shift. Verify: look and audio ease in and out, survive a run end mid-effect. Pass condition: no snap, no stuck look.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/` from the same spot: normal, slow motion, superspeed + sign-off in `production/qa/evidence/story-013-ability-look-evidence.md`

**Status**: [x] Screenshots + probe in `production/qa/evidence/story-013-ability-screen-feel/`; doc `production/qa/evidence/story-013-ability-screen-feel-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `story-006-shift-ability.md`, `story-012-audio.md` (same folder)
- Unlocks: None
