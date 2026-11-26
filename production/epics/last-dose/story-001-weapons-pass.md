# Story 001: Weapons pass: first-person view, pistol, SMG, shotgun

> **Epic**: Last Dose
> **Status**: Complete
> **Layer**: N/A (minimal)
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-25

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 1

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("First-person hitscan guns…"):*

- [ ] A first-person player walks and looks with keyboard and mouse on a flat test floor (the bare controller the guns need; polish is not part of this story).
- [ ] Pistol: semi-automatic hitscan, one shot per press, endless spare ammo.
- [ ] SMG: fires automatically while the button is held (a full-automatic pistol); spare ammo is limited.
- [ ] Shotgun: one press fires a spread of hitscan pellets, pushes the target back strongly, and does no less damage at long range (no falloff); spare ammo is limited.
- [ ] All three guns are available from the start and can be switched between.
- [ ] Firing an empty gun reloads it from spare ammo; the pistol always has spare ammo.
- [ ] A public method adds spare ammo to the SMG or shotgun (enemies call it when they drop ammo, story 008).
- [ ] A hit on anything exposing `take_hit(damage, direction)` calls it with the gun's damage; a hit on plain geometry does nothing visible yet.
- [ ] Gun values (damage, fire rate, magazine, starting spare ammo, pellets, spread, pushback) live in data resources, not in code.

---

## Implementation Notes

- Typed GDScript. Player as a `CharacterBody3D`; hitscan through `PhysicsDirectSpaceState3D.intersect_ray` (or a `RayCast3D`). Physics is Jolt (project default).
- Look every engine API up in `docs/engine-reference/godot/` first: Godot 4.7 is past the model's training data.
- Gun data as a custom `Resource` (`.tres` under `assets/data/weapons/`).
- Emit `ammo_changed`, `gun_switched` and `reloaded` signals; the HUD (005) and viewmodel (004) listen to them.
- `design/research/shooting-feel-gap-analysis.md` and `feel-notes-gap-analysis.md` record feel gaps seen in the Unity version of the shooting; read them before tuning.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the gun model, hands and animations (use a placeholder).
- Story 002: heart-rate effects on aim and speed.
- Story 008: enemies and their drops.

---

## Files

- `src/player/player_controller.gd`, `src/player/player.tscn`
- `src/player/target_dummy.gd`, `src/player/target_dummy.tscn`, `src/player/test_range.gd`, `src/player/test_range.tscn` (test range)
- `src/weapons/gun.gd`, `src/weapons/gun_data.gd`, `src/weapons/weapon_holder.gd`
- `assets/data/weapons/pistol.tres`, `smg.tres`, `shotgun.tres`
- `project.godot` (input actions)
- tests: waived at `qa.level` minimal

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: waived at `qa.level` minimal (advisory)

**Status**: [ ] Waived

---

## Dependencies

- Depends on: None
- Unlocks: `story-004`, `story-005`, `story-007`, `story-008`

## Completion Notes
**Completed**: 2026-11-25
**Criteria**: 6/9 verified (AC-4, 6, 7, 8 by headless probe `production/qa/evidence/story-001-weapons-pass/probe.txt`; AC-9 by reading the data files; AC-1 view seen in `01-test-range.png`) · deferred to play: walk and look feel, pistol semi-auto per press, SMG hold-to-fire, switching guns (input cannot be driven headless)
**Deviations**: None
**Test Evidence**: waived at qa.level minimal
**Run result**: OBSERVED — first-person view of the test range: floor, boxes, three dummies, placeholder gun, crosshair, "Pistol 12 / inf" label (`production/qa/evidence/story-001-weapons-pass/01-test-range.png`)
**Reviewed by**: self, no independent review (engine check by godot-specialist: 4 runtime bugs found and fixed)

## Calls beyond the design
- Gun stats in `assets/data/weapons/*.tres`: pistol 25 dmg, 8/s, mag 12, reload 0.8 s; SMG 12 dmg, 14/s, mag 30, spare 90/180, 2° spread, reload 1.2 s; shotgun 8 × 15 dmg, 1.2/s, mag 6, spare 24/48, 6° spread, reload 1.8 s · kept 2026-11-25 (autonomous run)
- Pushback passed as `direction × pushback` in `take_hit` (pistol 1, SMG 1, shotgun 4); 200 m hitscan range · kept 2026-11-25
- Move 5 m/s, jump 4.5 (player `@export`s); Esc releases the mouse, a click recaptures without firing; R reloads by hand · kept 2026-11-25
