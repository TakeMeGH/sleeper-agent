class_name EnemyBase
extends CharacterBody3D
## Shared enemy body: placeholder capsule, navigation, take_hit, knockback, death and drops.
## Subclasses (MeleeEnemy, RangedEnemy, BossEnemy) implement _think().

signal damaged(amount: float, health_left: float)
signal died(enemy: EnemyBase)
## Emitted for every bullet fired; hit_player is true when the ray reached the player.
signal shot_fired(hit_player: bool)

const LAYER_WORLD: int = 1
const LAYER_ENEMY: int = 2
const FLASH_SECONDS: float = 0.12
const VISUAL_SCENE: PackedScene = preload("res://src/ai/enemy_visual.tscn")
## Push and detour numbers used when EnemyData.push is not set.
const DEFAULT_PUSH: EnemyPushData = preload("res://assets/data/enemies/enemy_push.tres")

## Dead bodies still lying around, oldest first (capped by EnemyVisualData.live_corpse_cap).
static var _corpses: Array[EnemyBase] = []

@export var data: EnemyData
@export var drop_data: DropData
## Print AI state transitions (debug).
@export var log_transitions: bool = false
## Set before add_child (the spawner does this from the wave scaling).
var health_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
## Drop rolls come from this generator; tests may seed or replace it.
var drop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Gun/shot spread noise.
var aim_rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _health: float = 1.0
var _max_health: float = 1.0
var _dead: bool = false
var _state: StringName = &"idle"
var _knockback: Vector3 = Vector3.ZERO
var _desired_velocity: Vector3 = Vector3.ZERO
var _player: Node3D
var _agent: NavigationAgent3D
var _repath_timer: float = 0.0
var _material: StandardMaterial3D
var _flash: float = 0.0
var _dying_left: float = 0.0

var _push: EnemyPushData
var _stuck_time: float = 0.0
var _window_time: float = 0.0
var _window_dist: float = 0.0
var _window_blocked: bool = false
var _wall_normal: Vector3 = Vector3.ZERO
var _detour_left: float = 0.0
var _detour_point: Vector3 = Vector3.ZERO
var _detour_points: Array[Vector3] = []
var _detour_index: int = 0
var _detour_attempt: int = 0
var _last_nav_target: Vector3 = Vector3.ZERO
var _last_pushed_prop: PushableProp
var _blocking_prop: PushableProp
var _blocking_age: float = 999.0
var _blocking_normal: Vector3 = Vector3.ZERO
var _detour_prop: PushableProp
## Velocity the AI asked for this frame, before the push limit (used by the stuck check).
var _wanted_velocity: Vector3 = Vector3.ZERO
## Props this enemy is pushing (kept while its body stays within push_keep_gap of them).
var _push_contacts: Array[PushableProp] = []
var _pushing_now: bool = false

var _body_root: Node3D
var _visual: EnemyVisual
var _collision: CollisionShape3D
var _last_hit_direction: Vector3 = Vector3.ZERO
var _corpse_age: float = 0.0
var _corpse_fading: bool = false

## Debug/capture only: skips the AI step so the enemy stands where it was spawned.
var debug_freeze_ai: bool = false


func _ready() -> void:
	collision_layer = LAYER_ENEMY
	# Enemies collide with the world and each other so spawn groups spread out.
	collision_mask = LAYER_WORLD | LAYER_ENEMY
	if data == null:
		push_error("EnemyBase %s has no EnemyData" % name)
		set_physics_process(false)
		return
	add_to_group(&"enemies")
	_push = data.push if data.push != null else DEFAULT_PUSH
	_max_health = data.health * health_multiplier
	_health = _max_health
	drop_rng.randomize()
	aim_rng.randomize()
	_build_body()
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.5
	_agent.target_desired_distance = 0.4
	_agent.radius = data.body_radius * data.body_scale
	add_child(_agent)


