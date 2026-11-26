# Evidence: Story 004 — Two-handed viewmodel and consuming in first person

**Story**: `production/epics/last-dose/story-004-viewmodel-and-consuming.md`
**Captured**: 2026-11-26, Godot 4.7.2, test range scenes, 1152x648 Movie Maker frames
**Screenshots** (`production/qa/evidence/story-004-viewmodel-and-consuming/`):
- `01-gun-only.png` — pistol in the right hand, arm at rest lower left
- `02-coffee.png` — holding Q: cream cup with brown sleeve in the gloved left hand, pistol right
- `03-cigarette.png` — holding E: white cigarette with an orange ember, visibly different from the cup
- `04-reload.png` — pistol dipped and tilted mid-reload
- `05-wall.png` — shotgun 0.4 m from a wall stays fully visible (no clipping)

## Review notes (by the build run, not a sign-off)

| Criterion | Seen | Note |
|---|---|---|
| Gun in the right hand, changes with the selected gun | yes (pistol, shotgun) | The gun renders flat grey with no texture; SMG not captured |
| Left hand holds the substance; consume animation follows the hold | yes (raised poses) | The arm is a rough placeholder: oversized, not aligned to the prop (cup sits at the wrist) |
| Coffee and cigarette look different | yes | |
| Firing and reloading show on the gun | reload yes; recoil not capturable in a still | Recoil needs play |
| Never clips through nearby walls | yes (05-wall) | |
| Gritty, low-poly, desaturated | partly | Untextured placeholder gun; steam and smoke are switched off (rendered as black squares before the fix; untested since) |

Story 011 replaces the placeholder arms with real arm motion.

## Sign-off

- [ ] Approved — art/feel (name, date)
