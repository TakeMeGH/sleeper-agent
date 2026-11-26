class_name EnemyPushData
extends Resource
## How enemies push loose props and what they do when pinned against one (story 021).
## Values: assets/data/enemies/enemy_push.tres.

## Target speed of the pushed contact point as a fraction of the enemy's wanted speed along the contact
## (the enemy walks at about this fraction of its speed while pushing).
@export var push_speed_factor: float = 0.85
## Steady push force (newtons) an enemy can put into a prop; with the prop's mass and friction it sets how
## quickly a shoved prop gets up to speed.
@export var push_force: float = 450.0
## Body mass (kg) used for the first-contact shove: the enemy's momentum along the contact is shared with
## the prop (scaled by impact_fraction), so the prop lurches on impact instead of easing off from zero.
@export var body_mass: float = 80.0
## Fraction of the full momentum exchange applied as the first-contact shove (0 = no shove).
@export_range(0.0, 1.0, 0.05) var impact_fraction: float = 0.6
## Boss multiplier on push_force and body_mass (strength).
@export var boss_push_factor: float = 3.0
## A pushed prop stays "in contact" (and keeps being pushed) while the gap between this enemy's body and
## the prop's footprint is below this (metres), so a frame without a slide collision does not drop the push.
@export var push_keep_gap: float = 0.12
## Gap (metres) the enemy holds to the prop it pushes: just outside the collision skins, so its body
## follows the prop without bumping into it each frame (a bump zeroes its slide for that frame).
@export var push_hold_gap: float = 0.05
## How fast (per second) the enemy closes a small gap to the prop it is pushing (capped by push_close_speed).
@export var push_close_gain: float = 10.0
## While pushing, the enemy may close on the prop this much faster (m/s) than the prop's contact moves, so
## the contact holds without the enemy slamming into it.
@export var push_close_speed: float = 0.35
## Forward lean of the enemy's body while pushing (degrees, at full push).
@export var push_lean_degrees: float = 12.0
## Seconds the lean takes to blend in and out.
@export var push_lean_blend_seconds: float = 0.2
## Fraction of the enemy's wanted speed that must point into the prop for it to push (cosine of the
## approach angle): an enemy brushing along a side slides past instead of nudging and wobbling the prop.
@export_range(0.0, 1.0, 0.05) var push_min_alignment: float = 0.4
## Once pushing, the enemy keeps pushing while this fraction of its wanted speed still points into the prop
## (lower than push_min_alignment, so a path that wavers a little does not make the push stutter).
@export_range(0.0, 1.0, 0.05) var push_hold_alignment: float = 0.2
## Speed along the contact normal (m/s) below which an enemy does not push.
@export var min_push_speed: float = 0.3
## Seconds blocked (see stuck_min_progress) before a detour starts.
@export var stuck_seconds: float = 1.0
## Real horizontal speed (m/s) below which a moving enemy counts as blocked.
@export var stuck_min_progress: float = 0.6
## Desired speed (m/s) above which an enemy counts as wanting to move.
@export var wants_move_speed: float = 1.0
## Seconds a prop contact stays "the blocker" after the last touch.
@export var blocker_memory_seconds: float = 2.0
## Seconds before a detour (all its waypoints) is given up.
@export var detour_timeout_seconds: float = 4.0
## Metres from the detour point that count as arrived.
@export var detour_arrive_distance: float = 0.6
## Largest height difference (m) between the snapped detour point and the enemy.
@export var detour_max_height_error: float = 0.2
## Height above the detour point (m) at which the "inside a solid body" point check is made.
@export var detour_clear_height: float = 0.9
## Extra clearance (m, on top of the body radius) kept from the prop side while walking round it.
@export var detour_clearance: float = 0.4
## How far (m) past the prop far face the second waypoint is placed.
@export var detour_pass_distance: float = 1.0
## Distance (m) walked back along the contact normal when both sides fail.
@export var detour_backoff_distance: float = 1.5
## A stuck enemy with no recent prop contact detours around a prop whose footprint is within this many metres.
@export var detour_near_prop_range: float = 1.0
## Window (s) over which the average real speed decides "blocked" (creeping or jittering counts).
@export var stuck_window_seconds: float = 0.4
