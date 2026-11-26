class_name DiveState
extends Node
## Dive state machine: DIVE_LAUNCH (dash + leap) -> AIRBORNE (fall until landing) -> SLIDE -> GET_UP -> IDLE.
## PlayerController owns move_and_slide: while is_diving() it sets velocity from compute_velocity(),
## calls move_and_slide() once, then calls finish_step(). This node never touches weapons, substances or Shift.
## Camera: a film-style offset on Head/Camera3D local position/rotation (never Head, which holds mouse pitch).
## Roll sign: Godot rotation.z > 0 tilts the view left, so a dive to the right gives rotation.z < 0.

enum Phase { IDLE, DIVE_LAUNCH, AIRBORNE, SLIDE, GET_UP }

## Emitted when a dive starts; direction is the locked horizontal world direction.
signal dive_started(direction: Vector3)
## Emitted on every phase change.
signal phase_changed(phase: Phase, previous_phase: Phase)
## Emitted when the dive is over and control returns (phase back to IDLE).
signal dive_ended

@export var data: DiveData

var _phase: Phase = Phase.IDLE
var _phase_time: float = 0.0
var _cooldown_left: float = 0.0
var _direction: Vector3 = Vector3.ZERO
var _speed_factor: float = 1.0
var _horizontal_speed: float = 0.0
var _landing_time: float = -1.0
var _planned_vy: float = 0.0
var _off_floor_frames: int = 0
## Total metres lifted by edge-lifts in the running dive (capped at data.air_step_height).
var _lifted_total: float = 0.0
## Floor height (world y of the feet) latched at dive start; the edge-lift reach is measured from it.
var _start_floor_y: float = 0.0
var _stall_frames: int = 0
var _resume_phase: Phase = Phase.IDLE
var _resume_time: float = 0.0
## Local direction shares: x = sideways (+ right), y = forward (+ forward), locked at dive start.
var _side_forward: Vector2 = Vector2.ZERO
## Hang factor latched at dive start (slow_motion_hang_factor in slow motion, else 1.0); lengthens the
## leap and fall phases and is kept until the dive ends, so a dive that latched it always finishes coherently.
var _hang: float = 1.0
var _player_time: PlayerTime
var _cam_drop: float = 0.0
var _cam_pitch: float = 0.0
var _cam_roll_weight: float = 0.0
var _body: CharacterBody3D
var _camera: Camera3D
var _head: Node3D


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_camera = get_node_or_null("../Head/Camera3D") as Camera3D
	_head = get_node_or_null("../Head") as Node3D
	set_process(false)


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta * _multiplier(), 0.0)


func _process(delta: float) -> void:
	_update_camera(delta * _multiplier())


## Starts a dive if idle, on the floor and off cooldown. input_dir uses the Input.get_vector
## (move_left, move_right, move_forward, move_back) space; Vector2.ZERO dives forward.
## speed_factor is the current speed multiplier (heart rate x Shift). Returns true if started.
func try_start(input_dir: Vector2, speed_factor: float = 1.0) -> bool:
	if data == null or _body == null or _phase != Phase.IDLE or _cooldown_left > 0.0 \
			or not _body.is_on_floor():
		return false
	var local: Vector3
	if input_dir.length() < 0.01:
		# No movement input: dive FORWARD (the camera's horizontal facing, player -Z).
		local = Vector3(0.0, 0.0, -1.0)
	else:
		local = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	_direction = (_body.global_transform.basis * local)
	_direction.y = 0.0
	_direction = _direction.normalized()
	_side_forward = Vector2(local.x, -local.z)
	_speed_factor = clampf(1.0 + (speed_factor - 1.0) * data.speed_factor_influence,
		1.0, data.max_speed_factor)
	_landing_time = -1.0
	_lifted_total = 0.0
	_start_floor_y = _body.global_position.y
	_resume_phase = Phase.IDLE
	# Hang is latched here (not live): the leap and fall share one factor and gravity stays coherent.
	var player_time: PlayerTime = _get_player_time()
	_hang = data.slow_motion_hang_factor \
			if player_time != null and player_time.is_slow_motion_active() else 1.0
	dive_started.emit(_direction)
	_set_phase(Phase.DIVE_LAUNCH)
	return true


