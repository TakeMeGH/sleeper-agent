class_name PushablePropData
extends Resource
## Push behaviour of one kind of loose prop (canteen tables, plaza bins and railings). Used by PushableProp,
## which integrates planar rigid-body motion from these numbers; the values live in
## assets/data/levels/table_push.tres, loose_prop_push.tres and railing_push.tres.

## Text the level builder looks for in an imported prop scene's file path to turn it into a PushableProp.
@export var scene_token: String = "dynamic_table"

@export_group("Mass and friction")
## kg. Heavier = a shove moves it less and pushers need longer to bring it up to speed.
@export var mass: float = 25.0
## Floor friction coefficient (Coulomb): the free slide decelerates at friction x g. Sets how far it coasts.
@export var friction: float = 0.5
## Metres: effective radius of the floor friction torque that brakes spinning (about a third of the length).
@export var spin_friction_radius: float = 0.6
## Extra viscous slowdown per second (fraction of speed), softens the last part of a slide.
@export var linear_damping: float = 1.0
## Extra viscous slowdown of the spin per second (fraction of the turn rate).
@export var angular_damping: float = 1.5
## Bounce kept along the contact normal when it knocks into a wall or another prop (0 = dead stop).
@export_range(0.0, 1.0, 0.05) var restitution: float = 0.15
## Approach speeds (m/s) below this get no bounce, so a prop pushed against a wall rests on it instead of
## buzzing back and forth.
@export var bounce_min_speed: float = 0.6

@export_group("Limits")
## Hard cap on the prop's speed, metres per second.
@export var max_speed: float = 4.0
## Hard cap on the turn rate, degrees per second (no wild spins).
@export var max_turn_rate: float = 120.0
## Below this speed (and turn rate) with no push the prop is at rest and stops processing.
@export var rest_speed: float = 0.03
## Degrees per second.
@export var rest_turn_rate: float = 1.0
## Moved less than this fraction of the wanted distance while pushed = counted as blocked.
@export_range(0.0, 1.0, 0.05) var blocked_fraction: float = 0.25
## Collision slides per physics frame (each hit exchanges an impulse, then the rest of the motion slides).
@export var max_slides: int = 3

@export_group("Body")
## The turned box is shrunk by this much per side for the overlap check, so touching things do not veto it.
@export var rotate_shrink: float = 0.015
## Gap kept between the floor and the collider (metres).
@export var ground_clearance: float = 0.02
## Body safe margin (metres).
@export var skin: float = 0.004
## Physics layer of the prop (1 = world: the player, dive and bullets treat it like the old static prop).
@export var collision_layer: int = 1
## What stops the prop: world, enemies, player (1 | 2).
@export var collision_mask: int = 3
