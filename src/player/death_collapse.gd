class_name DeathCollapse
extends Node
## The death collapse (story 018): the knees buckle (camera drops), then the view tips over, falls to the
## floor, rolls a little and settles. Camera-only (no ragdoll for the player); the arms drop out of view and
## the gun falls out as a RigidBody3D. Runs in unscaled real time (RealClock), so hitstop and slow motion
## never stretch it. Deterministic: the fall side comes from the last hit, a nearby wall, or data.
##
## The collapse owns the Camera3D from `start()` on: each frame (process priority 60, after GunFeel 50,
## AbilityLook 55 and HeartRateScreen 56, before the mirror cameras at 100) it writes the camera's global
## transform as the player-relative start pose plus the collapse offset. The mirror cameras copy that.

## Emitted on every phase change.
signal phase_changed(phase: Phase, previous_phase: Phase)
## Emitted when the gun body has been created.
signal gun_released(body: RigidBody3D)
## Emitted once when the view is at rest.
signal finished

enum Phase { IDLE, BUCKLE, FALL, SETTLE, REST }

const PROCESS_PRIORITY: int = 60

@export var data: DeathFlowData
@export var player: PlayerController
@export var camera: Camera3D
@export var viewmodel: Viewmodel
## Parent of the dropped gun body (default: the player's parent, the game root).
@export var world_parent: Node
@export_group("Debug")
## Stops the collapse clock at this many seconds (negative = off); used by capture scenes.
@export var debug_freeze_at_seconds: float = -1.0

var _phase: Phase = Phase.IDLE
var _active: bool = false
var _finished: bool = false
var _elapsed: float = 0.0
var _side: float = 1.0
var _scale_override: float = -1.0
var _base_local: Transform3D = Transform3D.IDENTITY
## Pose the collapse starts from, frozen at start() so a dive or gravity moving the body cannot move it.
var _base_world: Transform3D = Transform3D.IDENTITY
var _floor_y: float = 0.0
var _total_drop: float = 0.0
var _hit_source: Variant = null
var _hit_usec: int = 0
var _camera_transform: Transform3D = Transform3D.IDENTITY
var _offset: Vector3 = Vector3.ZERO
var _drop: float = 0.0
var _roll_degrees: float = 0.0
var _pitch_degrees: float = 0.0
var _arms_drop: float = 0.0
var _gun_body: RigidBody3D
var _released: bool = false
var _clock: RealClock = RealClock.new()
var _camera_shape: SphereShape3D = SphereShape3D.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = PROCESS_PRIORITY
	set_process(false)
	if player != null:
		player.hit_taken.connect(_on_player_hit_taken)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Remembers the latest hit so the fall can go away from it. age_seconds back-dates it (probes).
func record_hit(source_position: Variant, age_seconds: float = 0.0) -> void:
	_hit_source = source_position
	_hit_usec = Time.get_ticks_usec() - int(age_seconds * 1000000.0)


## Overrides the comfort scale (0..1) for probes; negative returns to the data value.
func set_motion_scale(value: float) -> void:
	_scale_override = value


## The comfort scale in use.
func get_motion_scale() -> float:
	return clampf(data.camera_motion_scale if _scale_override < 0.0 else _scale_override, 0.0, 1.0)


## Starts the collapse from the camera's current pose. Returns false when it cannot run.
func start(_reason: StringName = &"") -> bool:
	if _active:
		return false
	if data == null or player == null or camera == null:
		push_error("DeathCollapse needs data, player and camera assigned.")
		return false
	_active = true
	_finished = false
	_elapsed = 0.0
	_released = false
	player.set_input_locked(true)
	_base_local = player.global_transform.affine_inverse() * camera.global_transform
	_base_world = _live_base()
	player.velocity = Vector3.ZERO
	var base: Transform3D = _base_world
	var age: float = float(Time.get_ticks_usec() - _hit_usec) / 1000000.0 if _hit_source != null else -1.0
	_side = compute_fall_side(base.origin, _right_flat(base), _hit_source, age)
	_floor_y = _probe_floor(base.origin)
	_total_drop = maxf(base.origin.y - _floor_y - data.rest_height, 0.0)
	_set_phase(Phase.BUCKLE)
	set_process(true)
	tick(0.0)
	return true


