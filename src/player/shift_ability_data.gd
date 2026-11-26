class_name ShiftAbilityData
extends Resource
## Tuning for the Shift ability (slow motion / superspeed). Durations and cooldown are REAL seconds.

@export_group("Slow motion")
## Engine.time_scale while slow motion runs.
@export var slow_time_scale: float = 0.3
## Time scale of the player (movement, weapons, arms, dive) while slow motion runs (story 016).
@export var player_time_scale: float = 0.7
## Real seconds slow motion lasts.
@export var slow_seconds: float = 7.0

@export_group("Superspeed")
## Player move speed multiplier while superspeed runs.
@export var superspeed_multiplier: float = 1.8
## Real seconds superspeed lasts.
@export var superspeed_seconds: float = 8.0

@export_group("Cooldown")
## Real seconds after an effect ends before Shift can start another.
@export var cooldown_seconds: float = 8.0
