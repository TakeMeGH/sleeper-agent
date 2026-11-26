class_name DeathFlowData
extends Resource
## All numbers of the death and loading flow (story 018): the collapse, the fades, the tip.
## Unity values come from player_death.json and run.json; the groups marked (ours) are new.

@export_group("Collapse")
## Metres the camera drops while the knees buckle.
@export var buckle_drop: float = 0.35
## Seconds of the buckle.
@export var buckle_seconds: float = 0.25
## Side the view falls to when nothing else decides it: &"right" or &"left".
@export var fall_side: StringName = &"right"
## Degrees of roll at rest (toward the fall side).
@export var max_roll_degrees: float = 65.0
## Degrees of nose-down tilt at rest.
@export var max_pitch_degrees: float = 30.0
## Metres the camera slides sideways while falling.
@export var fall_distance: float = 0.5
## Camera height above the floor at rest, in metres.
@export var rest_height: float = 0.3
## Radius of the sphere that keeps the camera out of walls, floor and props.
@export var camera_radius: float = 0.2
## Metres of the little bounce on landing.
@export var bounce_height: float = 0.08
## Seconds of that bounce.
@export var bounce_seconds: float = 0.2
## Seconds from the start of the buckle to the landing.
@export var collapse_seconds: float = 0.9
## Metres the arms (and the substance prop) drop out of view, camera space.
@export var arms_drop_distance: float = 0.8
## Seconds of that drop.
@export var arms_drop_seconds: float = 0.22
## Drop the gun as a physics object.
@export var drop_gun: bool = true
## Seconds after the collapse starts before the gun is released.
@export var gun_release_seconds: float = 0.08
## Downward speed given to the gun (m/s).
@export var gun_push_down: float = 1.0
## Forward speed given to the gun (m/s).
@export var gun_push_forward: float = 0.8
## Spin of the gun in degrees per second (about the view axis, toward the fall side).
@export var gun_spin_degrees: float = 200.0
## Mass of the gun body.
@export var gun_mass: float = 1.0
## Metres the floor probe looks down from the camera.
@export var floor_probe_distance: float = 6.0

@export_group("Collapse (ours)")
## Physics layers the camera sphere and the probes collide with (bit mask, 1 = layer 1, the world).
@export_flags_3d_physics var camera_collision_mask: int = 1
## Comfort scale for roll, tilt, sideways slide and bounce. 0 = the view only lowers smoothly.
## Death has its own value; the heart-rate screen keeps its own in heart_rate_screen.tres.
@export_range(0.0, 1.0, 0.05) var camera_motion_scale: float = 1.0
## A hit this recent (real seconds) before the run ends decides the fall direction.
@export var hit_window_seconds: float = 2.0
## Hits whose source is this close to the forward/back line (metres sideways) are ignored.
@export var hit_side_deadzone: float = 0.05
## Distance of the sideways wall probe in metres.
@export var wall_probe_distance: float = 1.2
## Height of the camera above the floor when no floor is found below it.
@export var fallback_eye_height: float = 1.6
## Physics layer number (1-based) of the dropped gun.
@export_range(1, 32) var gun_collision_layer: int = 8
## Bit mask the dropped gun collides with.
@export_flags_3d_physics var gun_collision_mask: int = 1
@export var gun_bounce: float = 0.15
@export var gun_friction: float = 0.9
@export var gun_linear_damp: float = 0.4
@export var gun_angular_damp: float = 2.0
## Smallest side of the gun's collision box in metres.
@export var gun_min_size: float = 0.05

@export_group("Flow")
## Seconds the world holds after the collapse before the fade starts.
@export var death_hold_seconds: float = 1.2
## Seconds of the fade to black.
@export var death_fade_seconds: float = 0.5
## Seconds of the fade-in once a level is ready.
@export var level_fade_in_seconds: float = 0.4
## Seconds of the fade to black before a restart reloads the scene.
@export var restart_fade_out_seconds: float = 0.2

@export_group("Layers and look (ours)")
## CanvasLayer numbers: world -1, viewmodel 0, look 1, vignette 2, HUD 3, fade 20, tip 25, results 30.
@export var fade_layer: int = 20
@export var tip_layer: int = 25
@export var fade_color: Color = Color(0.0, 0.0, 0.0, 1.0)
## The fade layer starts fully black (the level fades it in once ready).
@export var start_black: bool = true

@export_group("Tip (ours)")
## Seconds the tip takes to fade in, stay, and fade out. A hold of 0 (or less) shows no tip.
@export var tip_fade_in_seconds: float = 0.6
@export var tip_hold_seconds: float = 4.0
@export var tip_fade_out_seconds: float = 0.5
## Font size at 720p (canvas_items stretch scales it).
@export var tip_font_size: int = 34
@export var tip_color: Color = Color(0.92, 0.92, 0.92, 1.0)
## Fraction of the screen width the tip may use.
@export_range(0.2, 1.0, 0.05) var tip_width_ratio: float = 0.6