func _physics_process(delta: float) -> void:
	if _dead:
		_slide_dead_body(delta)
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
	_desired_velocity = Vector3.ZERO
	if not debug_freeze_ai:
		_think(delta)
	_wanted_velocity = _desired_velocity
	_drive_push_contacts(delta)
	_knockback *= exp(-data.knockback_decay * delta)
	var horizontal: Vector3 = _desired_velocity + _knockback
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	var before: Vector3 = global_position
	move_and_slide()
	_push_props(delta)
	_update_stuck(delta, before)
	if _visual != null and not debug_freeze_ai:
		_visual.update_locomotion(Vector2(velocity.x - _knockback.x, velocity.z - _knockback.z).length())
	if _visual != null:
		_visual.set_push_lean(_push.push_lean_degrees if _pushing_now else 0.0, _push.push_lean_blend_seconds)
	if _visual != null and _player != null and is_instance_valid(_player):
		_visual.set_aim_point(_player_chest(), _is_aiming())
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		if _visual != null:
			_visual.set_flash(_flash / FLASH_SECONDS)
		else:
			_material.albedo_color = data.body_color.lerp(Color(1, 1, 1), _flash / FLASH_SECONDS * 0.7)


## Pushes a killed body: horizontal velocity along the shot (decays, capped). Ignored while alive.
func apply_death_push(push_velocity: Vector3) -> void:
	if not _dead or data == null:
		return
	var flat: Vector3 = Vector3(push_velocity.x, 0.0, push_velocity.z)
	_knockback += flat
	if _knockback.length() > data.max_knockback_speed * 2.0:
		_knockback = _knockback.normalized() * data.max_knockback_speed * 2.0
	if _visual != null:
		_dying_left = maxf(_dying_left, data.death_slide_seconds)


## A shot into a dead body: pushes it (a fraction of the kill push). Does nothing while alive.
func corpse_hit(direction: Vector3, strength: float) -> void:
	if not _dead or _visual == null:
		return
	apply_death_push(direction.normalized() * strength * data.visual.corpse_hit_push_scale)


func _slide_dead_body(delta: float) -> void:
	if _dying_left > 0.0:
		_dying_left -= delta
		_knockback *= exp(-data.knockback_decay * delta)
		velocity.x = _knockback.x
		velocity.z = _knockback.z
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		if _dying_left <= 0.0 and _visual == null:
			queue_free()
	if _visual != null:
		_corpse_step(delta)


## Corpse timeline: lingers corpse_linger, fades corpse_fade, then is removed.
func _corpse_step(delta: float) -> void:
	_corpse_age += delta
	var look: EnemyVisualData = data.visual
	if not _corpse_fading and _corpse_age >= look.corpse_linger:
		_corpse_fading = true
		_visual.fade_out(look.corpse_fade)
	if _corpse_age >= look.corpse_linger + look.corpse_fade:
		queue_free()


func _exit_tree() -> void:
	_corpses.erase(self)


## Number of dead bodies currently kept (for probes).
static func get_live_corpse_count() -> int:
	var live: Array[EnemyBase] = []
	for body: EnemyBase in _corpses:
		if is_instance_valid(body) and not body.is_queued_for_deletion():
			live.append(body)
	_corpses = live
	return _corpses.size()


## The rigged visual, or null for the capsule fallback.
func get_visual() -> EnemyVisual:
	return _visual


## Seconds the body has been dead (0 while alive).
func get_corpse_age() -> float:
	return _corpse_age


## World position of the gun muzzle (the eyes when there is no prop).
func get_muzzle_position() -> Vector3:
	if _visual != null and _visual.has_muzzle():
		return _visual.get_muzzle_position()
	return _eye_position()


## Attack clip this enemy's visual should use; ranged kinds override with their gun's clip.
func _get_attack_clip() -> StringName:
	return &""


## Seconds this enemy has wanted to move but made no real progress against a prop.
func get_stuck_time() -> float:
	return _stuck_time


## True while walking to a detour point around a pinned prop.
func is_detouring() -> bool:
	return _detour_left > 0.0


## The current (or last) detour point.
func get_detour_point() -> Vector3:
	return _detour_point


## The prop this enemy pushed last (null if none or freed).
func get_last_pushed_prop() -> PushableProp:
	return _last_pushed_prop if is_instance_valid(_last_pushed_prop) else null


