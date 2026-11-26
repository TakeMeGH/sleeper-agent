# Story 023: Tutorial in the gameplay

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 23
*(Unity reference: stories 055 and 056, and `Assets/_Game/Gameplay/Tutorial/`.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Tutorial in the gameplay…"):*

- [ ] A hint is one short line centred above the status bar, with an amber box pulsing around the HUD part it explains (danger hints use a red box); it never covers the danger countdown; only one hint shows at a time.
- [ ] Keys in a hint's text come from the input actions (hold Q, hold E), so rebinding changes the text.
- [ ] An action hint ends when the player does it; an information hint ends after its time; every hint shows for a minimum time. The game never pauses and never waits for a click.
- [ ] Before wave 1, the opening shows in order: move and look; "your heart rate keeps falling" (heart panel boxed); hold Q for coffee; hold E for a cigarette; then wave 1 starts with "left mouse to shoot" (gun panel boxed).
- [ ] No enemy spawns until the opening's first four steps are done or a time cap from data runs out.
- [ ] Until wave 1 starts, the heart rate is held between two limits from data (draft 40 and 160), so the player cannot pass out or have a heart attack while learning.
- [ ] Moment hints show the first time each moment happens, each boxed: entering the slow zone, entering the fast zone, nearing danger (a danger hint), the first hit, an empty gun, a pickup, the dive. A danger hint goes ahead of others and replaces an information hint; a waiting hint whose moment has passed is dropped and waits for the next time.
- [ ] Holding Tab for a set time skips the tutorial for the rest of the launch; a short "hold Tab to skip" line shows whenever a hint is up.
- [ ] Hints already shown stay shown across restarts in the same launch; nothing is written to disk, so the next launch teaches again.
- [ ] Every text, timing, limit and key name is in data.

---

## Implementation Notes

- A `TutorialHost` autoload listening to signals from stories 002, 003, 005, 007 and 008 (never reaching into them).
- Heart-rate limits through the heart-rate node's public clamp, set by the tutorial and cleared when wave 1 starts.

---

## Out of Scope

- A settings menu or a separate tutorial level.

---

## Files

- `src/tutorial/tutorial_host.gd` (autoload TutorialHost), `src/tutorial/hint_box.gd`, `src/tutorial/tutorial_data.gd`, `src/tutorial/tutorial_hint.gd`, `src/tutorial/tutorial_goal.gd`
- `assets/data/tutorial/tutorial.tres`
- `src/ui/hud/hud.gd` (get_tutorial_target_rect), `src/heart/heart_rate.gd` (set/clear_rate_limits), `src/run/level_rotation.gd` (set_wave_hold)
- `project.godot` (autoload TutorialHost, input skip_tutorial = Tab)
- `src/run/game_tutorial_{move_look,heart_falls,coffee,cigarette,shoot,danger,empty_gun}.tscn` (capture scenes)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: playtest doc OR integration test (waived at `qa.level` minimal)

**Status**: [ ] Waived

---

## Dependencies

- Depends on: `story-002-heart-rate-and-zones.md`, `story-003-substances.md`, `story-005-status-bar-hud.md`, `story-007-dive.md`, `story-008-enemies-and-waves.md`, `story-015-hit-direction-and-danger-countdown.md` (same folder)
- Unlocks: None

---

## Completion Notes

**Completed**: 2026-11-26
**Criteria**: 9/10 covered, 1 partly deferred. Deferred: criterion 3's "an action hint ends when the player does it" for the shoot hint. A fire press did not register in the headless probe, so the hint timed out at 30 s; the move_look, coffee and cigarette goals did end on the action. The pulse look of the box (criterion 1) is also left to a playtest.
**Deviations**:
- Outside the story's Files list: `src/heart/heart_rate.gd` (public rate clamp) and `src/run/level_rotation.gd` (`set_wave_hold`), both asked for by the Implementation Notes.
- `project.godot`: new autoload and the `skip_tutorial` input.
- Seven capture scenes `src/run/game_tutorial_*.tscn`.
- No hardcoded gameplay numbers: all texts, timings and limits are in `assets/data/tutorial/tutorial.tres`.
**Test Evidence**:
- Waived at qa.level minimal (Integration).
- Probe `production/qa/evidence/story-023-tutorial/probe.txt` (script `probe_script.gd.txt`).
- Screenshots 01-07 in the same folder.
**Run result**: OBSERVED — all seven hints show as one line above the status bar, with the skip line and amber boxes on the heart panel, coffee and cigarette rows and gun panel. The danger hint has a red box, and the crosshair countdown is not covered. After fix round 1 the shoot hint is the first after the opening (probe f924, wave 1 just started). Screenshots: `production/qa/evidence/story-023-tutorial/01-move_look.png` … `07-empty_gun.png`.
**Story 022 note**: the "LEVEL CLEARED at 0:01 / ENEMIES 8" in the art view scenes is a capture-scene artifact (`debug_open_exit_immediately` plus RunState's placeholder `enemies_left` 8), not a bug.
**Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- Activation only in the main scene (game.tscn) or a scene with root meta `tutorial_enabled` · kept 2026-11-25
- Public heart clamp `HeartRate.set_rate_limits/clear_rate_limits` applied in `_set_rate` · kept 2026-11-25
- `LevelRotation.set_wave_hold(bool)` defers the visit's first wave start · kept 2026-11-25
- `skip_tutorial` = physical Tab; skip progress counts whenever the tutorial is active · kept 2026-11-25
- Moment hint texts and priorities (danger 200, first hit 60, empty gun 55, zones 50, pickup 40, dive 30); moment hints 2 s minimum, 4-4.5 s maximum · kept 2026-11-25
- Boxed parts: zones, danger and first hit box the heart panel; empty gun boxes the gun panel; pickup boxes the substance and gun panels; dive boxes the whole status bar · kept 2026-11-25
- Hint canvas layer 4 · kept 2026-11-25
- Moment hints are held back until the shoot hint has shown (danger excepted); the current zone or countdown counts as entered afterwards · kept 2026-11-25
- A danger hint replaces information hints only, not action hints; a replaced hint is marked shown · kept 2026-11-25
- On the 90 s cap the remaining opening steps are marked shown; the heart limits clear at wave start · kept 2026-11-25
- Key labels: first binding only; mouse button names and "the mouse" come from data · kept 2026-11-25
