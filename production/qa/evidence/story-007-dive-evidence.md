# Story 007: Dive — Visual/Feel evidence

> **Story**: `production/epics/last-dose/story-007-dive.md`
> **Status**: waiting on sign-off (story stays In Progress)
> **Captured**: 2026-11-26, Godot 4.7.2, windowed Movie Maker 1280x720 @ 60 fps
> **Capture scenes**: `src/player/test_range_dive_{launch,airborne,slide}.tscn`. Each dives at physics frame 10 with input (1,-1) (right-forward), holds the SMG trigger through the dive, and runs for 18 / 30 / 46 frames.

## Screenshots

| Phase | Screenshot | Capture log phase line |
|---|---|---|
| Launch (mid-leap, frame 18) | [01-launch.png](story-007-dive/01-launch.png) | `DIVE phase=DIVE_LAUNCH frame=10` |
| Airborne (frame 30) | [02-airborne.png](story-007-dive/02-airborne.png) | `DIVE phase=AIRBORNE frame=25` |
| Slide (frame 46) | [03-slide.png](story-007-dive/03-slide.png) | `DIVE phase=SLIDE frame=34` |

Probe (headless, on a real Player body with physics): [probe.txt](story-007-dive/probe.txt). Hashes of the changed files: [stamp.txt](story-007-dive/stamp.txt).

## Review notes per criterion

- **AC-1: Space dives in the movement direction (dash and leap, fall to landing, slide, get up).**
  - Probe, flat floor: phases run `DIVE_LAUNCH@60 -> AIRBORNE@75 -> SLIDE@84 -> GET_UP@112 -> IDLE@148`.
  - Landing is detected from the floor, not timed.
  - With no input the dive goes forward (-Z): the player ends at z -3.48 with x 0.
  - Not checked: pressing Space itself in play.
- **AC-2: The dive starts on the ground and can't restart until the player has got up.**
  - Probe: 0 of the `try_start` calls made during the dive succeeded.
  - Right after getting up the cooldown is 1.18 s and `try_start` returns false. 75 frames later the cooldown is 0 and `try_start` returns true.
- **AC-3: The gun fires through the whole dive.**
  - Probe: the SMG fired 23 shots during one dive.
  - In the screenshots the ammo drops from 30 to 28 (launch), 25 (airborne) and 22 (slide).
  - The dummies show 0 hits because the scripted aim misses them. Whether shots land on a target during a dive needs a playtest.
- **AC-4: The view drops and tilts through the dive and settles on getting up.**
  - Launch and airborne show a clear roll to the right and a lower view.
  - The slide shows the lowest eye height with a small roll.
  - The settle on getting up was not captured in a still. The probe only shows the camera offset reaching zero at IDLE indirectly (the camera stops processing).
  - **Needs your judgement**: does it read as a film-style dive?
- **AC-5: Control returns smoothly, with no stuck state against a wall or ledge.** Probe results:
  - **Wall** 0.5 m ahead: the body stops at z -0.50 (wall face at -0.85, capsule radius 0.35), and the phases still run to IDLE@148.
  - **Off the edge of a platform**: AIRBORNE@75 -> IDLE@166, which is the 1.5 s `max_airborne_seconds` guard. Control returns and normal gravity resumes.
  - **Slide off a 0.4 m step**: `SLIDE -> AIRBORNE@102 -> SLIDE@107 -> GET_UP -> IDLE`. The speed carries on at 2.75 m/s with no reset to full dive speed.
  - **V-trench**: the player landed on the trench bottom and the dive ended normally.
  - **Steeper trench**: the player fell through, and the timeout guard ended the dive.
  - The stall guard (`stall_speed` / `stall_frames`) never triggered in any probe case, so that path is untested.
  - "Smoothly" needs a playtest.
- **AC-6: The tuning lives in a data resource.** I read `assets/data/player/dive.tres`. It holds the Unity values plus the new guards and `camera_smoothing`.

Extra: with the head at -89° pitch, the minimum of head plus camera pitch during a dive is -89.00°, so the view never flips.

## Open for playtest

- How the dive feels when Space is pressed for real, including a standing dive going forward.
- Shots hitting targets mid-dive.
- Whether the camera reads as "film-style", and whether the settle on getting up looks right.
- The dive covers about 3.5 m in total with the Unity values. It runs on game time, so Shift slow motion stretches it (story 016 owns the hang).

## Sign-off

- [ ] Approved — art/feel (name, date)
- [ ] Approved — dive state machine plays without stuck states (name, date)
