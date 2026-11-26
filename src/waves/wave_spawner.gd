class_name WaveSpawner
extends Node
## Runs waves of melee/ranged enemies (and a boss every few waves) at Marker3D spawn points
## (group `spawn_point`). Feeds the HUD's RunState with wave and enemies left. A spawn point with a SpawnDoor
## (canteen) has its door started burst_time seconds before each group's first member and closed after the last.

signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal enemies_left_changed(count: int)
signal enemy_killed(enemy: EnemyBase)

const GROUP_SPAWN: StringName = &"spawn_point"

@export var data: WaveData
@export var drop_data: DropData
@export var run_state: RunState
## Node enemies are added under; defaults to the spawner's parent.
@export var enemy_parent: Node
@export var start_wave: int = 1
## Seconds before the first wave when start() is called.
@export var start_delay: float = 1.5
@export var auto_start: bool = false
## Seeds the spawner's rng when non-zero. Spawn order and points are deterministic (story 019) and no
## longer use it; kept for callers that set it.
@export var rng_seed: int = 0
## Radius (metres, horizontal) of the ring a group's later members are placed on around the spawn point,
## so a group does not stack. Deterministic: member k sits at angle k x golden angle (member 0 on the marker).
@export var spawn_jitter: float = 1.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _wave: int = 0
var _running: bool = false
var _run_id: int = 0
var _queue: Array[EnemyData] = []
var _queue_wave: int = 0
var _alive: Array[EnemyBase] = []
var _kills: int = 0
var _wave_limit: int = 0
var _waves_done: int = 0
## Groups spawned since start(); the next group uses point (this mod point count).
var _group_counter: int = 0


func _ready() -> void:
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	if auto_start:
		start()


## Starts running waves from first_wave (or start_wave when < 1) after start_delay.
## wave_limit > 0 stops the spawner after that many waves have been cleared (a level visit);
## 0 keeps spawning forever (test arenas).
func start(first_wave: int = -1, wave_limit: int = 0) -> void:
	_wave = (first_wave if first_wave > 0 else start_wave) - 1
	_wave_limit = wave_limit
	_waves_done = 0
	_group_counter = 0
	_prune()
	_running = true
	_run_id += 1
	_run(_run_id)


## Stops spawning; living enemies stay.
func stop() -> void:
	_running = false
	_run_id += 1
	_queue.clear()
	_prune()
	_publish()
	if is_inside_tree():
		for node: Node in get_tree().get_nodes_in_group(SpawnDoor.GROUP):
			(node as SpawnDoor).close()


## Current wave number (0 before the first wave).
func get_wave() -> int:
	return _wave


## Enemies still to spawn plus enemies alive.
func get_enemies_left() -> int:
	return _queue.size() + _alive.size()


## Kills since start.
func get_kills() -> int:
	return _kills


## {enemy id: count} for a wave. See WaveData.get_wave_mix.
func get_wave_mix(wave: int) -> Dictionary:
	return data.get_wave_mix(wave)


## {health, speed, damage} multipliers for an enemy id at a wave. See WaveData.get_scaling.
func get_wave_scaling(wave: int, id: StringName) -> Dictionary:
	return data.get_scaling(wave, id)


## Builds the spawn queue for a wave: mix order (wave table order), no shuffle.
func build_wave_queue(wave: int) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	var mix: Dictionary = data.get_wave_mix(wave)
	for id: StringName in mix:
		var enemy_data: EnemyData = data.get_enemy_data(id)
		for i: int in int(mix[id]):
			out.append(enemy_data)
	return out


## Splits a wave total into groups of group_size; the last group takes the rest (7, 3 -> [3, 3, 1]).
static func split_groups(total: int, size: int) -> Array[int]:
	var out: Array[int] = []
	var step: int = maxi(size, 1)
	var left: int = maxi(total, 0)
	while left > 0:
		var n: int = mini(step, left)
		out.append(n)
		left -= n
	return out