## Current phase.
func get_phase() -> Phase:
	return _phase


## True while the dive runs (any phase except IDLE).
func is_diving() -> bool:
	return _phase != Phase.IDLE


## True when the slow-motion hang factor was latched for the running dive.
func is_hang_applied() -> bool:
	return is_diving() and _hang != 1.0


## The hang factor of the running dive (1.0 when none).
func get_hang_factor() -> float:
	return _hang if is_diving() else 1.0


## Nominal player-time length of the current phase (DIVE_LAUNCH = dash + leap, AIRBORNE = fall time,
## SLIDE = lying, GET_UP = stand; 0.0 when IDLE). Leap and fall include the hang factor.
func get_phase_duration() -> float:
	match _phase:
		Phase.DIVE_LAUNCH:
			return data.dash_seconds + _leap_seconds()
		Phase.AIRBORNE:
			return _fall_seconds()
		Phase.SLIDE:
			return data.lying_seconds
		Phase.GET_UP:
			return data.stand_seconds
	return 0.0


## Seconds of cooldown left after getting up (0 when a dive may start).
func get_cooldown_left() -> float:
	return _cooldown_left


## Velocity for this physics frame (horizontal from the locked direction, vertical from the phase).
func compute_velocity(delta: float) -> Vector3:
	var vy: float = _body.velocity.y
	match _phase:
		Phase.DIVE_LAUNCH:
			if _phase_time < data.dash_seconds:
				_horizontal_speed = _speed_factor * data.dash_distance / data.dash_seconds
				vy = 0.0
			else:
				_horizontal_speed = _speed_factor * data.leap_distance / _leap_seconds()
				if _phase_time - data.dash_seconds < data.peak_seconds * _hang:
					vy = data.leap_height / (data.peak_seconds * _hang)
					# The rise stops at start floor + leap_height, so an edge-lift cannot stack on the apex.
					if delta > 0.0:
						var rise_left: float = _start_floor_y + data.leap_height - _body.global_position.y
						vy = clampf(rise_left / delta, 0.0, vy)
				else:
					# Past the peak: drop the rise speed (apex), then fall under dive gravity.
					vy = minf(vy, 0.0) - _gravity() * delta
		Phase.AIRBORNE:
			# Horizontal speed is kept (set once at the launch -> airborne transition).
			vy -= _gravity() * delta
		Phase.SLIDE, Phase.GET_UP:
			_horizontal_speed = maxf(_horizontal_speed - data.slide_deceleration * delta, 0.0)
			vy = 0.0 if _body.is_on_floor() else vy - _gravity() * delta
		_:
			return _body.velocity
	if _is_edge_lift_phase() 			and _try_edge_lift(Vector3(_direction.x, 0.0, _direction.z) * _horizontal_speed * delta):
		# Lifted this frame: do not also move down, or the body is dragged back down the obstacle's face.
		vy = maxf(vy, 0.0)
	_planned_vy = vy
	return Vector3(_direction.x * _horizontal_speed, vy, _direction.z * _horizontal_speed)


