extends Node3D
## Launchable arena for story 008: bakes a navigation mesh at runtime, then starts the wave spawner.
## Story 009 builds the real levels.

## Wave the spawner starts at (4 = boss wave, 2 = first ranged enemies).
@export var start_wave: int = 1
## Seconds after load before the first wave (the navigation map needs a physics frame to sync).
@export var start_delay: float = 1.5
## Print wave events and enemy counts.
@export var log_events: bool = true

## Debug only: keeps the heart rate at or above this value each physics frame so a capture is not ended
## by a heart-rate run end. 0 = off.
@export var debug_keep_heart_rate: float = 0.0

## Debug only (story 019 capture): when not empty, no waves run; one enemy of each type is spawned at the
## matching debug_spawn_positions entry after start_delay, turned to face the player.
@export var debug_spawn_kinds: Array[EnemyData] = []
@export var debug_spawn_positions: PackedVector3Array = PackedVector3Array()

## Debug only (story 020 capture), aligned with debug_spawn_kinds: "" = live AI; "idle", "walk", "run" or
## "attack" = AI frozen and the pose held after debug_pose_seconds.
@export var debug_poses: PackedStringArray = PackedStringArray()
@export var debug_pose_seconds: float = 0.5
## Debug only (enemy parity captures), aligned with debug_spawn_kinds: skin index to force on that spawn
## (EnemyVisualData.forced_skin_index); -1 or missing = random.
@export var debug_skin_indices: PackedInt32Array = PackedInt32Array()
## Debug only: physics frames after the spawn at which the enemies listed in debug_kill_indices are shot dead
## (0 = never). debug_kill_direction is the shot direction (world).
@export var debug_kill_after_frames: int = 0
@export var debug_kill_indices: PackedInt32Array = PackedInt32Array()
@export var debug_kill_direction: Vector3 = Vector3(1, 0, 0.3)

var _debug_enemies: Array[EnemyBase] = []
var _debug_frames: int = -1

@onready var heart: HeartRate = $Player/HeartRate
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var spawner: WaveSpawner = $WaveSpawner


func _ready() -> void:
	# Synchronous bake (on_thread = false) from static colliders under the region; works headless.
	nav_region.bake_navigation_mesh(false)
	var polygons: int = nav_region.navigation_mesh.get_polygon_count()
	print("NAV baked polygons=%d vertices=%d" % [polygons, nav_region.navigation_mesh.get_vertices().size()])
	if polygons == 0:
		push_error("test_arena: navigation bake produced no polygons")
	if log_events:
		spawner.wave_started.connect(func(n: int) -> void: print("WAVE started %d mix=%s" % [n, spawner.get_wave_mix(n)]))
		spawner.wave_cleared.connect(func(n: int) -> void: print("WAVE cleared %d" % n))
		spawner.enemy_killed.connect(func(e: EnemyBase) -> void: print("KILLED %s" % e.name))
		spawner.enemies_left_changed.connect(func(c: int) -> void: print("ENEMIES left=%d" % c))
	spawner.start_delay = start_delay
	if not debug_spawn_kinds.is_empty():
		_spawn_debug_kinds()
		return
	spawner.start(start_wave)


func _physics_process(_delta: float) -> void:
	if debug_keep_heart_rate > 0.0 and heart.get_rate() < debug_keep_heart_rate:
		heart.change_rate(debug_keep_heart_rate - heart.get_rate())
	if _debug_frames >= 0 and debug_kill_after_frames > 0:
		_debug_frames += 1
		if _debug_frames == debug_kill_after_frames:
			for i: int in _debug_enemies.size():
				if debug_kill_indices.is_empty() or i in debug_kill_indices:
					if is_instance_valid(_debug_enemies[i]):
						_debug_enemies[i].take_hit(99999.0, debug_kill_direction.normalized() * 3.0)


func _spawn_debug_kinds() -> void:
	await get_tree().create_timer(start_delay, false).timeout
	for i: int in debug_spawn_kinds.size():
		var pos: Vector3 = debug_spawn_positions[i] if i < debug_spawn_positions.size() else Vector3.ZERO
		var look: EnemyVisualData = debug_spawn_kinds[i].visual
		var skin: int = debug_skin_indices[i] if i < debug_skin_indices.size() else -1
		var previous_skin: int = look.forced_skin_index if look != null else -1
		if look != null and skin >= 0:
			look.forced_skin_index = skin
		var enemy: EnemyBase = spawner.spawn_enemy(debug_spawn_kinds[i], pos, start_wave)
		if look != null:
			look.forced_skin_index = previous_skin
		enemy.rotation.y = PI
		_debug_enemies.append(enemy)
		var pose: String = debug_poses[i] if i < debug_poses.size() else ""
		if pose != "" and enemy.get_visual() != null:
			# "attack@0.43" holds the pose at 0.43 s instead of debug_pose_seconds.
			var parts: PackedStringArray = pose.split("@")
			var hold: float = float(parts[1]) if parts.size() > 1 else debug_pose_seconds
			enemy.debug_freeze_ai = true
			enemy.get_visual().debug_hold(StringName(parts[0]), hold)
	_debug_frames = 0
