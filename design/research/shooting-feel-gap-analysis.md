# Shooting Feel Gap Analysis: Last Dose vs Cop Bastard

> **Date**: 2026-11-10
> **Status**: Analysis for story selection (no stories created from it yet)
> **Measured against**: commit 0315e55 (stories 001, 002, 008, 009, 010, 011 complete)
> **Reference game**: Cop Bastard (Steam app 1742440), used as a feel reference only

## Short Answer

Every link from pulling the trigger to the kill already exists in Last Dose. Each one is just turned down low.
The two links Cop Bastard pushes hardest are missing:

- **The target blowing apart.** Cop Bastard has blood mist on every hit, bodies bursting, and points for shooting
  bodies.
- **The kill moment.** It has slow motion you charge with kills.

Our sound is also the flattest part of the chain. The engine isn't the problem: Cop Bastard is a Unity game made
by one developer. Closing the gap is mostly tuning, content and two or three new systems.

## Assumptions

1. **Cop Bastard wasn't played or watched for this analysis.** It comes from its Steam page and press coverage.
   Anything about its recoil, sound, animation or hit reactions that those pages don't say comes from its genre and
   tags (Boomer Shooter, Gore, Bullet Time). Those are marked **[assumed]**.
2. **"Feel of shooting" means the moment-to-moment loop:** trigger, gun, hit, kill. Not progression or story.
3. **Play is at 1920×1080, around 60 fps, with mouse and keyboard, in the Editor's Play mode.**
4. **Most fights happen 5 to 15 m away** in the Arena.
5. **Placeholders count as gaps.** The synth hit sounds and the flat grey arena are felt whether or not they get
   fixed later.
6. **Cop Bastard is a feel reference only.** Last Dose takes techniques from it, not its look, setting or content.
   Last Dose keeps its zombies and doses.
7. **The player sometimes clicks the pistol faster than 5 times a second.**
8. **On-screen sizes below use our camera:** 60° vertical field of view at 1080p, about 16 px per degree near the
   centre (focal length 540 / tan 30° ≈ 935 px).
9. **Sound is about half of how hard a gun feels.** That's a common game-feel rule of thumb, not something measured
   in this game.
10. **[assumed] Cop Bastard's VHS look is darker and higher-contrast than ours,** which makes flashes and blood
    stand out.

## What Cop Bastard Does (from sources)

| Fact | Source |
|---|---|
| Solo developer, made in Unity, released Oct 29 2026, 91% positive of 423 reviews | Steam, Gamespress |
| Lo-fi VHS/CRT look | Steam, 80.lv |
| A muzzle flash and a blood mist with each shot; enemies burst into red mist | Steam, Aftermath |
| Thick smoke and flying lead | Press coverage |
| Pistol with unlimited ammo, described as very fun to fire; double-barrel shotgun, magnum, six guns | Aftermath |
| Enemies shoot on sight; tight corridors, staged arenas, endless waves | Steam, Aftermath |
| Kills charge a meter spent on slow motion or on healing | Steam, Aftermath |
| Extra points for shooting already-dead enemies | Aftermath |
| No aiming down sights, no perks, gore, loud music | Steam, Aftermath |
| 80.lv ran a whole article on its combat animation | 80.lv |

