class_name PushableProp
extends CharacterBody3D
## A table or loose prop that enemies push. A kinematic body that integrates its own planar rigid-body
## motion: mass, moment of inertia, Coulomb floor friction, and contact impulses solved at the contact point
## (so an off-centre push swings it about the contact). Enemies push it through apply_push() (EnemyBase);
## nothing else moves it, so the player is blocked by it but never pushes it. It moves itself with
## move_and_collide, stays on physics layer 1 like the static prop it replaces, bumps other pushable props
## (impulse exchange), and is stopped by walls, benches, the player and enemies. Never moves vertically.
## The level builder (LevelBase) wraps the imported prop scene in one of these.

## Emitted when a push impulse is applied (push_velocity = prop velocity right after the push).
signal pushed(push_velocity: Vector3)

## Group every pushable prop is in.
const GROUP: StringName = &"pushable_prop"
## Physics priority: props integrate before the enemies (priority 0) step, so an enemy pushing one walks
## into the space the prop has just made this frame instead of the space it will make next frame.
const PHYSICS_PRIORITY: int = -10

@export var data: PushablePropData

var _size: Vector3 = Vector3.ONE
var _box_center_y: float = 0.0
var _velocity: Vector3 = Vector3.ZERO
## Angular velocity about +Y, radians per second.
var _spin: float = 0.0
var _inertia: float = 1.0
var _push_frame: int = -1000
var _blocked: bool = false
var _rotation_blocked: bool = false
var _resting: bool = true
var _last_pusher: Node3D
var _turn_shape: BoxShape3D


## Sets the data and builds the box collider. `local_box` is the visual's bounds with the pivot at its
## horizontal centre (x/z centred on 0); the box spans floor to top, ground_clearance above the floor.
func configure(prop_data: PushablePropData, local_box: AABB) -> void:
	data = prop_data
	collision_layer = data.collision_layer
	collision_mask = data.collision_mask
	safe_margin = data.skin
	_size = Vector3(local_box.size.x, maxf(local_box.size.y - data.ground_clearance, 0.05), local_box.size.z)
	_box_center_y = local_box.position.y + data.ground_clearance + _size.y * 0.5
	# Solid box about its vertical axis: I = m (w^2 + d^2) / 12.
	_inertia = maxf(data.mass * (_size.x * _size.x + _size.z * _size.z) / 12.0, 0.001)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = _size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.0, _box_center_y, 0.0)
	add_child(collision)
	var shrink: float = data.rotate_shrink * 2.0
	_turn_shape = BoxShape3D.new()
	_turn_shape.size = Vector3(maxf(_size.x - shrink, 0.01), maxf(_size.y - shrink, 0.01), maxf(_size.z - shrink, 0.01))
	add_to_group(GROUP)
	process_physics_priority = PHYSICS_PRIORITY
	set_physics_process(false)


## A pusher drives the contact point at `contact_point` along the horizontal unit `normal` (pointing into
## the prop) toward `target_speed` m/s. Solves the contact impulse (mass and turning both resist it), never
## pulls, and is capped by `max_impulse` (N s; the pusher's force x delta). Several pushers each call this in
## the same frame; each only tops its own contact up to its target, so they share the effort, not add speeds.
## Returns the impulse applied.
func apply_push(contact_point: Vector3, normal: Vector3, target_speed: float, max_impulse: float, pusher: Node3D) -> float:
	if data == null or max_impulse <= 0.0:
		return 0.0
	var n: Vector3 = Vector3(normal.x, 0.0, normal.z)
	if n.length_squared() < 0.000001:
		return 0.0
	n = n.normalized()
	var r: Vector3 = _arm(contact_point)
	var c: float = r.z * n.x - r.x * n.z
	var current: float = get_point_velocity(contact_point).dot(n)
	var k: float = 1.0 / data.mass + c * c / _inertia
	var j: float = clampf((target_speed - current) / k, 0.0, max_impulse)
	_push_frame = Engine.get_physics_frames()
	_last_pusher = pusher
	if j <= 0.0:
		return 0.0
	_add_impulse(n * j, c * j)
	pushed.emit(_velocity)
	return j


