class_name EnemyData
extends Resource
## Stats for one enemy type (melee, ranged, boss). Defaults are the Unity values from
## docs/port/unity-reference/data/enemies_*.json; the .tres files under assets/data/enemies/ override them.

enum Kind { MELEE, RANGED, BOSS }

@export var id: StringName = &"melee"
@export var kind: Kind = Kind.MELEE
@export var display_name: String = "Enemy"

@export_group("Body")
@export var health: float = 50.0
@export var move_speed: float = 3.5
## Damage dealt to the player per hit (melee swing) or per landed bullet (ranged, boss).
@export var damage: float = 15.0
## Uniform scale of the placeholder body, hitbox and props.
@export var body_scale: float = 1.0
@export var body_height: float = 1.8
@export var body_radius: float = 0.4
## Height of the eyes / muzzle above the feet (before body_scale).
@export var eye_height: float = 1.5
@export var body_color: Color = Color(0.8, 0.45, 0.2)
@export var repath_interval: float = 0.25
## Seconds a killed body keeps sliding along the shot before it is removed (story 011; ragdoll is story 020).
@export var death_slide_seconds: float = 0.45
## Rigged model, animation and corpse numbers (story 020). Null = the code-built capsule.
@export var visual: EnemyVisualData
## Prop push and detour numbers (story 021). Null = assets/data/enemies/enemy_push.tres.
@export var push: EnemyPushData

@export_group("Melee")
@export var reach: float = 2.0
@export var windup_seconds: float = 0.6
@export var swing_seconds: float = 0.25
## Fraction of the swing at which the hit lands (0-1).
@export var swing_hit_fraction: float = 0.5
## Seconds from the start of one attack to the start of the next.
@export var attack_interval: float = 1.8

@export_group("Ranged and boss")
@export var band_min: float = 8.0
@export var band_max: float = 15.0
@export var spot_arrive_distance: float = 0.4
@export var no_line_wait_seconds: float = 0.8
@export var spot_check_height: float = 1.4
@export var aim_seconds: float = 0.6
## Shots per second (ranged).
@export var fire_rate: float = 1.6
@export var spread_degrees: float = 3.0
@export var shot_range: float = 30.0
@export var magazine_size: int = 6
@export var reload_seconds: float = 2.2
## Firing pattern, gun prop and shot sound of a ranged kind (null = plain single shots).
@export var gun: RangedGunData

@export_group("Boss")
@export var armour_points: float = 0.0
## Fraction of each hit absorbed by armour while armour_points remain.
@export var armour_absorb_fraction: float = 0.0
@export var orbit_step_degrees: float = 22.0
@export var orbit_flip_seconds: float = 4.5
@export var burst_size: int = 6
@export var shot_interval_seconds: float = 0.1
@export var burst_pause_seconds: float = 1.5
@export var plate_color: Color = Color(0.2, 0.21, 0.23)
## Armour plate centres in body space (metres, before body_scale) and matching box sizes.
@export var plate_offsets: PackedVector3Array = PackedVector3Array()
@export var plate_sizes: PackedVector3Array = PackedVector3Array()

@export_group("Knockback")
## Horizontal speed (m/s) added per unit of hit pushback (direction.length()).
@export var knockback_scale: float = 0.6
## Exponential decay rate of the knockback speed (per second).
@export var knockback_decay: float = 8.0
@export var max_knockback_speed: float = 10.0

@export_group("Drops")
@export_range(0.0, 1.0) var ammo_drop_chance: float = 0.25
## Weights for [smg, shotgun].
@export var ammo_weights: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
@export_range(0.0, 1.0) var dose_drop_chance: float = 0.5
## Weights for [coffee, cigarette].
@export var dose_weights: PackedFloat32Array = PackedFloat32Array([3.0, 1.0])
## Always-dropped counts for [smg, shotgun] (boss).
@export var guaranteed_ammo: PackedInt32Array = PackedInt32Array()
## Always-dropped counts for [coffee, cigarette] (boss).
@export var guaranteed_doses: PackedInt32Array = PackedInt32Array()