## Call right after move_and_slide(): advances timers and phases (landing is detected, not timed).
func finish_step(delta: float) -> void:
	_phase_time += delta
	if _landing_time >= 0.0:
		_landing_time += delta
	var on_floor: bool = _body.is_on_floor()
	match _phase:
		Phase.DIVE_LAUNCH:
			if _phase_time >= data.dash_seconds + _leap_seconds():
				_horizontal_speed = _speed_factor * data.fall_distance / _fall_seconds()
				_off_floor_frames = 0
				_stall_frames = 0
				_set_phase(Phase.AIRBORNE)
		Phase.AIRBORNE:
			if on_floor and _planned_vy <= 0.0:
				if _resume_phase != Phase.IDLE:
					# Landed after a hop: continue the interrupted phase, no new bump or speed scale.
					var resume: Phase = _resume_phase
					_resume_phase = Phase.IDLE
					_set_phase(resume, _resume_time)
				else:
					_landing_time = 0.0
					_horizontal_speed *= data.slide_speed_scale
					_set_phase(Phase.SLIDE)
				return
			# Stuck guards: a stalled body or too long in the air ends the dive safely.
			if not on_floor and _body.get_real_velocity().length() / maxf(_multiplier(), PlayerTime.MIN_MULTIPLIER) < data.stall_speed:
				_stall_frames += 1
			else:
				_stall_frames = 0
			if _phase_time >= data.max_airborne_seconds * _hang or _stall_frames >= data.stall_frames:
				_end_safely(on_floor)
		Phase.SLIDE, Phase.GET_UP:
			_off_floor_frames = 0 if on_floor else _off_floor_frames + 1
			if _off_floor_frames >= data.hop_frames:
				# Slid off a ledge: keep falling, never get up in mid-air. The timer resumes on landing.
				_resume_phase = _phase
				_resume_time = _phase_time
				_stall_frames = 0
				_set_phase(Phase.AIRBORNE)
			elif _phase == Phase.SLIDE and _phase_time >= data.lying_seconds and on_floor:
				# Never stand up in mid-air (story 017: sliding off a table top): wait for the floor or the hop rule.
				_set_phase(Phase.GET_UP)
			elif _phase == Phase.GET_UP and _phase_time >= data.stand_seconds and on_floor:
				_finish()


## Ends a stuck airborne dive: on the floor go to GET_UP, otherwise hand control back (IDLE).
func _end_safely(on_floor: bool) -> void:
	_resume_phase = Phase.IDLE
	if on_floor:
		_set_phase(Phase.GET_UP)
	else:
		_finish()


func _finish() -> void:
	_cooldown_left = data.cooldown_seconds
	_resume_phase = Phase.IDLE
	_hang = 1.0
	_set_phase(Phase.IDLE)
	dive_ended.emit()


## True while the edge-lift may act: the leap (after the dash) and the fall, not the ground phases.
func _is_edge_lift_phase() -> bool:
	if _phase == Phase.AIRBORNE:
		return true
	return _phase == Phase.DIVE_LAUNCH and _phase_time >= data.dash_seconds


## Edge-lift (story 017): when this frame's horizontal move (step, in player-time units) is blocked by an
## obstacle whose top is within data.air_step_height of the feet, raises the body just enough to clear
## it; the horizontal speed is untouched, so the dive carries on over the edge. Does nothing when the
## way is free, the obstacle is too tall, a ceiling is in the way, or the dive's lift budget is used up.
## Returns true when the body was lifted.
func _try_edge_lift(step: Vector3) -> bool:
	var length: float = step.length()
	if length < 0.0001:
		return false
	var margin: float = _body.safe_margin
	var probe: Vector3 = step / length * maxf(length, data.air_step_probe_distance)
	var origin: Transform3D = _body.global_transform
	if not _body.test_move(origin, probe, null, margin):
		return false
	var max_lift: float = data.air_step_height - _lifted_total
	# Reach cap: the lifted feet may not end above the start floor + air_step_max_reach.
	max_lift = minf(max_lift, _start_floor_y + data.air_step_max_reach - origin.origin.y)
	if max_lift <= data.air_step_margin:
		return false
	# Ceiling: sweep up first and lower the allowed lift to the free height.
	var up: KinematicCollision3D = KinematicCollision3D.new()
	if _body.test_move(origin, Vector3(0.0, max_lift, 0.0), up, margin):
		max_lift = maxf(up.get_travel().y, 0.0)
		if max_lift <= data.air_step_margin:
			return false
	# Too tall (wall, counter): still blocked with the body raised by the allowed lift -> leave it.
	if _body.test_move(origin.translated(Vector3(0.0, max_lift, 0.0)), probe, null, margin, true):
		return false
	# Bisect the lowest lift that clears the obstacle.
	var low: float = 0.0
	var high: float = max_lift
	for i: int in data.air_step_search_steps:
		var mid: float = (low + high) * 0.5
		if _body.test_move(origin.translated(Vector3(0.0, mid, 0.0)), probe, null, margin, true):
			low = mid
		else:
			high = mid
	var lift: float = minf(high + data.air_step_margin, max_lift)
	_lifted_total += lift
	_body.global_position += Vector3(0.0, lift, 0.0)
	return true