No source gives figures for its recoil, camera shake, sound layers or reload animation. The PC Gamer ("punchy guns,
satisfying but shallow") and DTF ("very durable enemies") claims come from search snippets only, not pages that
were read.

## Each Link of the Chain: Last Dose Now vs Cop Bastard

| Link | Last Dose now (measured) | Cop Bastard | Gap |
|---|---|---|---|
| Gun sound | One sample per gun, same pitch and volume every shot (`Assets/_Game/Gameplay/Weapons/GunFeedback.cs:207`) | [assumed] layered and loud | **Large** |
| Camera | Kick 0.6° pistol (≈10 px), 0.35° rifle (≈6 px), 1.4° shotgun (≈23 px); shake is mostly sideways movement, not rotation | [assumed] strong | **Large** |
| Gun on screen | Floating gun, no arms, reload is a 35° dip, no smoke, casings or light | Thick smoke; its animation got an article | **Medium–large** |
| Hit on target | 6 blood quads of 0.18 m for 0.35 s (≈21 px at 8 m, a tenth of the zombie's height); 0.25 m push, 0.3 s stagger | Blood mist every shot | **Largest** |
| Kill | 14-quad burst, red marker, one canned 1.8 s fall | Bodies burst into red mist | **Large** |
| After the kill | Corpse colliders off (`Assets/_Game/Gameplay/Combat/ZombieAnimation.cs:490`): later bullets pass through and puff dust on the floor | Points for shooting bodies | **Large** |
| Time | No hitstop, no slow motion | Slow motion from a kill meter | **Large** |
| Pressure | Wave 1 is 3 melee zombies at 3.5 m/s; the player moves at 5 m/s in an open, flat arena | Enemies shoot on sight, tight spaces | **Large** |
| Look | No post-processing volume in the Arena, default sky, bright light | VHS/CRT lo-fi | **Medium–large** |

## The Gaps, Biggest First

### 1. The target barely reacts (biggest gap)

**Now:** a hit looks like a few small red squares that are gone in a third of a second. Every death is the same
fall, whichever way the zombie was shot. Dead bodies can't be hit.

**How to fix:**

- **One blood cloud per hit,** 0.6–1 m across, growing and fading over 0.5–0.8 s. A 1 m cloud at 8 m is about
  117 px, against today's 21 px quads.
- **10–20 fast droplets** sprayed out behind the target along the bullet's path.
- **Scale it all with damage,** so a close shotgun blast is huge.
- **A kill burst 2–3× the size of a hit,** plus a large splat on the floor.
- **Deaths that follow the shot:** a ragdoll pushed along the bullet's direction (the Quaternius rig can take one).
  A cheaper option is 2–3 death clips picked by hit direction, plus a push.
- **Shootable bodies:** keep a collider on the corpse so hits make blood and move it.
- **A bigger flinch:** about a 0.5 m push and an upper-body hit reaction toward the shot.

### 2. The sound is flat

**Now:**

- The rifle fires 10 times a second with the identical sample, and the ear hears it as a loop.
- Bullets hitting the floor make no sound (`ImpactEffects` plays sounds only for hits and deaths).
- The hit and death sounds are synth placeholders.
- There's no music.

**How to fix:**

- **Vary each shot:** pitch ±5% and volume ±10%. That's a two-line change.
- **Layer each gunshot:** a sharp crack, a body and an echo tail, plus a bass thump for the shotgun. 2–4 variants
  per gun also works.
- **Add impact sounds:** a wet sound on every hit, a heavier one on a kill, and 3D thuds or ricochets on surfaces.
- **Music** is a separate decision, but Cop Bastard leans on it.

### 3. The kill has no moment

**How to fix:**

- **Hitstop on a kill:** freeze for 40–60 ms (about 3 frames), and 80–100 ms for a shotgun kill.
- **A distinct kill sound.**
- **A small zoom punch.**

Whether Cop Bastard uses hitstop is unknown. Its sourced version of this is slow motion, covered in gap 9.

### 4. The camera hardly moves, and the shake is the wrong kind

**Now:** the pistol's shake moves the camera 8 mm sideways. That shifts a zombie 8 m away by about **1 pixel**
(935 × 0.008 / 8), so only the shotgun's 1.2° roll shows on screen.

**How to fix:**

- **Shake by rotation, not movement:** pitch, yaw and roll jitter of 0.5–1° for the pistol and 2–3° for the
  shotgun, fading in about 0.1 s.
- **Bigger kick:** about 1.5–2° pistol, 4–5° shotgun, and 0.6° rifle with a slight climb.
- **Keep story 008's forgiving auto-recovery,** so the aim comes back on its own.
- **Kick the gun model sideways and with roll,** not only straight back.

### 5. The look hides the effects

**Now:** in the bright default scene, a 0.12 m muzzle flash that lasts 3 frames and gives off no light doesn't pop.

**How to fix:**

- **Add a Global Volume:** bloom, vignette, film grain and more contrast.
- **Make the scene darker,** with dimmer light and some fog.
- **Add a muzzle light that lasts 1–2 frames.** It only shows once the scene is darker.
- **Make the filter Last Dose's own:** tie it to the doses the brief already plans, rather than a permanent copy of
  VHS.

### 6. The gun has no physical life

**Cheap:**

- **Muzzle smoke,** using the Kenney smoke sprites already in the project.
- **Shell casings,** with a tinkle when they land.
- **Gun sway and bob** while moving.

**Expensive:**

- **Arms and a real reload animation.** Free (CC0) first-person arms are rare; doing it in code is a big job.
- **A moving slide or bolt.** Each model is a single mesh, so this needs the model edited.

### 7. The pistol drops fast clicks

**Now:** it fires while held, capped at 5 shots a second. It appears to have no input buffer, so a click within
0.2 s of the last shot is lost.

**How to fix:** fire on each press with a short buffer (about 0.1 s), and allow up to about 8 shots a second when
clicking.

### 8. Nothing pushes the player to shoot fast

The player is faster than the zombies, the floor is open and the enemies only melee, so backing away and plinking
is safe.

**How to fix:**

- **Bigger waves sooner,** e.g. 6–8 zombies in wave 1.
- **A faster runner zombie.**
- **Spawns closer to the player.**
- **Cover and narrow lanes.**
- **More surfaces to hit.**

Ranged enemies may be outside the brief, so that one is a design decision.

### 9. No reward loop and no time control

Our version could be a dose that slows time (the brief already has doses that change how the world feels), kills
that charge it, and a score with a bonus for shooting corpses. This belongs with the dose and scoring stories still
in the backlog (004–007).

### Not gaps, or smaller than they look

- **Field of view:** 60° vertical is about 91° horizontal at 16:9, which is normal for the genre. A bump to 65–70°
  is optional.
- **Zombie health:** 4 pistol hits is in line with "durable enemies" (unverified). Cutting health makes kills
  faster, but each hit still feels weak. Fix the per-hit feedback first.
- **Shotgun range:** its pellets sit 1.25°–4.8° off centre, so at 6 m the outer pellets land up to 0.5 m off. The
  estimate is that it only one-shots inside about 3 m and usually needs two shots at 6 m. Tighten the pattern or
  raise pellet damage in the tuning pass.

## Candidate Stories

Effort is a rough guess at this project's pace: S ≈ one session, M ≈ 2–3, L ≈ a week or more.

| # | Story | What's in it | Feel impact | Effort | Type | Depends on |
|---|---|---|---|---|---|---|
| A | Punch tuning pass | Rotation shake, bigger kick, zoom punch, shot pitch and volume variation, pistol fires per click, shotgun pattern and damage | High | S | Visual/Feel | — |
| B | Gun and impact audio | Layered gunshots, flesh hit and kill sounds, 3D surface impacts | Very high | M | Visual/Feel | Finding CC0 sounds |
| C | Hit and kill pass | Blood cloud scaled by damage, bigger kill burst, kill hitstop, deaths that follow the shot, shootable bodies, stronger flinch | **Very high** | M–L | Visual/Feel | Story 009 model |
| D | Look pass | Global Volume, darker lighting and fog, muzzle light | High | M | Visual/Feel | Best after C |
| E | Gun presentation | Muzzle smoke, casings, sway and bob | Medium | M | Visual/Feel | Casing sounds from B |
| F | Encounter pressure | Bigger waves, runner zombie, cover and lanes | High | L | Integration | Brief decision |
| G | Slow-motion dose | Kill-charged slow motion with pitched-down audio | High | M | Integration | Dose story |
| H | Score and corpse bonus | Points, corpse-shot bonus, combo | Medium | M | Logic/UI | Scoring stories |
| I | Arms and reload animation | Hands, real reload | Medium | L | Visual/Feel | CC0 arms or done in code |

**Recommended order:** A, then B, then C, then D, then E. Decide on F, G and H after that, and leave I for last.
A, B and C attack the three biggest gaps using systems that already exist (`GunFeedback`, `CameraKick`,
`ImpactEffects`, `BloodEffects`). The estimate is that those three close most of the gap.

Some items (ranged enemies, gibs, arms, music) may sit outside `design/game-brief.md`'s scope; check the brief
before picking them.

## What Was Not Checked

- **Cop Bastard footage or hands-on play.**
- **Our frame rate and input lag.** If the Editor hitches, everything above feels worse; profiling a build is worth
  doing before a feel pass.
- **The PC Gamer and DTF claims,** which come from search snippets only.

## Measured Values (as of commit 0315e55)

| Area | Values |
|---|---|
| Pistol | 25 damage, 12 rounds, 5 shots/s while held, reload 1.5 s; kick 0.6°, recovery 0.35 s, shake 0.008 m / 0.12 s, gun kick 0.05 m / 6°, flash 0.05 s / 0.12 m |
| Rifle | 18 damage, 30 rounds, 10 shots/s; kick 0.35°, shake 0.004 m / 0.08 s, roll 0.3°, gun kick 0.03 m / 2.5°, flash 0.04 s / 0.14 m |
| Shotgun | 14 damage × 8 pellets, 6 shells, 1.1 shots/s, pellets 1.25°–4.8° off centre, falloff 6–20 m to 0.2, range 40 m; kick 1.4°, shake 0.016 m / 0.2 s, roll 1.2°, gun kick 0.09 m / 10°, flash 0.07 s / 0.25 m |
| Impact | Hit flash 0.12 s, knockback 0.25 m, sparks 0.08 s |
| Zombie | 100 HP (pistol 4 hits, rifle 6), speed 3.5 m/s, wind-up 0.5 s, stagger 0.3 s, death 1.8 s, corpse stays 4 s |
| Waves | 3 zombies in wave 1, +2 per wave, 0.75 s between spawns; player speed 5 m/s |
| Blood | Spray 6 quads / 0.35 s per hit, kill burst 14, screen blood within 3 m |
| Camera | 60° vertical field of view, near clip 0.05; no Global Volume in the Arena |
| Audio | One 2D `PlayOneShot` per shot, fixed pitch; no surface impact sounds; synth hit and death sounds; no music |

## Sources

- [Steam: Cop Bastard](https://store.steampowered.com/app/1742440/COP_BASTARD/)
- [80.lv: combat animation article](https://80.lv/articles/check-out-sick-combat-animation-from-fps-inspired-by-90s-action-films)
- [Aftermath: impressions](https://aftermath.site/cop-bastard-impressions-review/)
- [Gamespress: launch announcement](https://www.gamespress.com/de/COP-BASTARD-Launches-on-PC-October-29)
- [CogConnected: launch preview](https://cogconnected.com/2026/10/cop-bastard-is-shooting-its-way-to-pc-later-this-month/)
- [PC Gamer (didn't load; snippet only)](https://www.pcgamer.com/games/fps/cop-bastard-is-a-retro-first-person-shooter-thats-exactly-as-aggressively-weird-as-youd-expect-from-a-game-called-cop-bastard)
- [DTF review (snippet only)](https://dtf.ru/games/5094189-obzor-igry-cop-bastard)
