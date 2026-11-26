class_name ViewmodelGunData
extends Resource
## Viewmodel tuning for one gun: model mount, hold pose, recoil, raise after a switch, and the arms
## (grip hand on the gun, free hand's reload timeline). Ported from the Unity weapons_*_feel.json.
## Positions are metres, Godot axes (-Z is forward); angles are degrees (YXZ Euler).

## GunData.gun_id this entry belongs to.
@export var gun_id: StringName = &""
## Imported model scene shown in the right hand.
@export var model: PackedScene
## Material put on every surface of the model (null = keep imported materials).
@export var model_material: Material

@export_group("Model mount")
## Mount position in gun-pivot space (Unity viewmodel_model_offset).
@export var model_offset: Vector3 = Vector3.ZERO
## Mount rotation (Unity viewmodel_model_rotation).
@export var model_rotation_degrees: Vector3 = Vector3.ZERO
@export var model_scale: float = 1.0
## Extra rotation of the imported model inside the mount; zero = ViewmodelData.fbx_rotation_degrees.
## Set for a model whose Godot import is turned differently from Unity's (solved from its *_tip node).
@export var model_fix_degrees: Vector3 = Vector3.ZERO

@export_group("Hold pose")
## Gun pivot position in camera space (Unity viewmodel_position).
@export var hold_position: Vector3 = Vector3(0.17, -0.16, -0.32)

@export_group("Recoil")
## Metres the gun is pushed back toward the camera (+Z) at the peak of a shot.
@export var kick_back: float = 0.05
## Degrees the muzzle rises at the peak of a shot.
@export var kick_pitch_degrees: float = 6.0
## Metres the gun jumps to a random side at the peak of a shot.
@export var kick_side: float = 0.012
## Degrees the gun rolls toward that side at the peak of a shot.
@export var kick_roll_degrees: float = 4.0
## Seconds the kick takes to ease back to rest (it snaps to full on the shot).
@export var settle_seconds: float = 0.15

@export_group("Raise after a switch")
@export var raise_seconds: float = 0.4
@export var raise_dip_depth: float = 0.12
@export var raise_dip_degrees: float = 35.0

@export_group("Arms")
## Arms model root in gun-pivot space (Unity arms_root_*).
@export var arms_root_position: Vector3 = Vector3(-0.17, -1.583, 0.28)
@export var arms_root_rotation_degrees: Vector3 = Vector3.ZERO
@export var arms_scale: float = 1.0
## Fraction of the arm's full length a hand may stretch to.
@export var reach_limit: float = 0.98
## Share of the wrist's twist the forearm takes.
@export var forearm_twist_follow: float = 0.5
## Finger curl axis in the hand frame (positive turn curls toward the palm).
@export var curl_axis: Vector3 = Vector3(-1.0, 0.0, 0.0)
## Thumb curl axis in the hand frame; zero = the thumb's own rest bend.
@export var thumb_axis: Vector3 = Vector3.ZERO
## Curl multiplier at each finger's first, second and third joint.
@export var curl_joint_weights: Vector3 = Vector3(1.0, 1.1, 0.7)

@export_group("Grip hand")
## Grip wrist position in gun-pivot space.
@export var grip_position: Vector3 = Vector3.ZERO
@export var grip_rotation_degrees: Vector3 = Vector3.ZERO
## Finger curl: x index, y middle/ring/pinky, z thumb.
@export var grip_curl: Vector3 = Vector3(35.0, 85.0, 25.0)
## Direction (gun-pivot space) the grip elbow bends toward.
@export var grip_pole: Vector3 = Vector3(0.6, -1.0, 0.2)

@export_group("Reload props")
@export var magazine_size: Vector3 = Vector3(0.088, 0.035, 0.029)
@export var magazine_offset: Vector3 = Vector3.ZERO
@export var magazine_rotation_degrees: Vector3 = Vector3.ZERO
@export var shell_size: Vector3 = Vector3(0.02, 0.02, 0.07)
@export var shell_offset: Vector3 = Vector3.ZERO
@export var shell_rotation_degrees: Vector3 = Vector3.ZERO

@export_group("Reload motion")
## True: the free hand loops the shell cycle every shell_cycle_seconds while the gun reloads.
@export var shell_reload: bool = false
@export var shell_cycle_seconds: float = 0.45
## Magazine reloads: point of the reload (0-1) the timeline's halfway key is reached at.
@export var reload_in_at: float = 0.35
## Blend into a timeline from where the hand was, per second.
@export var blend_in_speed: float = 8.0
## Blend back to the substance pose after a finish, cancel or interruption, per second.
@export var blend_out_speed: float = 4.0
## Seconds of the finish timeline played after a completed reload.
@export var finish_seconds: float = 0.3
@export var reload_keys: Array[ViewmodelHandKey] = []
@export var finish_keys: Array[ViewmodelHandKey] = []