func _leap_seconds() -> float:
	return data.leap_seconds * _hang


func _fall_seconds() -> float:
	return data.fall_seconds * _hang


func _multiplier() -> float:
	var player_time: PlayerTime = _get_player_time()
	return 1.0 if player_time == null else player_time.get_delta_multiplier()


func _get_player_time() -> PlayerTime:
	if _player_time == null:
		_player_time = get_node_or_null("../PlayerTime") as PlayerTime
	return _player_time


func _gravity() -> float:
	return 2.0 * data.fall_distance / (_fall_seconds() * _fall_seconds())


func _set_phase(new_phase: Phase, start_time: float = 0.0) -> void:
	var previous: Phase = _phase
	_phase = new_phase
	_phase_time = start_time
	if new_phase != Phase.IDLE:
		set_process(true)
	phase_changed.emit(new_phase, previous)


## Target camera pose (drop, pitch, roll weight) for the current phase.
func _target_pose() -> Vector3:
	match _phase:
		Phase.DIVE_LAUNCH:
			return data.camera_dash if _phase_time < data.dash_seconds else data.camera_leap
		Phase.AIRBORNE:
			return data.camera_fall
		Phase.SLIDE:
			return data.camera_lying
		Phase.GET_UP:
			var t: float = clampf(_phase_time / data.stand_seconds, 0.0, 1.0)
			return data.camera_lying * (1.0 - smoothstep(0.0, 1.0, t))
	return Vector3.ZERO


func _update_camera(delta: float) -> void:
	if _camera == null:
		set_process(false)
		return
	var target: Vector3 = _target_pose()
	var k: float = 1.0 - exp(-data.camera_smoothing * delta)
	_cam_drop = lerpf(_cam_drop, target.x, k)
	_cam_pitch = lerpf(_cam_pitch, target.y, k)
	_cam_roll_weight = lerpf(_cam_roll_weight, target.z, k)
	var drop: float = _cam_drop
	var pitch: float = _cam_pitch
	if _landing_time >= 0.0 and _landing_time < data.landing_impact_seconds:
		var pulse: float = sin(PI * _landing_time / data.landing_impact_seconds)
		drop += data.landing_impact_drop * pulse
		pitch += data.landing_impact_pitch * pulse
	# Forward share of the dive adds nose-down pitch ("forward roll"); sideways share rolls toward the side.
	pitch += _side_forward.y * data.roll_degrees * data.forward_roll_fraction * _cam_roll_weight
	# Keep head pitch + offset above straight down so the view never flips over.
	if _head != null and _body is PlayerController:
		var room: float = maxf((_body as PlayerController).max_pitch_degrees + rad_to_deg(_head.rotation.x), 0.0)
		pitch = minf(pitch, room)
	var roll: float = -_side_forward.x * data.roll_degrees * _cam_roll_weight
	_camera.position = Vector3(0.0, -drop, 0.0)
	_camera.rotation = Vector3(-deg_to_rad(pitch), 0.0, deg_to_rad(roll))
	if _phase == Phase.IDLE and target == Vector3.ZERO and drop < 0.001 \
			and absf(pitch) < 0.01 and absf(roll) < 0.01:
		_camera.position = Vector3.ZERO
		_camera.rotation = Vector3.ZERO
		_cam_drop = 0.0
		_cam_pitch = 0.0
		_cam_roll_weight = 0.0
		set_process(false)
