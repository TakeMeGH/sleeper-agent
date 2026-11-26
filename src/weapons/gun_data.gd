class_name GunData
extends Resource
## Data definition of one gun. All gun tuning lives in the .tres instances.

## Stable identifier used by ammo pickups (for example &"smg").
@export var gun_id: StringName = &""
@export var display_name: String = ""
@export_group("Firing")
## Damage per pellet passed to take_hit().
@export var damage: float = 1.0
## Shots per second.
@export var fire_rate: float = 1.0
## True: keeps firing while the button is held. False: one shot per press.
@export var automatic: bool = false
## Hitscan rays per shot.
@export var pellets: int = 1
## Half-angle of the spread cone, in degrees.
@export var spread_degrees: float = 0.0
## Hitscan range in metres.
@export var max_range: float = 200.0
## Strength of the push per pellet. take_hit() receives the unit shot direction
## multiplied by this value, so direction.length() is the pushback strength.
@export var pushback: float = 1.0
@export_group("Ammo")
@export var magazine_size: int = 1
## Spare ammo the gun starts with (ignored when infinite_spare).
@export var starting_spare: int = 0
## Cap on spare ammo that pickups can add up to.
@export var max_spare: int = 0
## True: reloads never run out (the pistol).
@export var infinite_spare: bool = false
## Seconds a reload takes (magazine guns; ignored when shell_load_time > 0).
@export var reload_time: float = 1.0
## Seconds per shell for a shell-by-shell reload (the shotgun, Unity shell_load_time). 0 = magazine reload.
## A shell reload loads one shell each interval until full or out of spare, and a shot interrupts it.
@export var shell_load_time: float = 0.0