## Applies a horizontal impulse (N s) at a world point (used for prop-to-prop knocks).
func apply_impulse_at(world_point: Vector3, impulse: Vector3) -> void:
	if data == null:
		return
	var flat: Vector3 = Vector3(impulse.x, 0.0, impulse.z)
	var r: Vector3 = _arm(world_point)
	_add_impulse(flat, r.z * flat.x - r.x * flat.z)


## Horizontal velocity of the prop's material at a world point (translation + spin).
func get_point_velocity(world_point: Vector3) -> Vector3:
	var r: Vector3 = _arm(world_point)
	return _velocity + Vector3(_spin * r.z, 0.0, -_spin * r.x)


## Current horizontal velocity of the prop's centre.
func get_push_velocity() -> Vector3:
	return _velocity


## Current turn rate in degrees per second (positive = counter-clockwise seen from above).
func get_yaw_rate() -> float:
	return rad_to_deg(_spin)


## Mass in kg (from data).
func get_mass() -> float:
	return data.mass if data != null else 0.0


## True when the prop is not moving and not being pushed.
func is_resting() -> bool:
	return _resting


## True when the last move while pushed was stopped (wall, bench, other prop, player, enemy).
func was_blocked_last_push() -> bool:
	return _blocked


## True when the last wanted turn was refused because the turned box would overlap something.
func was_rotation_blocked() -> bool:
	return _rotation_blocked


## The node that pushed last (may be null or freed).
func get_last_pusher() -> Node3D:
	return _last_pusher


## Half extents (x, z) of the collider footprint in the prop's own axes.
func get_footprint_extents() -> Vector2:
	return Vector2(_size.x, _size.z) * 0.5


## Full size of the collider box in the prop's own axes.
func get_box_size() -> Vector3:
	return _size


## World-axis bounds of the oriented collider box.
func get_box_aabb_world() -> AABB:
	var local: AABB = AABB(Vector3(-_size.x * 0.5, _box_center_y - _size.y * 0.5, -_size.z * 0.5), _size)
	return global_transform * local


## The four footprint corners in world space, at the prop's floor height.
func get_corner_points() -> PackedVector3Array:
	var half: Vector2 = get_footprint_extents()
	var points: PackedVector3Array = PackedVector3Array()
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			points.append(global_transform * Vector3(sx * half.x, 0.0, sz * half.y))
	return points


## Closest point of the footprint rectangle to a world point (at the point's height). A point inside the
## footprint returns itself.
func closest_footprint_point(point: Vector3) -> Vector3:
	var local: Vector3 = global_transform.affine_inverse() * point
	var half: Vector2 = get_footprint_extents()
	local.x = clampf(local.x, -half.x, half.x)
	local.z = clampf(local.z, -half.y, half.y)
	var world: Vector3 = global_transform * local
	world.y = point.y
	return world


## True when a world point lies inside the footprint (extended by margin metres).
func footprint_contains(point: Vector3, margin: float = 0.0) -> bool:
	var local: Vector3 = global_transform.affine_inverse() * point
	var half: Vector2 = get_footprint_extents()
	return absf(local.x) <= half.x + margin and absf(local.z) <= half.y + margin


## All pushable props in the tree.
static func get_all(tree: SceneTree) -> Array[PushableProp]:
	var result: Array[PushableProp] = []
	for node: Node in tree.get_nodes_in_group(GROUP):
		result.append(node as PushableProp)
	return result


func _physics_process(delta: float) -> void:
	if data == null:
		set_physics_process(false)
		return
	var pushed_recently: bool = Engine.get_physics_frames() - _push_frame <= 1
	_apply_friction(delta)
	if not pushed_recently and _velocity.length() < data.rest_speed and absf(rad_to_deg(_spin)) < data.rest_turn_rate:
		_velocity = Vector3.ZERO
		_spin = 0.0
		_blocked = false
		_resting = true
		set_physics_process(false)
		return
	_rotation_blocked = false
	if absf(_spin) > 0.00001:
		_try_rotate(_spin * delta)
	_blocked = false
	var wanted: Vector3 = _velocity * delta
	if wanted.length_squared() > 0.0000001:
		_move(wanted, pushed_recently, delta)


func _arm(world_point: Vector3) -> Vector3:
	return Vector3(world_point.x - global_position.x, 0.0, world_point.z - global_position.z)


