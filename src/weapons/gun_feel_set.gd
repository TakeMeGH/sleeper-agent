class_name GunFeelSet
extends Resource
## All shooting-feel data: one GunFeelData per gun plus the shared hitstop, push and crosshair values.

@export var guns: Array[GunFeelData] = []
@export_group("Muzzle flash")
## Flash sprites (white on transparent); one is picked at random per shot.
@export var muzzle_textures: Array[Texture2D] = []
@export_group("Hitstop")
## Engine time scale during hitstop (Unity used 0; kept above 0 so physics still ticks and input is seen).
@export var hitstop_time_scale: float = 0.05
## Total real seconds of hitstop that can be pending at once (kills close together never exceed this).
@export var hitstop_max_seconds: float = 0.12
@export_group("Kill")
## Horizontal speed (m/s) a killed body is pushed along the shot, per unit of gun pushback.
@export var kill_push_speed_per_pushback: float = 2.0
@export_group("Crosshair")
@export var crosshair_color: Color = Color(1.0, 1.0, 1.0, 0.85)
## Distance of each tick from the centre, tick length and line width, in pixels.
@export var crosshair_gap: float = 6.0
@export var crosshair_length: float = 9.0
@export var crosshair_thickness: float = 2.0
@export var hit_marker_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var hit_marker_seconds: float = 0.12
@export var hit_marker_gap: float = 7.0
@export var hit_marker_length: float = 8.0
@export var kill_marker_color: Color = Color(1.0, 0.15, 0.1, 1.0)
@export var kill_marker_seconds: float = 0.3
@export var kill_marker_gap: float = 8.0
@export var kill_marker_length: float = 13.0
@export var marker_thickness: float = 3.0
