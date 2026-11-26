class_name ImpactEffectsData
extends Resource
## Data for wall impacts, bullet holes, blood and floor splats (Unity effects_impact.json / effects_blood.json).

@export_group("Sparks")
@export var spark_texture: Texture2D
@export var spark_pool_size: int = 16
@export var spark_count: int = 6
@export var spark_size: float = 0.22
@export var spark_end_scale: float = 1.5
@export var spark_lifetime: float = 0.1
@export var spark_speed: float = 3.0
@export var spark_spread_degrees: float = 55.0
@export var spark_gravity: float = 4.0
@export var spark_color: Color = Color(1.0, 0.85, 0.55, 1.0)
@export_group("Dust")
@export var dust_texture: Texture2D
@export var dust_pool_size: int = 32
@export var dust_count: int = 4
@export var dust_size: float = 0.25
@export var dust_end_scale: float = 2.2
@export var dust_lifetime: float = 0.5
@export var dust_speed: float = 0.5
@export var dust_color: Color = Color(0.42, 0.38, 0.32, 0.7)
@export_group("Bullet holes")
@export var hole_texture: Texture2D
@export var bullet_hole_cap: int = 40
@export var bullet_hole_size: float = 0.12
@export var bullet_hole_lifetime: float = 8.0
@export var bullet_hole_fade_seconds: float = 2.0
## Depth of the decal box in metres (how far it reaches into the surface).
@export var decal_depth: float = 0.2
@export var bullet_hole_color: Color = Color(0.06, 0.05, 0.045, 0.9)
@export_group("Blood spray")
@export var blood_texture: Texture2D
@export var spray_pool_size: int = 16
@export var spray_count: int = 12
@export var spray_size: float = 0.3
@export var spray_end_scale: float = 1.8
@export var spray_lifetime: float = 0.35
@export var spray_speed: float = 4.0
@export var spray_spread_degrees: float = 25.0
## Weight of the outward surface normal added to the along-surface part of the shot direction
## (higher = more of the spray comes back out toward the shooter).
@export var spray_normal_blend: float = 0.8
@export var spray_gravity: float = 6.0
@export var spray_color: Color = Color(0.5, 0.02, 0.02, 1.0)
@export_group("Kill burst")
@export var burst_pool_size: int = 6
@export var burst_count: int = 14
@export var burst_size: float = 0.3
@export var burst_end_scale: float = 2.2
@export var burst_lifetime: float = 0.5
@export var burst_speed: float = 3.5
@export var burst_spread_degrees: float = 60.0
@export var burst_color: Color = Color(0.3, 0.02, 0.02, 0.9)
@export_group("Floor splats")
@export var splat_textures: Array[Texture2D] = []
@export var splat_cap: int = 48
@export var splat_ray_count: int = 1
@export var kill_splat_ray_count: int = 10
@export var splat_reach: float = 3.0
@export var splat_spread_degrees: float = 40.0
@export var splat_down_bias: float = 0.4
## Extra downward bias (max) used for kill rays so some always reach the floor.
@export var kill_splat_down_bias_max: float = 1.5
@export var splat_size: float = 0.35
@export var splat_lifetime: float = 20.0
@export var splat_fade_seconds: float = 5.0
@export var splat_color: Color = Color(0.28, 0.02, 0.02, 0.85)
