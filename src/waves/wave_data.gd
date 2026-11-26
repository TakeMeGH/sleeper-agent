class_name WaveData
extends Resource
## Wave table and timings (Unity waves_arena.json). Pure queries: no node access.

@export var delay_between_waves: float = 5.0
## Seconds between spawn groups.
@export var spawn_interval: float = 0.75
@export var group_size: int = 3
## Seconds between enemies inside one group.
@export var group_spawn_interval: float = 0.4
@export var entries: Array[WaveEnemyEntry] = []
## Boss scaling; boss.enemy is the boss type. base_count and the count fields are unused.
@export var boss: WaveEnemyEntry
## A boss wave happens every this many waves (4, 8, ...).
@export var boss_interval: int = 4
@export var escort_enemies: Array[EnemyData] = []
@export var escort_counts: PackedInt32Array = PackedInt32Array()


## True when this wave is a boss wave.
func is_boss_wave(wave: int) -> bool:
	return boss != null and boss_interval > 0 and wave > 0 and wave % boss_interval == 0


## Returns {enemy id (StringName): count}. A boss wave is the boss plus its escort only.
func get_wave_mix(wave: int) -> Dictionary:
	var mix: Dictionary = {}
	if is_boss_wave(wave):
		mix[boss.enemy.id] = 1
		for i: int in mini(escort_enemies.size(), escort_counts.size()):
			var id: StringName = escort_enemies[i].id
			mix[id] = int(mix.get(id, 0)) + escort_counts[i]
		return mix
	for entry: WaveEnemyEntry in entries:
		var count: int = entry.get_count(wave)
		if count > 0:
			mix[entry.enemy.id] = count
	return mix


## Returns {health, speed, damage} multipliers for an enemy id at a wave: 1 + per_wave * (wave - 1).
func get_scaling(wave: int, id: StringName) -> Dictionary:
	var entry: WaveEnemyEntry = _find_entry(id)
	var steps: float = float(maxi(wave - 1, 0))
	if entry == null:
		return {"health": 1.0, "speed": 1.0, "damage": 1.0}
	return {
		"health": 1.0 + entry.health_scale_per_wave * steps,
		"speed": 1.0 + entry.speed_scale_per_wave * steps,
		"damage": 1.0 + entry.damage_scale_per_wave * steps,
	}


## Returns the EnemyData for an id (regular, boss or escort), or null.
func get_enemy_data(id: StringName) -> EnemyData:
	var entry: WaveEnemyEntry = _find_entry(id)
	if entry != null:
		return entry.enemy
	for e: EnemyData in escort_enemies:
		if e.id == id:
			return e
	return null


## Total enemies in a wave.
func get_wave_total(wave: int) -> int:
	var total: int = 0
	for id: StringName in get_wave_mix(wave):
		total += int(get_wave_mix(wave)[id])
	return total


func _find_entry(id: StringName) -> WaveEnemyEntry:
	if boss != null and boss.enemy != null and boss.enemy.id == id:
		return boss
	for entry: WaveEnemyEntry in entries:
		if entry.enemy != null and entry.enemy.id == id:
			return entry
	return null