## Before the move: keeps pushing every prop this enemy is in contact with (body within push_keep_gap of
## its footprint) toward push_speed_factor x the wanted speed along the contact normal, at the contact point,
## then limits this enemy's own speed along that normal to the contact's speed plus a small closing speed,
## so it leans into the prop and walks at its pace instead of slamming into it and stopping (no stop-go).
func _drive_push_contacts(delta: float) -> void:
	_pushing_now = false
	var wanted: Vector3 = Vector3(_desired_velocity.x, 0.0, _desired_velocity.z)
	var radius: float = (_collision.shape as CapsuleShape3D).radius if _collision != null and _collision.shape is CapsuleShape3D 		else data.body_radius * data.body_scale
	var kept: Array[PushableProp] = []
	for prop: PushableProp in _push_contacts:
		if not is_instance_valid(prop):
			continue
		var point: Vector3 = prop.closest_footprint_point(global_position)
		var offset: Vector3 = Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
		var distance: float = offset.length()
		if distance < 0.0001:
			continue
		var gap: float = distance - radius
		var n: Vector3 = offset / distance
		var along: float = wanted.dot(n)
		if gap > _push.push_keep_gap or along < maxf(_push.min_push_speed, wanted.length() * _push.push_hold_alignment):
			continue
		kept.append(prop)
		prop.apply_push(point, n, along * _push.push_speed_factor, _push_force() * delta, self)
		_last_pushed_prop = prop
		_pushing_now = true
		var closing: float = clampf((gap - _push.push_hold_gap) * _push.push_close_gain, -_push.push_close_speed, _push.push_close_speed)
		var allowed: float = maxf(prop.get_point_velocity(point).dot(n), 0.0) + closing
		if along > allowed:
			_desired_velocity -= n * (along - allowed)
			wanted = Vector3(_desired_velocity.x, 0.0, _desired_velocity.z)
	_push_contacts = kept


## After the move: records the props this frame's slide touched (normal, contact point in prop space) and
## gives each newly touched prop the first-contact shove (a share of this enemy's momentum along the normal).
func _push_props(delta: float) -> void:
	_blocking_age += delta
	var seen: Array[PushableProp] = []
	var wanted: Vector3 = Vector3(_wanted_velocity.x, 0.0, _wanted_velocity.z)
	for i: int in get_slide_collision_count():
		var hit: KinematicCollision3D = get_slide_collision(i)
		var prop: PushableProp = hit.get_collider() as PushableProp
		if prop == null:
			var flat_normal: Vector3 = Vector3(hit.get_normal().x, 0.0, hit.get_normal().z)
			if flat_normal.length_squared() > 0.01:
				_wall_normal = flat_normal.normalized()
		if prop == null or seen.has(prop):
			continue
		seen.append(prop)
		var dir: Vector3 = -hit.get_normal()
		dir.y = 0.0
		if dir.length_squared() < 0.000001:
			continue
		dir = dir.normalized()
		# Any contact counts as "the blocker" (also a slanted one); contacts while walking a detour do not.
		if _detour_left <= 0.0:
			_blocking_prop = prop
			_blocking_age = 0.0
			_blocking_normal = _face_normal(prop, -dir)
		var along: float = wanted.dot(dir)
		if along < maxf(_push.min_push_speed, wanted.length() * _push.push_min_alignment):
			continue
		if _push_contacts.has(prop):
			continue
		_push_contacts.append(prop)
		# First touch: the shove. Momentum along the normal (enemy minus contact speed) x impact_fraction.
		var closing: float = along - prop.get_point_velocity(hit.get_position()).dot(dir)
		if closing > 0.0:
			prop.apply_push(hit.get_position(), dir, along * _push.push_speed_factor,
				_push_mass() * closing * _push.impact_fraction, self)
		_last_pushed_prop = prop


func _push_force() -> float:
	return _push.push_force * (_push.boss_push_factor if data.kind == EnemyData.Kind.BOSS else 1.0)


func _push_mass() -> float:
	return _push.body_mass * (_push.boss_push_factor if data.kind == EnemyData.Kind.BOSS else 1.0)


