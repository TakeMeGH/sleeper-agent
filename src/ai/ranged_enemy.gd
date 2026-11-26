class_name RangedEnemy
extends EnemyBase
## Runs to a Marker3D firing spot (group `firing_spot`), shoots only with a clear line of fire,
## reloads when the magazine is empty. States: move_to_spot -> shoot <-> reload.

const STATE_MOVE_TO_SPOT: StringName = &"move_to_spot"
const STATE_SHOOT: StringName = &"shoot"
const STATE_RELOAD: StringName = &"reload"
const GROUP_SPOT: StringName = &"firing_spot"
const META_OCCUPANT: StringName = &"occupant"

var _spot: Marker3D
var _magazine: int = 0
var _aim_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _reload_timer: float = 0.0
var _no_line_timer: float = 0.0
var _burst_index: int = 0
var _shot_player: AudioStreamPlayer3D
var _pulls: int = 0


func _ready() -> void:
	super._ready()
	if data == null:
		return
	_magazine = data.magazine_size
	_state = STATE_MOVE_TO_SPOT
	_build_gun_prop()
	_build_shot_sound()


## Rounds left in the magazine.
func get_magazine() -> int:
	return _magazine


## The firing spot currently assigned, or null.
func get_spot() -> Marker3D:
	return _spot


## Id of this enemy kind (&"ranged_pistol", &"ranged_shotgun", &"ranged_smg").
func get_kind_id() -> StringName:
	return data.id


## The gun data of this kind, or null when the enemy has none (plain single shots).
func get_gun_data() -> RangedGunData:
	return data.gun


## Distance from the player this kind prefers to fire from: the gun's preferred_distance, or the
## middle of the distance band when the gun has no preference.
func get_preferred_distance() -> float:
	if data.gun != null and data.gun.preferred_distance > 0.0:
		return data.gun.preferred_distance
	return (data.band_min + data.band_max) * 0.5


## Shots already fired in the current burst (0 between bursts).
func get_burst_index() -> int:
	return _burst_index


## Seconds until the next trigger pull is allowed.
func get_fire_cooldown() -> float:
	return _fire_cooldown


## Trigger pulls made so far (a shotgun blast is one pull).
func get_pull_count() -> int:
	return _pulls


## Resource path of the shot sound this enemy plays ("" when none).
func get_shot_sound_path() -> String:
	if data.gun == null or data.gun.shot_sound == null:
		return ""
	return data.gun.shot_sound.resource_path


## Pulls the trigger once at the player right now: one bullet (SINGLE, BURST) or a pellet spread (SPREAD).
## Uses a magazine round, sets the cooldown for the pattern and plays the shot sound. Returns how many
## rays reached the player (each one called the player's take_hit). rng overrides the enemy's aim generator.
func fire_once(rng: RandomNumberGenerator = null) -> int:
	if _player == null or not is_instance_valid(_player) or _magazine <= 0:
		return 0
	var gun: RangedGunData = data.gun
	var generator: RandomNumberGenerator = rng if rng != null else aim_rng
	var dir: Vector3 = (_player_chest() - _eye_position()).normalized()
	if data.spread_degrees > 0.0:
		dir = spread_direction(dir, data.spread_degrees, generator.randf() * TAU, sqrt(generator.randf()))
	var dirs: Array[Vector3] = [dir]
	if gun != null and gun.pattern == RangedGunData.Pattern.SPREAD:
		dirs = get_pellet_directions(dir, gun.pellets_per_shot, gun.pellet_spread_degrees, generator)
	var hits: int = 0
	for d: Vector3 in dirs:
		if _fire_ray(d, get_damage(), data.shot_range):
			hits += 1
	_magazine -= 1
	_pulls += 1
	_fire_cooldown = _cooldown_after_pull()
	_play_shot_sound()
	return hits