## Fall side as +1 (right) or -1 (left): away from a hit that landed within the data window, else away
## from a wall within the probe distance (the nearer one if both sides have one), else the data side.
## hit_age_seconds < 0 or a null/non-Vector3 source means "no usable hit".
func compute_fall_side(origin: Vector3, right: Vector3, hit_source: Variant, hit_age_seconds: float) -> float:
	if hit_source is Vector3 and hit_age_seconds >= 0.0 and hit_age_seconds <= data.hit_window_seconds:
		var lateral: float = ((hit_source as Vector3) - origin).dot(right)
		if absf(lateral) > data.hit_side_deadzone:
			return -signf(lateral)
	var distance_right: float = _probe_distance(origin, right)
	var distance_left: float = _probe_distance(origin, -right)
	if distance_right >= 0.0 and (distance_left < 0.0 or distance_right < distance_left):
		return -1.0
	if distance_left >= 0.0 and (distance_right < 0.0 or distance_left < distance_right):
		return 1.0
	return -1.0 if data.fall_side == &"left" else 1.0


## Advances the collapse by real seconds and writes the camera. No-op before start().
func tick(real_delta: float) -> void:
	if not _active:
		return
	var limit: float = INF if debug_freeze_at_seconds < 0.0 else debug_freeze_at_seconds
	_elapsed = minf(_elapsed + maxf(real_delta, 0.0), maxf(limit, _elapsed))
	_update_phase()
	_update_arms_and_gun()
	_update_camera()
	if _phase == Phase.REST and not _finished:
		_finished = true
		finished.emit()


## Current phase.
func get_phase() -> Phase:
	return _phase


## Current phase name (idle, buckle, fall, settle, rest).
func get_phase_name() -> StringName:
	return StringName(String(Phase.keys()[_phase]).to_lower())


## +1 right, -1 left (decided at start()).
func get_fall_side() -> float:
	return _side


## Seconds of collapse so far.
func get_elapsed() -> float:
	return _elapsed


## Seconds from start to rest (collapse + bounce).
func get_total_seconds() -> float:
	return data.collapse_seconds + data.bounce_seconds


## True from start() on.
func is_active() -> bool:
	return _active


## True once the view is at rest.
func is_finished() -> bool:
	return _finished


## World-space offset of the camera from the pose it would have had without the collapse (after the
## wall/floor sphere cast).
func get_camera_offset() -> Vector3:
	return _offset


## The transform written to the camera this frame.
func get_camera_transform() -> Transform3D:
	return _camera_transform


## Roll in degrees (negative = tilted to the right), before the sphere cast.
func get_roll_degrees() -> float:
	return _roll_degrees


## Nose-down tilt in degrees.
func get_pitch_degrees() -> float:
	return _pitch_degrees


## Metres the camera has dropped (buckle + fall, without the bounce).
func get_drop() -> float:
	return _drop


## Metres the arms have dropped out of view.
func get_arms_drop() -> float:
	return _arms_drop


## The dropped gun body (null until released).
func get_gun_body() -> RigidBody3D:
	return _gun_body


## True once the gun has been released.
func was_gun_released() -> bool:
	return _released


func _on_player_hit_taken(_damage: float, source_position: Variant) -> void:
	if not _active:
		record_hit(source_position)


func _base_global() -> Transform3D:
	return _base_world


func _live_base() -> Transform3D:
	var t: Transform3D = player.global_transform * _base_local
	return Transform3D(t.basis.orthonormalized(), t.origin)


func _right_flat(base: Transform3D) -> Vector3:
	var right: Vector3 = base.basis.x
	right.y = 0.0
	if right.length_squared() < 0.0001:
		right = player.global_transform.basis.x
	return right.normalized()


func _set_phase(next: Phase) -> void:
	if next == _phase:
		return
	var previous: Phase = _phase
	_phase = next
	phase_changed.emit(next, previous)


func _update_phase() -> void:
	if _elapsed < data.buckle_seconds:
		_set_phase(Phase.BUCKLE)
	elif _elapsed < data.collapse_seconds:
		_set_phase(Phase.FALL)
	elif _elapsed < data.collapse_seconds + data.bounce_seconds:
		_set_phase(Phase.SETTLE)
	else:
		_set_phase(Phase.REST)


