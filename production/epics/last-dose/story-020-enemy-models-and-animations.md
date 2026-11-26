# Story 020: Human enemy models and animations

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 20
*(Unity reference: stories 029 and 052.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Human enemy models with animations and weapon props"):*

- [ ] The melee enemy, the ranged enemies and the boss all use the one human model and rig the Unity project settled on (`enemy_base` with its texture), brought into Godot; the texture shows correctly.
- [ ] The model stands at the enemies' collision height (1.8 m); the boss is 1.3 times as big and darker.
- [ ] An idle animation plays when an enemy stands still and a run animation when it chases, with the feet matching the ground at the agent's speed; a weaker walk is used for slow movement. Idle, run and walk loop; attack clips do not.
- [ ] Melee: the club or bat is in the right hand; the swing animation plays and the hit lands at the moment the weapon connects in the clip.
- [ ] Ranged: the gun prop (pistol, shotgun or SMG per story 019) is in the right hand; shots, flash and tracer come from the prop's muzzle point, and each shot plays the attack animation; the reload shows.
- [ ] Boss: an SMG prop fires from its tip with the SMG attack animation on the upper body.
- [ ] A hit shows a stagger, an upper-body jolt and knockback on the new rig.
- [ ] A killed enemy becomes a ragdoll (or plays a death animation) pushed along the shot; the body lingers, stays shootable until it fades (a hit shows blood and pushes it, no second death), never blocks or pushes the player or living enemies; the number of live bodies is capped.
- [ ] Models, animation files and textures are brought over from the Unity project with their source and licence kept (story 022's credits file).

---

## Implementation Notes

- Import FBX or glTF to `assets/art/enemies/`; use `AnimationTree` with a state machine for locomotion and an upper-body blend for attacks; `PhysicalBone3D` or a simple death clip for the ragdoll (check `docs/engine-reference/godot/modules/animation.md` and `physics.md` first).
- Unity references the clips `enemy_idle_breathing`, `enemy_run`, `enemy_walk_weak`, `enemy_attack_melee`, `enemy_attack_pistol`, `enemy_attack_smg`.

---

## Out of Scope

- Story 019: which gun each ranged enemy carries. Story 011: blood effects.

---

## Files

- `src/ai/enemy_visual.gd`, `src/ai/enemy_visual.tscn`, `src/ai/enemy_visual_data.gd`, `src/ai/enemy_pose_modifier.gd` (new; AnimationTree is built in code, no `enemy_animation_tree.tres`)
- `src/ai/enemy_base.gd`, `src/ai/melee_enemy.gd`, `src/ai/ranged_enemy.gd`, `src/ai/boss_enemy.gd`, `src/ai/enemy_data.gd`, `src/ai/ranged_gun_data.gd` (edited)
- `src/weapons/gun_feel.gd` (edited: blood + push on corpse hits)
- `src/waves/test_arena.gd` (debug exports), `src/waves/test_arena_enemy_models.tscn`, `test_arena_enemy_models_idle.tscn`, `_attack.tscn`, `_dead.tscn` (new capture scenes)
- `assets/data/enemies/visual_melee.tres`, `visual_ranged.tres`, `visual_boss.tres` (new); `melee/ranged/ranged_pistol/ranged_shotgun/ranged_smg/boss.tres` (edited: `visual`, `attack_clip`)
- `assets/art/enemies/` (enemy_base / enemy_a/b/c FBX, unchanged imports), `assets/art/textures/rs_textures_bot.png`, `assets/art/weapons/enemy_*.fbx` (used as-is)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-1..8**: Setup: a wave with all three types and a boss. Verify: idle, run, melee swing, ranged shots and reload, boss, hit reactions, deaths. Pass condition: no T-pose, no sliding feet, the hit lands with the swing, bodies fade and never block.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/`: each enemy type idle, mid-attack and dead + sign-off in `production/qa/evidence/story-020-enemy-models-evidence.md`

**Status**: [x] Created — `production/qa/evidence/story-020-enemy-models-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: `story-008-enemies-and-waves.md`, `story-011-shooting-feel.md` (same folder)
- Unlocks: None
