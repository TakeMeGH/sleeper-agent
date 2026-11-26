class_name GunFeelData
extends Resource
## Feel tuning for one gun: camera kick, shake, FOV punch, muzzle flash and hitstop.
## Defaults are the pistol; the Unity values are in docs/port/unity-reference/data/weapons_*_feel.json.

## GunData.gun_id this entry belongs to.
@export var gun_id: StringName = &""
@export_group("Camera kick")
## Degrees the view rises per shot (additive offset that returns to zero; never written into the look angles).
@export var kick_pitch_degrees: float = 1.8
## Largest random sideways kick per shot, in degrees (sign is random).
@export var kick_yaw_degrees: float = 0.4
## The kick offset never grows past these, however long fire is held.
@export var max_pitch_degrees: float = 4.5
@export var max_yaw_degrees: float = 1.0
## Seconds a fully built-up kick needs to recover to zero.
@export var recovery_seconds: float = 0.35
@export_group("Shake")
## Camera position shake amplitude in metres.
@export var shake_position: float = 0.002
## Rotation shake amplitudes in degrees.
@export var shake_roll_degrees: float = 1.0
@export var shake_pitch_degrees: float = 1.0
@export var shake_yaw_degrees: float = 1.0
@export var shake_seconds: float = 0.12
## Shake cycles per second.
@export var shake_frequency: float = 25.0
@export_group("FOV punch")
## Degrees added to the field of view at the peak of a shot (negative = zoom in).
@export var fov_punch_degrees: float = -1.0
@export var fov_punch_seconds: float = 0.12
@export_group("Muzzle flash")
## Where the flash sits, in the gun pivot space of the viewmodel (metres, -Z is forward).
@export var muzzle_offset: Vector3 = Vector3(0.0, 0.03, -0.14)
## Extra metres forward (-Z) past muzzle_offset, for a gun whose front sight hides a flash centred on the tip
## (the flash is depth tested against the gun). 0 = exactly at the tip.
@export var muzzle_flash_forward: float = 0.0
@export var muzzle_flash_size: float = 0.16
@export var muzzle_flash_seconds: float = 0.05
@export var muzzle_flash_color: Color = Color(1.0, 0.85, 0.5, 1.0)
@export_group("Kill")
## Real seconds of hitstop requested when a shot of this gun kills.
@export var hitstop_seconds: float = 0.05
