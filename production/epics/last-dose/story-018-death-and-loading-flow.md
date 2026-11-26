# Story 018: Death and loading flow: collapse, fades, tip

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 22
*(Unity reference: stories 047, 048, 049.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Death and loading flow…"):*

- [ ] When the run ends, the view collapses: first the knees buckle (the camera drops), then it tips over and falls to the floor, rolling a little and settling.
- [ ] The falling camera never passes through walls, floor or props; against a wall it falls away from it. It falls away from the last hit if one landed shortly before; otherwise toward a side set in data. The same death falls the same way every time.
- [ ] The arms drop out of view; the gun falls out of the hands as a physics object, lands near the player and stays; the substance goes with the arms. The crosshair hides at once; the status bar stays frozen as at run end.
- [ ] The collapse runs in unscaled time, so a hitstop or an ending slow motion never stretches it. At a camera-motion scale of 0 the view only lowers smoothly, with no roll, tilt or bounce.
- [ ] After the collapse the world holds for a set time, then the screen fades to black, and one tip fades in at the centre (from a list in data; the same tip never shows twice in a row; Enter or a click skips it), then the results (story 010) appear on the black. An empty list or a tip time of 0 shows no tip.
- [ ] A single fade layer covers the screen: above the game view, HUD, crosshair and arcs, below the tip and the results. Gameplay code can ask it to fade to black or clear over a time and can tell when it finishes.
- [ ] A level starts black and fades in once it is ready (never half-loaded); if loading fails it fades in anyway after the error.
- [ ] Restart fades fully to black before the scene reloads, then the level-start fade applies. Story 009's level change uses the same fade.
- [ ] All fades run in unscaled time; every duration, tip and number is in data.

---

## Implementation Notes

- The collapse is camera-only: no ragdoll for the player. A `RigidBody3D` for the dropped gun; check `docs/engine-reference/godot/modules/physics.md` for Jolt body settings.
- The restart input guard from story 010 still starts when the results appear.

---

## Out of Scope

- Story 010: the results content. Story 015: the in-run countdown.

---

## Files

- New: `src/player/death_collapse.gd`, `src/ui/screen_fade.gd`, `src/ui/screen_fade.tscn`, `src/ui/death_tip.gd`, `src/run/run_flow.gd`, `src/run/death_flow_data.gd`, `src/ui/tip_list_data.gd`
- Data: `assets/data/run/death_flow.tres`, `assets/data/run/tips.tres`
- Modified: `src/run/level_rotation.gd` (the story named `src/levels/`; the file lives in `src/run/`) (uses the shared fade; level starts black, fades in when ready or after a load error; travel bails once the run is over), `src/run/game.tscn` (ScreenFade, DeathTip, DeathCollapse, RunFlow nodes), `src/ui/run_end/run_end_screen.gd` (screen_fade, show_on_run_end, restart fades to black, same-frame restart guard), `src/player/player_controller.gd` (input lock), `src/viewmodel/viewmodel.gd` (death drop, gun model access, hide gun)
- Capture scenes: `src/run/game_death_buckle.tscn`, `game_death_fall.tscn`, `game_death_rest.tscn`, `game_death_tip.tscn`, `game_loading_black.tscn`; `game_end_passed_out.tscn`, `game_end_heart_attack.tscn` (RunFlow log on)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1..8**: Setup: die by passing out and by heart attack, once against a wall; start a run; restart; change level. Verify: collapse, gun on the floor, fade, tip, results; no half-loaded level. Pass condition: smooth sequence, no clipping, no flash of an unloaded level.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/`: mid-buckle, mid-fall, at rest, the tip on black, the black screen during a load + sign-off in `production/qa/evidence/story-018-death-and-loading-flow-evidence.md`

**Status**: [x] Created — `production/qa/evidence/story-018-death-and-loading-flow-evidence.md` (5 screenshots + probe; sign-off pending)

Run result: OBSERVED — buckle (level view, arms gone), mid-fall (rolled view, gun in the air), at rest (view on its side, pistol on the floor), tip centred on black over the HUD, solid black during a held load (`production/qa/evidence/story-018-death-and-loading-flow/01..05.png`)

---

## Dependencies

- Depends on: `story-004-viewmodel-and-consuming.md`, `story-009-levels-and-rotation.md`, `story-010-run-end-and-restart.md`, `story-011-shooting-feel.md` (same folder)
- Unlocks: None
