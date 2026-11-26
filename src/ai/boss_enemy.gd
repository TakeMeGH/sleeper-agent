class_name BossEnemy
extends EnemyBase
## Slow, heavily armoured boss with one SMG. Armour absorbs armour_absorb_fraction of each hit
## until armour_points run out; after that hits do full damage. States: orbit -> aim -> burst -> orbit.

## Emitted once when the armour is used up.
signal armour_broken

const STATE_ORBIT: StringName = &"orbit"
const STATE_AIM: StringName = &"aim"
const STATE_BURST: StringName = &"burst"

var _armour: float = 0.0
var _plates: Array[MeshInstance3D] = []
var _orbit_sign: float = 1.0
var _orbit_timer: float = 0.0
var _pause_timer: float = 0.0
var _aim_timer: float = 0.0
var _shots_left: int = 0
var _shot_timer: float = 0.0
var _no_line_timer: float = 0.0


func _ready() -> void:
	super._ready()
	if data == null:
		return
	_armour = data.armour_points
	_state = STATE_ORBIT
	_pause_timer = data.burst_pause_seconds
	var s: float = data.body_scale
	if _visual != null:
		_visual.attach_prop(data.visual.held_prop_scene, data.visual.held_prop_position,
			data.visual.held_prop_rotation_degrees, data.visual.held_prop_scale)
	else:
		_add_box(_body_root, Vector3(0.35 * s, 1.1 * s, -0.4 * s), Vector3(0.1, 0.18, 0.6) * s, Color(0.1, 0.1, 0.1))
	# With the rigged model the plates are bone-attached boxes built by EnemyVisual (EnemyVisualData plates).
	for i: int in 0 if _visual != null else mini(data.plate_offsets.size(), data.plate_sizes.size()):
		_plates.append(_add_box(_body_root, data.plate_offsets[i] * s, data.plate_sizes[i] * s, data.plate_color))


func _is_aiming() -> bool:
	return _state == STATE_AIM or _state == STATE_BURST


## Armour points left.
func get_armour() -> float:
	return _armour


## Armour points at full strength.
func get_max_armour() -> float:
	return data.armour_points


## True once armour_points have been used up.
func is_armour_broken() -> bool:
	return _armour <= 0.0


## Number of armour plate meshes still shown.
func get_plate_count() -> int:
	if _visual != null:
		return _visual.get_plate_count()
	return _plates.size()


func _mitigate_damage(damage: float) -> float:
	if _armour <= 0.0:
		return damage
	var absorbed: float = minf(_armour, damage * data.armour_absorb_fraction)
	_armour -= absorbed
	if _armour <= 0.0:
		_armour = 0.0
		for plate: MeshInstance3D in _plates:
			plate.queue_free()
		_plates.clear()
		if _visual != null:
			_visual.remove_plates()
		armour_broken.emit()
	return damage - absorbed


func _think(delta: float) -> void:
	if _player == null:
		return
	var dist: float = _flat_distance_to(_player.global_position)
	match _state:
		STATE_ORBIT:
			_face(_player.global_position, delta)
			_orbit_timer += delta
			if _orbit_timer >= data.orbit_flip_seconds:
				_orbit_timer = 0.0
				_orbit_sign = -_orbit_sign
			_pause_timer -= delta
			_desired_velocity = _nav_velocity(_orbit_target(), get_move_speed(), delta)
			if _pause_timer <= 0.0 and dist <= data.shot_range and has_line_of_fire():
				_aim_timer = 0.0
				_set_state(STATE_AIM)
			elif not has_line_of_fire():
				_no_line_timer += delta
				if _no_line_timer >= data.no_line_wait_seconds:
					_no_line_timer = 0.0
					_orbit_sign = -_orbit_sign
			else:
				_no_line_timer = 0.0
		STATE_AIM:
			_face(_player.global_position, delta)
			_aim_timer += delta
			if _aim_timer >= data.aim_seconds:
				if has_line_of_fire():
					_shots_left = data.burst_size
					_shot_timer = 0.0
					_set_state(STATE_BURST)
				else:
					_pause_timer = data.no_line_wait_seconds
					_set_state(STATE_ORBIT)
		STATE_BURST:
			_face(_player.global_position, delta)
			_shot_timer -= delta
			if _shot_timer <= 0.0:
				_fire_shot(get_damage(), data.spread_degrees, data.shot_range)
				_shots_left -= 1
				_shot_timer = data.shot_interval_seconds
				if _shots_left <= 0:
					_pause_timer = data.burst_pause_seconds
					_set_state(STATE_ORBIT)


## Point on the circle (mid band radius) one orbit step further around the player.
func _orbit_target() -> Vector3:
	var radial: Vector3 = global_position - _player.global_position
	radial.y = 0.0
	if radial.length() < 0.01:
		radial = Vector3.FORWARD
	var radius: float = (data.band_min + data.band_max) * 0.5
	var rotated: Vector3 = radial.normalized().rotated(Vector3.UP, deg_to_rad(data.orbit_step_degrees) * _orbit_sign)
	return _player.global_position + rotated * radius
