class_name ViewmodelSubstanceData
extends Resource
## Viewmodel tuning for one substance held in the free (left) hand: prop, hand poses, steam/smoke.
## Ported from the Unity arms_substances.json and arms_substance_fx.json.
## Hand poses are camera-space wrist positions (metres, -Z is forward) and hand-frame rotations
## (degrees, YXZ Euler; identity = fingers forward, palm down).

## SubstanceInventory kind this entry belongs to (&"coffee" or &"cigarette").
@export var kind: StringName = &""
## Imported prop model.
@export var model: PackedScene

@export_group("Materials")
## Material per mesh surface of the prop, in surface order. Empty = keep imported materials.
@export var surface_materials: Array[Material] = []

@export_group("Hand poses")
@export var rest_position: Vector3 = Vector3(-0.17, -0.135, -0.3)
@export var rest_rotation_degrees: Vector3 = Vector3(-15.0, -10.0, 90.0)
## Finger curl: x index, y middle/ring/pinky, z thumb.
@export var rest_curl: Vector3 = Vector3(35.0, 85.0, 25.0)
@export var raised_position: Vector3 = Vector3(-0.09, -0.13, -0.24)
@export var raised_rotation_degrees: Vector3 = Vector3.ZERO
@export var raised_curl: Vector3 = Vector3(35.0, 85.0, 25.0)

@export_group("Prop in hand")
## Prop position in the hand frame (from the wrist).
@export var prop_offset: Vector3 = Vector3.ZERO
@export var prop_rotation_degrees: Vector3 = Vector3.ZERO
## World scale of the prop.
@export var prop_scale: float = 1.0

@export_group("Steam / smoke")
## Emitter position in the prop's space (Unity SteamPoint / SmokeTip).
@export var fx_offset: Vector3 = Vector3.ZERO
## Particles per second while the prop is shown at rest.
@export var fx_idle_rate: float = 1.5
## Particles per second once the prop is raised past fx_raised_threshold.
@export var fx_raised_rate: float = 4.5
## Raise amount (0-1) above which fx_raised_rate applies.
@export var fx_raised_threshold: float = 0.85
@export var fx_lifetime: float = 1.8
## Seconds at the end of the lifetime over which a particle fades out.
@export var fx_fade_seconds: float = 1.4
@export var fx_rise_speed: float = 0.08
@export var fx_drift: float = 0.02
@export var fx_scatter: float = 0.004
@export var fx_start_size: float = 0.018
@export var fx_end_size: float = 0.075
@export var fx_color: Color = Color(0.9, 0.9, 0.9, 0.3)
