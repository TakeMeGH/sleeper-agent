# Story 015: Hit direction arcs and danger countdown on the crosshair

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 16
*(Unity reference: story 046.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Hit direction and danger on the crosshair…"):*

- [ ] Each enemy hit on the player shows a short red arc on a ring around the crosshair, pointing toward where the hit came from (in front at the top, behind at the bottom, left on the left), in the horizontal plane only.
- [ ] The arc keeps pointing at the source as the player turns, holds for a set time, then fades.
- [ ] A new hit within a set angle of a showing arc refreshes it; hits from different directions show together, up to a pool size; past that the oldest is reused.
- [ ] Every enemy attack (bat, ranged shot, boss) passes the attacker's position with the hit (`take_hit` gains a source position); a hit with no source shows no arc and logs nothing.
- [ ] While the pass-out or heart-attack countdown runs, its seconds left (5 to 1) show as a small number under the crosshair in the status bar countdown's colour; it hides when the countdown stops and after the run ends.
- [ ] Arcs and the number run in unscaled time, so slow motion and hitstop do not stretch them; at run end showing arcs finish fading and the number hides.
- [ ] Every number and colour is in data.

---

## Implementation Notes

- Arcs drawn with a `Control` `_draw()` or a shader on a `TextureRect`; the ring is centred on the crosshair from story 011.
- A small camera jolt on a hit is optional in Unity; leave it out unless wanted.
- The brief's vignette pulse near the limits is story 014, not here.

---

## Out of Scope

- Story 014: vignette pulse. Story 005: the status bar's own countdown.

---

## Files

- `src/ui/hud/hit_arcs.gd`
- `src/ui/hud/hit_arcs_data.gd`
- `src/ui/hud/danger_countdown_label.gd`
- `assets/data/ui/hit_arcs.tres`
- `src/player/player_controller.gd`
- `src/ai/melee_enemy.gd`
- `src/ai/enemy_base.gd`
- `src/player/hit_arcs_debug.gd`
- `src/player/test_range.tscn`
- `src/waves/test_arena.tscn`
- `src/run/game.tscn`
- `src/player/test_range_hit_arcs_front.tscn`
- `src/player/test_range_hit_arcs_left.tscn`
- `src/player/test_range_hit_arcs_behind.tscn`
- `src/player/test_range_hit_arcs_two.tscn`
- `src/player/test_range_danger_countdown.tscn`
- `production/session-logs/build-notes.md`

## QA Test Cases

**UI verification steps:**

- **AC-1..5**: Setup: let enemies hit from front, left, behind and two at once; reach the countdown. Verify: arcs point and move with the turn; the number shows 5 to 1. Pass condition: all directions correct, nothing lingers after the run ends.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: retained screenshots in `production/qa/evidence/`: arcs from front, left and behind; two arcs at once; the countdown under the crosshair

**Status**: [x] Created: `production/qa/evidence/story-015-hit-direction-and-danger-countdown/` (01-arcs-front, 02-arcs-left, 03-arcs-behind, 04-arcs-two, 05-countdown .png; probe.txt)

---

## Dependencies

- Depends on: `story-002-heart-rate-and-zones.md`, `story-008-enemies-and-waves.md`, `story-011-shooting-feel.md` (same folder)
- Unlocks: None

## Completion Notes

**Completed**: 2026-11-26
**Criteria**: 7/7 covered (none deferred; how the arcs feel in live combat is left to normal playtesting)
- AC1 direction/horizontal: probe angles front 0, right 90, left -90, behind 180, front-high 0, left-low -90; PNGs 01-03 show top/left/bottom arcs.
- AC2 follows turn + hold/fade: probe arc at -90 becomes 0 after a 90 deg left turn; gone after hold+fade (1.1 s).
- AC3 merge/pool: hit 20 deg away refreshes (1 arc, age 0); 60 deg away adds a second; 8 hits -> 6 arcs, the two oldest reused; PNG 04 shows two at once.
- AC4 source contract: `take_hit(damage, direction, source_position: Variant = null)`; melee and the shared enemy bullet path (ranged, boss SMG) pass `global_position`; a no-source hit adds no arc and printed nothing.
- AC5 countdown: live sequence 5,4,3,2,1 then hidden at run end, colour (1, 0.84, 0.4) = HudData.highlight_color; hidden after the rate recovers; PNG 05 shows "3" under the crosshair with the bar at 2.5 s.
- AC6 unscaled: at time_scale 0.1 the arc aged 0.57 s in 580 real ms and was gone by 1.18 real s; at run end no new arc, the showing one faded out in 1.3 s.
- AC7 data: every number/colour in `assets/data/ui/hit_arcs.tres`; the countdown colour is read from hud.tres.
**Deviations**: none (no gameplay literals in code; files outside the story's list are capture scenes, `hit_arcs_debug.gd`, `hit_arcs_data.gd`, scene wiring and build-notes).
**Test Evidence**: UI: retained screenshots in `production/qa/evidence/story-015-hit-direction-and-danger-countdown/`; probe.txt (scripts p015b/p015c copied there).
**Run result**: OBSERVED — red arcs at the top (front), left, bottom (behind), and two at once (front-right + left) on the ring round the crosshair; yellow "3" under the crosshair while the bar shows PASS OUT 2.5 SEC (production/qa/evidence/story-015-hit-direction-and-danger-countdown/01..05 .png)
**Reviewed by**: self, no independent review (engine check by godot-specialist)

## Calls beyond the design

- take_hit gains an optional third parameter `source_position: Variant = null` + signal `PlayerController.hit_taken(damage, source_position)` · kept 2026-11-26
- Angle reference is the player body's yaw (not camera pitch); source straight above/below = front · kept 2026-11-26
- Merge compares with each arc's current angle, first match wins, a fading arc can be refreshed · kept 2026-11-26
- Pool full: the arc with the largest age is replaced · kept 2026-11-26
- Run end: no new arcs, showing arcs run their normal hold+fade (PROCESS_MODE_ALWAYS) · kept 2026-11-26
- Sizes authored at 1280x720, scaled by the canvas_items stretch only · kept 2026-11-26
- Extra data fields: arc_point_count 24, countdown_outline_size 4, countdown_outline_color black 0.85 · kept 2026-11-26
- Number = ceil(seconds left), centred 60 px under the crosshair centre · kept 2026-11-26
- Camera jolt left out (story says optional); jolt fields not ported · kept 2026-11-26
- Capture scenes re-inject 0-damage hits at 8 m every 20 frames; countdown scene holds the rate at 5 · kept 2026-11-26
