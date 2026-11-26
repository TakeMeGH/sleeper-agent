class_name EnemyVisualData
extends Resource
## Look and animation numbers of one enemy type's rigged model (story 020). Defaults are the Unity values
## from docs/port/unity-reference/data/enemies_{melee,ranged,boss}_anim.json and effects_ragdoll.json;
## the .tres files assets/data/enemies/visual_{melee,ranged,boss}.tres override them.

@export_group("Model")
## Model used when skin_scenes is empty (and by the boss).
@export var base_scene: PackedScene
## Skins on the same skeleton; one is picked per spawn with equal chance (docs/port/unity-reference/data/enemies_skins.json).
@export var skin_scenes: Array[PackedScene] = []
## Index into skin_scenes to always use (-1 = random). For deterministic captures.
@export var forced_skin_index: int = -1
## Material of base_scene's body (Unity: the FBX's "bot" slot remapped to Placeholders.mat, rs_textures_bot.png;
## the boss: EnemyBossBody.mat, the same texture tinted darker). Each spawn gets its own copy.
@export var body_material: StandardMaterial3D
## Material of every skin in skin_scenes (Unity: the skin FBX's "prop" slot remapped to manprop.mat,
## gj_26_manprop.png). The skins are UV-mapped to that texture, not to body_material's.
@export var skin_material: StandardMaterial3D
## Height of the imported model in metres at scale 1. The default is the mesh AABB (1.7696); the .tres files use
## 1.7113, which reproduces the Unity prefabs' model scale (1.0518 at a 1.8 m body).
@export var source_height: float = 1.7696
## The model faces +Z, an enemy faces -Z.
@export var model_yaw_degrees: float = 180.0

@export_group("Clips")
@export var idle_clip: StringName = &"enemy_idle_breathing"
@export var walk_clip: StringName = &"enemy_walk_weak"
@export var run_clip: StringName = &"enemy_run"
## Default attack clip; ranged kinds override it with RangedGunData.attack_clip.
@export var attack_clip: StringName = &"enemy_attack_melee"
## True: the attack plays on the upper body only (ranged, boss); false: full body (melee).
@export var attack_upper_body_only: bool = false
@export var upper_body_root_bone: StringName = &"spine_b"
## Seconds into the attack clip at which the hit lands / the shot leaves.
@export var attack_clip_hit_time: float = 0.425
@export var attack_blend_time: float = 0.1

@export_group("Locomotion")
@export var walk_reference_speed: float = 0.8
@export var run_reference_speed: float = 3.05
@export var speed_scale_min: float = 0.6
@export var speed_scale_max: float = 1.6
## Cross-fade between idle, walk and run.
@export var locomotion_blend_time: float = 0.1
## Horizontal speed (m/s) below which the enemy counts as standing still.
@export var idle_speed_threshold: float = 0.15
## Speeds below this use the weak walk clip, above it the run clip (midpoint of the two reference speeds).
@export var walk_run_threshold: float = 1.9

@export_group("Hit reaction")
@export var stagger_duration: float = 0.3
## Degrees the whole body leans back at the start of a stagger.
@export var stagger_lean_degrees: float = 8.0
## Degrees the upper body bends back (spread over jolt_bones) at the start of a stagger.
@export var jolt_degrees: float = 24.0
@export var jolt_bones: PackedStringArray = PackedStringArray(["spine_b", "spine_c"])
## Emission strength of the white hit flash.
@export var flash_energy: float = 2.0

@export_group("Death and corpse")
@export var death_fall_seconds: float = 0.55
## Metres the lying body is raised so it does not sink into the floor.
@export var death_lift: float = 0.15
@export var corpse_linger: float = 4.0
@export var corpse_fade: float = 1.5
## Most dead bodies kept at once; the oldest is removed first (Unity live_ragdoll_cap).
@export var live_corpse_cap: int = 6
## Physics layer bit of a corpse: not the player's (1) or enemies' (2) layer, so nothing collides with it
## except hitscan rays, which test every layer.
@export var corpse_collision_layer: int = 4
## Push of a shot into a corpse relative to the kill push (Unity body_hit_impulse 40 / kill_impulse 150).
@export var corpse_hit_push_scale: float = 0.27

@export_group("Held prop")
## Weapon in the right hand for melee (club) and boss (SMG). Ranged kinds use RangedGunData.prop_scene instead.
@export var held_prop_scene: PackedScene
@export var held_prop_position: Vector3 = Vector3.ZERO
@export var held_prop_rotation_degrees: Vector3 = Vector3.ZERO
@export var held_prop_scale: float = 1.0
@export var hand_bone: StringName = &"palm_R"
## Material of every held prop (Unity: the prop FBX's "bot" slot remapped to Placeholders.mat, rs_textures_bot.png).
@export var prop_material: StandardMaterial3D

@export_group("Armour plates")
## Boxes parented to bones (the boss; Unity enemies_boss.json "plates"). Bone of each plate.
@export var plate_bones: PackedStringArray = PackedStringArray()
## Offset of each plate from its bone in the model's frame (+Z = the model's front, +X = its left; Unity's offsets with
## X negated), metres at model scale 1 (they scale with the model). Applied at the rest pose, then the plate follows the bone.
@export var plate_offsets: PackedVector3Array = PackedVector3Array()
## Size of each plate (model frame, metres at model scale 1).
@export var plate_sizes: PackedVector3Array = PackedVector3Array()
@export var plate_material: StandardMaterial3D

@export_group("Aim turn")
## Unity RangedPose / BossPose: while aiming, the upper body turns about aim_bone by the rotation that takes the
## barrel (the prop's *_tip node, +Z) onto the line to the target, at most this many degrees (Unity
## aim_correction_max_degrees: ranged 60, boss 75). 0 = no turn (melee).
@export var aim_correction_max_degrees: float = 0.0
@export var aim_bone: StringName = &"spine_b"
## Seconds the turn takes to blend in or out (Unity aim_seconds: ranged 0.6, boss 0.7).
@export var aim_blend_seconds: float = 0.6

@export_group("Reload pose")
## Degrees the upper body bends forward while reloading.
@export var reload_lean_degrees: float = 18.0
## Degrees the gun is tilted about the hand while reloading.
@export var reload_prop_tilt_degrees: float = -55.0
@export var reload_blend_seconds: float = 0.2

@export_group("Muzzle flash and tracer")
@export var muzzle_flash_seconds: float = 0.05
@export var muzzle_flash_size: float = 0.22
@export var muzzle_flash_color: Color = Color(1.0, 0.8, 0.35, 1.0)
@export var tracer_seconds: float = 0.06
@export var tracer_width: float = 0.025
@export var tracer_color: Color = Color(1.0, 0.85, 0.5, 1.0)
@export var tracer_pool_size: int = 8
@export var tracer_max_length: float = 40.0