## Tracks real progress; blocked by a prop for stuck_seconds -> walk around it by a two-waypoint detour.
func _update_stuck(delta: float, before: Vector3) -> void:
	var moved: Vector2 = Vector2(global_position.x - before.x, global_position.z - before.z)
	var progress: float = moved.length() / maxf(delta, 0.0001)
	var wants: bool = Vector2(_wanted_velocity.x, _wanted_velocity.z).length() >= _push.wants_move_speed
	# Verdict over a window of stuck_window_seconds (average speed), so creeping or jittering counts as blocked.
	_window_time += delta
	_window_dist += progress * delta
	if not wants:
		_window_time = 0.0
		_window_dist = 0.0
		_window_blocked = false
	elif _window_time >= _push.stuck_window_seconds:
		_window_blocked = _window_dist / _window_time < _push.stuck_min_progress
		_window_time = 0.0
		_window_dist = 0.0
	var blocked_now: bool = wants and _window_blocked
	if _detour_left > 0.0:
		_detour_left -= delta
		if _flat_distance_to(_detour_point) < _push.detour_arrive_distance:
			_detour_index += 1
			_stuck_time = 0.0
			_repath_timer = 0.0
			if _detour_index >= _detour_points.size():
				_end_detour(true)
			else:
				_detour_point = _detour_points[_detour_index]
			return
		_stuck_time = _stuck_time + delta if blocked_now else 0.0
		if _detour_left <= 0.0 or _stuck_time >= _push.stuck_seconds:
			_fail_detour()
		return
	_stuck_time = _stuck_time + delta if blocked_now else 0.0
	if _stuck_time >= _push.stuck_seconds:
		if _blocking_age <= _push.blocker_memory_seconds and is_instance_valid(_blocking_prop):
			_begin_detour(_blocking_prop)
		else:
			_begin_detour_near_prop()


## Stuck without a recent prop contact (wedged in the gap beside a prop, as the navmesh runs through prop
## spots): detour around the nearest prop within detour_near_prop_range, if any. Stuck against plain
## level geometry with no prop near is left as it was.
func _begin_detour_near_prop() -> void:
	var nearest: PushableProp
	var best: float = INF
	for prop: PushableProp in PushableProp.get_all(get_tree()):
		if not prop.footprint_contains(global_position, _push.detour_near_prop_range):
			continue
		var d: float = prop.global_position.distance_to(global_position)
		if d < best:
			best = d
			nearest = prop
	if nearest == null:
		_begin_backoff()
		return
	_blocking_normal = _face_normal(nearest, global_position - nearest.global_position)
	_begin_detour(nearest)


## Stuck against plain geometry: walks back along the last contact normal, then the normal path is re-asked.
func _begin_backoff() -> void:
	_stuck_time = 0.0
	if _wall_normal.length_squared() < 0.01:
		return
	var raw: Vector3 = global_position + _wall_normal * _push.detour_backoff_distance
	var snapped_point: Vector3 = NavigationServer3D.map_get_closest_point(
		_agent.get_navigation_map(), Vector3(raw.x, global_position.y, raw.z))
	if not _detour_point_valid(snapped_point):
		return
	_detour_prop = null
	_detour_points = [snapped_point]
	_detour_index = 0
	_detour_point = snapped_point
	_detour_left = _push.detour_timeout_seconds
	_repath_timer = 0.0


## Gives the current detour up and starts the next attempt (other side, then a back-off).
func _fail_detour() -> void:
	var prop: PushableProp = _detour_prop
	_end_detour(false)
	if is_instance_valid(prop):
		_detour_attempt += 1
		_begin_detour(prop)


func _end_detour(succeeded: bool) -> void:
	_detour_left = 0.0
	_stuck_time = 0.0
	_repath_timer = 0.0
	if succeeded:
		_detour_attempt = 0


## The prop's own axis (x or z, either sign) closest to the given world normal.
func _face_normal(prop: PushableProp, normal: Vector3) -> Vector3:
	var ax: Vector3 = Vector3(prop.global_basis.x.x, 0.0, prop.global_basis.x.z).normalized()
	var az: Vector3 = Vector3(prop.global_basis.z.x, 0.0, prop.global_basis.z.z).normalized()
	var flat: Vector3 = Vector3(normal.x, 0.0, normal.z)
	if absf(flat.dot(ax)) >= absf(flat.dot(az)):
		return ax if flat.dot(ax) >= 0.0 else -ax
	return az if flat.dot(az) >= 0.0 else -az


