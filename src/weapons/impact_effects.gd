class_name ImpactEffects
extends Node3D
## Pooled world effects for shots: wall sparks and dust, bullet holes, blood sprays, kill bursts and
## floor splats. Everything is preallocated in _ready; nothing is created per shot.
## Particles: CPUParticles3D quads with an unshaded StandardMaterial3D (alpha blend, or additive for
## sparks), particle billboards and vertex colour as albedo. Holes and splats are Decals.

@export var data: ImpactEffectsData
## Bodies ignored by the floor-splat rays (the player).
var exclude: Array[RID] = []

var _sparks: Array[CPUParticles3D] = []
var _dust: Array[CPUParticles3D] = []
var _sprays: Array[CPUParticles3D] = []
var _bursts: Array[CPUParticles3D] = []
var _next: Dictionary = {}  # StringName pool -> int
var _holes: DecalPool
var _splats: DecalPool
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.randomize()
	if data == null:
		push_error("ImpactEffects needs data.")
		set_process(false)
		return
	# Work on converted copies so the shared data resource is not modified.
	data = data.duplicate() as ImpactEffectsData
	data.spark_texture = make_alpha_texture(data.spark_texture)
	data.dust_texture = make_alpha_texture(data.dust_texture)
	data.hole_texture = make_alpha_texture(data.hole_texture)
	data.blood_texture = make_alpha_texture(data.blood_texture)
	var converted: Array[Texture2D] = []
	for texture: Texture2D in data.splat_textures:
		converted.append(make_alpha_texture(texture))
	data.splat_textures = converted
	for i: int in data.spark_pool_size:
		_sparks.append(_make_emitter(data.spark_texture, data.spark_count, data.spark_size,
				data.spark_end_scale, data.spark_lifetime, data.spark_speed, data.spark_spread_degrees,
				data.spark_gravity, data.spark_color, true))
	for i: int in data.dust_pool_size:
		_dust.append(_make_emitter(data.dust_texture, data.dust_count, data.dust_size,
				data.dust_end_scale, data.dust_lifetime, data.dust_speed, 60.0, 0.0, data.dust_color, false))
	for i: int in data.spray_pool_size:
		_sprays.append(_make_emitter(data.blood_texture, data.spray_count, data.spray_size,
				data.spray_end_scale, data.spray_lifetime, data.spray_speed, data.spray_spread_degrees,
				data.spray_gravity, data.spray_color, false))
	for i: int in data.burst_pool_size:
		_bursts.append(_make_emitter(data.blood_texture, data.burst_count, data.burst_size,
				data.burst_end_scale, data.burst_lifetime, data.burst_speed, data.burst_spread_degrees,
				data.spray_gravity, data.burst_color, false))
	_holes = DecalPool.new(self, data.bullet_hole_cap, data.bullet_hole_lifetime,
			data.bullet_hole_fade_seconds, data.decal_depth)
	_splats = DecalPool.new(self, data.splat_cap, data.splat_lifetime, data.splat_fade_seconds,
			data.decal_depth)


func _process(delta: float) -> void:
	_holes.update(delta)
	_splats.update(delta)


## Sparks and dust along the surface normal plus a fading bullet hole. Pooled and capped.
func spawn_wall_impact(position: Vector3, normal: Vector3) -> void:
	if data == null:
		return
	_fire_emitter(&"spark", _sparks, position + normal * 0.03, normal)
	_fire_emitter(&"dust", _dust, position + normal * 0.03, normal)
	_holes.place(position, normal, data.bullet_hole_size, data.bullet_hole_color,
			data.hole_texture, _rng.randf() * TAU)


## Blood spray along the shot (mixed with the surface normal); a kill adds a bigger burst.
func spawn_blood_hit(position: Vector3, normal: Vector3, shot_direction: Vector3, killed: bool) -> void:
	if data == null:
		return
	# Along the shot as seen on the surface (its sliding part) plus outward along the normal, so the spray
	# leaves the body toward the camera instead of disappearing into it (a head-on shot goes straight out).
	var slide: Vector3 = shot_direction - normal * shot_direction.dot(normal)
	var direction: Vector3 = (slide + normal * data.spray_normal_blend).normalized()
	_fire_emitter(&"spray", _sprays, position + normal * 0.03, direction)
	if killed:
		_fire_emitter(&"burst", _bursts, position + normal * 0.03, direction)


## Casts rays around the shot and down from origin and leaves a blood splat where they hit the world.
## A kill casts kill_splat_ray_count rays (some steeply down so the floor is reached), else splat_ray_count.
func spawn_splats(origin: Vector3, shot_direction: Vector3, killed: bool) -> void:
	if data == null or not is_inside_tree():
		return
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var rays: int = data.kill_splat_ray_count if killed else data.splat_ray_count
	for i: int in rays:
		var cone: Vector3 = _random_in_cone(shot_direction, deg_to_rad(data.splat_spread_degrees))
		var bias: float = data.splat_down_bias
		if killed:
			bias = _rng.randf_range(data.splat_down_bias, data.kill_splat_down_bias_max)
			if i == 0:
				cone = Vector3.DOWN
				bias = 4.0
		var direction: Vector3 = (cone + Vector3.DOWN * bias).normalized()
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				origin, origin + direction * data.splat_reach, 1)
		query.exclude = exclude
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			continue
		var texture: Texture2D = null
		if not data.splat_textures.is_empty():
			texture = data.splat_textures[_rng.randi() % data.splat_textures.size()]
		_splats.place(hit["position"], hit["normal"], data.splat_size * _rng.randf_range(0.6, 1.4),
				data.splat_color, texture, _rng.randf() * TAU)


