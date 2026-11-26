# Unity → Godot asset port inventory

> **Source**: `E:/Unity Project/fps-substance/Assets/` (Unity 6000.3.8f1, URP)
> **Generated**: 2026-11-25, by tracing GUID references from the current scenes and prefabs
> (`Game`, `Canteen_Art/Layout`, `Plaza_Art/Layout`, `Boss`, `Melee`, `Ranged`, dose pickups, `StatusBar`),
> plus names found in the game's data JSON and code.
> **Credits**: `assets/credits.md`.

## Summary

| Group | Files | What happens to it |
|---|---|---|
| Copied into `assets/` (models, textures, audio) | 155 | Godot imports them when the editor opens |
| Pack licence files copied | 2 | Kept next to each pack |
| Copied to `docs/port/unity-reference/` for reference | 94 | Unity text formats and data; `.gdignore` keeps Godot from importing them |
| Not copied: unused by the current game | 40 | Listed below, still in the Unity project |
| Not copied: Unity-only | see below | Rebuilt in Godot by the story named |

File names are converted to snake_case (the project's naming rule); the table maps each one back to its Unity name.

## Copied assets

### Enemy models (4)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Art/enemy/enemy_a.fbx` | `assets/art/enemies/enemy_a.fbx` | in-house (gankdroid) | 020 |
| `_Game/Art/enemy/enemy_b.fbx` | `assets/art/enemies/enemy_b.fbx` | in-house (gankdroid) | 020 |
| `_Game/Art/enemy/enemy_base.fbx` | `assets/art/enemies/enemy_base.fbx` | in-house (gankdroid) | 020 |
| `_Game/Art/enemy/enemy_c.fbx` | `assets/art/enemies/enemy_c.fbx` | in-house (gankdroid) | 020 |

### Level models (14)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Art/envi/canteen_door_enemy_a.fbx` | `assets/art/levels/canteen/canteen_door_enemy_a.fbx` | in-house (gankdroid) | 022, 019 |
| `_Game/Art/envi/canteen_door_enemy_b.fbx` | `assets/art/levels/canteen/canteen_door_enemy_b.fbx` | in-house (gankdroid) | 022, 019 |
| `_Game/Art/envi/canteen_dynamic_bottle.fbx` | `assets/art/levels/canteen/canteen_dynamic_bottle.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/canteen_dynamic_bowl.fbx` | `assets/art/levels/canteen/canteen_dynamic_bowl.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/canteen_dynamic_table.fbx` | `assets/art/levels/canteen/canteen_dynamic_table.fbx` | in-house (gankdroid) | 022, 017, 021 |
| `_Game/Art/envi/canteen_fixed_benches.fbx` | `assets/art/levels/canteen/canteen_fixed_benches.fbx` | in-house (gankdroid) | 022, 017, 021 |
| `_Game/Art/envi/canteen_main.fbx` | `assets/art/levels/canteen/canteen_main.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/plaza_dynamic_bin.fbx` | `assets/art/levels/plaza/plaza_dynamic_bin.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/plaza_dynamic_railing_a.fbx` | `assets/art/levels/plaza/plaza_dynamic_railing_a.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/plaza_dynamic_railing_b.fbx` | `assets/art/levels/plaza/plaza_dynamic_railing_b.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/plaza_dynamic_railing_c.fbx` | `assets/art/levels/plaza/plaza_dynamic_railing_c.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/plaza_main.fbx` | `assets/art/levels/plaza/plaza_main.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/plaza_static_debris.fbx` | `assets/art/levels/plaza/plaza_static_debris.fbx` | in-house (gankdroid) | 022 |
| `_Game/Art/envi/plaza_static_pillar.fbx` | `assets/art/levels/plaza/plaza_static_pillar.fbx` | in-house (gankdroid) | 022 |

### Props (5)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Art/props/drop_ammo.fbx` | `assets/art/props/drop_ammo.fbx` | in-house (gankdroid) | 008 (drops) |
| `_Game/Art/props/drop_kopi.fbx` | `assets/art/props/drop_kopi.fbx` | in-house (gankdroid) | 008 (drops) |
| `_Game/Art/props/drop_rokok.fbx` | `assets/art/props/drop_rokok.fbx` | in-house (gankdroid) | 008 (drops) |
| `_Game/Art/props/player_kopi.fbx` | `assets/art/props/player_kopi.fbx` | in-house (gankdroid) | 004 |
| `_Game/Art/props/player_rokok.fbx` | `assets/art/props/player_rokok.fbx` | in-house (gankdroid) | 004 |

### Enemy weapon models (4)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Art/weapons/EnemyKayu.fbx` | `assets/art/weapons/enemy_kayu.fbx` | in-house (gankdroid) | 019, 020, 001 |
| `_Game/Art/weapons/EnemyPistol.fbx` | `assets/art/weapons/enemy_pistol.fbx` | in-house (gankdroid) | 019, 020, 001 |
| `_Game/Art/weapons/EnemyShotgun.fbx` | `assets/art/weapons/enemy_shotgun.fbx` | in-house (gankdroid) | 019, 020, 001 |
| `_Game/Art/weapons/EnemySmg.fbx` | `assets/art/weapons/enemy_smg.fbx` | in-house (gankdroid) | 019, 020, 001 |

### Textures (3)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Art/Textures_new/gj+26_manprop.png` | `assets/art/textures/gj_26_manprop.png` | in-house (gankdroid) | 022, 020 |
| `_Game/Art/Textures_new/rs_textures_bot.png` | `assets/art/textures/rs_textures_bot.png` | in-house (gankdroid) | 022, 020 |
| `_Game/Art/Textures_new/envi.png` | `assets/art/textures/envi.png` | in-house (gankdroid) | 022 (added 2026-11-26: the level FBXs' `envi` material is Unity `envi.mat`, whose base map is this texture; the generator missed it because the FBX material remap goes through the FBX .meta) |

### Fonts (1, added 2026-11-26)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `TextMesh Pro/Fonts/LiberationSans.ttf` (TMP default "LiberationSans SDF", used by the StatusBar) | `assets/fonts/liberation_sans.ttf` (licence beside it: `liberation_sans_ofl.txt`) | SIL OFL 1.1 (Red Hat) | 005 (HUD parity pass) |

### HUD art (36)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Art/UI/hud_bevel_tile.png` | `assets/art/ui/hud/hud_bevel_tile.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_0.png` | `assets/art/ui/hud/hud_face_0.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_0_flinch.png` | `assets/art/ui/hud/hud_face_0_flinch.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_1.png` | `assets/art/ui/hud/hud_face_1.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_1_flinch.png` | `assets/art/ui/hud/hud_face_1_flinch.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_2.png` | `assets/art/ui/hud/hud_face_2.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_2_flinch.png` | `assets/art/ui/hud/hud_face_2_flinch.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_3.png` | `assets/art/ui/hud/hud_face_3.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_3_flinch.png` | `assets/art/ui/hud/hud_face_3_flinch.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_4.png` | `assets/art/ui/hud/hud_face_4.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_face_4_flinch.png` | `assets/art/ui/hud/hud_face_4_flinch.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_fill_white.png` | `assets/art/ui/hud/hud_fill_white.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_00_0.png` | `assets/art/ui/hud/hud_glyph_00_0.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_01_1.png` | `assets/art/ui/hud/hud_glyph_01_1.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_02_2.png` | `assets/art/ui/hud/hud_glyph_02_2.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_03_3.png` | `assets/art/ui/hud/hud_glyph_03_3.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_04_4.png` | `assets/art/ui/hud/hud_glyph_04_4.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_05_5.png` | `assets/art/ui/hud/hud_glyph_05_5.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_06_6.png` | `assets/art/ui/hud/hud_glyph_06_6.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_07_7.png` | `assets/art/ui/hud/hud_glyph_07_7.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_08_8.png` | `assets/art/ui/hud/hud_glyph_08_8.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_09_9.png` | `assets/art/ui/hud/hud_glyph_09_9.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_10_slash.png` | `assets/art/ui/hud/hud_glyph_10_slash.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_11_colon.png` | `assets/art/ui/hud/hud_glyph_11_colon.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_12_infinity.png` | `assets/art/ui/hud/hud_glyph_12_infinity.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_13_left.png` | `assets/art/ui/hud/hud_glyph_13_left.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_14_right.png` | `assets/art/ui/hud/hud_glyph_14_right.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_15_minus.png` | `assets/art/ui/hud/hud_glyph_15_minus.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_glyph_16_dot.png` | `assets/art/ui/hud/hud_glyph_16_dot.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_icon_cigarette.png` | `assets/art/ui/hud/hud_icon_cigarette.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_icon_coffee.png` | `assets/art/ui/hud/hud_icon_coffee.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_icon_heart.png` | `assets/art/ui/hud/hud_icon_heart.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_icon_pistol.png` | `assets/art/ui/hud/hud_icon_pistol.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_icon_shotgun.png` | `assets/art/ui/hud/hud_icon_shotgun.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_icon_smg.png` | `assets/art/ui/hud/hud_icon_smg.png` | in-house (TakeMeGH) | 005 |
| `_Game/Art/UI/hud_pulse_strip.png` | `assets/art/ui/hud/hud_pulse_strip.png` | in-house (TakeMeGH) | 005 |

### Music (2)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Audio/BGM/bgm_boss.wav` | `assets/audio/music/bgm_boss.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/BGM/bgm_combat.wav` | `assets/audio/music/bgm_combat.wav` | in-house (navisraditya) | 012 |

### Sound effects (in-house and synthesised) (17)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `_Game/Audio/Placeholder/sfx_dry_click.wav` | `assets/audio/sfx/placeholder/sfx_dry_click.wav` | project-synthesised | 012 |
| `_Game/Audio/Placeholder/sfx_shell_load.wav` | `assets/audio/sfx/placeholder/sfx_shell_load.wav` | project-synthesised | 012 |
| `_Game/Audio/SFX/ENEMY-SWARMING.wav` | `assets/audio/sfx/enemy_swarming.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/SMG.wav` | `assets/audio/sfx/smg.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/Substance Taken.wav` | `assets/audio/sfx/substance_taken.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/darah rendah.wav` | `assets/audio/sfx/darah_rendah.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/darah tinggi.wav` | `assets/audio/sfx/darah_tinggi.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/drop from heights.wav` | `assets/audio/sfx/drop_from_heights.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/enemy dead.wav` | `assets/audio/sfx/enemy_dead.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/footstep for walking.wav` | `assets/audio/sfx/footstep_for_walking.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/ngopi.wav` | `assets/audio/sfx/ngopi.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/ngudud.wav` | `assets/audio/sfx/ngudud.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/pistol.wav` | `assets/audio/sfx/pistol.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/SFX/shotgun.wav` | `assets/audio/sfx/shotgun.wav` | in-house (navisraditya) | 012 |
| `_Game/Audio/Synth/sfx_dose_pickup.wav` | `assets/audio/sfx/synth/sfx_dose_pickup.wav` | project-synthesised | 012 |
| `_Game/Audio/Synth/sfx_melee_hit.wav` | `assets/audio/sfx/synth/sfx_melee_hit.wav` | project-synthesised | 012 |
| `_Game/Audio/Synth/shotgun_thump_01.wav` | `assets/audio/sfx/synth/shotgun_thump_01.wav` | project-synthesised | 012 |

### Third-party packs (CC0) (70)

| Unity source (`Assets/…`) | Godot destination | Licence | Story |
|---|---|---|---|
| `ThirdParty/Drillimpact_PSXFirstPersonArms/arms_01.png` | `assets/third_party/drillimpact_psx_first_person_arms/arms_01.png` | CC0 (Drillimpact_PSXFirstPersonArms) | 011 |
| `ThirdParty/Drillimpact_PSXFirstPersonArms/arms_gloves_01.png` | `assets/third_party/drillimpact_psx_first_person_arms/arms_gloves_01.png` | CC0 (Drillimpact_PSXFirstPersonArms) | 011 |
| `ThirdParty/Drillimpact_PSXFirstPersonArms/arms_rig.fbx` | `assets/third_party/drillimpact_psx_first_person_arms/arms_rig.fbx` | CC0 (Drillimpact_PSXFirstPersonArms) | 011 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_tail_01.wav` | `assets/third_party/free_firearm_sound_library/layers/pistol_tail_01.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_tail_02.wav` | `assets/third_party/free_firearm_sound_library/layers/pistol_tail_02.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_tail_03.wav` | `assets/third_party/free_firearm_sound_library/layers/pistol_tail_03.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_tail_04.wav` | `assets/third_party/free_firearm_sound_library/layers/pistol_tail_04.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_close_01.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_close_01.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_close_02.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_close_02.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_close_03.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_close_03.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_close_04.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_close_04.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_tail_01.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_tail_01.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_tail_02.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_tail_02.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_tail_03.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_tail_03.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/shotgun_tail_04.wav` | `assets/third_party/free_firearm_sound_library/layers/shotgun_tail_04.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_tail_01.wav` | `assets/third_party/free_firearm_sound_library/layers/smg_tail_01.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_tail_02.wav` | `assets/third_party/free_firearm_sound_library/layers/smg_tail_02.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_tail_03.wav` | `assets/third_party/free_firearm_sound_library/layers/smg_tail_03.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_tail_04.wav` | `assets/third_party/free_firearm_sound_library/layers/smg_tail_04.wav` | CC0 (FreeFirearmSoundLibrary) | 012 |
| `ThirdParty/IndependentNu_ExtremeSplatter/kill_burst_01.wav` | `assets/third_party/independent_nu_extreme_splatter/kill_burst_01.wav` | CC0 (IndependentNu_ExtremeSplatter) | 012 |
| `ThirdParty/IndependentNu_ExtremeSplatter/kill_burst_02.wav` | `assets/third_party/independent_nu_extreme_splatter/kill_burst_02.wav` | CC0 (IndependentNu_ExtremeSplatter) | 012 |
| `ThirdParty/IndependentNu_ExtremeSplatter/kill_burst_03.wav` | `assets/third_party/independent_nu_extreme_splatter/kill_burst_03.wav` | CC0 (IndependentNu_ExtremeSplatter) | 012 |
| `ThirdParty/IndependentNu_ExtremeSplatter/kill_burst_04.wav` | `assets/third_party/independent_nu_extreme_splatter/kill_burst_04.wav` | CC0 (IndependentNu_ExtremeSplatter) | 012 |
| `ThirdParty/IndependentNu_WetSquish/flesh_hit_01.wav` | `assets/third_party/independent_nu_wet_squish/flesh_hit_01.wav` | CC0 (IndependentNu_WetSquish) | 012 |
| `ThirdParty/IndependentNu_WetSquish/flesh_hit_02.wav` | `assets/third_party/independent_nu_wet_squish/flesh_hit_02.wav` | CC0 (IndependentNu_WetSquish) | 012 |
| `ThirdParty/IndependentNu_WetSquish/flesh_hit_03.wav` | `assets/third_party/independent_nu_wet_squish/flesh_hit_03.wav` | CC0 (IndependentNu_WetSquish) | 012 |
| `ThirdParty/IndependentNu_WetSquish/flesh_hit_04.wav` | `assets/third_party/independent_nu_wet_squish/flesh_hit_04.wav` | CC0 (IndependentNu_WetSquish) | 012 |
| `ThirdParty/IndependentNu_WetSquish/flesh_hit_05.wav` | `assets/third_party/independent_nu_wet_squish/flesh_hit_05.wav` | CC0 (IndependentNu_WetSquish) | 012 |
| `ThirdParty/IndependentNu_WetSquish/flesh_hit_06.wav` | `assets/third_party/independent_nu_wet_squish/flesh_hit_06.wav` | CC0 (IndependentNu_WetSquish) | 012 |
| `ThirdParty/Kenney_ParticlePack/dirt_01.png` | `assets/third_party/kenney_particle_pack/dirt_01.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/dirt_02.png` | `assets/third_party/kenney_particle_pack/dirt_02.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/flare_01.png` | `assets/third_party/kenney_particle_pack/flare_01.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/muzzle_01.png` | `assets/third_party/kenney_particle_pack/muzzle_01.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/muzzle_02.png` | `assets/third_party/kenney_particle_pack/muzzle_02.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/muzzle_03.png` | `assets/third_party/kenney_particle_pack/muzzle_03.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/muzzle_04.png` | `assets/third_party/kenney_particle_pack/muzzle_04.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/muzzle_05.png` | `assets/third_party/kenney_particle_pack/muzzle_05.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/scorch_01.png` | `assets/third_party/kenney_particle_pack/scorch_01.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/scorch_02.png` | `assets/third_party/kenney_particle_pack/scorch_02.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/scorch_03.png` | `assets/third_party/kenney_particle_pack/scorch_03.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/smoke_01.png` | `assets/third_party/kenney_particle_pack/smoke_01.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/smoke_03.png` | `assets/third_party/kenney_particle_pack/smoke_03.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/smoke_04.png` | `assets/third_party/kenney_particle_pack/smoke_04.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/spark_01.png` | `assets/third_party/kenney_particle_pack/spark_01.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/spark_04.png` | `assets/third_party/kenney_particle_pack/spark_04.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/spark_05.png` | `assets/third_party/kenney_particle_pack/spark_05.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/Kenney_ParticlePack/spark_07.png` | `assets/third_party/kenney_particle_pack/spark_07.png` | CC0 (Kenney_ParticlePack) | 011 |
| `ThirdParty/LFA_EquipmentClicks/dry_click_01.wav` | `assets/third_party/lfa_equipment_clicks/dry_click_01.wav` | CC0 (LFA_EquipmentClicks) | 012 |
| `ThirdParty/LFA_EquipmentClicks/dry_click_02.wav` | `assets/third_party/lfa_equipment_clicks/dry_click_02.wav` | CC0 (LFA_EquipmentClicks) | 012 |
| `ThirdParty/Quaternius_UltimateGunPack/Pistol_1.fbx` | `assets/third_party/quaternius_ultimate_gun_pack/Pistol_1.fbx` | CC0 (Quaternius_UltimateGunPack) | 001 (placeholder guns) |
| `ThirdParty/Quaternius_UltimateGunPack/Shotgun_1.fbx` | `assets/third_party/quaternius_ultimate_gun_pack/Shotgun_1.fbx` | CC0 (Quaternius_UltimateGunPack) | 001 (placeholder guns) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_hit_05.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_hit_05.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_hit_08.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_hit_08.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_hit_09.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_hit_09.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_hit_10.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_hit_10.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_hit_11.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_hit_11.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_hit_13.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_hit_13.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_rock_breaking_03.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_rock_breaking_03.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/Rubberduck_BreakingFallingHit/bfh1_rock_hit_01.ogg` | `assets/third_party/rubberduck_breaking_falling_hit/bfh1_rock_hit_01.ogg` | CC0 (Rubberduck_BreakingFallingHit) | 012, 008 (armour break) |
| `ThirdParty/SpringySpringo_GunReload/smg_bolt_rack_01.wav` | `assets/third_party/springy_springo_gun_reload/smg_bolt_rack_01.wav` | CC0 (SpringySpringo_GunReload) | 012 |
| `ThirdParty/SpringySpringo_GunReload/smg_mag_in_01.wav` | `assets/third_party/springy_springo_gun_reload/smg_mag_in_01.wav` | CC0 (SpringySpringo_GunReload) | 012 |
| `ThirdParty/SpringySpringo_GunReload/smg_mag_out_01.wav` | `assets/third_party/springy_springo_gun_reload/smg_mag_out_01.wav` | CC0 (SpringySpringo_GunReload) | 012 |
| `ThirdParty/zer0sol_HandgunReload/pistol_mag_in_01.wav` | `assets/third_party/zer0sol_handgun_reload/pistol_mag_in_01.wav` | CC0 (zer0sol_HandgunReload) | 012 |
| `ThirdParty/zer0sol_HandgunReload/pistol_mag_out_01.wav` | `assets/third_party/zer0sol_handgun_reload/pistol_mag_out_01.wav` | CC0 (zer0sol_HandgunReload) | 012 |
| `ThirdParty/zer0sol_HandgunReload/pistol_slide_rack_01.wav` | `assets/third_party/zer0sol_handgun_reload/pistol_slide_rack_01.wav` | CC0 (zer0sol_HandgunReload) | 012 |
| `ThirdParty/zer0sol_ShotgunReload/shotgun_pump_01.wav` | `assets/third_party/zer0sol_shotgun_reload/shotgun_pump_01.wav` | CC0 (zer0sol_ShotgunReload) | 012 |
| `ThirdParty/zer0sol_ShotgunReload/shotgun_shell_01.wav` | `assets/third_party/zer0sol_shotgun_reload/shotgun_shell_01.wav` | CC0 (zer0sol_ShotgunReload) | 012 |
| `ThirdParty/zer0sol_ShotgunReload/shotgun_shell_02.wav` | `assets/third_party/zer0sol_shotgun_reload/shotgun_shell_02.wav` | CC0 (zer0sol_ShotgunReload) | 012 |
| `ThirdParty/zer0sol_ShotgunReload/shotgun_shell_03.wav` | `assets/third_party/zer0sol_shotgun_reload/shotgun_shell_03.wav` | CC0 (zer0sol_ShotgunReload) | 012 |
| `ThirdParty/zer0sol_ShotgunReload/shotgun_shell_04.wav` | `assets/third_party/zer0sol_shotgun_reload/shotgun_shell_04.wav` | CC0 (zer0sol_ShotgunReload) | 012 |

## Reference files (not game assets)

| Unity source | Copied to | Use |
|---|---|---|
| `_Game/Data/abilities.json` | `docs/port/unity-reference/data/abilities.json` | tuning values for every story's data resource |
| `_Game/Data/ability_look.json` | `docs/port/unity-reference/data/ability_look.json` | tuning values for every story's data resource |
| `_Game/Data/ammo_drops.json` | `docs/port/unity-reference/data/ammo_drops.json` | tuning values for every story's data resource |
| `_Game/Data/arms_substance_fx.json` | `docs/port/unity-reference/data/arms_substance_fx.json` | tuning values for every story's data resource |
| `_Game/Data/arms_substances.json` | `docs/port/unity-reference/data/arms_substances.json` | tuning values for every story's data resource |
| `_Game/Data/audio_impacts.json` | `docs/port/unity-reference/data/audio_impacts.json` | tuning values for every story's data resource |
| `_Game/Data/bgm_audio.json` | `docs/port/unity-reference/data/bgm_audio.json` | tuning values for every story's data resource |
| `_Game/Data/consume_audio.json` | `docs/port/unity-reference/data/consume_audio.json` | tuning values for every story's data resource |
| `_Game/Data/dose_drops.json` | `docs/port/unity-reference/data/dose_drops.json` | tuning values for every story's data resource |
| `_Game/Data/effects_blood.json` | `docs/port/unity-reference/data/effects_blood.json` | tuning values for every story's data resource |
| `_Game/Data/effects_impact.json` | `docs/port/unity-reference/data/effects_impact.json` | tuning values for every story's data resource |
| `_Game/Data/effects_kill.json` | `docs/port/unity-reference/data/effects_kill.json` | tuning values for every story's data resource |
| `_Game/Data/effects_ragdoll.json` | `docs/port/unity-reference/data/effects_ragdoll.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_boss.json` | `docs/port/unity-reference/data/enemies_boss.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_boss_anim.json` | `docs/port/unity-reference/data/enemies_boss_anim.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_melee.json` | `docs/port/unity-reference/data/enemies_melee.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_melee_anim.json` | `docs/port/unity-reference/data/enemies_melee_anim.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_ranged.json` | `docs/port/unity-reference/data/enemies_ranged.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_ranged_anim.json` | `docs/port/unity-reference/data/enemies_ranged_anim.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_skins.json` | `docs/port/unity-reference/data/enemies_skins.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_zombie.json` | `docs/port/unity-reference/data/enemies_zombie.json` | tuning values for every story's data resource |
| `_Game/Data/enemies_zombie_anim.json` | `docs/port/unity-reference/data/enemies_zombie_anim.json` | tuning values for every story's data resource |
| `_Game/Data/event_audio.json` | `docs/port/unity-reference/data/event_audio.json` | tuning values for every story's data resource |
| `_Game/Data/heart_rate.json` | `docs/port/unity-reference/data/heart_rate.json` | tuning values for every story's data resource |
| `_Game/Data/heart_rate_audio.json` | `docs/port/unity-reference/data/heart_rate_audio.json` | tuning values for every story's data resource |
| `_Game/Data/heart_rate_screen.json` | `docs/port/unity-reference/data/heart_rate_screen.json` | tuning values for every story's data resource |
| `_Game/Data/hit_direction.json` | `docs/port/unity-reference/data/hit_direction.json` | tuning values for every story's data resource |
| `_Game/Data/hud.json` | `docs/port/unity-reference/data/hud.json` | tuning values for every story's data resource |
| `_Game/Data/level_notice.json` | `docs/port/unity-reference/data/level_notice.json` | tuning values for every story's data resource |
| `_Game/Data/levels.json` | `docs/port/unity-reference/data/levels.json` | tuning values for every story's data resource |
| `_Game/Data/player_comfort.json` | `docs/port/unity-reference/data/player_comfort.json` | tuning values for every story's data resource |
| `_Game/Data/player_death.json` | `docs/port/unity-reference/data/player_death.json` | tuning values for every story's data resource |
| `_Game/Data/player_dive.json` | `docs/port/unity-reference/data/player_dive.json` | tuning values for every story's data resource |
| `_Game/Data/player_movement.json` | `docs/port/unity-reference/data/player_movement.json` | tuning values for every story's data resource |
| `_Game/Data/run.json` | `docs/port/unity-reference/data/run.json` | tuning values for every story's data resource |
| `_Game/Data/substances.json` | `docs/port/unity-reference/data/substances.json` | tuning values for every story's data resource |
| `_Game/Data/tutorial.json` | `docs/port/unity-reference/data/tutorial.json` | tuning values for every story's data resource |
| `_Game/Data/waves_arena.json` | `docs/port/unity-reference/data/waves_arena.json` | tuning values for every story's data resource |
| `_Game/Data/weapons_gun.json` | `docs/port/unity-reference/data/weapons_gun.json` | tuning values for every story's data resource |
| `_Game/Data/weapons_gun_feel.json` | `docs/port/unity-reference/data/weapons_gun_feel.json` | tuning values for every story's data resource |
| `_Game/Data/weapons_rifle.json` | `docs/port/unity-reference/data/weapons_rifle.json` | tuning values for every story's data resource |
| `_Game/Data/weapons_rifle_feel.json` | `docs/port/unity-reference/data/weapons_rifle_feel.json` | tuning values for every story's data resource |
| `_Game/Data/weapons_shotgun.json` | `docs/port/unity-reference/data/weapons_shotgun.json` | tuning values for every story's data resource |
| `_Game/Data/weapons_shotgun_feel.json` | `docs/port/unity-reference/data/weapons_shotgun_feel.json` | tuning values for every story's data resource |
| `InputSystem_Actions.inputactions` | `docs/port/unity-reference/input/InputSystem_Actions.inputactions` | key bindings for the Input Map |
| `_Game/Scenes/Game.unity` | `docs/port/unity-reference/scenes/Game.unity` | positions of spawn points, firing spots, player start, exit, lights |
| `_Game/Scenes/Canteen_Art.unity` | `docs/port/unity-reference/scenes/Canteen_Art.unity` | positions of spawn points, firing spots, player start, exit, lights |
| `_Game/Scenes/Canteen_Layout.unity` | `docs/port/unity-reference/scenes/Canteen_Layout.unity` | positions of spawn points, firing spots, player start, exit, lights |
| `_Game/Scenes/Plaza_Art.unity` | `docs/port/unity-reference/scenes/Plaza_Art.unity` | positions of spawn points, firing spots, player start, exit, lights |
| `_Game/Scenes/Plaza_Layout.unity` | `docs/port/unity-reference/scenes/Plaza_Layout.unity` | positions of spawn points, firing spots, player start, exit, lights |
| `_Game/Art/Materials/AmmoPickup.mat` | `docs/port/unity-reference/materials/AmmoPickup.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsCigaretteEmber.mat` | `docs/port/unity-reference/materials/ArmsCigaretteEmber.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsCigaretteFilter.mat` | `docs/port/unity-reference/materials/ArmsCigaretteFilter.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsCigarettePaper.mat` | `docs/port/unity-reference/materials/ArmsCigarettePaper.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsCoffeeCupBody.mat` | `docs/port/unity-reference/materials/ArmsCoffeeCupBody.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsCoffeeCupLid.mat` | `docs/port/unity-reference/materials/ArmsCoffeeCupLid.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsCoffeeCupSleeve.mat` | `docs/port/unity-reference/materials/ArmsCoffeeCupSleeve.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsMagazine.mat` | `docs/port/unity-reference/materials/ArmsMagazine.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ArmsShell.mat` | `docs/port/unity-reference/materials/ArmsShell.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/BossBody_0.mat` | `docs/port/unity-reference/materials/BossBody_0.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/BossPlate.mat` | `docs/port/unity-reference/materials/BossPlate.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/BulletHole.mat` | `docs/port/unity-reference/materials/BulletHole.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/Casing.mat` | `docs/port/unity-reference/materials/Casing.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/DosePickupGlow_cigarette.mat` | `docs/port/unity-reference/materials/DosePickupGlow_cigarette.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/DosePickupGlow_coffee.mat` | `docs/port/unity-reference/materials/DosePickupGlow_coffee.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/DosePickupGlow_weed.mat` | `docs/port/unity-reference/materials/DosePickupGlow_weed.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/DosePickup_cigarette.mat` | `docs/port/unity-reference/materials/DosePickup_cigarette.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/DosePickup_coffee.mat` | `docs/port/unity-reference/materials/DosePickup_coffee.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/DosePickup_weed.mat` | `docs/port/unity-reference/materials/DosePickup_weed.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/EnemyBodyFade.mat` | `docs/port/unity-reference/materials/EnemyBodyFade.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/EnemyBossBody.mat` | `docs/port/unity-reference/materials/EnemyBossBody.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/EnemySkinFade_manprop.mat` | `docs/port/unity-reference/materials/EnemySkinFade_manprop.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/Human.mat` | `docs/port/unity-reference/materials/Human.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/HumanFade.mat` | `docs/port/unity-reference/materials/HumanFade.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ImpactAdditive.mat` | `docs/port/unity-reference/materials/ImpactAdditive.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ImpactAlpha.mat` | `docs/port/unity-reference/materials/ImpactAlpha.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/LevelExit.mat` | `docs/port/unity-reference/materials/LevelExit.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/MuzzleFlash.mat` | `docs/port/unity-reference/materials/MuzzleFlash.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ViewmodelArms.mat` | `docs/port/unity-reference/materials/ViewmodelArms.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/Zombie.mat` | `docs/port/unity-reference/materials/Zombie.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ZombieFade.mat` | `docs/port/unity-reference/materials/ZombieFade.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Materials/ZombieTemp.mat` | `docs/port/unity-reference/materials/ZombieTemp.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Material_new/envi.mat` | `docs/port/unity-reference/materials/envi.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Material_new/manprop.mat` | `docs/port/unity-reference/materials/manprop.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Material_new/manpropUnlit.mat` | `docs/port/unity-reference/materials/manpropUnlit.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Art/Material_new/Placeholders.mat` | `docs/port/unity-reference/materials/Placeholders.mat` | colours and texture slots to rebuild as Godot materials |
| `_Game/Settings/AbilityLook.asset` | `docs/port/unity-reference/looks/AbilityLook.asset` | screen-look values for stories 013 and 014 |
| `_Game/Settings/HeartRateLook.asset` | `docs/port/unity-reference/looks/HeartRateLook.asset` | screen-look values for stories 013 and 014 |
| `Settings/DefaultVolumeProfile.asset` | `docs/port/unity-reference/looks/DefaultVolumeProfile.asset` | screen-look values for stories 013 and 014 |
| `_Game/Animation/Enemy.controller` | `docs/port/unity-reference/animation/Enemy.controller` | state machine and upper-body mask to rebuild as an AnimationTree |
| `_Game/Animation/EnemyBoss.overrideController` | `docs/port/unity-reference/animation/EnemyBoss.overrideController` | state machine and upper-body mask to rebuild as an AnimationTree |
| `_Game/Animation/EnemyRanged.overrideController` | `docs/port/unity-reference/animation/EnemyRanged.overrideController` | state machine and upper-body mask to rebuild as an AnimationTree |
| `_Game/Animation/EnemyUpperBody.mask` | `docs/port/unity-reference/animation/EnemyUpperBody.mask` | state machine and upper-body mask to rebuild as an AnimationTree |
| `ThirdParty/CREDITS.md` | `docs/port/unity-reference/CREDITS-unity.md` | the Unity credits file, source for assets/credits.md |

## Not copied: unused by the current game

Nothing in the current scenes, prefabs, data or code reaches these. They stay in the Unity project; copy one by hand if a story wants it.

| Unity source | Licence | Likely reason |
|---|---|---|
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_close_01.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_close_02.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_close_03.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/pistol_close_04.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_close_01.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_close_02.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_close_03.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_close_04.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_tail_01.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_tail_02.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_tail_03.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/rifle_tail_04.wav` | CC0 (FreeFirearmSoundLibrary) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_close_01.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_close_02.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_close_03.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/Layers/smg_close_04.wav` | CC0 (FreeFirearmSoundLibrary) | old crack layer off by default (Unity story 044) |
| `ThirdParty/FreeFirearmSoundLibrary/gunshot_1911_near.wav` | CC0 (FreeFirearmSoundLibrary) | replaced by the Layers/ takes, then by the new SFX |
| `ThirdParty/FreeFirearmSoundLibrary/gunshot_ar15_near.wav` | CC0 (FreeFirearmSoundLibrary) | replaced by the Layers/ takes, then by the new SFX |
| `ThirdParty/FreeFirearmSoundLibrary/gunshot_nova_near.wav` | CC0 (FreeFirearmSoundLibrary) | replaced by the Layers/ takes, then by the new SFX |
| `ThirdParty/Quaternius_AnimatedHuman/AnimatedHuman.fbx` | CC0 (Quaternius_AnimatedHuman) | replaced by gankdroid's enemy_base (Unity story 052) |
| `ThirdParty/Quaternius_AnimatedHuman/ClothedLightSkin.png` | CC0 (Quaternius_AnimatedHuman) | replaced by gankdroid's enemy_base (Unity story 052) |
| `ThirdParty/Quaternius_UltimateGunPack/AssaultRifle_1.fbx` | CC0 (Quaternius_UltimateGunPack) | the rifle became the SMG |
| `ThirdParty/Quaternius_UltimateGunPack/SubmachineGun_1.fbx` | CC0 (Quaternius_UltimateGunPack) | the boss moved to gankdroid's EnemySmg |
| `ThirdParty/SpringySpringo_GunReload/rifle_bolt_rack_01.wav` | CC0 (SpringySpringo_GunReload) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/SpringySpringo_GunReload/rifle_mag_in_01.wav` | CC0 (SpringySpringo_GunReload) | the rifle became the SMG (Unity story 021) |
| `ThirdParty/SpringySpringo_GunReload/rifle_mag_out_01.wav` | CC0 (SpringySpringo_GunReload) | the rifle became the SMG (Unity story 021) |
| `_Game/Art/Textures/HumanPalette.png` | in-house | old human and zombie palettes |
| `_Game/Art/Textures/ZombiePalette.png` | in-house | old human and zombie palettes |
| `_Game/Art/ccr_logo.png` | in-house | not referenced |
| `_Game/Art/envi/canteen_dynamic_seats.fbx` | in-house (gankdroid) | not placed in the canteen |
| `_Game/Audio/Placeholder/sfx_reload.wav` | project-synthesised | replaced by layered reload sounds |
| `_Game/Audio/Placeholder/sfx_zombie_death.wav` | project-synthesised | zombies were replaced by humans |
| `_Game/Audio/Placeholder/sfx_zombie_hit.wav` | project-synthesised | zombies were replaced by humans |
| `_Game/Audio/Synth/casing_tinkle_01.wav` | project-synthesised | casing sound switched off (2026-11-13) |
| `_Game/Audio/Synth/casing_tinkle_02.wav` | project-synthesised | casing sound switched off (2026-11-13) |
| `_Game/Audio/Synth/casing_tinkle_03.wav` | project-synthesised | casing sound switched off (2026-11-13) |
| `_Game/Audio/Synth/casing_tinkle_04.wav` | project-synthesised | casing sound switched off (2026-11-13) |
| `_Game/Audio/Synth/shell_knock_01.wav` | project-synthesised | casing sound switched off (2026-11-13) |
| `_Game/Audio/Synth/shell_knock_02.wav` | project-synthesised | casing sound switched off (2026-11-13) |
| `_Game/Audio/Synth/shell_knock_03.wav` | project-synthesised | casing sound switched off (2026-11-13) |

## Not copied: Unity-only formats (rebuilt in Godot)

| Unity files | Count | Rebuilt as | Story |
|---|---|---|---|
| Materials (`.mat`, URP Lit/Unlit) | 38 | `StandardMaterial3D` / `ShaderMaterial` from the copied textures; originals in the reference folder | 022, 020, 011 |
| URP Volume profiles, `AbilityLook.asset`, `HeartRateLook.asset` | 3 | `WorldEnvironment` / full-screen shader; values in the reference folder | 013, 014 |
| Animator controllers, override controllers, avatar masks | 6 | `AnimationTree` state machine with an upper-body blend; the clips come inside `enemy_base.fbx` | 020 |
| Door animations (`door_enemy_a/b.anim`, 2 controllers) | 4 | `AnimationPlayer` on the door models | 022, 019 |
| Unity meshes (`.asset`): `BossPlate` | 1 | A `BoxMesh` (it was a code-made box) | 008 |
| Unity meshes (`.asset`): `ArmsCoffeeCup`, `ArmsCigarette` | 2 | Not needed: replaced by `player_kopi.fbx` / `player_rokok.fbx` | — |
| Prefabs | 8 | Godot scenes (`.tscn`) | 004, 005, 008 |
| Scenes (`.unity`) | 7 | Godot scenes; the five current ones are in the reference folder | 009, 022 |
| Shaders | 0 game shaders | The 23 shader files are all TextMesh Pro's (a Unity package); the game wrote none | — |
| TextMesh Pro, `TutorialInfo`, `SampleScene`, URP renderer assets, `Readme.asset` | — | Unity template and package files; not needed | — |
| Cut features: weed pickup, zombie prefab and controller, `enemies_zombie*.json` | — | Out of scope in the brief | — |

## Import notes

- FBX models import through Godot's built-in FBX importer (ufbx). Their embedded texture paths point at the Unity folders, so materials are reassigned in Godot (story 022 / 020).
- `enemy_base.fbx` holds the clips `enemy_idle_breathing`, `enemy_run`, `enemy_walk_weak`, `enemy_attack_melee`, `enemy_attack_pistol` (take `.001`), `enemy_attack_shotgun`, `enemy_attack_smg`; `enemy_a/b/c.fbx` are skins on the same skeleton (`enemies_skins.json`).
- The JSON in the reference folder uses the Unity schema; each story converts the values it needs into its Godot data resource.
