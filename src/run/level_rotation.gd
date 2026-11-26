class_name LevelRotation
extends Node3D
## Root of the game scene. Owns the persistent run (Player, HUD, RunState, WaveSpawner) and swaps level
## scenes in and out of `level_holder`: canteen -> plaza -> canteen ... Each visit runs
## `waves_per_visit` waves; the exit opens when the last one is cleared. Wave number, heart rate,
## ammo, substances and time survived live in nodes that are never freed, so they carry over.

signal level_loaded(level_id: StringName, visit_index: int)
signal exit_opened(level_id: StringName)
signal travel_started(from_level_id: StringName)

@export var data: LevelRotationData
@export var notice_data: LevelNoticeData
@export var spawner: WaveSpawner
@export var player: CharacterBody3D
@export var run_state: RunState
@export var heart: HeartRate
@export var level_holder: Node3D
## The single fade layer (story 018). Levels start black and fade in once ready; travel uses it too.
@export var screen_fade: ScreenFade
## Level id to start at (empty = first of the rotation).
@export var start_level_id: StringName = &""
## Print level and wave events.
@export var log_events: bool = true

@export_group("Debug")
## Keeps the screen black after the first level is ready (capture of the black loading screen).
@export var debug_hold_level_black: bool = false
## Opens the exit as soon as a level loads and runs no waves.
@export var debug_open_exit_immediately: bool = false
## Keeps the heart rate at or above this each physics frame (0 = off).
@export var debug_keep_heart_rate: float = 0.0
## Ends the run this many seconds after the scene starts by driving the real HeartRate (0 = off).
@export var debug_end_run_after_seconds: float = 0.0
## Reason to end with: HeartRate.REASON_PASSED_OUT or REASON_HEART_ATTACK.
@export var debug_end_reason: StringName = &"passed_out"
## Danger countdown used by the debug end (seconds; the real value is 5 s). Applied to a copy of the heart data.
@export var debug_end_countdown_seconds: float = 0.5
## Kills, time survived (seconds) and wave to preset just before the debug end (0 = leave as is).
@export var debug_preset_kills: int = 0
@export var debug_preset_time_seconds: float = 0.0
@export var debug_preset_wave: int = 0

## Places the player at debug_player_position facing debug_player_yaw_degrees once the first level is loaded.
@export var debug_override_player_pose: bool = false
@export var debug_player_position: Vector3 = Vector3.ZERO
@export var debug_player_yaw_degrees: float = 0.0
## Physics frame at which DiveState.try_start(debug_dive_input) is called (0 = off); prints DIVE phase lines.
@export var debug_dive_after_frames: int = 0
## Dive input in move_left/right/forward/back space (x right, y back); ZERO dives forward.
@export var debug_dive_input: Vector2 = Vector2.ZERO

## Debug only: enemies spawned (wave-free, with debug_open_exit_immediately) 2 physics frames after the
## level loads, at debug_spawn_positions (same index).
@export var debug_spawn_kinds: Array[EnemyData] = []
@export var debug_spawn_positions: PackedVector3Array = PackedVector3Array()

var _debug_frames: int = 0
var _level_index: int = 0
var _visit_index: int = 0
var _level: LevelBase
var _waves_cleared_in_visit: int = 0
var _last_cleared_wave: int = 0
var _visit_start_wave: int = 1
var _traveling: bool = false
var _level_ready: bool = false
## Set when the run ends: a level change in progress stops without touching the level or the fade.
var _run_over: bool = false
var _cleared_label: Label
var _exit_label: Label
var _notice_token: int = 0
## While true the visit's waves are not started (tutorial opening); they start on release.
var _wave_hold: bool = false
var _wave_start_pending: bool = false


func _ready() -> void:
	_build_overlay()
	spawner.wave_cleared.connect(_on_wave_cleared)
	run_state.run_ended.connect(_on_run_ended)
	if log_events:
		spawner.wave_started.connect(func(n: int) -> void: print("WAVE started %d" % n))
		spawner.wave_cleared.connect(func(n: int) -> void: print("WAVE cleared %d" % n))
	_level_index = maxi(data.index_of(start_level_id), 0)
	_last_cleared_wave = spawner.start_wave - 1
	_load_level(_level_index)
	_fade_in_first_level()
	if debug_override_player_pose:
		player.global_position = debug_player_position
		player.rotation_degrees.y = debug_player_yaw_degrees
		player.velocity = Vector3.ZERO
	var dive: DiveState = player.get_node_or_null("DiveState") as DiveState
	if dive != null and debug_dive_after_frames > 0:
		dive.phase_changed.connect(_on_debug_dive_phase_changed)
	if debug_end_run_after_seconds > 0.0:
		_debug_end_run()
	if not debug_spawn_kinds.is_empty():
		_debug_spawn_enemies()


func _debug_spawn_enemies() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i: int in debug_spawn_kinds.size():
		var pos: Vector3 = debug_spawn_positions[i] if i < debug_spawn_positions.size() else Vector3.ZERO
		spawner.spawn_enemy(debug_spawn_kinds[i], pos, 1)


