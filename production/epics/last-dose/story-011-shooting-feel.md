# Story 011: Shooting feel: recoil, flash, impacts, blood, hit feedback, arms

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 12
*(Unity reference: stories 008, 010, 014, 016 in `E:\Unity Project\fps-substance\production\epics\`; behaviour to match, not code to translate.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Shooting feel…"), with Unity's finished behaviour as the reference:*

- [ ] Recoil is forgiving (Left 4 Dead / CoD Zombies, not CS:GO): each shot gives a small camera kick and light shake that fully recover in a set time; holding fire never drifts the aim.
- [ ] Each shot shows a muzzle flash at the barrel; a dry click plays on an empty gun.
- [ ] A crosshair sits at screen centre; a hit marker flashes when a shot lands on a damageable target, with a distinct marker when it kills.
- [ ] A shot at a non-damageable surface spawns sparks or dust aligned to the surface and leaves a bullet hole that fades; the number alive is capped.
- [ ] A non-lethal hit on an enemy sprays blood along the shot direction, flashes the enemy briefly and pushes it back along the shot.
- [ ] A kill makes a bigger blood burst, leaves a floor splat, and the body is pushed along the shot. Splats fade after a set time; their number is capped.
- [ ] A kill freezes the game for a very short hitstop; kills close together do not stack past a cap, and input pressed during the freeze is not lost.
- [ ] First-person arms (replacing story 004's placeholders) hold each gun; the arms follow the gun through recoil, and each reload is a motion timed to the gun's reload time.
- [ ] A reload cancelled by a weapon switch blends back without a snap; the arms never clip through the camera near plane.
- [ ] Every feel value (kick, recovery, shake, flash length, knockback, hitstop, lifetimes, caps) is in data; effects are pooled, nothing is created per shot.

---

## Implementation Notes

- Shots ignore the player's own collider. Check particles/`GPUParticles3D`, decals and `Decal` node APIs in `docs/engine-reference/godot/modules/rendering.md` first.
- Hitstop uses `Engine.time_scale` or a short pause: only one class writes to it; coordinate with story 006 and 016 (slow motion).
- `design/research/shooting-feel-gap-analysis.md` and `feel-notes-gap-analysis.md` list the gaps against other shooters; read them before tuning.
- Arms and gun art: bring over from the Unity project (`Assets/ThirdParty/Drillimpact_PSXFirstPersonArms`); keep its licence entry (story 022).

---

## Out of Scope

- Story 012: every sound. Story 020: enemy models and ragdoll. Story 018: death effects on the player.

---

## Files

- `src/weapons/gun_feel.gd`
- `src/weapons/gun_feel_data.gd`
- `src/weapons/gun_feel_set.gd`
- `src/weapons/impact_effects.gd`
- `src/weapons/impact_effects_data.gd`
- `src/weapons/real_clock.gd`
- `src/weapons/gun.gd`
- `src/weapons/weapon_holder.gd`
- `src/ui/hud/crosshair.gd`
- `src/ui/hud/crosshair.tscn`
- `src/viewmodel/viewmodel.gd`
- `src/viewmodel/viewmodel_data.gd`
- `src/viewmodel/viewmodel_gun_data.gd`
- `src/player/shift_ability.gd`
- `src/player/target_dummy.gd`
- `src/player/test_range.gd`
- `src/player/player.tscn`
- `src/player/test_range.tscn`
- `src/player/test_range_feel_flash.tscn`
- `src/player/test_range_feel_wall.tscn`
- `src/player/test_range_feel_blood.tscn`
- `src/player/test_range_feel_kill.tscn`
- `src/player/test_range_feel_reload.tscn`
- `src/ai/enemy_base.gd`
- `src/ai/enemy_data.gd`
- `src/run/game.tscn`
- `src/waves/test_arena.tscn`
- `assets/data/weapons/gun_feel.tres`
- `assets/data/weapons/impact_effects.tres`
- `assets/data/viewmodel/viewmodel.tres`

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1..8**: Setup: shooting range with a wall and enemies. Verify: fire each gun in bursts, hit walls, wound and kill an enemy, reload, switch mid-reload. Pass condition: no aim drift, effects read clearly, hitstop is short, no snap or clipping.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/` (muzzle flash, wall hit, blood on a hit, kill burst, mid-reload) + sign-off in `production/qa/evidence/story-011-shooting-feel-evidence.md`

**Status**: [x] Created — `production/qa/evidence/story-011-shooting-feel-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `story-001-weapons-pass.md`, `story-004-viewmodel-and-consuming.md`, `story-008-enemies-and-waves.md` (same folder)
- Unlocks: `story-018`, `story-020`
