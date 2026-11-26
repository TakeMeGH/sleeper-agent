# Story 005: Status-bar HUD

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 11

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("HUD: an old-school status bar…"):*

- [ ] An old-school status bar runs along the bottom with five boxes; the 3D view sits above the bar, never behind it.
- [ ] Box 1: coffee and cigarette counts, updated on `count_changed`.
- [ ] Box 2: heart rate number, its zone, a pulse trace, and the danger countdown (shown only while under 10 or over 190), updated from story 002's signals.
- [ ] Box 3: a face that gets more battered as heart rate nears either danger limit (10 or 190).
- [ ] Box 4: enemies left in the wave, the wave number and time survived. Until story 008 exists it shows placeholder values from a run-state stub.
- [ ] Box 5: the current gun and its ammo (magazine and spare, or endless for the pistol), updated on `ammo_changed`.
- [ ] The HUD only reads state through signals and getters; it changes no game state.
- [ ] Layout is correct at 1280x720 and holds at other 16:9 resolutions.

---

## Implementation Notes

- `CanvasLayer` + `Control` nodes; the 3D view in a `SubViewportContainer` (or a viewport rect) above the bar. Verify Control/anchor APIs against `docs/engine-reference/godot/modules/ui.md`.
- Pixel-style bar art can be placeholder; keep colours desaturated per the brief.
- Run-state stub: a small autoload or node exposing `wave`, `enemies_left`, `time_survived`; story 008 and 010 take it over.

---

## Out of Scope

- Story 010: the run-end screen. Story 008: real wave data.

---

## Files

- `src/ui/hud/hud.gd`, `src/ui/hud/hud.tscn`, `src/ui/hud/glyph_row.gd` (glyph text helper), `src/ui/hud/hud_data.gd`
- `assets/data/ui/hud.tres` (HUD data, Unity hud.json defaults, box width ratios, bar height)
- `src/run/run_state.gd` (stub node: wave, enemies_left, time_survived)
- `assets/art/ui/hud/` (HUD kit, already imported; used as is)
- `src/player/test_range.gd`, `src/player/test_range.tscn` (StatusBar + RunState added; HeartLabel/SubstanceLabel/AmmoLabel removed; crosshair anchored to the world rect; `debug_heart_rate` export)
- `src/player/test_range_hr_calm.tscn`, `test_range_hr_near_10.tscn`, `test_range_hr_below_10.tscn`, `test_range_hr_above_190.tscn` (capture scenes)
- `project.godot` (window viewport 1280x720)
- tests: waived at `qa.level` minimal

## QA Test Cases

**UI verification steps:**

- **AC-1..5**: Setup: start a run, use substances, fire, let heart rate drift to both danger limits. Verify: each box updates and the face worsens. Pass condition: all five boxes correct, view above the bar.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: retained screenshots of the HUD in `production/qa/evidence/` (calm, near 10, near 190 with countdown) 

**Status**: [x] Retained screenshots in `production/qa/evidence/story-005-status-bar-hud/`

---

## Dependencies

- Depends on: `story-001-weapons-pass.md`, `story-002-heart-rate-and-zones.md`, `story-003-substances.md` (same folder)
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-26
**Criteria**: 8/8 covered (AC-1 bar below the world view in every PNG, arm and gun clip at the bar edge; AC-2 counts 7/3 read from getters at start and coffee 7->6 on `count_changed` in `07-hold-coffee.png`, cigarette 3->4 in probe; AC-3 rate/zone/trace/countdown in `01`-`04` (countdown hidden at 77 and 11 bpm, shown at 8 bpm "PASS OUT 4.3 SEC" and 197 bpm "HEART ATTACK 4.0 SEC"); AC-4 face clean at 77, bruised at 11, bloody at 8/197; AC-5 stub values ENEMIES 8, WAVE 1, TIME ticking; AC-6 PISTOL 12/∞, SMG 30/90 -> 30/100 on `ammo_changed` in probe; AC-7 probe: rate, counts, magazine unchanged after a HUD refresh, and the HUD only connects to signals and calls getters; AC-8 correct at 1280x720, same layout from a 960x540 window in `06-540p.png`) · deferred: sharpness at 1920x1080 and above (the 1080p window did not fit this display, `05-1080p.png` is cropped; the world SubViewport renders at the 1280x576 canvas size under canvas_items stretch and may look soft); live play with real input
**Deviations**: `project.godot` window viewport set to 1280x720 (outside the listed files; needed for 1:1 canvas at 720p). Extra files beyond the list: `glyph_row.gd`, `hud_data.gd`, `hud.tres`, four capture scenes. UI label font size 14 and bar colours/labels are in code or data as noted below; English strings are not localized
**Test Evidence**: UI screenshots `production/qa/evidence/story-005-status-bar-hud/01-calm.png`, `02-near-10.png`, `03-below-10.png`, `04-above-190.png`, `06-540p.png`, `07-hold-coffee.png`; probe `probe.txt`; stamp `stamp.txt`
**Run result**: OBSERVED — five-box status bar under the 3D view; calm 77 BPM NORMAL green trace clean face; 11 BPM SLOW bruised face no countdown; 8 BPM PASS OUT 4.3 SEC; 197 BPM HEART ATTACK 4.0 SEC bloody face; coffee 6 while holding; PISTOL 12/∞ (`production/qa/evidence/story-005-status-bar-hud/01-calm.png`, `02-near-10.png`, `03-below-10.png`, `04-above-190.png`)
**Reviewed by**: self, no independent review (engine check by godot-specialist: no wrong API; 2 latent runtime bugs (disable_3d never restored, freed-node access in _process) and the 9-patch dark-centre artefact fixed in one round)

## Calls beyond the design
- 3D view moved into a SubViewportContainer (root `disable_3d`), world and viewmodel overlays both anchored to the rect above the bar; restored on `_exit_tree` · kept 2026-11-26
- Bar height 20% of screen; box width ratios 1.0/2.2/0.9/1.5/1.6 (`hud.tres`) · kept 2026-11-26
- Unity hud.json values as defaults: zone names, colours, face steps 0.25/0.5/0.75 from resting rate toward 10/190, 2 bpm hysteresis when improving · kept 2026-11-26
- Box tint and dim text brighter than Unity so the bar reads · kept 2026-11-26
- Countdown row hidden by alpha; shows zone name, seconds to 0.1, "SEC"; reason inferred from zone at start (no getter) · kept 2026-11-26
- Time as m:ss; gun box = icon + upper-case name + mag/spare, ∞ for pistol; substance box = icon + count only · kept 2026-11-26
- Run state is a plain node in test_range (not an autoload), wave 1, enemies 8, time counts up; HUD polls it · kept 2026-11-26
- No flinch face (no hit signal yet); `flinch_seconds` kept in data unused · kept 2026-11-26
- Crosshair anchored to the centre of the world rect from `bar_height_ratio` · kept 2026-11-26
- test_range debug labels (heart, substance, ammo) removed; `debug_heart_rate` export and four capture scenes added · kept 2026-11-26