## Bullet holes currently alive (not yet faded out).
func get_bullet_hole_count() -> int:
	return _holes.active_count() if _holes != null else 0


## Most bullet holes that can be alive at once.
func get_bullet_hole_cap() -> int:
	return data.bullet_hole_cap if data != null else 0


## Blood splats currently alive.
func get_splat_count() -> int:
	return _splats.active_count() if _splats != null else 0


## Most blood splats that can be alive at once.
func get_splat_cap() -> int:
	return data.splat_cap if data != null else 0


## Total preallocated nodes in the pools (stays constant: nothing is created per shot).
func get_pool_node_count() -> int:
	return _sparks.size() + _dust.size() + _sprays.size() + _bursts.size() \
			+ _holes.nodes.size() + _splats.nodes.size()


func _fire_emitter(pool_name: StringName, pool: Array[CPUParticles3D], position: Vector3, direction: Vector3) -> void:
	if pool.is_empty():
		return
	var index: int = int(_next.get(pool_name, 0))
	_next[pool_name] = (index + 1) % pool.size()
	var emitter: CPUParticles3D = pool[index]
	emitter.global_transform = Transform3D(_basis_from_y(direction, 0.0), position)
	emitter.restart()
	emitter.emitting = true


func _make_emitter(texture: Texture2D, count: int, size: float, end_scale: float, lifetime: float,
		speed: float, spread_degrees: float, gravity: float, color: Color, additive: bool) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = maxi(count, 1)
	particles.lifetime = lifetime
	particles.local_coords = false
	particles.direction = Vector3.UP
	particles.spread = spread_degrees
	particles.gravity = Vector3(0.0, -gravity, 0.0)
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0 / maxf(end_scale, 0.01)))
	curve.add_point(Vector2(1.0, 1.0))
	particles.scale_amount_curve = curve
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([color, color, Color(color.r, color.g, color.b, 0.0)])
	particles.color_ramp = gradient
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * size * end_scale
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = material
	particles.mesh = quad
	add_child(particles)
	return particles


func _random_in_cone(axis: Vector3, half_angle: float) -> Vector3:
	var angle: float = _rng.randf() * TAU
	var radius: float = sqrt(_rng.randf()) * half_angle
	var basis: Basis = _basis_from_y(axis, 0.0)
	# basis.y is the axis; tilt it by radius around a random perpendicular.
	return (basis * Vector3(cos(angle) * sin(radius), cos(radius), sin(angle) * sin(radius))).normalized()


## The Kenney particle sprites are opaque grey on black (no alpha channel), which renders as black
## squares. This returns a white copy (max 128 px) whose alpha is the source brightness.
static func make_alpha_texture(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	var image: Image = source.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() > 128:
		image.resize(128, 128, Image.INTERPOLATE_BILINEAR)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var c: Color = image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, maxf(c.r, maxf(c.g, c.b)) * c.a))
	return ImageTexture.create_from_image(image)


## Basis whose Y axis is y_axis (spun by spin radians around it).
static func _basis_from_y(y_axis: Vector3, spin: float) -> Basis:
	var up: Vector3 = y_axis.normalized()
	if up.length_squared() < 0.5:
		up = Vector3.UP
	var reference: Vector3 = Vector3.FORWARD if absf(up.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x_axis: Vector3 = reference.cross(up).normalized()
	var z_axis: Vector3 = x_axis.cross(up).normalized()
	var result: Basis = Basis(x_axis, up, z_axis)
	return Basis(up, spin) * result


## Fixed-size ring of Decals that fade out and recycle the oldest when full.
class DecalPool:
	var nodes: Array[Decal] = []
	var ages: PackedFloat32Array = PackedFloat32Array()
	var base_colors: PackedColorArray = PackedColorArray()
	var lifetime: float = 1.0
	var fade: float = 1.0
	var depth: float = 0.2
	var next_index: int = 0

	func _init(parent: Node3D, cap: int, life: float, fade_seconds: float, decal_depth: float) -> void:
		lifetime = life
		fade = maxf(fade_seconds, 0.001)
		depth = decal_depth
		for i: int in cap:
			var decal: Decal = Decal.new()
			decal.visible = false
			decal.cull_mask = 1
			parent.add_child(decal)
			nodes.append(decal)
			ages.append(-1.0)
			base_colors.append(Color.WHITE)

	func place(position: Vector3, normal: Vector3, size: float, color: Color, texture: Texture2D, spin: float) -> void:
		if nodes.is_empty():
			return
		var index: int = next_index
		next_index = (next_index + 1) % nodes.size()
		var decal: Decal = nodes[index]
		decal.size = Vector3(size, depth, size)
		decal.texture_albedo = texture
		decal.modulate = color
		decal.global_transform = Transform3D(ImpactEffects._basis_from_y(normal, spin), position)
		decal.visible = true
		ages[index] = 0.0
		base_colors[index] = color

	func update(delta: float) -> void:
		for i: int in nodes.size():
			if ages[i] < 0.0:
				continue
			ages[i] += delta
			if ages[i] >= lifetime + fade:
				ages[i] = -1.0
				nodes[i].visible = false
			elif ages[i] > lifetime:
				var color: Color = base_colors[i]
				color.a *= 1.0 - (ages[i] - lifetime) / fade
				nodes[i].modulate = color

	func active_count() -> int:
		var count: int = 0
		for age: float in ages:
			if age >= 0.0:
				count += 1
		return count