## Deterministic spawn plan for a list of enemy ids: [{id, group, member, point_index, time}].
## Group g uses point (first_group + g) mod point_count; member k spawns within_seconds after member k-1;
## the next group starts between_seconds after its predecessor's last member.
static func build_spawn_plan(ids: Array[StringName], size: int, within_seconds: float,
		between_seconds: float, point_count: int, first_group: int = 0) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var index: int = 0
	var start_time: float = 0.0
	var sizes: Array[int] = split_groups(ids.size(), size)
	for g: int in sizes.size():
		for k: int in sizes[g]:
			plan.append({
				&"id": ids[index],
				&"group": g,
				&"member": k,
				&"point_index": (first_group + g) % maxi(point_count, 1),
				&"time": start_time + float(k) * within_seconds,
			})
			index += 1
		start_time += float(sizes[g] - 1) * within_seconds + between_seconds
	return plan


## Spawn plan of a wave with the data's group size and timings. point_count < 0 uses the number of
## spawn_point markers in the tree. first_group is the round-robin offset (the live spawner continues
## across waves; 0 restarts at the first point).
func get_spawn_plan(wave: int, point_count: int = -1, first_group: int = 0) -> Array[Dictionary]:
	var ids: Array[StringName] = []
	for enemy_data: EnemyData in build_wave_queue(wave):
		ids.append(enemy_data.id)
	var points: int = point_count if point_count >= 0 else _get_points().size()
	return build_spawn_plan(ids, data.group_size, data.group_spawn_interval, data.spawn_interval, points, first_group)


## Horizontal offset of group member k on the ring around the spawn point (member 0 = no offset).
static func jitter_offset(member: int, radius: float) -> Vector3:
	if member <= 0:
		return Vector3.ZERO
	var angle: float = float(member) * 2.399963
	return Vector3(cos(angle), 0.0, sin(angle)) * radius


## Spawns one enemy of the given type at a world position with the wave's scaling applied.
func spawn_enemy(enemy_data: EnemyData, world_position: Vector3, wave: int) -> EnemyBase:
	var enemy: EnemyBase
	match enemy_data.kind:
		EnemyData.Kind.RANGED:
			enemy = RangedEnemy.new()
		EnemyData.Kind.BOSS:
			enemy = BossEnemy.new()
		_:
			enemy = MeleeEnemy.new()
	var scaling: Dictionary = data.get_scaling(wave, enemy_data.id)
	enemy.name = "%s_%d" % [enemy_data.id, _kills + _alive.size() + 1]
	enemy.data = enemy_data
	enemy.drop_data = drop_data
	enemy.health_multiplier = scaling["health"]
	enemy.speed_multiplier = scaling["speed"]
	enemy.damage_multiplier = scaling["damage"]
	var parent: Node = enemy_parent if enemy_parent != null else get_parent()
	parent.add_child(enemy)
	enemy.global_position = world_position
	enemy.died.connect(_on_enemy_died)
	_alive.append(enemy)
	return enemy


func _is_current(id: int) -> bool:
	return is_inside_tree() and _running and id == _run_id


func _run(id: int) -> void:
	await get_tree().create_timer(start_delay, false).timeout
	while _is_current(id):
		_wave += 1
		await _run_wave(id)
		if not _is_current(id):
			return
		_waves_done += 1
		if _wave_limit > 0 and _waves_done >= _wave_limit:
			_running = false
			return
		await get_tree().create_timer(data.delay_between_waves, false).timeout


func _run_wave(id: int) -> void:
	_queue_wave = _wave
	_queue = build_wave_queue(_wave)
	var plan: Array[Dictionary] = get_spawn_plan(_wave, -1, _group_counter)
	_group_counter += split_groups(plan.size(), data.group_size).size()
	var doors: Array[SpawnDoor] = _get_doors()
	var leads: Array[float] = []
	for door: SpawnDoor in doors:
		leads.append(door.get_open_lead() if door != null else 0.0)
	var schedule: Array[Dictionary] = build_door_schedule(plan, leads)
	wave_started.emit(_wave)
	_publish()
	var previous_time: float = 0.0
	for event: Dictionary in schedule:
		var wait: float = float(event[&"time"]) - previous_time
		previous_time = float(event[&"time"])
		if wait > 0.0:
			await get_tree().create_timer(wait, false).timeout
		if not _is_current(id) or _queue.is_empty():
			return
		var point_index: int = int(event[&"point_index"])
		var door: SpawnDoor = doors[point_index] if point_index < doors.size() else null
		if event[&"kind"] == &"open":
			door.open()
			continue
		_spawn_next(point_index, int(event[&"member"]))
		if door != null and bool(event[&"last_member"]):
			door.close_after_delay()
	while true:
		if not _is_current(id):
			return
		_prune()
		if _alive.is_empty():
			break
		await get_tree().process_frame
	wave_cleared.emit(_wave)


