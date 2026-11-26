# Game Brief: Last Dose

**One-sentence pitch:** A first-person shooter against waves of armed humans where your heart is the clock: coffee drives your heart rate up and cigarettes drag it down, each zone gives you an edge (slow motion when calm, superspeed when racing), and the run lasts until you pass out or have a heart attack.

## Core loop
- Fight waves of human enemies (bat-wielding brawlers, gunmen who take a firing spot, and an armoured boss with an SMG) in first person, with a pistol, an SMG and a shotgun. Survive three waves in a level, walk to its exit, and go on to the next level; the levels rotate and the waves keep getting harder.
- Steer your heart rate: hold coffee or a cigarette in your free hand to push it up or down; the longer you hold, the faster it moves. Left alone it keeps falling, and every enemy hit knocks it lower.
- Play the zone you are in: a slow heart steadies your aim and unlocks slow motion; a racing heart speeds you up, shakes your aim and unlocks superspeed. Dive to dodge. When you fall, the results show how long you lasted, and you start again.

## Player goal & fail state — what "working" looks like
- Push each run further (more time, kills or waves) on skill alone: every run starts with the same guns and substances.
- The run ends when heart rate stays under 10 for 5 seconds in a row (you pass out), or over 190 for 5 seconds in a row (heart attack). There is no health: enemy hits lower the heart rate. Nothing carries over between runs.

## MVP — what must exist to be the game
- First-person hitscan guns, all available from the start: pistol (semi-automatic, endless spare ammo), SMG (a full-automatic pistol) and shotgun (spread, strong pushback, no damage falloff). The SMG and shotgun use limited spare ammo dropped by enemies. Firing an empty gun reloads it.
- The gun is held in the right hand and the substance in the left; consuming is shown in first person.
- Two levels, the canteen and the plaza, in rotation: three waves a visit, then an exit opens and the player walks to it; the wave count and difficulty carry across levels.
- Three human enemy types in escalating waves: melee with a baseball bat; ranged (runs to a firing spot, shoots only with a clear line of fire, reloads); a boss with an SMG who walks around in heavy armour that absorbs part of each hit until it breaks.
- No health: an enemy hit lowers the heart rate by an amount set by the hit's damage.
- Heart rate with five zones: under 10, pass out after 5 s; 10–60, slower, steady aim, slow motion available; 60–100, normal; 100–190, faster, aim tremor, superspeed available; over 190, heart attack after 5 s. Each run starts at 80, and the rate keeps falling (3 bpm per second) at every rate.
- Two substances, coffee (raises heart rate) and cigarette (lowers it), consumed by holding (hold Q for coffee, E for a cigarette): slow at first, faster the longer you hold. Each coffee or cigarette lasts a few seconds of holding; each run starts with a few of each, and killed enemies drop more.
- Shift: slow motion (10–60) or superspeed (100–190), lasting a few seconds, then a cooldown.
- Space: dive in the direction you are moving (dash, leap, fall until you land, slide, get up), film-style; you can shoot while diving.
- Run-end screen with time survived, wave, kills, session best and how the run ended; restarts the run.
- HUD: an old-school status bar along the bottom with five boxes — coffee and cigarette counts; heart rate with its zone, a pulse trace and the danger countdown; a face that gets more battered as the heart rate nears either danger limit; the enemies left in the wave with the wave number and time survived; the gun with its ammo. The 3D view sits above the bar.
- Shooting feel: recoil, muzzle flash, impacts, blood on hits, and hit and kill feedback; first-person arms with a reload animation.
- Audio: gunshot and impact sounds; coffee, cigarette and heart-rate sounds; background music that crossfades.
- Ability screen feel: slow motion gets a strong colour grade and muffled audio; superspeed a warm, high-contrast look and a wider field of view.
- Heart-rate vignette and field of view: white and wider as the rate climbs (up to +20° at 190), black and narrower as it falls; the vignette pulses near 10 and 190.
- Hit direction and danger on the crosshair: arcs around the crosshair show where a hit came from, and the danger countdown also shows under the crosshair.
- Slow-motion player edge: in slow motion the player runs on their own faster time (reload, fire, animations, consuming), the dive hangs in the air longer, and both abilities last longer; enemies and physics stay on world time.
- The dive clears obstacles: the leap goes over canteen tables and benches, and a low edge met in the air lifts the player over it instead of stopping the dive.
- Enemy variety: enemies spawn in groups at one spawn point, and ranged enemies carry a pistol, a shotgun or an SMG, each firing its own way, chosen by the wave mix.
- Human enemy models with animations and weapon props.
- Enemies push tables aside and never pass through them.
- Death and loading flow: on death the view collapses (knees buckle, the view falls to the floor, the gun drops), fades to black with a tip from a list, then shows the results; black fades cover level loads and restarts.
- Tutorial in the gameplay: a safe opening before wave 1 (heart rate kept away from danger), one hint at a time with a box around the HUD part it explains, hints the first time key moments happen (zones, danger, hits, empty gun, pickups, the dive); skippable by holding Tab; taught again each launch, nothing saved.
- Level art: the canteen and plaza art from the Unity version, rebuilt in Godot — models, textures and audio brought over (`docs/port/unity-asset-inventory.md`), the 38 URP materials and the screen looks rebuilt as Godot materials and environment (the Unity version wrote no shaders of its own).

## Out of scope — not building this
- Multiplayer.
- More than 2 substances, or tolerance (heart-rate zones replace it).
- More than the two levels (canteen and plaza; a second level added 2026-11-15) or the three enemy types; zombies (replaced by humans on 2026-11-14).
- More than the three guns.
- Permanent upgrades, currency, unlocks and save files (removed 2026-11-12).
- Base building, brewing or crafting.
- Story, cutscenes and a full settings menu.

## Build order
1. Weapons pass: auto-reload, spare ammo, shotgun, SMG.
2. Heart rate, its zones and the two substances held to consume. The riskiest part: playtest it here.
3. Two-handed viewmodel and consuming in first person; heart-rate HUD.
4. Shift ability and the dive.
5. Human enemies: melee, ranged, boss, and the wave mix.
6. Port parity: feel and audio, death flow, enemy variety, level art, tutorial.

---
**Who it's for / what they feel:** Fans of run-based arena shooters who want white-knuckle resource juggling and the "one more run" itch of beating their best time.

**Art & audio direction:** Gritty low-poly, desaturated; a racing heart jitters the screen and pounds in the audio, a slow heart hazes and muffles it; heartbeat-driven tension audio.

**Reference game:** Endless wave-survival modes such as Call of Duty: Zombies, with the slow motion and shootdodge dive of Max Payne.
