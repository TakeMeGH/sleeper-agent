class_name ViewmodelData
extends Resource
## All tuning for the first-person viewmodel (guns, substances, arms, timings), ported from the Unity
## weapons_*_feel.json, arms_substances.json and arms_substance_fx.json (Godot axes: -Z forward).

@export var guns: Array[ViewmodelGunData] = []
@export var substances: Array[ViewmodelSubstanceData] = []

@export_group("Rendering")
## 1-based visual layer reserved for viewmodel geometry (hidden from the main camera).
@export_range(1, 20) var render_layer: int = 20
@export var view_near: float = 0.01
@export var view_far: float = 5.0
## Vertical fov of the viewmodel camera at the world camera's starting fov (Unity camera: 60).
## Later changes of the world fov (heart rate, gun punch) are added on top.
@export var view_fov: float = 60.0
## Extra rotation every imported FBX (arms, guns, props) gets so it faces the way Unity shows it
## (Unity mirrors X on import; Godot keeps the file's handedness: a 180 degree turn about Y).
@export var fbx_rotation_degrees: Vector3 = Vector3(0.0, 180.0, 0.0)

@export_group("Arms")
@export var show_arms: bool = true
@export var arms_scene: PackedScene
@export var arms_material: Material
@export var magazine_material: Material
@export var shell_material: Material

@export_group("Free hand")
## Seconds for the free hand to raise a substance to the mouth.
@export var raise_seconds: float = 0.35
## Seconds for it to lower it again.
@export var lower_seconds: float = 0.25
## Swap to the other substance: seconds down to the lowered pose, then back up.
@export var swap_lower_seconds: float = 0.18
@export var swap_raise_seconds: float = 0.22
## Seconds to blend to (or from) the empty-hand pose when the held substance runs out.
@export var empty_seconds: float = 0.3
## Direction (camera space) the free elbow bends toward.
@export var free_hand_pole: Vector3 = Vector3(-0.6, -1.0, 0.2)
## Pose at the bottom of a swap (out of view).
@export var lowered_position: Vector3 = Vector3(-0.21, -0.38, -0.2)
@export var lowered_rotation_degrees: Vector3 = Vector3(20.0, -10.0, 90.0)
@export var lowered_curl: Vector3 = Vector3(45.0, 60.0, 20.0)
## Pose of an empty free hand.
@export var empty_position: Vector3 = Vector3(-0.21, -0.235, -0.25)
@export var empty_rotation_degrees: Vector3 = Vector3(15.0, -10.0, 80.0)
@export var empty_curl: Vector3 = Vector3(10.0, 20.0, 5.0)

@export_group("Effects")
## Steam and smoke particles.
@export var fx_enabled: bool = true