## Turns a spawn plan (see build_spawn_plan) into timed events: [{kind, time, point_index, member, last_member}],
## sorted by time. kind &"spawn" is one plan entry; a point with a door (leads[point_index] > 0) also gets a
## kind &"open" event leads[point_index] seconds before its group's first member, so the enemy comes through as
## the door bursts open. When an open would fall before 0 the whole wave is shifted later by that much. With no
## doors (all leads 0, or leads empty) the events are the plan's spawns at the plan's times.
static func build_door_schedule(plan: Array[Dictionary], leads: Array[float]) -> Array[Dictionary]:
	var shift: float = 0.0
	for entry: Dictionary in plan:
		if int(entry[&"member"]) == 0:
			shift = maxf(shift, _lead_of(leads, int(entry[&"point_index"])) - float(entry[&"time"]))
	var events: Array[Dictionary] = []
	for i: int in plan.size():
		var entry: Dictionary = plan[i]
		var point_index: int = int(entry[&"point_index"])
		var time: float = float(entry[&"time"]) + shift
		var lead: float = _lead_of(leads, point_index)
		if int(entry[&"member"]) == 0 and lead > 0.0:
			events.append({&"kind": &"open", &"time": time - lead, &"point_index": point_index,
				&"member": -1, &"last_member": false, &"seq": events.size()})
		var last: bool = i + 1 >= plan.size() or int(plan[i + 1][&"group"]) != int(entry[&"group"])
		events.append({&"kind": &"spawn", &"time": time, &"point_index": point_index,
			&"member": int(entry[&"member"]), &"last_member": last, &"seq": events.size()})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a[&"time"]), float(b[&"time"])):
			return float(a[&"time"]) < float(b[&"time"])
		return int(a[&"seq"]) < int(b[&"seq"]))
	return events


static func _lead_of(leads: Array[float], point_index: int) -> float:
	return leads[point_index] if point_index >= 0 and point_index < leads.size() else 0.0


## The SpawnDoor of each spawn point (same order as the points), null where a point has none.
func _get_doors() -> Array[SpawnDoor]:
	var doors: Array[SpawnDoor] = []
	for point: Node3D in _get_points():
		doors.append(SpawnDoor.find_for_point(get_tree(), point))
	return doors


func _spawn_next(point_index: int, member: int) -> void:
	var enemy_data: EnemyData = _queue.pop_front()
	spawn_enemy(enemy_data, _spawn_position(point_index, member), _queue_wave)
	_publish()


func _get_points() -> Array[Node3D]:
	var points: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group(GROUP_SPAWN):
		if node is Node3D:
			points.append(node as Node3D)
	# Sorted by path so the round-robin order does not depend on group insertion order.
	points.sort_custom(func(a: Node3D, b: Node3D) -> bool: return str(a.get_path()).naturalnocasecmp_to(str(b.get_path())) < 0)
	return points


func _spawn_position(point_index: int, member: int) -> Vector3:
	var points: Array[Node3D] = _get_points()
	if points.is_empty():
		push_warning("WaveSpawner: no nodes in group 'spawn_point'; spawning at the origin")
		return Vector3.ZERO
	return points[point_index % points.size()].global_position + jitter_offset(member, spawn_jitter)


func _exit_tree() -> void:
	stop()


func _on_enemy_died(enemy: EnemyBase) -> void:
	_alive.erase(enemy)
	_kills += 1
	enemy_killed.emit(enemy)
	_publish()


func _prune() -> void:
	var before: int = _alive.size()
	var kept: Array[EnemyBase] = []
	for e: EnemyBase in _alive:
		if is_instance_valid(e):
			kept.append(e)
	_alive = kept
	if _alive.size() != before:
		_publish()


func _publish() -> void:
	var left: int = get_enemies_left()
	if run_state != null:
		run_state.wave = _wave
		run_state.enemies_left = left
	enemies_left_changed.emit(left)