## Camera pose at time t. Lowering is one continuous curve (buckle ease, then a gravity-like fall that
## starts at rest). Roll, tilt, sideways slide and bounce are scaled by the comfort scale.
func _update_camera() -> void:
	var scale: float = get_motion_scale()
	var buckle_seconds: float = maxf(data.buckle_seconds, 0.001)
	var fall_seconds: float = maxf(data.collapse_seconds - data.buckle_seconds, 0.001)
	var buckle: float = minf(data.buckle_drop, _total_drop)
	var progress: float = 0.0
	if _elapsed < buckle_seconds:
		_drop = buckle * smoothstep(0.0, 1.0, _elapsed / buckle_seconds)
	elif _elapsed < data.collapse_seconds:
		progress = (_elapsed - data.buckle_seconds) / fall_seconds
		_drop = buckle + (_total_drop - buckle) * progress * progress
	else:
		progress = 1.0
		_drop = _total_drop
	var bounce: float = 0.0
	if _elapsed > data.collapse_seconds and data.bounce_seconds > 0.0:
		var q: float = clampf((_elapsed - data.collapse_seconds) / data.bounce_seconds, 0.0, 1.0)
		bounce = data.bounce_height * scale * sin(PI * q)
	var tilt: float = smoothstep(0.0, 1.0, progress)
	_roll_degrees = -_side * data.max_roll_degrees * scale * tilt
	_pitch_degrees = data.max_pitch_degrees * scale * tilt
	var base: Transform3D = _base_global()
	var target: Vector3 = base.origin + _right_flat(base) * (_side * data.fall_distance * scale * tilt) \
			+ Vector3.DOWN * _drop + Vector3.UP * bounce
	target = _clip_to_world(base.origin, target)
	_offset = target - base.origin
	var basis: Basis = base.basis * Basis(Vector3.BACK, deg_to_rad(_roll_degrees)) \
			* Basis(Vector3.RIGHT, deg_to_rad(-_pitch_degrees))
	_camera_transform = Transform3D(basis, target)
	if camera.is_inside_tree():
		camera.global_transform = _camera_transform