## Detour attempt k: 0 = nearer side, 1 = other side, 2 = back off along the contact normal, then repeat.
## A side is two waypoints: past the near corner (sideways, clear of the prop), then past the far corner.
func _begin_detour(prop: PushableProp) -> void:
	_detour_prop = prop
	var n: Vector3 = _blocking_normal
	if n.length_squared() < 0.01:
		n = _face_normal(prop, global_position - prop.global_position)
	var half: Vector2 = prop.get_footprint_extents()
	var n_is_x: bool = absf(n.dot(prop.global_basis.x)) > absf(n.dot(prop.global_basis.z))
	var half_n: float = half.x if n_is_x else half.y
	var half_t: float = half.y if n_is_x else half.x
	var axis: Vector3 = prop.global_basis.z if n_is_x else prop.global_basis.x
	var t: Vector3 = Vector3(axis.x, 0.0, axis.z).normalized()
	var radius: float = data.body_radius * data.body_scale
	var lateral: float = half_t + radius + _push.detour_clearance
	var c: Vector3 = prop.global_position
	var routes: Array[PackedVector3Array] = []
	for side: float in [1.0, -1.0]:
		var route: PackedVector3Array = PackedVector3Array()
		route.append(c + n * (half_n + radius) + t * side * lateral)
		route.append(c - n * (half_n + _push.detour_pass_distance) + t * side * lateral)
		routes.append(route)
	var target: Vector3 = _last_nav_target
	routes.sort_custom(func(a: PackedVector3Array, b: PackedVector3Array) -> bool:
		return a[0].distance_to(global_position) + a[1].distance_to(target) \
			< b[0].distance_to(global_position) + b[1].distance_to(target))
	var back: PackedVector3Array = PackedVector3Array()
	back.append(global_position + n * _push.detour_backoff_distance)
	routes.append(back)
	for k: int in routes.size():
		var route: PackedVector3Array = routes[(_detour_attempt + k) % routes.size()]
		var points: Array[Vector3] = []
		var ok: bool = true
		for raw: Vector3 in route:
			var flat: Vector3 = Vector3(raw.x, global_position.y, raw.z)
			var snapped_point: Vector3 = NavigationServer3D.map_get_closest_point(_agent.get_navigation_map(), flat)
			if not _detour_point_valid(snapped_point):
				# A route whose first waypoint is fine but whose second is blocked is walked as far as it goes.
				ok = not points.is_empty()
				break
			points.append(snapped_point)
		if not ok:
			continue
		_detour_points = points
		_detour_index = 0
		_detour_point = points[0]
		_detour_left = _push.detour_timeout_seconds
		_stuck_time = 0.0
		_repath_timer = 0.0
		if log_transitions:
			print("%s: detour around %s via %s" % [name, prop.name, points])
		return
	_stuck_time = 0.0


## A detour point must be at about the enemy height and not inside a world body.
func _detour_point_valid(point: Vector3) -> bool:
	# The navmesh floats above the visual floor, so compare against the navmesh height under the enemy.
	var reference: Vector3 = NavigationServer3D.map_get_closest_point(_agent.get_navigation_map(), global_position)
	if absf(point.y - reference.y) > _push.detour_max_height_error:
		return false
	var query: PhysicsPointQueryParameters3D = PhysicsPointQueryParameters3D.new()
	query.position = Vector3(point.x, global_position.y + _push.detour_clear_height, point.z)
	query.collision_mask = LAYER_WORLD
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_point(query, 1).is_empty()


## Hit contract used by the player's guns: direction.length() is the pushback strength.
func take_hit(damage: float, direction: Vector3) -> void:
	if _dead or data == null:
		return
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length() > 0.001:
		_knockback += flat.normalized() * direction.length() * data.knockback_scale
		if _knockback.length() > data.max_knockback_speed:
			_knockback = _knockback.normalized() * data.max_knockback_speed
	if flat.length() > 0.001:
		_last_hit_direction = flat.normalized()
	var applied: float = _mitigate_damage(damage)
	_health -= applied
	_flash = FLASH_SECONDS
	damaged.emit(applied, maxf(_health, 0.0))
	if _health <= 0.0:
		_die()
	elif _visual != null:
		_visual.play_stagger()


## Current health.
func get_health() -> float:
	return _health


## Maximum health after wave scaling.
func get_max_health() -> float:
	return _max_health


## True once the enemy has died.
func is_dead() -> bool:
	return _dead


## Current AI state name (&"chase", &"move_to_spot", &"orbit", ...) for probes.
func get_state() -> StringName:
	return _state


## Current knockback velocity (decays over time).
func get_knockback_velocity() -> Vector3:
	return _knockback


## Move speed after wave scaling.
func get_move_speed() -> float:
	return data.move_speed * speed_multiplier


## Damage per hit/bullet after wave scaling.
func get_damage() -> float:
	return data.damage * damage_multiplier


## True when a ray from this enemy's eyes to the player's chest is not blocked by the world.
func has_line_of_fire() -> bool:
	return _has_clear_line(_eye_position())