func _physics_process(_delta: float) -> void:
	_debug_frames += 1
	if debug_dive_after_frames > 0 and _debug_frames == debug_dive_after_frames:
		var dive: DiveState = player.get_node_or_null("DiveState") as DiveState
		var controller: PlayerController = player as PlayerController
		if dive != null and controller != null:
			var speed_multiplier: float = heart.get_speed_multiplier()
			if controller.shift_ability != null:
				speed_multiplier *= controller.shift_ability.get_speed_multiplier()
			dive.try_start(debug_dive_input, speed_multiplier)
	if debug_keep_heart_rate > 0.0 and heart != null and heart.get_rate() < debug_keep_heart_rate:
		heart.change_rate(debug_keep_heart_rate - heart.get_rate())


## Holds (true) or releases (false) the start of the visit's waves. While held, a level load only
## remembers that the waves are due; releasing starts them (unless the run ended). Never held = old behaviour.
func set_wave_hold(held: bool) -> void:
	_wave_hold = held
	if not held and _wave_start_pending:
		_wave_start_pending = false
		if not _run_over and is_inside_tree():
			_start_visit_waves()


## True while the wave start is held.
func is_wave_held() -> bool:
	return _wave_hold


## Id of the level currently loaded.
func get_current_level_id() -> StringName:
	return StringName(data.level_ids[_level_index])


## Zero-based count of level changes so far (0 = first visit).
func get_visit_index() -> int:
	return _visit_index


## Waves cleared in the current visit (the exit opens at waves_per_visit).
func get_waves_cleared_in_visit() -> int:
	return _waves_cleared_in_visit


## First wave number of the next visit (last cleared wave + 1).
func get_next_first_wave() -> int:
	return _last_cleared_wave + 1


## True while a level change is in progress.
func is_traveling() -> bool:
	return _traveling


## The loaded level scene root.
func get_level() -> LevelBase:
	return _level


## True when the current level's exit is open.
func is_exit_open() -> bool:
	return _level != null and _level.get_exit().is_exit_open()


func _on_debug_dive_phase_changed(phase: DiveState.Phase, _previous: DiveState.Phase) -> void:
	print("DIVE phase=%s frame=%d pos=%s" % [DiveState.Phase.keys()[phase], _debug_frames, player.global_position])


## Opens the current exit now (the wave-clear path and a debug shortcut).
func open_exit() -> void:
	if _level == null or _level.get_exit().is_exit_open():
		return
	_level.get_exit().open()
	_show_exit_notice()
	exit_opened.emit(get_current_level_id())
	if log_events:
		print("EXIT open level=%s" % get_current_level_id())


## Debug: kills every living enemy (several hits so boss armour does not stop it).
func debug_kill_enemies() -> void:
	for i: int in 30:
		var alive: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
		if alive.is_empty():
			return
		for e: Node in alive:
			if is_instance_valid(e) and e.has_method(&"take_hit"):
				e.call(&"take_hit", 1000000.0, Vector3.ZERO)


## Debug: ends the visit as if all its waves were cleared: stops the spawner, removes enemies, sets the
## wave counter to the visit's last wave and opens the exit.
func debug_force_visit_cleared() -> void:
	spawner.stop()
	_free_dynamic_nodes()
	_last_cleared_wave = _visit_start_wave + data.waves_per_visit - 1
	_waves_cleared_in_visit = data.waves_per_visit
	run_state.wave = _last_cleared_wave
	run_state.enemies_left = 0
	open_exit()


## Leaves the current level through the exit: fade out, load the next level, fade in, start its waves.
## The next visit's first wave is the last cleared wave + 1.
func travel_to_next_level() -> void:
	if _traveling:
		return
	if _run_over:
		return
	_traveling = true
	travel_started.emit(get_current_level_id())
	spawner.stop()
	_free_dynamic_nodes()
	await _fade_to(1.0, data.travel_fade_out_seconds)
	if _run_over:
		_traveling = false
		return
	_level_index = (_level_index + 1) % data.level_ids.size()
	_visit_index += 1
	_load_level(_level_index)
	await _wait_level_ready()
	if _run_over:
		_traveling = false
		return
	await _fade_to(0.0, data.travel_fade_in_seconds)
	_traveling = false


## Waits, presets the run totals, then pushes the heart rate out of range with a short countdown so
## HeartRate itself ends the run (nothing is faked on the results screen).
func _debug_end_run() -> void:
	await get_tree().create_timer(debug_end_run_after_seconds).timeout
	if not is_instance_valid(heart) or heart.has_ended():
		return
	run_state.debug_set_totals(debug_preset_kills, debug_preset_time_seconds, debug_preset_wave)
	var short: HeartRateData = heart.data.duplicate() as HeartRateData
	short.pass_out_seconds = debug_end_countdown_seconds
	short.heart_attack_seconds = debug_end_countdown_seconds
	heart.data = short
	if debug_end_reason == HeartRate.REASON_HEART_ATTACK:
		heart.change_rate(1000.0)
	else:
		heart.change_rate(-1000.0)


