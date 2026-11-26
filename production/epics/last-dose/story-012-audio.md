# Story 012: Audio: guns, impacts, substances, heart rate, footsteps, music

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 13
*(Unity reference: stories 013 and 044, and `Assets/_Game/Gameplay/Music/`.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Audio…"), with Unity's finished behaviour as the reference:*

- [ ] Each gun has its own shot sound with several takes rotated, so automatic fire never repeats one sample; the shotgun adds a low thump. An empty gun plays a dry click; a reload plays magazine-out, magazine-in and rack sounds at their points in the motion.
- [ ] A hit on an enemy plays a flesh-impact sound at the hit point in 3D; a kill plays a heavier distinct sound. One shotgun blast plays at most one flesh and one kill sound however many pellets hit.
- [ ] A shot at the world plays a 3D surface-impact sound with variants (count capped per shot).
- [ ] Holding coffee or cigarette plays its own consume sound, looping while held and stopping with a short fade on release; a short sound plays each time one is used up.
- [ ] Two heart-rate loops (low, high) are silent in 60–100 and fade in as the rate moves away, reaching full volume at 10 and at 190; they follow the rate smoothly and stop with a fade when the run ends.
- [ ] Footsteps loop while the player walks on the ground above a speed threshold and stop with a short fade; a landing sound plays after a dive or a long fall, once per landing.
- [ ] A combat music loop plays through the run; while at least one boss is alive a boss loop crossfades in and the combat loop crossfades back when the last boss dies.
- [ ] Sounds go through buses (SFX, music) so story 013's muffling can apply to all of them; 3D sounds come from a pool with a capped voice count.
- [ ] Every clip list, volume, pitch range and distance is in data.
- [ ] All audio files are brought over from the Unity project with their source and licence kept (story 022's credits file).

---

## Implementation Notes

- Use `AudioStreamPlayer3D` (pooled) and `AudioStreamRandomizer` for rotated takes; verify against `docs/engine-reference/godot/modules/audio.md` first.
- Crossfades run on real time so slow motion and hitstop never stretch them.
- Unity audio sits under `Assets/_Game/Audio` (BGM, SFX, Synth, Placeholder) and `Assets/ThirdParty/FreeFirearmSoundLibrary`; convert to `.ogg` or `.wav` as Godot prefers.

---

## Out of Scope

- Story 013: the slow-motion and superspeed audio filter.

---

## Files

- `src/audio/audio_emitter.gd`, `loop_voice.gd`, `audio_config.gd`, `gun_audio_data.gd`, `reload_sound_part.gd`, `consume_sound_data.gd`, `sfx_player.gd`, `music_director.gd`, `heart_rate_audio.gd`, `footsteps.gd` (new)
- `assets/data/audio/audio_config.tres` (new), `default_bus_layout.tres` (new: Master, SFX, Music)
- `src/player/player.tscn` (adds `SfxPlayer`, `MusicDirector`, `HeartRateAudio`, `Footsteps` under Player)
- `src/weapons/gun.gd` (additive `get_reload_progress()`)
- `.import` files set to loop (`edit/loop_mode=2`): `assets/audio/music/bgm_combat.wav`, `bgm_boss.wav`, `assets/audio/sfx/darah_rendah.wav`, `darah_tinggi.wav`, `ngopi.wav`, `ngudud.wav`, `footstep_for_walking.wav`
- `production/session-logs/build-notes.md` (Story 012 section)

---

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1..8**: Setup: a wave with enemies and a boss. Verify: each sound in turn, heart rate to both extremes, boss in and out. Pass condition: nothing loops audibly, nothing pops, music crossfades, no sound is missing.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: sign-off in `production/qa/evidence/story-012-audio-evidence.md` (a checklist of each sound heard) + a screenshot of the audio bus layout

**Status**: [x] Evidence doc created (`production/qa/evidence/story-012-audio-evidence.md`, probe log + bus layout and game screenshots); sign-off pending

---

## Dependencies

- Depends on: `story-001-weapons-pass.md`, `story-002-heart-rate-and-zones.md`, `story-003-substances.md`, `story-008-enemies-and-waves.md` (same folder)
- Unlocks: `story-013`