## Sphere cast from the un-collapsed position to the wanted one; stops short of anything solid.
func _clip_to_world(from: Vector3, to: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = _space()
	var motion: Vector3 = to - from
	if space == null or motion.length_squared() < 0.000001:
		return to
	_camera_shape.radius = data.camera_radius
	# 1) the full sweep; 2) if the sphere already overlaps at the start (head against a wall or prop),
	# a downward-only sweep so the camera still drops; 3) the full sweep from the capsule axis.
	var fraction: float = _sweep(space, from, motion)
	if fraction > 0.0:
		return from + motion * fraction
	var down: Vector3 = Vector3(0.0, motion.y, 0.0)
	if absf(down.y) > 0.000001:
		fraction = _sweep(space, from, down)
		if fraction > 0.0:
			return from + down * fraction
	var axis_from: Vector3 = Vector3(player.global_position.x, from.y, player.global_position.z)
	if axis_from.distance_squared_to(from) > 0.000001:
		var axis_motion: Vector3 = to - axis_from
		fraction = _sweep(space, axis_from, axis_motion)
		if fraction > 0.0:
			return axis_from + axis_motion * fraction
	return from


## Safe fraction (0..1) of a sphere sweep; 1.0 when the result is empty (nothing hit).
func _sweep(space: PhysicsDirectSpaceState3D, from: Vector3, motion: Vector3) -> float:
	var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	params.shape = _camera_shape
	params.transform = Transform3D(Basis.IDENTITY, from)
	params.motion = motion
	params.collision_mask = data.camera_collision_mask
	params.exclude = [player.get_rid()]
	var result: PackedFloat32Array = space.cast_motion(params)
	return 1.0 if result.is_empty() else result[0]


func _space() -> PhysicsDirectSpaceState3D:
	if player == null or not player.is_inside_tree():
		return null
	return player.get_world_3d().direct_space_state


## Distance to the first solid thing along dir within the wall probe distance, or -1.
func _probe_distance(origin: Vector3, dir: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = _space()
	if space == null:
		return -1.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			origin, origin + dir * data.wall_probe_distance, data.camera_collision_mask, [player.get_rid()])
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return -1.0
	return origin.distance_to(hit.position as Vector3)


func _probe_floor(origin: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = _space()
	if space != null:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				origin, origin + Vector3.DOWN * data.floor_probe_distance, data.camera_collision_mask, [player.get_rid()])
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			return (hit.position as Vector3).y
	return origin.y - data.fallback_eye_height


func _update_arms_and_gun() -> void:
	if viewmodel != null:
		var t: float = 1.0 if data.arms_drop_seconds <= 0.0 else clampf(_elapsed / data.arms_drop_seconds, 0.0, 1.0)
		_arms_drop = data.arms_drop_distance * smoothstep(0.0, 1.0, t)
		viewmodel.set_death_drop(_arms_drop)
	if data.drop_gun and not _released and _elapsed >= data.gun_release_seconds:
		_released = true
		_release_gun()


## Replaces the viewmodel gun with a RigidBody3D copy of its mesh in the world (visible to the main
## camera: render layer 1, not the viewmodel layer), pushed down and forward with some spin.
func _release_gun() -> void:
	if viewmodel == null:
		return
	var model: Node3D = viewmodel.get_active_gun_model()
	if model == null:
		return
	var model_transform: Transform3D = model.global_transform
	var copy: Node3D = model.duplicate() as Node3D
	copy.visible = true
	copy.transform = Transform3D(Basis.from_scale(model_transform.basis.get_scale()), Vector3.ZERO)
	_set_world_layer(copy)
	var body: RigidBody3D = RigidBody3D.new()
	body.name = "DroppedGun"
	body.mass = data.gun_mass
	body.continuous_cd = true
	body.linear_damp = data.gun_linear_damp
	body.angular_damp = data.gun_angular_damp
	body.collision_layer = 0
	body.set_collision_layer_value(data.gun_collision_layer, true)
	body.collision_mask = data.gun_collision_mask
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.bounce = data.gun_bounce
	material.friction = data.gun_friction
	body.physics_material_override = material
	body.add_child(copy)
	var boxes: Array[AABB] = []
	_collect_aabbs(copy, copy.transform, boxes)
	if not boxes.is_empty():
		var merged: AABB = boxes[0]
		for box: AABB in boxes:
			merged = merged.merge(box)
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(maxf(merged.size.x, data.gun_min_size), maxf(merged.size.y, data.gun_min_size),
				maxf(merged.size.z, data.gun_min_size))
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = shape
		collision.position = merged.get_center()
		body.add_child(collision)
	var parent: Node = world_parent if world_parent != null else player.get_parent()
	parent.add_child(body)
	body.global_transform = Transform3D(model_transform.basis.orthonormalized(), _safe_gun_origin(model_transform.origin))
	body.add_collision_exception_with(player)
	var view_basis: Basis = camera.global_transform.basis
	body.linear_velocity = Vector3.DOWN * data.gun_push_down - view_basis.z * data.gun_push_forward
	body.angular_velocity = view_basis.z * (deg_to_rad(data.gun_spin_degrees) * _side)
	viewmodel.set_gun_hidden(true)
	_gun_body = body
	gun_released.emit(body)


## The gun spawn point: the viewmodel pose, pulled back to the camera side of any wall between the
## camera and it (the viewmodel draws through walls, the world body must not start inside one).
func _safe_gun_origin(origin: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = _space()
	if space == null:
		return origin
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			camera.global_position, origin, data.gun_collision_mask, [player.get_rid()])
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return origin
	return (hit.position as Vector3) + (hit.normal as Vector3) * data.camera_radius


func _set_world_layer(node: Node) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = 1
	for child: Node in node.get_children():
		_set_world_layer(child)


func _collect_aabbs(node: Node3D, node_transform: Transform3D, boxes: Array[AABB]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		boxes.append(node_transform * (node as MeshInstance3D).mesh.get_aabb())
	for child: Node in node.get_children():
		if child is Node3D:
			_collect_aabbs(child as Node3D, node_transform * (child as Node3D).transform, boxes)
