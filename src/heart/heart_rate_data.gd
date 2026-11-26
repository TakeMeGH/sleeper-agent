class_name HeartRateData
extends Resource
## Tunable numbers for the heart rate system (story 002). Ported defaults from the Unity reference.

@export_group("Rate")
## Rate at the start of a run (bpm).
@export var resting_rate: float = 80.0
## Continuous fall per second at every rate (bpm/s).
@export var drop_per_second: float = 3.0
## Rate lost per point of damage taken by a hit (bpm per damage).
@export var bpm_per_damage: float = 1.0
@export var min_rate: float = 0.0
@export var max_rate: float = 250.0

@export_group("Zones")
## Lower bound (inclusive) of the slow zone; below this is "passed out" territory.
@export var slow_from: float = 10.0
## Lower bound (inclusive) of the normal zone.
@export var normal_from: float = 60.0
## Lower bound (inclusive) of the fast zone.
@export var fast_from: float = 100.0
## Upper bound (inclusive) of the fast zone; strictly above this is "heart attack" territory.
@export var heart_attack_above: float = 190.0
## Seconds in a row below slow_from before the run ends as passed out.
@export var pass_out_seconds: float = 5.0
## Seconds in a row above heart_attack_above before the run ends as heart attack.
@export var heart_attack_seconds: float = 5.0

@export_group("Modifiers")
## Aim spread multiplier in the slow zone (below 1 = steadier).
@export var slow_zone_spread_scale: float = 0.5
## Movement speed multiplier in the fast zone (above 1 = faster).
@export var fast_zone_speed_multiplier: float = 1.3
## Aim tremor amplitude (degrees) at the bottom / top of the fast zone.
@export var tremor_amplitude_min: float = 0.15
@export var tremor_amplitude_max: float = 1.0
## Aim tremor frequency (Hz) at the bottom / top of the fast zone.
@export var tremor_frequency_min: float = 2.0
@export var tremor_frequency_max: float = 8.0
## Ratio of the pitch tremor oscillation frequency to the yaw one.
@export var tremor_pitch_phase_ratio: float = 1.3
