class_name RangedGunData
extends Resource
## How one kind of ranged enemy fires and what its gun prop looks and sounds like (story 019).
## Referenced from EnemyData.gun; values live in assets/data/enemies/ranged_{pistol,shotgun,smg}.tres.

## SINGLE: one bullet per trigger pull. SPREAD: pellets_per_shot pellets in a cone per pull.
## BURST: burst_shots bullets burst_interval_seconds apart, then burst_pause_seconds of quiet.
enum Pattern { SINGLE, SPREAD, BURST }

@export var id: StringName = &"pistol"
@export var pattern: Pattern = Pattern.SINGLE

@export_group("Firing")
## Rays fired per trigger pull (SPREAD). Every pellet that reaches the player is one take_hit call.
@export var pellets_per_shot: int = 1
## Cone half-angle (degrees) the pellets are spread across (SPREAD).
@export var pellet_spread_degrees: float = 0.0
## Bullets per burst (BURST).
@export var burst_shots: int = 1
## Seconds between bullets inside a burst (BURST).
@export var burst_interval_seconds: float = 0.1
## Seconds after the last bullet of a burst before the next burst may start (BURST).
@export var burst_pause_seconds: float = 1.0
## Distance from the player (metres) the enemy would like to fire from; spot choice picks the
## spot whose distance is closest to this. 0 = no preference (nearest spot to the enemy).
@export var preferred_distance: float = 0.0

@export_group("Look")
## Gun prop (placeholder FBX until story 020). Null = a coloured box is built instead.
@export var prop_scene: PackedScene
@export var prop_position: Vector3 = Vector3(0.35, 1.1, -0.4)
@export var prop_rotation_degrees: Vector3 = Vector3.ZERO
@export var prop_scale: float = 1.0
## Colour of the fallback box and of the muzzle-side accent.
@export var prop_color: Color = Color(0.1, 0.1, 0.1)
## Size of the fallback box (metres, before body_scale).
@export var prop_box_size: Vector3 = Vector3(0.1, 0.15, 0.5)

@export_group("Hand")
## Prop placement in the right hand bone frame (the FBX props are authored at the palm).
@export var hand_position: Vector3 = Vector3.ZERO
@export var hand_rotation_degrees: Vector3 = Vector3.ZERO
@export var hand_scale: float = 1.0
## Attack animation clip played on every trigger pull.
@export var attack_clip: StringName = &"enemy_attack_pistol_001"

@export_group("Sound")
## Positional shot sound (existing player gun sounds until story 012 adds more).
@export var shot_sound: AudioStream
@export var shot_volume_db: float = 0.0
@export var shot_pitch: float = 1.0
@export var sound_max_distance: float = 40.0
@export var sound_unit_size: float = 6.0
## Overlapping shot sounds the enemy can play at once (fast SMG bursts need several).
@export var shot_polyphony: int = 1
@export var sound_bus: StringName = &"SFX"


## Rays one trigger pull casts. SINGLE and BURST fire one ray per pull.
func get_rays_per_pull() -> int:
	return maxi(pellets_per_shot, 1) if pattern == Pattern.SPREAD else 1