## Eyes / muzzle position in world space.
func get_eye_position() -> Vector3:
	return _eye_position()


## Applies armour or other mitigation; returns the damage that reaches health. Subclasses override.
func _mitigate_damage(damage: float) -> float:
	return damage


## AI step; sets _desired_velocity (horizontal) and _state.
func _think(_delta: float) -> void:
	pass


func _eye_position() -> Vector3:
	return global_position + Vector3.UP * data.eye_height * data.body_scale


## True while the enemy aims its gun at the player (the visual turns the upper body onto the target). Overridden.
func _is_aiming() -> bool:
	return false


func _player_chest() -> Vector3:
	return _player.global_position + Vector3.UP * 1.0


func _has_clear_line(from: Vector3) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, _player_chest(), LAYER_WORLD)
	var excluded: Array[RID] = [get_rid()]
	if _player is CollisionObject3D:
		excluded.append((_player as CollisionObject3D).get_rid())
	query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _flat_distance_to(point: Vector3) -> float:
	var d: Vector3 = point - global_position
	return Vector2(d.x, d.z).length()


## Steers toward target using the navigation agent; falls back to a straight line if no path.
func _nav_velocity(wanted_target: Vector3, speed: float, delta: float) -> Vector3:
	_last_nav_target = wanted_target
	var target: Vector3 = _detour_point if _detour_left > 0.0 else wanted_target
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = data.repath_interval
		_agent.target_position = target
	var next: Vector3 = _agent.get_next_path_position()
	var dir: Vector3 = next - global_position
	dir.y = 0.0
	if dir.length() < 0.05 and _flat_distance_to(target) > _agent.target_desired_distance:
		dir = target - global_position
		dir.y = 0.0
	if dir.length() < 0.01:
		return Vector3.ZERO
	return dir.normalized() * speed


func _face(point: Vector3, delta: float) -> void:
	var d: Vector3 = point - global_position
	if Vector2(d.x, d.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), clampf(12.0 * delta, 0.0, 1.0))


## Fires one hitscan bullet at the player with random spread. Returns true if it reached the player.
func _fire_shot(bullet_damage: float, spread_degrees: float, max_range: float) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var dir: Vector3 = (_player_chest() - _eye_position()).normalized()
	if spread_degrees > 0.0:
		dir = spread_direction(dir, spread_degrees, aim_rng.randf() * TAU, sqrt(aim_rng.randf()))
	return _fire_ray(dir, bullet_damage, max_range)


## Rotates dir by an angle off-axis: radius_fraction (0-1) of max_degrees, around the axis at angle_radians.
static func spread_direction(dir: Vector3, max_degrees: float, angle_radians: float, radius_fraction: float) -> Vector3:
	var basis: Basis = Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT)
	var radius: float = radius_fraction * deg_to_rad(max_degrees)
	return (basis * Vector3(cos(angle_radians) * sin(radius), sin(angle_radians) * sin(radius), -cos(radius))).normalized()


## Casts one bullet ray from the eyes along dir; a player hit calls take_hit(damage, dir, source). True on a hit.
func _fire_ray(dir: Vector3, bullet_damage: float, max_range: float) -> bool:
	var origin: Vector3 = _eye_position()
	var ray_dir: Vector3 = dir
	if _visual != null and _visual.has_muzzle():
		# Shoot from the muzzle, aimed so the ray crosses the eye ray at the player's distance.
		var converge: float = 20.0
		if _player != null and is_instance_valid(_player):
			converge = maxf(origin.distance_to(_player_chest()), 1.0)
		var muzzle: Vector3 = _visual.get_muzzle_position()
		ray_dir = (origin + dir * converge - muzzle).normalized()
		origin = muzzle
		_visual.play_attack()
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, origin + ray_dir * max_range, LAYER_WORLD)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if _visual != null and _visual.has_muzzle():
		var end: Vector3 = hit["position"] if not hit.is_empty() else origin + ray_dir * max_range
		_visual.show_shot(origin, end)
	var hit_player: bool = false
	if not hit.is_empty():
		var collider: Object = hit["collider"]
		if collider is Node and (collider as Node).is_in_group(&"player") and collider.has_method("take_hit"):
			collider.call("take_hit", bullet_damage, ray_dir, global_position)
			hit_player = true
	shot_fired.emit(hit_player)
	return hit_player


