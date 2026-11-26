class_name SubstanceData
extends Resource
## Data for one consumable substance (coffee, cigarette). All tuning lives in the .tres files.

## Kind id used by SubstanceInventory and its signals, e.g. &"coffee".
@export var kind: StringName = &""
## Name shown to the player.
@export var display_name: String = ""
## Input action polled while the player holds the button.
@export var input_action: StringName = &""
## Accumulated hold seconds that use up one unit.
@export var seconds_per_item: float = 1.0
## Units the player starts a run with.
@export var start_count: int = 0
## Cap on the count (applied by add_substance).
@export var max_count: int = 1
## Ramp point times in held seconds (ascending). Same length as ramp_bpm_per_second.
@export var ramp_seconds: PackedFloat32Array = PackedFloat32Array()
## Ramp point values: bpm gained per second at the matching ramp_seconds entry.
@export var ramp_bpm_per_second: PackedFloat32Array = PackedFloat32Array()


## Rate change in bpm per second after the button has been held for held_seconds.
## Linear between points; the first value before the first point and the last value after the last.
func bpm_per_second(held_seconds: float) -> float:
	var count: int = mini(ramp_seconds.size(), ramp_bpm_per_second.size())
	if count == 0:
		return 0.0
	if held_seconds <= ramp_seconds[0]:
		return ramp_bpm_per_second[0]
	for i: int in range(1, count):
		if held_seconds <= ramp_seconds[i]:
			var span: float = ramp_seconds[i] - ramp_seconds[i - 1]
			if span <= 0.0:
				return ramp_bpm_per_second[i]
			var t: float = (held_seconds - ramp_seconds[i - 1]) / span
			return lerpf(ramp_bpm_per_second[i - 1], ramp_bpm_per_second[i], t)
	return ramp_bpm_per_second[count - 1]