## Pellet directions for one blast: count rays spread evenly over a cone of spread_degrees around base_dir
## (sunflower pattern). Without rng the pattern is fixed; with rng the whole pattern is rotated randomly.
static func get_pellet_directions(base_dir: Vector3, count: int, spread_degrees: float,
		rng: RandomNumberGenerator = null) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var n: int = maxi(count, 1)
	var offset: float = 0.0 if rng == null else rng.randf() * TAU
	for i: int in n:
		var fraction: float = sqrt((float(i) + 0.5) / float(n))
		out.append(spread_direction(base_dir, spread_degrees, offset + float(i) * 2.399963, fraction))
	return out


func _cooldown_after_pull() -> float:
	var gun: RangedGunData = data.gun
	if gun != null and gun.pattern == RangedGunData.Pattern.BURST:
		_burst_index += 1
		if _burst_index >= maxi(gun.burst_shots, 1):
			_burst_index = 0
			return gun.burst_pause_seconds
		return gun.burst_interval_seconds
	return 1.0 / maxf(data.fire_rate, 0.01)


func _build_gun_prop() -> void:
	var s: float = data.body_scale
	var gun: RangedGunData = data.gun
	if _visual != null:
		if gun != null and gun.prop_scene != null:
			_visual.attach_prop(gun.prop_scene, gun.hand_position, gun.hand_rotation_degrees, gun.hand_scale)
		return
	if gun == null:
		_add_box(_body_root, Vector3(0.35 * s, 1.1 * s, -0.4 * s), Vector3(0.1, 0.15, 0.5) * s, Color(0.1, 0.1, 0.1))
		return
	if gun.prop_scene != null:
		var prop: Node3D = gun.prop_scene.instantiate() as Node3D
		if prop != null:
			prop.position = gun.prop_position * s
			prop.rotation_degrees = gun.prop_rotation_degrees
			prop.scale = Vector3.ONE * gun.prop_scale * s
			_body_root.add_child(prop)
			return
	_add_box(_body_root, gun.prop_position * s, gun.prop_box_size * s, gun.prop_color)


func _build_shot_sound() -> void:
	var gun: RangedGunData = data.gun
	if gun == null or gun.shot_sound == null:
		return
	_shot_player = AudioStreamPlayer3D.new()
	_shot_player.stream = gun.shot_sound
	_shot_player.volume_db = gun.shot_volume_db
	_shot_player.pitch_scale = gun.shot_pitch
	_shot_player.max_distance = gun.sound_max_distance
	_shot_player.unit_size = gun.sound_unit_size
	_shot_player.bus = gun.sound_bus
	_shot_player.max_polyphony = maxi(gun.shot_polyphony, 1)
	_shot_player.position = Vector3(0.0, data.eye_height * data.body_scale, 0.0)
	add_child(_shot_player)


func _play_shot_sound() -> void:
	if _shot_player != null and _shot_player.is_inside_tree():
		_shot_player.play()


func _is_aiming() -> bool:
	return _state == STATE_SHOOT


func _get_attack_clip() -> StringName:
	return data.gun.attack_clip if data.gun != null else &""


func _exit_tree() -> void:
	super._exit_tree()
	_release_spot()


func _on_died() -> void:
	_release_spot()