func _build_body() -> void:
	var s: float = data.body_scale
	_body_root = Node3D.new()
	add_child(_body_root)
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = data.body_radius * s
	shape.height = data.body_height * s
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = data.body_height * s * 0.5
	add_child(collision)
	_collision = collision
	if data.visual != null:
		_visual = VISUAL_SCENE.instantiate() as EnemyVisual
		add_child(_visual)
		_visual.setup(data.visual, data.body_height * s, _get_attack_clip())
		return
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = shape.radius
	capsule.height = shape.height
	_material = StandardMaterial3D.new()
	_material.albedo_color = data.body_color
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = capsule
	mesh_instance.material_override = _material
	mesh_instance.position.y = collision.position.y
	_body_root.add_child(mesh_instance)
	# A light box on the front (-Z) so the facing direction is readable.
	_add_box(_body_root, Vector3(0.0, data.eye_height * s, -data.body_radius * s),
		Vector3(0.3, 0.12, 0.2) * s, Color(0.95, 0.85, 0.7))


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _die() -> void:
	if _dead:
		return
	_dead = true
	collision_layer = 0
	# The dying body keeps colliding with the world only, so it slides along the floor.
	collision_mask = LAYER_WORLD
	remove_from_group(&"enemies")
	_on_died()
	if _visual != null:
		_become_corpse()
	died.emit(self)
	_spawn_drops()
	_dying_left = data.death_slide_seconds
	if _visual == null and _dying_left <= 0.0:
		set_physics_process(false)
		queue_free()


## Turns the body into a shootable corpse: own layer (not the player's or enemies'), a lying capsule,
## the fall animation along the last shot, and the live-body cap.
func _become_corpse() -> void:
	var look: EnemyVisualData = data.visual
	collision_layer = look.corpse_collision_layer
	var fall: Vector3 = _last_hit_direction if _last_hit_direction.length() > 0.001 else global_basis.z
	fall.y = 0.0
	fall = fall.normalized()
	var local_fall: Vector3 = global_basis.orthonormalized().inverse() * fall
	var s: float = data.body_scale
	var axis: Vector3 = Vector3.UP.cross(local_fall).normalized()
	_collision.basis = Basis(axis, PI * 0.5)
	_collision.position = local_fall * data.body_height * s * 0.5 + Vector3.UP * data.body_radius * s
	_visual.set_reloading(false)
	_visual.set_flash(0.0)
	_visual.play_death(fall)
	_corpses.append(self)
	var live: Array[EnemyBase] = []
	for body: EnemyBase in _corpses:
		if is_instance_valid(body) and not body.is_queued_for_deletion():
			live.append(body)
	while live.size() > maxi(look.live_corpse_cap, 1):
		var oldest: EnemyBase = live.pop_front()
		if oldest != self:
			oldest.queue_free()
	_corpses = live


## Changes the AI state and logs the transition when log_transitions is on.
func _set_state(new_state: StringName) -> void:
	if new_state == _state:
		return
	if log_transitions:
		print("%s: %s -> %s" % [name, _state, new_state])
	_state = new_state


## Hook for subclasses (release firing spot, etc.).
func _on_died() -> void:
	pass


func _spawn_drops() -> void:
	var parent: Node = get_parent()
	if drop_data == null or parent == null:
		return
	var kinds: Array[StringName] = DropRoller.roll_drops_rng(data, drop_rng)
	# Unity placement: a dose lands at the death point (DoseDrops), an ammo box drop_offset metres to the side,
	# world +X (AmmoDrops). Extra drops of the same family (the boss) spread around that point.
	var placed: Dictionary = {}
	for kind: StringName in kinds:
		var is_ammo_kind: bool = DropRoller.AMMO_KINDS.has(kind)
		var base: Vector3 = global_position + (Vector3.RIGHT * drop_data.drop_offset if is_ammo_kind else Vector3.ZERO)
		var family: StringName = &"ammo" if is_ammo_kind else &"dose"
		var index: int = placed.get(family, 0) as int
		placed[family] = index + 1
		var pos: Vector3 = base
		if index > 0:
			var angle: float = TAU * float(index) / 6.0 + drop_rng.randf() * 0.5
			pos += Vector3(cos(angle), 0.0, sin(angle)) * drop_data.drop_spread_radius
		DropPickup.spawn(parent, kind, pos, drop_data)
