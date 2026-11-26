# Story 010: Run-end screen and restart

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 10

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Run-end screen…") and Player goal & fail state:*

- [ ] When the run ends (`run_ended`, story 002) gameplay stops and a results screen appears.
- [ ] The screen shows time survived, wave reached, kills, the session best, and how the run ended (passed out or heart attack).
- [ ] The session best is kept in memory for the session only; there are no save files and nothing else carries over.
- [ ] A restart button or key starts a fresh run: heart rate 80, starting guns, ammo and substances, wave 1, the first level, kills and time reset.
- [ ] `Engine.time_scale` is 1.0 after restart even if the run ended during slow motion.
- [ ] The mouse cursor is usable on the screen and captured again on restart.

---

## Implementation Notes

- A `CanvasLayer` scene shown over the frozen game; restart reloads the run scene and clears the run state (stub from story 005, completed by 008 and 009).
- Session best compares what the brief calls "more time, kills or waves": pick the primary (time survived is the brief's headline) and note it here: time survived is the primary; ties broken by wave reached, then kills; a run must be strictly better to replace the best (`RunState.is_better`).

---

## Out of Scope

- Menus beyond this screen (the brief excludes a full settings menu).

---

## Files

- `src/ui/run_end/run_end_screen.gd`, `src/ui/run_end/run_end_screen.tscn`, `src/ui/run_end/run_end_data.gd`
- `assets/data/ui/run_end.tres`
- `src/run/run_state.gd` (kills, end reason, reset, session best)
- `src/run/level_rotation.gd` (spawner stop on run end, debug end-run exports), `src/run/game.tscn` (RunEndScreen, RunState wiring)
- `src/run/game_end_passed_out.tscn`, `src/run/game_end_heart_attack.tscn` (capture scenes)
- `src/waves/wave_spawner.gd` (timers obey pause)
- `project.godot` (`restart_run` input action)

## QA Test Cases

**UI verification steps:**

- **AC-1..4**: Setup: end a run by passing out and another by heart attack, then restart. Verify: both reasons show, session best updates, the restart is clean. Pass condition: all five figures correct, run restarts from wave 1.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: retained screenshots of the screen (passed out, heart attack) in `production/qa/evidence/`

**Status**: [x] Retained screenshots `production/qa/evidence/story-010-run-end-and-restart/01-passed-out.png`, `02-heart-attack.png`; probe `probe.txt`

---

## Dependencies

- Depends on: `story-002-heart-rate-and-zones.md`, `story-008-enemies-and-waves.md`, `story-009-levels-and-rotation.md` (same folder)
- Unlocks: None

## Completion Notes

**Completed**: 2026-11-26
**Criteria**: 6/6 covered (probe + two opened captures); deferred to playtest: restarting with a real Enter / gamepad / mouse click (the probe calls `restart_run()` directly), and the screen's look and feel.
**Deviations**: files changed outside the story's list: `src/waves/wave_spawner.gd` (story 008: timers now obey pause, so no spawns behind the screen), `src/run/level_rotation.gd` and `src/run/game.tscn` (story 009: spawner stop on run end, debug end-run exports, screen wiring), `project.godot` (`restart_run` action). No hardcoded gameplay numbers (all in `assets/data/ui/run_end.tres`; debug presets are exports on capture scenes).
**Test Evidence**: `production/qa/evidence/story-010-run-end-and-restart/` — `01-passed-out.png`, `02-heart-attack.png`, `probe.txt` (4 runs, windowed so mouse mode is real), `probe_script.gd.txt`, `stamp.txt`.
**Run result**: OBSERVED — results panel fits 1280x720 over the frozen game with title, reason (YOU PASSED OUT / HEART ATTACK), time, wave, kills, session best, NEW BEST, PLAY AGAIN and prompt (production/qa/evidence/story-010-run-end-and-restart/01-passed-out.png, 02-heart-attack.png); probe: kills 3/5/6/0 counted, wave 2 reached, time frozen and tree paused at end, spawns stop, best updates only on a longer run and is kept in memory (no user:// files), restart from time_scale 0.3 gives 1.0, heart ~80, full starting ammo 12/0 30/90 6/24, coffee 7 cig 3, wave 1, canteen visit 0, kills/time reset, mouse VISIBLE on screen and CAPTURED after restart.
**Story 018 hook**: `RunEndScreen` signals `run_end_requested(reason)`, `results_shown(reason)`, `restart_started`; `RunEndData.show_delay_seconds` (0.0, real seconds; gameplay keeps running during it).
**Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- Session best: time survived primary, then wave, then kills; strictly better replaces · kept 2026-11-26
- Session best stored in a `static var` on RunState (memory only, survives reload) · kept 2026-11-26
- Time survived counts scaled (game) time, unchanged from the stub, so slow motion slows it · kept 2026-11-26
- Freeze = `get_tree().paused`; screen PROCESS_MODE_ALWAYS; spawner stopped on run end · kept 2026-11-26
- Restart = `Engine.time_scale = 1`, unpause, `reload_current_scene()`; no restart fade (run.json fades left to story 018) · kept 2026-11-26
- Restart input: `restart_run` action Enter / KP Enter / joypad A (0) / Start (6) + mouse click; 0.75 s real-time guard; button not focusable so Space (dive) cannot restart · kept 2026-11-26
- Layout: Unity 1080p sizes scaled by viewport height / 1080 (`reference_height`), plus a fit-to-90% safety; CanvasLayer 30 over everything; best line "SESSION BEST: {time} - wave N - K kills"; time m:ss · kept 2026-11-26
- Capture scenes preset 37 kills / wave 7 / 12:34 and 17:03 via debug exports and end through the real HeartRate countdown (0.5 s on a duplicated data copy) · kept 2026-11-26