func _add_impulse(linear: Vector3, angular: float) -> void:
	_velocity += linear / data.mass
	_spin += angular / _inertia
	var speed: float = _velocity.length()
	if speed > data.max_speed:
		_velocity *= data.max_speed / speed
	var cap: float = deg_to_rad(data.max_turn_rate)
	_spin = clampf(_spin, -cap, cap)
	if _resting or not is_physics_processing():
		_resting = false
		set_physics_process(true)


## Coulomb floor friction (constant deceleration mu*g) plus light viscous damping, for both slide and spin.
func _apply_friction(delta: float) -> void:
	var g: float = get_gravity().length()
	var speed: float = _velocity.length()
	if speed > 0.0:
		var drop: float = (data.friction * g + data.linear_damping * speed) * delta
		_velocity = _velocity * (maxf(speed - drop, 0.0) / speed)
	var spin_abs: float = absf(_spin)
	if spin_abs > 0.0:
		# Friction torque of a sliding box ~ mu * m * g * spin_friction_radius.
		var spin_drop: float = (data.friction * g * data.mass * data.spin_friction_radius / _inertia
			+ data.angular_damping * spin_abs) * delta
		_spin = signf(_spin) * maxf(spin_abs - spin_drop, 0.0)


func _move(wanted: Vector3, pushed_recently: bool, delta: float) -> void:
	var start: Vector3 = global_position
	var motion: Vector3 = wanted
	for _i: int in data.max_slides:
		var hit: KinematicCollision3D = move_and_collide(motion, false, data.skin)
		if hit == null:
			break
		_resolve_hit(hit)
		var n: Vector3 = Vector3(hit.get_normal().x, 0.0, hit.get_normal().z)
		if n.length_squared() < 0.000001:
			break
		motion = hit.get_remainder().slide(n.normalized())
		motion.y = 0.0
		if motion.length_squared() < 0.00000001:
			break
	global_position.y = start.y
	var moved: Vector3 = global_position - start
	if moved.dot(wanted.normalized()) < wanted.length() * data.blocked_fraction:
		# Hemmed in: keep only the motion it really made, so pushers see a stopped prop (and give up).
		_velocity = Vector3(moved.x, 0.0, moved.z) / delta
		_blocked = pushed_recently


## Contact impulse against what the prop ran into: another pushable prop shares the impulse (by mass and
## lever arm), anything else (walls, benches, player, enemies) is immovable. Restitution from data.
func _resolve_hit(hit: KinematicCollision3D) -> void:
	var n: Vector3 = Vector3(hit.get_normal().x, 0.0, hit.get_normal().z)
	if n.length_squared() < 0.000001:
		return
	n = n.normalized()
	var p: Vector3 = hit.get_position()
	var other: PushableProp = hit.get_collider() as PushableProp
	var relative: Vector3 = get_point_velocity(p)
	if other != null:
		relative -= other.get_point_velocity(p)
	var approach: float = relative.dot(n)
	if approach >= 0.0:
		return
	var r: Vector3 = _arm(p)
	var c: float = r.z * n.x - r.x * n.z
	var k: float = 1.0 / data.mass + c * c / _inertia
	if other != null and other.data != null:
		var r2: Vector3 = other._arm(p)
		var c2: float = r2.z * n.x - r2.x * n.z
		k += 1.0 / other.data.mass + c2 * c2 / other._inertia
	var bounce: float = data.restitution if -approach >= data.bounce_min_speed else 0.0
	var j: float = -(1.0 + bounce) * approach / k
	_velocity += n * (j / data.mass)
	_spin += c * j / _inertia
	if other != null:
		other.apply_impulse_at(p, -n * j)


func _try_rotate(angle: float) -> void:
	var new_basis: Basis = (Basis(Vector3.UP, angle) * global_basis).orthonormalized()
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = _turn_shape
	query.transform = Transform3D(new_basis, global_position) * Transform3D(Basis.IDENTITY, Vector3(0.0, _box_center_y, 0.0))
	query.collision_mask = data.collision_mask
	query.exclude = [get_rid()]
	if get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		global_basis = new_basis
	else:
		_rotation_blocked = true
		_spin = 0.0