func _think(delta: float) -> void:
	if _player == null:
		return
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	var dist: float = _flat_distance_to(_player.global_position)
	match _state:
		STATE_MOVE_TO_SPOT:
			if _spot == null:
				_spot = _pick_spot()
			if _spot != null:
				if _flat_distance_to(_spot.global_position) <= data.spot_arrive_distance:
					_begin_shoot()
				else:
					_face(_spot.global_position, delta)
					_desired_velocity = _nav_velocity(_spot.global_position, get_move_speed(), delta)
			else:
				# No spots in the level: advance on the player until in band with a clear line.
				_face(_player.global_position, delta)
				if dist <= data.band_max and has_line_of_fire():
					_begin_shoot()
				else:
					_desired_velocity = _nav_velocity(_player.global_position, get_move_speed(), delta)
		STATE_SHOOT:
			_face(_player.global_position, delta)
			if dist > data.shot_range:
				_choose_new_spot()
			elif not has_line_of_fire():
				_aim_timer = 0.0
				_no_line_timer += delta
				if _no_line_timer >= data.no_line_wait_seconds:
					_choose_new_spot()
			else:
				_no_line_timer = 0.0
				_aim_timer += delta
				if _aim_timer >= data.aim_seconds and _fire_cooldown <= 0.0:
					fire_once()
					if _magazine <= 0:
						_burst_index = 0
						_reload_timer = data.reload_seconds
						if _visual != null:
							_visual.set_reloading(true)
						_set_state(STATE_RELOAD)
		STATE_RELOAD:
			_face(_player.global_position, delta)
			_reload_timer -= delta
			if _reload_timer <= 0.0:
				_magazine = data.magazine_size
				_begin_shoot()


func _begin_shoot() -> void:
	if _visual != null:
		_visual.set_reloading(false)
	_burst_index = 0
	_aim_timer = 0.0
	_no_line_timer = 0.0
	_set_state(STATE_SHOOT)


func _choose_new_spot() -> void:
	if _visual != null:
		_visual.set_reloading(false)
	var previous: Marker3D = _spot
	_release_spot()
	_burst_index = 0
	_spot = _pick_spot(previous)
	_set_state(STATE_MOVE_TO_SPOT)


func _release_spot() -> void:
	if _spot != null and is_instance_valid(_spot) and _spot.has_meta(META_OCCUPANT) and _spot.get_meta(META_OCCUPANT) == self:
		_spot.remove_meta(META_OCCUPANT)
	_spot = null


## Picks a free firing spot in the distance band, preferring spots with a clear line of fire to the player.
## Reserves it for this enemy. Returns null when the level has no spots.
func _pick_spot(avoid: Marker3D = null) -> Marker3D:
	var in_band_clear: Array[Marker3D] = []
	var in_band: Array[Marker3D] = []
	var others: Array[Marker3D] = []
	for node: Node in get_tree().get_nodes_in_group(GROUP_SPOT):
		var marker: Marker3D = node as Marker3D
		if marker == null or marker == avoid:
			continue
		if marker.has_meta(META_OCCUPANT):
			var occupant: Variant = marker.get_meta(META_OCCUPANT)
			if occupant != self and is_instance_valid(occupant):
				continue
		var d: float = Vector2(marker.global_position.x - _player.global_position.x,
			marker.global_position.z - _player.global_position.z).length()
		if d >= data.band_min and d <= data.band_max:
			var from: Vector3 = marker.global_position + Vector3.UP * data.spot_check_height
			if _has_clear_line(from):
				in_band_clear.append(marker)
			else:
				in_band.append(marker)
		elif d <= data.shot_range:
			others.append(marker)
	var pool: Array[Marker3D] = in_band_clear
	if pool.is_empty():
		pool = in_band
	if pool.is_empty():
		pool = others
	if pool.is_empty() and avoid != null:
		pool = [avoid]
	if pool.is_empty():
		return null
	var best: Marker3D = pool[0]
	var wants_distance: bool = data.gun != null and data.gun.preferred_distance > 0.0
	for m: Marker3D in pool:
		if wants_distance:
			if _spot_distance_error(m) < _spot_distance_error(best):
				best = m
		elif m.global_position.distance_to(global_position) < best.global_position.distance_to(global_position):
			best = m
	best.set_meta(META_OCCUPANT, self)
	return best


## How far a spot's flat distance to the player is from this kind's preferred distance.
func _spot_distance_error(marker: Marker3D) -> float:
	var d: float = Vector2(marker.global_position.x - _player.global_position.x,
		marker.global_position.z - _player.global_position.z).length()
	return absf(d - data.gun.preferred_distance)
