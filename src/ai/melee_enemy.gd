class_name MeleeEnemy
extends EnemyBase
## Chases the player and swings a baseball bat when close: chase -> windup -> swing -> recover.

const STATE_CHASE: StringName = &"chase"
const STATE_WINDUP: StringName = &"windup"
const STATE_SWING: StringName = &"swing"
const STATE_RECOVER: StringName = &"recover"

## Bat pivot rotation (degrees about X) at rest, wound up and at the end of the swing.
const BAT_REST_DEGREES: float = 20.0
const BAT_WINDUP_DEGREES: float = 110.0
const BAT_SWING_END_DEGREES: float = -80.0

var _timer: float = 0.0
var _cooldown: float = 0.0
var _hit_done: bool = false
var _bat_pivot: Node3D


func _ready() -> void:
	super._ready()
	if data == null:
		return
	_state = STATE_CHASE
	if _visual != null:
		_visual.attach_prop(data.visual.held_prop_scene, data.visual.held_prop_position,
			data.visual.held_prop_rotation_degrees, data.visual.held_prop_scale)
		return
	var s: float = data.body_scale
	_bat_pivot = Node3D.new()
	_bat_pivot.position = Vector3(0.5 * s, 1.1 * s, -0.1 * s)
	_body_root.add_child(_bat_pivot)
	_add_box(_bat_pivot, Vector3(0.0, 0.4 * s, 0.0), Vector3(0.1, 0.8, 0.1) * s, Color(0.55, 0.38, 0.2))
	_bat_pivot.rotation_degrees.x = BAT_REST_DEGREES


func _think(delta: float) -> void:
	if _player == null:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	var dist: float = _flat_distance_to(_player.global_position)
	match _state:
		STATE_CHASE:
			_face(_player.global_position, delta)
			if dist <= data.reach * 0.8:
				if _cooldown <= 0.0:
					_timer = _windup_time()
					if _visual != null:
						_visual.play_attack()
					_set_state(STATE_WINDUP)
			else:
				_desired_velocity = _nav_velocity(_player.global_position, get_move_speed(), delta)
		STATE_WINDUP:
			_face(_player.global_position, delta)
			_timer -= delta
			if _bat_pivot != null:
				_bat_pivot.rotation_degrees.x = lerpf(BAT_REST_DEGREES, BAT_WINDUP_DEGREES,
					1.0 - clampf(_timer / maxf(data.windup_seconds, 0.001), 0.0, 1.0))
			if _timer <= 0.0:
				_timer = 0.0
				_hit_done = false
				_set_state(STATE_SWING)
		STATE_SWING:
			_timer += delta
			var t: float = clampf(_timer / maxf(_swing_time(), 0.001), 0.0, 1.0)
			if _bat_pivot != null:
				_bat_pivot.rotation_degrees.x = lerpf(BAT_WINDUP_DEGREES, BAT_SWING_END_DEGREES, t)
			# With the model the hit lands the moment the windup (= clip hit time) ends.
			var hit_fraction: float = data.swing_hit_fraction if _visual == null else 0.0
			if not _hit_done and t >= hit_fraction:
				_hit_done = true
				_try_hit(dist)
			if t >= 1.0:
				_cooldown = maxf(data.attack_interval - _windup_time() - _swing_time(), 0.0)
				_set_state(STATE_RECOVER)
		STATE_RECOVER:
			if _bat_pivot != null:
				_bat_pivot.rotation_degrees.x = lerpf(_bat_pivot.rotation_degrees.x, BAT_REST_DEGREES,
					clampf(8.0 * delta, 0.0, 1.0))
			if _cooldown <= 0.0:
				_set_state(STATE_CHASE)


## Seconds from the start of the attack to the hit: the swing clip's hit time with the model, else the windup.
func _windup_time() -> float:
	return _visual.get_attack_hit_time() if _visual != null else data.windup_seconds


## Seconds from the hit to the end of the attack: rest of the swing clip with the model, else the swing.
func _swing_time() -> float:
	if _visual != null:
		return maxf(_visual.get_attack_clip_length() - _visual.get_attack_hit_time(), 0.01)
	return data.swing_seconds


## Applies the swing: hurts the player when within reach and not behind cover.
func _try_hit(flat_distance: float) -> void:
	if flat_distance > data.reach * 1.25 or not has_line_of_fire():
		return
	if _player.has_method("take_hit"):
		var dir: Vector3 = (_player.global_position - global_position)
		dir.y = 0.0
		_player.call("take_hit", get_damage(), dir.normalized(), global_position)
