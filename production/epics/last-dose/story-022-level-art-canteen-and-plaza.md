# Story 022: Canteen and plaza art, asset port and materials

> **Epic**: Last Dose
> **Status**: In Progress
> **Layer**: N/A (minimal)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-26

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 24
*(Unity reference: `Assets/_Game/Art`, `Assets/_Game/Scenes/Canteen_Art.unity`, `Plaza_Art.unity`, `Assets/ThirdParty`. The used files are already copied into `assets/` and listed in `docs/port/unity-asset-inventory.md`; the Unity materials, scenes and looks are in `docs/port/unity-reference/`. The Unity version wrote no shaders of its own (all 23 shader files are TextMesh Pro's). Likely bigger than L: split by level if it runs long.)*

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's MVP list ("Level art…") and Art direction (gritty low-poly, desaturated):*

- [ ] Every level asset listed in `docs/port/unity-asset-inventory.md` imports in Godot without errors; any asset dropped or added during the story is recorded there with the reason.
- [ ] `assets/credits.md` stays accurate: every asset added in the story gets its row; an asset with no known licence is not added.
- [ ] The canteen scene uses the canteen model and static props with colliders, lights, environment and sky; navigation is baked from its geometry; tables and benches are separate bodies (needed by stories 017 and 021).
- [ ] The plaza scene does the same for the plaza.
- [ ] Each Unity material the levels use (originals in `docs/port/unity-reference/materials/`) is rebuilt as a Godot material from the copied textures and colours, or dropped, with one line in Implementation Notes saying which and why.
- [ ] In play each level looks like the Unity version: a screenshot from the same spot in Unity and in Godot shows the same layout, palette and mood.
- [ ] The look stays gritty, low-poly and desaturated.
- [ ] Each level holds 60 fps on the developer's PC with a full wave (the performance budget in `technical-preferences.md`).

---

## Implementation Notes

- Import formats: FBX/glTF for models, PNG for textures, WAV/OGG for audio; Godot import settings per asset type.
- Replace story 009's blockout rooms in place; keep the spawn points, firing spots and exit where story 009 put them.
- FBX embedded texture paths point at Unity folders, so reassign materials in Godot. Check any shader syntax against `docs/engine-reference/godot/modules/rendering.md` before writing one.
- Light positions and settings: read them from `docs/port/unity-reference/scenes/Canteen_Art.unity` and `Plaza_Art.unity`.
- Material list: the level FBXs use two Unity materials. `envi.mat` was rebuilt as `assets/art/materials/envi.tres` (texture `envi.png`, newly copied); `Placeholders.mat` (FBX slot `bot`) was rebuilt as `assets/art/materials/bot.tres` (texture `rs_textures_bot.png`). Both are white, roughness 1, metallic 0, nearest filtering, double-sided because the FBX winding is inverted, and both are assigned through the FBX import settings. `plaza_main` maps both slots to envi, as Unity did. `LevelExit.mat` is not rebuilt here: story 009's exit already draws it. No level material was dropped.

---

## Out of Scope

- Story 012: audio behaviour (only the files come over here). Story 020: enemy models.

---

## Files

- `src/levels/level_base.gd`
- `src/levels/canteen.tscn`
- `src/levels/plaza.tscn`
- `src/levels/test_canteen_art_view.tscn`
- `src/levels/test_canteen_art_overview.tscn`
- `src/levels/test_plaza_art_view.tscn`
- `src/levels/test_plaza_art_overview.tscn`
- `assets/art/materials/envi.tres`
- `assets/art/materials/bot.tres`
- `assets/data/levels/railing_push.tres`
- `assets/art/textures/envi.png`
- `assets/art/textures/envi.png.import`
- `assets/art/levels/canteen/canteen_door_enemy_a.fbx.import`
- `assets/art/levels/canteen/canteen_door_enemy_b.fbx.import`
- `assets/art/levels/canteen/canteen_dynamic_bottle.fbx.import`
- `assets/art/levels/canteen/canteen_dynamic_bowl.fbx.import`
- `assets/art/levels/canteen/canteen_dynamic_table.fbx.import`
- `assets/art/levels/canteen/canteen_fixed_benches.fbx.import`
- `assets/art/levels/canteen/canteen_main.fbx.import`
- `assets/art/levels/plaza/plaza_dynamic_bin.fbx.import`
- `assets/art/levels/plaza/plaza_dynamic_railing_a.fbx.import`
- `assets/art/levels/plaza/plaza_dynamic_railing_b.fbx.import`
- `assets/art/levels/plaza/plaza_dynamic_railing_c.fbx.import`
- `assets/art/levels/plaza/plaza_main.fbx.import`
- `assets/art/levels/plaza/plaza_static_debris.fbx.import`
- `assets/art/levels/plaza/plaza_static_pillar.fbx.import`
- `docs/port/unity-asset-inventory.md`
- `production/session-logs/build-notes.md` (Story 022 section)

## QA Test Cases

**Visual/Feel verification steps:**

- **AC-3..7**: Setup: open each level in Unity and in Godot. Verify: same spot, same view. Pass condition: layout and mood match, no pink or missing materials, no navigation holes.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: retained screenshots in `production/qa/evidence/`: each level from the same spots as Unity, side by side + sign-off in `production/qa/evidence/story-022-level-art-evidence.md`

**Status**: [x] Created: `production/qa/evidence/story-022-level-art-evidence.md` (sign-off rows open)

---

## Dependencies

- Depends on: `production/epics/last-dose/story-009-levels-and-rotation.md`
- Unlocks: None
