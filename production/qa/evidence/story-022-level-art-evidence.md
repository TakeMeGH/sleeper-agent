# Story 022: Canteen and plaza art: visual evidence

> **Story**: `production/epics/last-dose/story-022-level-art-canteen-and-plaza.md`
> **Type**: Visual/Feel
> **Captured**: 2026-11-26, Godot 4.7.2, windowed 1280x720 (Movie Maker, `.scratch/capture.sh`)
> **Status**: waiting on sign-off

## Screenshots

| Shot | File | Scene |
|---|---|---|
| Canteen, player start | [01-canteen-start.png](story-022-level-art/01-canteen-start.png) | `src/levels/test_canteen_art_view.tscn` |
| Canteen, end platform looking down the hall | [02-canteen-overview.png](story-022-level-art/02-canteen-overview.png) | `src/levels/test_canteen_art_overview.tscn` |
| Plaza, player start | [03-plaza-start.png](story-022-level-art/03-plaza-start.png) | `src/levels/test_plaza_art_view.tscn` |
| Plaza, courtyard looking at the upper floors | [04-plaza-overview.png](story-022-level-art/04-plaza-overview.png) | `src/levels/test_plaza_art_overview.tscn` |
| Story 017 dive over a table, after the art change | [20-dive-over-table-after.png](story-022-level-art/20-dive-over-table-after.png) | `src/levels/test_canteen_dive_over_table.tscn` |
| Story 021 enemy pushing a table, after the art change | [21-push-table-after.png](story-022-level-art/21-push-table-after.png) | `src/levels/test_canteen_push_table.tscn` |

**No Unity screenshots exist.** None were found in the Unity project or in `docs/port`, and Unity was not opened in this run. The side-by-side comparison still needs a person: open `Canteen_Art.unity` and `Plaza_Art.unity` from the same spots and compare.

## Review notes per criterion

1. **Imports** (covered). All 14 level FBXs and the textures load in the captures. The logs show no import errors or SCRIPT ERRORs; the only ERROR line is "resources still in use at exit". One asset was added: `envi.png`. It is recorded in `docs/port/unity-asset-inventory.md`, which had wrongly listed it as unused. `canteen_dynamic_seats.fbx` stays unused, as it was in Unity.
2. **Credits** (covered). `envi.png` is gankdroid's in-house work. The existing `art/textures/` row in `assets/credits.md` covers it.
3. **Canteen** (covered). The canteen has the following, all at the Unity Art scene's transforms:
   - the model;
   - 16 pushable tables and 8 static benches;
   - 16 bottles and 16 bowls riding on the tables;
   - 16 closed doors, visual only.

   It also has the Unity directional light, ambient and background. The navmesh still has 372 polygons, unchanged. The story 017 dive lands SLIDE on the table top at frame 47, the same as before. In the story 021 push, the table moves 3.0 m and turns 14.7 degrees, the same as before.
4. **Plaza** (covered). The plaza has the following:
   - the model;
   - 3 pillars and 14 debris, all static with colliders;
   - 6 bins and 31 railings, all pushable;
   - 16 doors;
   - the Unity light, ambient and background.

   The navmesh has 849 polygons, up from 733 because of the 8 extra debris and their Unity rotations. All 9 spawns can still reach the player start, and all 7 firing spots still have sightlines (`probe.txt`).
5. **Materials** (covered). `envi.mat` was rebuilt as `assets/art/materials/envi.tres` and `Placeholders.mat` (the FBX `bot` slot) as `bot.tres`. Both use nearest filtering, roughness 1 and are double-sided. The screenshots show no pink or missing materials.
6. **Looks like Unity** (deferred: needs the Unity side-by-side). The light, ambient, background and post settings are Unity's own numbers. The result is a dark, blue-tinted scene lit by one cool sun. The canteen interior is mostly ambient-lit and dark; plaza floors under the sun read lighter.
7. **Gritty, low-poly, desaturated** (deferred to the person's judgement). Saturation is 0.85. Unity had no desaturation; story 009 used 0.7. This is a compromise call.
8. **60 fps with a full wave** (covered by `probe.txt`, `p022perf`). The probe ran windowed for 45 s from wave 6.
   - Canteen: up to 21 enemies, average 775 fps, 5th percentile 330.
   - Plaza: up to 28 enemies, average 563 fps, 5th percentile 220.
   - The slowest single frame was 48 fps in the canteen: one hitch, probably a spawn.

## Known gaps

- Doors have no collider, as in Unity, so the player and enemies can walk through a closed door. Door opening animations are not built.
- The plaza's upper-floor bins and railings are pushable but cannot fall, so one pushed past a ledge floats.
- In the plaza, a melee that spawns at Spawn1Front can fall through the floor at (-2, -34). Story 009's probe shows the same fall, so the art change did not cause it.

## Sign-off

- [ ] Approved — art/feel (name, date)
- [ ] Matches the Unity version side by side, canteen and plaza (name, date)
