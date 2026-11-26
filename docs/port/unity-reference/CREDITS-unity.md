# Third-party asset credits

Every asset under `Assets/ThirdParty/` is CC0 1.0 (public domain, https://creativecommons.org/publicdomain/zero/1.0/).
No credit is required; it is given here anyway. These are temporary assets for story 008
(`production/epics/last-dose/story-008-shooting-feel.md`), downloaded on 2026-11-08, for story 009
(`production/epics/last-dose/story-009-zombie-model-and-animation.md`), downloaded on 2026-11-09, and for story 011
(`production/epics/last-dose/story-011-rifle-second-weapon.md`), which on 2026-11-09 took two more models and two more
shots from the already-downloaded Ultimate Gun Pack and Free Firearm Sound Library (no new download). Story 013
(`production/epics/last-dose/story-013-gun-and-impact-audio.md`) cut layered gunshot takes from the same library (no new
download) and, on 2026-11-10, downloaded three OpenGameArt sound packs for flesh, kill and surface impacts. Those three
archives contain no licence file of their own, so their CC0 status rests on the source pages named below. Story 013 also
took reload and dry-click sounds from four more OpenGameArt downloads on 2026-11-10, none with a licence file of its own.
Story 016 (`production/epics/last-dose/story-016-arms-and-reload.md`) downloaded first-person arms from itch.io on
2026-11-13 with the user's approval; the zip has no licence file, so `Drillimpact_PSXFirstPersonArms/License.txt` quotes
the source page.
Story 021 (`production/epics/last-dose-rework/story-021-smg.md`) took the SMG model from the already-downloaded Ultimate Gun
Pack, cut new gunshot layers from the already-downloaded Free Firearm Sound Library, and made new reload clips from the
airsoft and handgun reload clips already in the project (no new download).
Story 029 (`production/epics/last-dose-rework/story-029-human-enemies.md`) reused the already-downloaded Quaternius
Animated Human and its clips for the human enemies, now with the pack's own `ClothedLightSkin.png` colours instead of the
grey-green zombie recolour (no new download).
Story 031 (`production/epics/last-dose-rework/story-031-ranged-enemy.md`) gave the ranged enemy the already-downloaded
`Pistol_1.fbx` from the Ultimate Gun Pack, with the pack's own material, and its reload sounds from the
`zer0sol_HandgunReload/` clips already in the project; its muzzle flash and tracer reuse the Kenney `muzzle_01`–`05` and
`flare_01` sprites (no new download).
Story 032 (`production/epics/last-dose-rework/story-032-boss.md`) gave the boss the already-downloaded `SubmachineGun_1.fbx`
from the Ultimate Gun Pack in each hand, with the pack's own material, and the armour-break sound
`Rubberduck_BreakingFallingHit/bfh1_rock_breaking_03.ogg` from the pack already in the project (no new download). Its armour
plates are boxes generated in code, and their material and the darker body materials are project-made copies; they contain no
third-party art.

| Folder | Pack and author | Source | Licence as stated on the source page | Files used |
|---|---|---|---|---|
| `Quaternius_UltimateGunPack/` | "50+ LowPoly Guns" (Ultimate Gun Pack, July 2019) by Quaternius | https://opengameart.org/content/low-poly-guns-pack (file `ultimate_gun_pack_by_quaternius.zip`); also https://quaternius.itch.io/50-lowpoly-guns | OpenGameArt: "License(s): CC0"; itch.io: "Free for everyone to use in any project, even comercially! (CC0)" | `Pistol_1.fbx`, `AssaultRifle_1.fbx`, `Shotgun_1.fbx` (all from `FBX/`); story 021 added `SubmachineGun_1.fbx` (from `FBX/` of the same zip, no new download); no weapon uses `AssaultRifle_1.fbx` any more |
| `Kenney_ParticlePack/` | "Particle Pack" by Kenney Vleugels (kenney.nl) | https://opengameart.org/content/particle-pack-80-sprites (file `kenney_particlePack.zip`); also https://kenney.nl/assets/particle-pack | "License (Creative Commons Zero, CC0)" — see `Kenney_ParticlePack/License.txt` | `muzzle_01`–`05`, `spark_01`, `04`, `05`, `07`, `smoke_01`, `03`, `04`, `dirt_01`, `02`, `scorch_01`–`03`, `flare_01` (PNG) |
| `FreeFirearmSoundLibrary/` | "The Free Firearm Sound Library" by Ben Jaszczak, Brian Nelson, Kevin Heras and Matthew Nanney | https://opengameart.org/content/the-free-firearm-sound-library (file `Prepared SFX Library.7z`) | "License(s): CC0"; "Our team holds CC0 NO RIGHTS RESERVED for this library. It may be used without royalty or credit" | `gunshot_1911_near.wav`: trimmed to 1.2 s from `1911/A_42P.wav` ("1911, handgun, pistol, semi automatic, .45, gunshot, near distance, front of shooter"); `gunshot_ar15_near.wav`: trimmed to 1.2 s from `AR-15/D_32P.wav` ("AR-15, M4, rifle, carbine, semi automatic, assault rifle, .223, 5.56x45, gunshot, near distance, front of shooter"); `gunshot_nova_near.wav`: trimmed to 1.2 s from `Nova/O_21P.wav` ("Benelli, Nova, shotgun, pump action, 12 gauge, gunshot, near distance, front of shooter"); story 013, in `Layers/`, resampled to 48 kHz 16-bit: `pistol_close_01`–`04` (0.6 s, from the two shots in `1911/A_42P.wav`) and `pistol_tail_01`–`04` (0.8 s, from `1911/A_34P.wav`, "mid distance"), `rifle_close_01`–`04` and `rifle_tail_01`–`04` (from `AR-15/D_32P.wav` and `D_24P.wav`), `shotgun_close_01`–`04` and `shotgun_tail_01`–`04` (from `Nova/O_21P.wav` and `O_17P.wav`); takes 03 and 04 are pitch-shifted variants of 01 and 02; story 021, in `Layers/`, resampled from 96 kHz 24-bit to 48 kHz 16-bit: `smg_close_01`–`03` (0.45 s, the three single shots of `Carl Gustav M45/G_31P.wav`: "Carl Gustav M45, Swedish K, rifle, fully automatic, machine gun, sub machine gun, 9mm, gunshot, near distance") and `smg_tail_01`–`03` (1.0 s, the three reports of `Carl Gustav M45/G_20P.wav`, "mid distance"); `smg_close_04` is `smg_close_01` sped up 6 percent and `smg_tail_04` is `smg_tail_01` slowed 5 percent |
| `IndependentNu_WetSquish/` | "8 wet squish, slurp impacts" by Independent.nu (Ljudbank), posted by qubodup | https://opengameart.org/content/8-wet-squish-slurp-impacts (file `independent_nu_ljudbank-wet_squish_slurp_impacts.7z`, 586,806 bytes) | OpenGameArt: "License(s): CC0" | `flesh_hit_01`–`06.wav`: 0.3–0.4 s mono cuts around the main hit of `impactsplat02`, `03`, `01`, `06`, `04` and `07` (FLAC decoded to 16-bit WAV, 44.1 kHz) |
| `IndependentNu_ExtremeSplatter/` | "2 wooden squish splatter sequences" by Independent.nu (Ljudbank), posted by qubodup | https://opengameart.org/node/2549 (file `independent_nu_ljudbank-extreme_splatter.7z`, 818,161 bytes) | OpenGameArt: "License(s): CC0" | `kill_burst_01`–`04.wav`: 0.7–1.3 s mono bursts cut from `crack11` and `crack12` (FLAC decoded to 16-bit WAV, 44.1 kHz) |
| `Rubberduck_BreakingFallingHit/` | "75 CC0 breaking / falling / hit SFX" by rubberduck | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx (file `sfx_breaking_and_falling.zip`, 1,624,406 bytes) | OpenGameArt: "License(s): CC0" | `bfh1_hit_05`, `08`, `09`, `10`, `11`, `13`, `bfh1_rock_breaking_03`, `bfh1_rock_hit_01` (`.ogg`, unchanged) |
| `zer0sol_HandgunReload/` | "Handgun Reload Sound Effect" by zer0_sol | https://opengameart.org/content/handgun-reload-sound-effect (file `reload.wav`, 280,620 bytes) | OpenGameArt: "License(s): CC0" | `pistol_mag_out_01`, `pistol_mag_in_01`, `pistol_slide_rack_01` (`.wav`, cut from the one take) |
| `zer0sol_ShotgunReload/` | "Shotgun Reload Sound effects" by zer0_sol | https://opengameart.org/content/shotgun-reload-sound-effects (file `shotgunsounds.zip`, 324,193 bytes) | OpenGameArt: "License(s): CC0" | `shotgun_shell_01`–`04` (two halves each of `Subsequent Shells.mp3` and `First Shell.mp3`) and `shotgun_pump_01` (from `Rack.mp3`), decoded to mono 16-bit WAV |
| `SpringySpringo_GunReload/` | "Gun reload sounds" by SpringySpringo (recorded with airsoft guns) | https://opengameart.org/content/gun-reload-sounds (file `assaultriflereload1_0.wav`, 274,476 bytes) | OpenGameArt: "License(s): CC0" | `rifle_mag_out_01`, `rifle_mag_in_01`, `rifle_bolt_rack_01` (`.wav`, cut from the one take); story 021 made `smg_mag_out_01`, `smg_mag_in_01` and `smg_bolt_rack_01` (`.wav`) from them, sped up 8 to 10 percent and layered with the matching `zer0sol_HandgunReload/` clips at a lower level; no weapon uses the `rifle_*` reload clips any more |
| `LFA_EquipmentClicks/` | "equipment clicks III" by LFA | https://opengameart.org/content/equipment-clicks-iii (file `equipment_clicks3.wav`, 2,021,420 bytes) | OpenGameArt: "License(s): CC0" | `dry_click_01`, `dry_click_02` (`.wav`, two clicks from the bolt-action rifle section) |
| `Quaternius_AnimatedHuman/` | "Animated Human Low Poly" (Animated Human by Quaternius, posted 2017-11-03) by Quaternius | https://opengameart.org/content/animated-human-low-poly (file `Animated Human by @Quaternius.zip`, 5,010,069 bytes) | OpenGameArt: "License(s): CC0"; the pack's own `License.txt` (kept here as `License.txt`): "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication" | `AnimatedHuman.fbx` (renamed from `FBX/Animated Human.fbx`; one skinned mesh, Mixamo-style humanoid skeleton, 9 clips), `ClothedLightSkin.png` (32x32 colour palette, from `Blend/Textures/`) |
| `Drillimpact_PSXFirstPersonArms/` | "PSX First Person Arms" (version 1.1.0) by Drillimpact | https://drillimpact.itch.io/psx-first-person-arms-free (file `psx-first-person-arms-free-game-assets.zip`, 4,013,463 bytes) | itch.io: "Asset license: Creative Commons Zero v1.0 Universal"; "This asset is released under CC0 (Public Domain)."; the author in a comment: "Yes CC0", "No credit is required" | `arms_rig.fbx` (one skinned mesh of both arms, 1,176 triangles, a generic skeleton with finger bones), `arms_01.png` (bare hands, 512x512), `arms_gloves_01.png` (black fingerless gloves, 512x512; the texture in use), all unchanged |

Not third-party: the placeholder sounds in `Assets/_Game/Audio/Placeholder/` (dry click, reload, zombie hit,
zombie death, and for story 011 the shotgun shell load) were synthesised for this project and need
no licence; since story 013 none of them is wired. So was story 013's `Assets/_Game/Audio/Synth/shotgun_thump_01.wav`, a decaying 90 to 40 Hz sine sweep
that contains no recorded audio. Story 017's `Assets/_Game/Audio/Synth/sfx_dose_pickup.wav`, the dose pickup chime, is a
0.25 s two-note rising bell (A5 then E6, sine tones with soft partials) synthesised for this project; it contains no
recorded audio. Story 015's `Assets/_Game/Audio/Synth/casing_tinkle_01`–`04.wav` (a brass casing bouncing on a hard floor:
three or four quick impacts of decaying inharmonic partials over a short noise click, 0.4 s) and `shell_knock_01`–`03.wav`
(a shotgun shell: a dull knock with a 180–240 Hz body tone and two or three slower bounces, 0.5 s), 16-bit mono 44.1 kHz,
were synthesised for this project by a script and contain no recorded audio; since 2026-11-13 they are not wired (the
casing landing sound is off). The melee enemy's landed-hit sound `Assets/_Game/Audio/Synth/sfx_melee_hit.wav` (a wooden
club on a body: a 140 to 55 Hz sine thump, three damped inharmonic knock partials and short high- and low-passed noise
bursts, 0.35 s, 16-bit mono 44.1 kHz) was synthesised for this project by a script on 2026-11-15 and contains no recorded audio. The ejected casings are Unity's built-in
Cylinder mesh with a project-made material (`Assets/_Game/Art/Materials/Casing.mat`); no model was downloaded.