func _load_level(index: int) -> void:
	if _level != null:
		level_holder.remove_child(_level)
		_level.queue_free()
		_level = null
	_hide_notices()
	var scene: PackedScene = data.level_scenes[index]
	_level = scene.instantiate() as LevelBase
	if _level == null:
		push_error("LEVEL scene %d is not a LevelBase" % index)
		return
	level_holder.add_child(_level)
	_level.get_exit().close()
	var start: Transform3D = _level.get_player_start_transform()
	player.global_position = start.origin + Vector3(0.0, 0.05, 0.0)
	player.global_rotation = Vector3(0.0, start.basis.get_euler().y, 0.0)
	player.velocity = Vector3.ZERO
	_waves_cleared_in_visit = 0
	_visit_start_wave = _last_cleared_wave + 1
	if log_events:
		print("LEVEL loaded %s visit=%d first_wave=%d" % [get_current_level_id(), _visit_index, _visit_start_wave])
	level_loaded.emit(get_current_level_id(), _visit_index)
	if debug_open_exit_immediately:
		open_exit()
		return
	_wave_start_pending = false
	if _wave_hold:
		_wave_start_pending = true
		return
	_start_visit_waves()


func _start_visit_waves() -> void:
	spawner.start_delay = data.first_wave_delay
	spawner.start(_visit_start_wave, data.waves_per_visit)


func _free_dynamic_nodes() -> void:
	for group: StringName in [&"enemies", DropPickup.GROUP_AMMO, DropPickup.GROUP_DOSE]:
		for n: Node in get_tree().get_nodes_in_group(group):
			n.queue_free()


func _on_run_ended(_reason: StringName) -> void:
	_run_over = true
	spawner.stop()


func _on_wave_cleared(wave: int) -> void:
	_last_cleared_wave = wave
	_waves_cleared_in_visit += 1
	if _waves_cleared_in_visit >= data.waves_per_visit:
		open_exit()


## True once the current level finished loading (collision and navmesh present).
func is_level_ready() -> bool:
	return _level_ready


## Fades through the shared ScreenFade (unscaled time). Without one it just waits a frame.
func _fade_to(alpha: float, seconds: float) -> void:
	if screen_fade == null:
		await get_tree().process_frame
	elif alpha >= 0.5:
		await screen_fade.fade_to_black(seconds)
	else:
		await screen_fade.fade_clear(seconds)


## The level fades in only after it is ready. A level that failed to load reports the error and fades in
## anyway, so the player is never stuck on black.
func _fade_in_first_level() -> void:
	await _wait_level_ready()
	if screen_fade == null or debug_hold_level_black or _run_over or not is_inside_tree():
		return
	await screen_fade.fade_clear(screen_fade.data.level_fade_in_seconds)


## Waits one physics frame (trimesh collision is in the space) and checks the level: it must exist and
## its navmesh must have polygons. Failures are pushed as errors; the caller fades in either way.
func _wait_level_ready() -> void:
	_level_ready = false
	var problem: String = ""
	if _level == null:
		problem = "level scene failed to load"
	elif _level.nav_region == null or _level.nav_region.navigation_mesh == null \
			or _level.nav_region.navigation_mesh.get_polygon_count() == 0:
		problem = "level has no baked navigation mesh"
	await get_tree().physics_frame
	if problem != "":
		push_error("LEVEL not ready (%s); fading in anyway." % problem)
		return
	_level_ready = true


func _build_overlay() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_cleared_label = _make_label(notice_data.cleared_font_size, notice_data.top_percent)
	_exit_label = _make_label(notice_data.exit_font_size, notice_data.top_percent + notice_data.exit_offset_percent)
	_cleared_label.text = notice_data.cleared_text
	_exit_label.text = notice_data.exit_open_text
	layer.add_child(_cleared_label)
	layer.add_child(_exit_label)
	_hide_notices()


func _make_label(font_size: int, top_percent: float) -> Label:
	var label: Label = Label.new()
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.anchor_top = top_percent / 100.0
	label.anchor_bottom = top_percent / 100.0
	label.offset_top = 0.0
	label.offset_bottom = float(font_size) * 1.4
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", notice_data.text_color)
	label.add_theme_color_override(&"font_outline_color", notice_data.outline_color)
	label.add_theme_constant_override(&"outline_size", int(ceil(notice_data.outline_width * 4.0)))
	return label


func _hide_notices() -> void:
	_notice_token += 1
	_cleared_label.visible = false
	_exit_label.visible = false


func _show_exit_notice() -> void:
	_notice_token += 1
	var token: int = _notice_token
	_cleared_label.visible = true
	_exit_label.visible = true
	await get_tree().create_timer(notice_data.cleared_seconds, false).timeout
	if token == _notice_token and is_instance_valid(_cleared_label):
		_cleared_label.visible = false
