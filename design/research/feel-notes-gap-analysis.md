# Feel Gap Analysis: New Feel Notes vs the Current Build

> **Date**: 2026-11-12
> **Status**: Analysis for story selection (no stories created from it yet)
> **Measured against**: commit 5a0eab9 (stories 001, 002, 008 to 013 complete)
> **Source**: the user's feel notes of 2026-11-12, kept as written in the appendix
> **Scope**: game feel only; design changes are flagged where they force a feel change, not decided here

## The Feel Target in One Line

Fast DOOM 2016 / Quake movement, Max Payne-style dodge dives, bullet time at low heartbeat, enemies that react hard
to every bullet, and a heartbeat you can feel through screen tint, tremor and sound.

## Where the Current Build Stands

| Area | Now (measured) | The notes want | What to adjust |
|---|---|---|---|
| **Movement** | Walk only at 5 m/s (`player_movement.json`), instant start and stop, gravity. No jump, sprint, crouch or slide: the `Jump`, `Sprint` and `Crouch` input actions exist but no code reads them. | DOOM/Quake speed, a slide hop, a Max Payne dive to dodge bullets, speed set by heartbeat | The biggest gap; see Movement below |
| **Aim** | Hip-fire only, no zoom, shots go exactly where the crosshair points, no random spread | Single state, no zoom, close quarters | **Already matches.** Keep it |
| **High heartbeat** | — | Move faster, aim faster, a tremor that makes aim worse, white screen edges | A heartbeat value that scales speed, turn speed and handling, plus a tremor and a white vignette |
| **Low heartbeat** | — | A little slower, no tremor, bullet time, black screen edges | Time control, a black vignette, a speed multiplier |
| **Enemy reaction** | 100 HP, 4 pistol hits per zombie, a 0.25 m push, a 0.3 s stagger | Very reactive, not spongy | Story 014 (ragdoll, blood mist, hitstop) matters more; fewer hits to kill; a flinch that interrupts their attack |
| **Enemy attacks** | Zombies only melee | Gangsters with pistol, shotgun and SMG; bullets you can dodge; coming from every side | A new system: visible, slower enemy bullets |
| **Weapons** | Pistol, rifle, shotgun | Akimbo pistols, shotgun, SMG | Akimbo needs two guns on screen firing alternately, each with its own kick and flash; the rifle's tuning becomes an SMG; the shotgun stays |
| **Camera** | 60° vertical field of view (about 91° horizontal), no head bob, no landing dip | Speed you can feel | Raise the field of view, add a speed boost, head bob and a landing dip |
| **Look** | No post-processing in the Arena | White and black vignettes driven by heartbeat | A post-processing volume, or a screen overlay, controlled by heartbeat |
| **Sound** | Layered gunshots, impacts, reloads and dry clicks (story 013) | — | A heartbeat sound whose tempo follows heartbeat, a whiz when enemy bullets pass close, enemy gunshots in 3D |

## What Each Feel System Needs

### 1. Movement (first, because every other number depends on it)

- **Speed:** base about 8–9 m/s instead of 5 (Quake runs at roughly 8 m/s). Heartbeat scales it, for example 0.85×
  low and 1.25× high.
- **Acceleration:** full speed in about 0.1 s and a stop in about 0.1 s, instead of instant. Partial air control.
- **Jump and slide hop:** a normal jump, a slide that keeps the player's speed, and a jump out of the slide that
  carries the momentum.
- **Dive:** a committed sideways or forward dive, low and fast, with the camera dropping and rolling. The player can
  shoot during it, and a short getting-up moment follows. At low heartbeat it can trigger bullet time.
- **Camera:** field of view up to about 70–75° vertical (100–105° horizontal), plus 5–10° while sliding, sprinting or
  at high heartbeat. Head bob and a landing dip.
- **Knock-on:** the zombie's 3.5 m/s speed, the camera kick sizes from story 012 and the arena size were all tuned for
  a 5 m/s walk, so they need retuning.

### 2. Time control

- One owner of the game's time scale, which story 014 already plans for hitstop; design it to serve bullet time too.
- Bullet time slows the world (for example to 0.3×) while the player's look stays at full speed, so aiming feels sharp.
- Sound pitches down during it.
- Enemy bullets slow visibly, which is what makes dodging readable.
- Trigger or toggle is still to be decided, as the notes say.

### 3. Enemy bullets you can dodge

- **Not hitscan:** projectiles with travel time, about 20–30 m/s (slower in bullet time), with a bright tracer.
- **Warnings:** a muzzle flash and a short wind-up before each shot; the zombies' 0.5 s attack wind-up can be reused.
- **Each weapon fires differently:** pistol single shots, a shotgun spread, SMG bursts.
- **Feedback:** a whiz on near misses, and a direction marker when the player is hit.

