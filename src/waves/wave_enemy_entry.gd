class_name WaveEnemyEntry
extends Resource
## One enemy type in the wave table: how many per wave and how it scales (waves_arena.json "enemies" entries).

@export var enemy: EnemyData
## First wave in which this type appears.
@export var first_wave: int = 1
@export var base_count: int = 6
@export var extra_per_wave: int = 2
@export var max_count: int = 20
@export var health_scale_per_wave: float = 0.1
@export var speed_scale_per_wave: float = 0.03
@export var damage_scale_per_wave: float = 0.1


## Count for a wave: min(base + extra * (wave - first_wave), max), or 0 before first_wave.
func get_count(wave: int) -> int:
	if wave < first_wave:
		return 0
	return mini(base_count + extra_per_wave * (wave - first_wave), max_count)
