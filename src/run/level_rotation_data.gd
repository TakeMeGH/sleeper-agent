class_name LevelRotationData
extends Resource
## Level rotation tuning (Unity levels.json): order of levels, waves per visit and travel fades.

## Level ids in rotation order; the rotation wraps around.
@export var level_ids: PackedStringArray = PackedStringArray()
## Level scenes, parallel to level_ids.
@export var level_scenes: Array[PackedScene] = []
## Waves cleared in one level visit before the exit opens.
@export var waves_per_visit: int = 3
## Seconds to fade to black when travelling (0 = no fade).
@export var travel_fade_out_seconds: float = 0.6
## Seconds to fade back in on the new level (0 = no fade).
@export var travel_fade_in_seconds: float = 0.5
## Seconds after a level loads before its first wave starts.
@export var first_wave_delay: float = 1.5


## Index of a level id, or -1.
func index_of(id: StringName) -> int:
	return level_ids.find(String(id))