### 4. Heartbeat feel layer

One value drives movement speed, turn and handling speed, tremor (high only), the white or black vignette, the
heartbeat sound's tempo and the field-of-view boost. It can be built and tuned with a debug slider before the heartbeat
rules exist. The tremor must also obey `camera_motion_scale` in `player_comfort.json` (story 012).

### 5. Enemies that are not spongy

- **Hits to kill:** about 2 pistol hits, a one-shot shotgun up close (already true at 5 m), 3–4 SMG hits.
- **Flinch:** every hit interrupts the enemy's own shooting.

## How the Planned Work Carries Over

- **Stays as built:** stories 008, 010, 012 and 013 (gun feel, blood, punch, sound). They need retuning, not
  rebuilding.
- **More important now:** story 014 (hit and kill pass); its time-scale owner should serve bullet time as well as
  hitstop.
- **Gets bigger:** story 015 (sway and bob) matters more at speed; story 016 (arms) roughly doubles for akimbo pistols.
- **Changed by the new design:** zombies become gangsters with guns (a new enemy model), and heartbeat replaces the
  vitality and dose systems of stories 003 and 004. That is a design decision; it conflicts with `design/game-brief.md`
  and stories 003–007, which are unchanged.

## Suggested Order

1. Movement core: speed, acceleration, jump, slide hop, camera.
2. Time control, together with story 014.
3. Enemy bullets you can dodge, then the dive.
4. Heartbeat feel layer.
5. Akimbo pistols and the SMG.

Movement comes first because enemy speeds, bullet speeds, distances and kick all have to be tuned against it.

## Assumptions

- **"Aim lebih cepet"** (aim faster) means faster turning and weapon handling, not aim assist.
- **Tremor** means the view drifts while the crosshair stays honest. If it means random bullet spread, the no-spread
  rule from stories 008 to 012 changes.
- **"Endless supply of bullets"** means infinite spare ammo, with magazines and reloads kept. If there are no reloads
  at all, story 013's reload sounds and story 016 change.
- **Slide hop** means a slide that keeps momentum into a jump, not full Quake strafe-jumping.
- **Speeds** use Quake's run speed of about 320 units/s at roughly an inch per unit, so about 8 m/s.

## Identity Note

A cop fighting gangsters with slow motion and substances sits very close to Cop Bastard, the feel reference in
`design/research/shooting-feel-gap-analysis.md`. The heartbeat range and the threat of falling asleep are this game's own
hook, so the feel identity should lean on them (the vignettes, the heartbeat sound, the tremor) so that it reads as its
own game rather than a variant.

## Appendix: The Source Notes (as written, 2026-11-12)

```text
General premise:
Fast paced FPS where a cop fight hordes of gangsters and the urge to sleep, with the help of various substances and an endless supply of bullets.

Balance your decreasing heartbeat/health to unlock different abilities and playstyles. take stimulants to raise your heartbeat and move manic, take depressants to take things slower. take things too slow, you fall asleep, take things too fast, your dying heart gives in. 

Objective:
clear area > unlock new area > boss > repeat
Main goal: Survive, clear enemies, keep heartbeat within range.

Movement:
Walk: speed tergantung heartbeat, (sprint kurangin heartbeat?)
Jump: jumpnya kayak dive di max payne buat dodge peluru.
aim: single state, gaada zoom in, mostly close quarter tembak2

Ability:
High heartbeat: Move faster, aim lebih cepet, aim ada tremor yang bikin ga akurat.
Slow heartbeat: Move a little slower, no tremor, bullet time ability

Enemies:
reaktif banget ke peluru, ga spongy to damage
dateng dari multiple directions, player dipaksa gerak gaada diem.
danger ditentuin senjata yang mereka pegang. pistol, shotgun, smg
peluru masih manageable buat didodge, reward pemain
boss gerak cepet, susah dikeker

Senjata:
pistol akimbo
shotgun
smg

possible persona for enemy:
- ranged (bisa dari bawah atau aerial unit)
- tank (gatau bakal pas atau gk)
- melee

vibes gameplay (in movement): DOOM 2016 or Quake

kalo HR tinggi (vignette positive; pinggir2annya tuh putih):
+ slide hop
- tremor (camera shake/accuracy rendah/drunk movement)

kalo HR rendah (vignette negative; pinggir2annya tuh hitam):
+ slowmo (dodge bullet); on trigger/on toggle (TBD; saat refining)
- movement bikin lebih lambat
```
