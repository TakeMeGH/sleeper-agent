class_name DiveData
extends Resource
## Dive tuning (ported from Unity player_dive.json). Values: assets/data/player/dive.tres.
## Camera poses are Vector3(drop in metres, pitch in degrees nose-down, roll weight 0..1).

@export_group("Launch")
## Dash: seconds and metres moved horizontally.
@export var dash_seconds: float = 0.04
@export var dash_distance: float = 0.1
## Leap: seconds, horizontal metres and height gained (rises over peak_seconds).
@export var leap_seconds: float = 0.22
@export var leap_distance: float = 1.0
@export var leap_height: float = 1.3
@export var peak_seconds: float = 0.12
## Unity air_step_height (story 017 edge-lift): while in the leap or the fall, a horizontal block by an
## obstacle whose top is at most this many metres above the feet lifts the player over it. Taller
## obstacles still stop the horizontal movement. Also the most the lifts of one dive may add up to.
@export var air_step_height: float = 0.8
## Extra metres added above the found obstacle top when lifting, so the feet clear it.
@export var air_step_margin: float = 0.03
## Minimum look-ahead (m) used to decide the dive is blocked, even when one frame's move is shorter.
@export var air_step_probe_distance: float = 0.12
## Highest the edge-lift may put the feet, in metres above the floor the dive started from. Keeps the
## lift from stacking on the leap apex and reaching props the plain dive cannot (story 017). Default = leap_height.
@export var air_step_max_reach: float = 1.3
## Bisection steps used to find the exact lift height (resolution = air_step_height / 2^steps).
@export var air_step_search_steps: int = 6

@export_group("Airborne")
## The fall covers fall_distance in fall_seconds. This also defines the dive gravity
## (2 * fall_distance / fall_seconds^2) and the horizontal speed while airborne.
@export var fall_seconds: float = 0.26
@export var fall_distance: float = 1.3
## Multiplier on the leap and fall phase times when the dive starts in slow motion (story 016).
@export var slow_motion_hang_factor: float = 2.0

## No-stuck guards: the airborne phase ends after max_airborne_seconds, or after stall_frames
## physics frames off the floor with real speed below stall_speed (m/s).
@export var max_airborne_seconds: float = 1.5
@export var stall_speed: float = 0.1
@export var stall_frames: int = 6

@export_group("Ground")
## Physics frames off the floor before SLIDE/GET_UP turn into AIRBORNE (bumpy ground, stairs).
@export var hop_frames: int = 4
@export var lying_seconds: float = 0.45
## Multiplier on the horizontal speed carried from the fall into the slide.
@export var slide_speed_scale: float = 1.0
## Metres per second squared removed from the slide speed.
@export var slide_deceleration: float = 7.5
@export var stand_seconds: float = 0.6
## Seconds after getting up before another dive can start.
@export var cooldown_seconds: float = 1.2

@export_group("Speed scaling")
## Dive distance factor = clamp(1 + (speed_multiplier - 1) * influence, 1, max_speed_factor).
@export var speed_factor_influence: float = 1.0
@export var max_speed_factor: float = 2.0

@export_group("Camera")
@export var camera_dash: Vector3 = Vector3(0.25, 4.0, 0.6)
@export var camera_leap: Vector3 = Vector3(0.45, 7.0, 1.0)
@export var camera_fall: Vector3 = Vector3(0.8, 5.0, 0.7)
@export var camera_lying: Vector3 = Vector3(1.1, 3.0, 0.2)
## Full roll in degrees (times the pose roll weight and the sideways share of the dive).
@export var roll_degrees: float = 12.0
## Share of roll_degrees applied as extra nose-down pitch for the forward share of the dive.
@export var forward_roll_fraction: float = 0.5
## Landing bump: seconds, extra drop (m) and extra pitch (deg), a sine pulse.
@export var landing_impact_seconds: float = 0.25
@export var landing_impact_drop: float = 0.12
@export var landing_impact_pitch: float = 3.0
## Camera follow rate (1/s) for the exponential smoothing toward the target pose. New, not in Unity.
@export var camera_smoothing: float = 14.0
