class_name Viewmodel
extends Node3D
## First-person viewmodel: two skinned PSX arms (Drillimpact arms_rig), the gun in the right (grip)
## hand and the held substance (coffee cup or cigarette) in the left (free) hand.
##
## Port of the Unity ViewmodelArms / ArmMotion / SubstanceHandMotion / TwoBoneIk / GunFeedback pose:
## the arms rig's animations are NOT played; every frame each arm is reset to its rest pose and
## solved with two-bone IK toward a wrist target and hand frame from data, then its fingers curled.
## - Grip hand: a fixed pose on the gun (gun-pivot space), so it follows the shot kick and the raise.
## - Free hand: the substance layer (rest, raised to the mouth while consuming, swap, empty hand) in
##   camera space, with the gun's reload timeline (magazine from the pouch, rack; shotgun shells)
##   blended over it in gun-pivot space. The substance prop shows while its stash is not empty.
## Reads WeaponHolder and SubstanceInventory only; it never changes ammo or dosing state.
## Clipping: all viewmodel geometry sits on its own visual layer, hidden from the main camera and
## drawn by a second camera in a transparent SubViewport on top of the 3D scene, so walls can
## never hide the gun. The viewport shares the main World3D (so lights still apply) and the
## second camera copies the main camera's transform every frame.

enum Phase { IDLE, RELOAD, FINISH }
enum Swap { NONE, LOWER, RAISE }

const FINGER_NAMES: PackedStringArray = ["f_index", "f_middle", "f_ring", "f_pinky", "thumb"]
const FINGER_COUNT: int = 5
const JOINT_COUNT: int = 3
const INDEX_FINGER: int = 0
const MIDDLE_FINGER: int = 1
const THUMB_FINGER: int = 4
## Shortest reach as a fraction of the limb length (solver safety limit, as in Unity TwoBoneIk).
const MIN_REACH_FRACTION: float = 0.2
const EPSILON: float = 1e-5
## Smallest rest bend (degrees) that defines the palm side and the thumb's bend axis.
const MIN_REST_BEND_DEGREES: float = 3.0
const SMOKE_TEXTURE: String = "res://assets/third_party/kenney_particle_pack/smoke_01.png"

@export var data: ViewmodelData
@export var weapon_holder: WeaponHolder
@export var substances: SubstanceInventory
## The player's camera this viewmodel is attached to.
@export var camera: Camera3D


## A free-hand pose: wrist position, hand-frame rotation, finger curl and held prop.
class HandSample:
	var position: Vector3
	var rotation: Quaternion
	var curl: Vector3
	var prop: int

	func _init(p: Vector3 = Vector3.ZERO, r: Quaternion = Quaternion.IDENTITY, c: Vector3 = Vector3.ZERO,
			held: int = ViewmodelHandKey.Prop.SUBSTANCE) -> void:
		position = p
		rotation = r
		curl = c
		prop = held

	static func blend(a: HandSample, b: HandSample, t: float, held: int) -> HandSample:
		return HandSample.new(a.position.lerp(b.position, t), a.rotation.slerp(b.rotation, t),
				a.curl.lerp(b.curl, t), held)


## One side's bones and what was read from its rest pose.
class Arm:
	var upper: int
	var forearm: int
	var hand: int
	var palm: int
	var fingers: PackedInt32Array = PackedInt32Array()
	var rest_upper: Quaternion
	var rest_forearm: Quaternion
	var rest_hand: Quaternion
	var rest_fingers: Array[Quaternion] = []
	## Rest basis of each finger bone in the hand bone's space.
	var finger_in_hand: Array[Basis] = []
	## Per finger bone, the curl axis in its own rest frame (set per gun).
	var curl_axes: PackedVector3Array = PackedVector3Array()
	## The hand frame (fingers -Z, back of the hand +Y) in the hand bone's space.
	var hand_frame: Basis
	## The thumb's rest bend axis in the hand bone's space.
	var auto_thumb_axis: Vector3


var _gun_models: Dictionary = {}  # StringName gun_id -> Node3D mount
var _gun_entries: Dictionary = {}  # StringName gun_id -> ViewmodelGunData
var _props: Dictionary = {}  # StringName kind -> Node3D wrapper
var _prop_entries: Dictionary = {}  # StringName kind -> ViewmodelSubstanceData
var _prop_fx: Dictionary = {}  # StringName kind -> Array[CPUParticles3D] (idle, raised extra)
var _active_gun: ViewmodelGunData
var _base_position: Vector3 = Vector3.ZERO
var _player_time: PlayerTime
var _camera_base_fov: float = 75.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Gun pose.
var _kick_elapsed: float = 1e9
var _kick_side: float = 1.0
var _raise_elapsed: float = 1e9

# Arms rig.
var _arms_root: Node3D
var _skeleton: Skeleton3D
var _grip: Arm
var _free: Arm
var _magazine: MeshInstance3D
var _shell: MeshInstance3D

# Substance layer (camera space).
var _held_kind: StringName = &""
var _shown_kind: StringName = &""
var _raise: float = 0.0
var _empty: float = 0.0
var _swap_phase: Swap = Swap.NONE
var _swap_depth: float = 0.0
var _was_consuming: Dictionary = {}
var _hand_pose: HandSample = HandSample.new()

# Reload timeline (gun-pivot space).
var _phase: Phase = Phase.IDLE
var _segment_elapsed: float = 0.0
var _progress: float = 0.0
var _weight: float = 0.0
var _entry: float = 1.0
var _entry_pose: HandSample = HandSample.new()
var _layer: HandSample = HandSample.new()
var _output: HandSample = HandSample.new()
var _baseline: HandSample = HandSample.new()
var _has_baseline: bool = false
var _motion_prop: int = ViewmodelHandKey.Prop.SUBSTANCE
var _substance_away: bool = false
var _was_reloading: bool = false
## The gun the running reload motion belongs to.
var _reload_gun: Gun

@onready var _view_camera: Camera3D = %ViewCamera
@onready var _gun_pivot: Node3D = %GunPivot
@onready var _hand_pivot: Node3D = %HandPivot


## Drops the whole viewmodel (arms, gun, prop) this many metres down in camera space (death, story 018).
func set_death_drop(meters: float) -> void:
	position = _base_position + Vector3(0.0, -meters, 0.0)


## The Node3D of the gun currently held (null if none).
func get_active_gun_model() -> Node3D:
	if _active_gun == null:
		return null
	return _gun_models.get(_active_gun.gun_id) as Node3D


## Hides or shows the held gun model (the death collapse hides it once the world copy is released).
func set_gun_hidden(hidden: bool) -> void:
	var model: Node3D = get_active_gun_model()
	if model != null:
		model.visible = not hidden


## The pivot the gun model hangs on (moves with recoil and the raise); effects attach here.
func get_gun_pivot() -> Node3D:
	return _gun_pivot


## 1-based visual layer all viewmodel geometry is on.
func get_render_layer() -> int:
	return data.render_layer


## Weight of the free hand's reload motion, 0 (substance pose) to 1 (reload timeline).
func get_reload_amount() -> float:
	return _weight if _phase != Phase.IDLE or _weight > 0.0 else 0.0


## Returns how far the free-hand prop is raised, 0 (resting) to 1 (at the mouth).
func get_raise_amount() -> float:
	return _raise


## Substance kind whose prop is in the free hand.
func get_shown_kind() -> StringName:
	return _shown_kind


## Current free-hand timeline: 0 idle, 1 reload, 2 finish.
func get_motion_phase() -> int:
	return _phase


## Starts the shot kick on the held gun (also triggered by the shot_fired signal): snaps to full and
## eases back over the gun's settle time, to a random side.
func play_recoil() -> void:
	if _active_gun == null:
		return
	_kick_elapsed = 0.0
	_kick_side = -1.0 if _rng.randf() < 0.5 else 1.0


## Copies the player camera transform and fov to the viewmodel camera. Called every frame and once by
## HeartRateScreen on run end (this node is pausable, so the last fov would otherwise stay).
func sync_camera() -> void:
	if _view_camera == null or camera == null or not is_instance_valid(camera):
		return
	_view_camera.global_transform = camera.global_transform
	var fov_change: float = camera.fov - _camera_base_fov
	_view_camera.fov = clampf(data.view_fov + fov_change, 1.0, 179.0)


func _ready() -> void:
	_base_position = position
	_rng.randomize()
	add_to_group(HeartRateScreen.CAMERA_MIRROR_GROUP)
	if data == null or camera == null:
		push_error("Viewmodel needs data and camera assigned.")
		set_process(false)
		return
	# Run after the camera has moved this frame so the view camera never lags.
	process_priority = 100
	_camera_base_fov = camera.fov
	_view_camera.cull_mask = 1 << (data.render_layer - 1)
	_view_camera.near = data.view_near
	_view_camera.far = data.view_far
	camera.set_cull_mask_value(data.render_layer, false)
	for entry: ViewmodelGunData in data.guns:
		_gun_entries[entry.gun_id] = entry
		_gun_models[entry.gun_id] = _build_gun_model(entry)
	for entry: ViewmodelSubstanceData in data.substances:
		_prop_entries[entry.kind] = entry
		_props[entry.kind] = _build_prop(entry)
		_was_consuming[entry.kind] = false
	if not data.substances.is_empty():
		_held_kind = data.substances[0].kind
		_shown_kind = _held_kind
	_magazine = _build_box("Magazine", data.magazine_material)
	_shell = _build_box("Shell", data.shell_material)
	if data.show_arms and data.arms_scene != null:
		_build_arms()
	if weapon_holder != null:
		weapon_holder.gun_switched.connect(_on_gun_switched)
		weapon_holder.shot_fired.connect(_on_shot_fired)
		weapon_holder.reloaded.connect(_on_reloaded)
		var gun: Gun = weapon_holder.get_current_gun()
		if gun != null:
			_show_gun(gun.data.gun_id)
	if _active_gun == null and not data.guns.is_empty():
		_show_gun(data.guns[0].gun_id)
	_update_hand_layer(0.0)
	_update_gun_pose(0.0)
	_update_motion(0.0, false)
	_pose()


func _process(delta: float) -> void:
	sync_camera()
	# Gun and arm animation run on player time (story 016).
	delta *= _current_multiplier()
	var reloading: bool = _poll_reload()
	_update_gun_pose(delta)
	_update_hand_layer(delta, reloading)
	_update_motion(delta, reloading)
	_pose()


## Current player-time delta multiplier (1.0 without a PlayerTime).
func _current_multiplier() -> float:
	if _player_time == null:
		_player_time = PlayerTime.find_for(self)
	return 1.0 if _player_time == null else _player_time.get_delta_multiplier()


# --- Building -------------------------------------------------------------------------------------

func _fbx_basis() -> Basis:
	return Basis.from_euler(_to_radians(data.fbx_rotation_degrees))


func _build_gun_model(entry: ViewmodelGunData) -> Node3D:
	var mount: Node3D = Node3D.new()
	mount.name = "Gun_%s" % entry.gun_id
	mount.transform = Transform3D(
			Basis.from_euler(_to_radians(entry.model_rotation_degrees)) * Basis.from_scale(Vector3.ONE * entry.model_scale),
			entry.model_offset)
	var model: Node3D = entry.model.instantiate() as Node3D
	var fix: Basis = _fbx_basis() if entry.model_fix_degrees == Vector3.ZERO 			else Basis.from_euler(_to_radians(entry.model_fix_degrees))
	model.transform = Transform3D(fix, Vector3.ZERO)
	mount.add_child(model)
	if entry.model_material != null:
		_override_materials(model, entry.model_material)
	_set_layers(mount)
	mount.visible = false
	_gun_pivot.add_child(mount)
	return mount


func _build_prop(entry: ViewmodelSubstanceData) -> Node3D:
	var wrapper: Node3D = Node3D.new()
	wrapper.name = "Prop_%s" % entry.kind
	var model: Node3D = entry.model.instantiate() as Node3D
	model.name = "Model"
	model.transform = Transform3D(_fbx_basis(), Vector3.ZERO)
	wrapper.add_child(model)
	_apply_surface_materials(model, entry.surface_materials)
	var emitter: Node3D = Node3D.new()
	emitter.name = "Emitter"
	emitter.position = entry.fx_offset
	wrapper.add_child(emitter)
	var idle: CPUParticles3D = _build_particles(entry, entry.fx_idle_rate)
	var extra: CPUParticles3D = _build_particles(entry, maxf(entry.fx_raised_rate - entry.fx_idle_rate, 0.0))
	emitter.add_child(idle)
	emitter.add_child(extra)
	_prop_fx[entry.kind] = [idle, extra]
	_set_layers(wrapper)
	wrapper.visible = false
	_hand_pivot.add_child(wrapper)
	return wrapper


func _build_box(box_name: String, material: Material) -> MeshInstance3D:
	var box: MeshInstance3D = MeshInstance3D.new()
	box.name = box_name
	box.mesh = BoxMesh.new()
	if material != null:
		box.material_override = material
	box.visible = false
	_hand_pivot.add_child(box)
	_set_layers(box)
	return box


func _override_materials(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child: Node in node.get_children():
		_override_materials(child, material)


func _apply_surface_materials(node: Node, materials: Array[Material]) -> void:
	if node is MeshInstance3D and not materials.is_empty():
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		for i: int in mini(mesh_instance.mesh.get_surface_count(), materials.size()):
			mesh_instance.set_surface_override_material(i, materials[i])
	for child: Node in node.get_children():
		_apply_surface_materials(child, materials)


## World-space smoke/steam puffs (Unity SubstanceFx: puffs rise from the emitter's world position).
func _build_particles(entry: ViewmodelSubstanceData, rate: float) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.name = "Fx"
	particles.emitting = false
	particles.amount = maxi(ceili(rate * entry.fx_lifetime), 1)
	particles.lifetime = entry.fx_lifetime
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = maxf(entry.fx_scatter, 0.0001)
	particles.direction = Vector3.UP
	particles.spread = rad_to_deg(atan2(entry.fx_drift, maxf(entry.fx_rise_speed, 0.0001)))
	particles.gravity = Vector3.ZERO
	var speed: float = Vector2(entry.fx_drift, entry.fx_rise_speed).length()
	particles.initial_velocity_min = speed * 0.8
	particles.initial_velocity_max = speed
	particles.angle_min = -180.0
	particles.angle_max = 180.0
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, entry.fx_start_size / entry.fx_end_size))
	curve.add_point(Vector2(1.0, 1.0))
	particles.scale_amount_curve = curve
	var gradient: Gradient = Gradient.new()
	var fade_start: float = clampf(1.0 - entry.fx_fade_seconds / entry.fx_lifetime, 0.0, 0.99)
	var clear: Color = Color(entry.fx_color.r, entry.fx_color.g, entry.fx_color.b, 0.0)
	gradient.offsets = PackedFloat32Array([0.0, fade_start, 1.0])
	gradient.colors = PackedColorArray([entry.fx_color, entry.fx_color, clear])
	particles.color_ramp = gradient
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * entry.fx_end_size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.billboard_keep_scale = true
	material.albedo_texture = ImpactEffects.make_alpha_texture(load(SMOKE_TEXTURE) as Texture2D)
	quad.material = material
	particles.mesh = quad
	return particles


func _build_arms() -> void:
	_arms_root = data.arms_scene.instantiate() as Node3D
	_arms_root.name = "Arms"
	_gun_pivot.add_child(_arms_root)
	if data.arms_material != null:
		_override_materials(_arms_root, data.arms_material)
	_set_layers(_arms_root)
	_skeleton = _find_skeleton(_arms_root)
	if _skeleton == null:
		push_error("Viewmodel: the arms scene has no Skeleton3D; the arms are hidden.")
		_arms_root.visible = false
		_arms_root = null
		return
	# The rig's clips are never played: the arms are posed from code every frame.
	_skeleton.reset_bone_poses()
	_grip = _build_arm(".R")
	_free = _build_arm(".L")
	if _grip == null or _free == null:
		push_error("Viewmodel: the arms rig is missing a bone; the arms are hidden.")
		_arms_root.visible = false
		_arms_root = null
		_skeleton = null


func _build_arm(side: String) -> Arm:
	var arm: Arm = Arm.new()
	arm.upper = _skeleton.find_bone("upper_arm" + side)
	arm.forearm = _skeleton.find_bone("forearm" + side)
	arm.hand = _skeleton.find_bone("hand" + side)
	arm.palm = _skeleton.find_bone("palm.02" + side)
	if arm.upper < 0 or arm.forearm < 0 or arm.hand < 0 or arm.palm < 0:
		return null
	for f: int in FINGER_COUNT:
		for j: int in JOINT_COUNT:
			var bone: int = _skeleton.find_bone("%s.0%d%s" % [FINGER_NAMES[f], j + 1, side])
			if bone < 0:
				return null
			arm.fingers.append(bone)
	arm.rest_upper = _skeleton.get_bone_pose_rotation(arm.upper)
	arm.rest_forearm = _skeleton.get_bone_pose_rotation(arm.forearm)
	arm.rest_hand = _skeleton.get_bone_pose_rotation(arm.hand)
	var hand_rest: Transform3D = _global_pose(arm.hand)
	var to_hand: Basis = hand_rest.basis.orthonormalized().inverse()
	for k: int in arm.fingers.size():
		arm.rest_fingers.append(_skeleton.get_bone_pose_rotation(arm.fingers[k]))
		arm.finger_in_hand.append(to_hand * _global_pose(arm.fingers[k]).basis.orthonormalized())
	arm.curl_axes.resize(arm.fingers.size())
	# Hand frame from the rest geometry (Unity TwoBoneIk.TryHandFrame): forward from the wrist to the
	# middle knuckle, the palm on the side the middle finger bends toward.
	var middle: int = MIDDLE_FINGER * JOINT_COUNT
	var wrist: Vector3 = hand_rest.origin
	var knuckle: Vector3 = _global_pose(arm.fingers[middle]).origin
	var joint: Vector3 = _global_pose(arm.fingers[middle + 1]).origin
	var forward: Vector3 = (knuckle - wrist).normalized()
	var metacarpal: Vector3 = (knuckle - _global_pose(arm.palm).origin).normalized()
	var finger: Vector3 = joint - knuckle
	var palm: Vector3 = finger - metacarpal * finger.dot(metacarpal)
	palm = palm - forward * palm.dot(forward)
	if palm.length() < EPSILON:
		return null
	var up: Vector3 = -palm.normalized()
	var back: Vector3 = -forward
	var frame: Basis = Basis(up.cross(back), up, back)
	arm.hand_frame = (to_hand * frame).orthonormalized()
	var thumb: int = THUMB_FINGER * JOINT_COUNT
	var t1: Vector3 = _global_pose(arm.fingers[thumb]).origin
	var t2: Vector3 = _global_pose(arm.fingers[thumb + 1]).origin
	var t3: Vector3 = _global_pose(arm.fingers[thumb + 2]).origin
	var bend_from: Vector3 = t2 - t1
	var bend_to: Vector3 = t3 - t2
	if rad_to_deg(bend_from.angle_to(bend_to)) >= MIN_REST_BEND_DEGREES:
		arm.auto_thumb_axis = (to_hand * bend_from.cross(bend_to)).normalized()
	else:
		arm.auto_thumb_axis = arm.hand_frame * Vector3(-1.0, 0.0, 0.0)
	return arm


## Each finger bone's curl axis in its own rest frame, from the gun's hand-frame axes.
func _set_curl_axes(arm: Arm, entry: ViewmodelGunData) -> void:
	var finger_axis: Vector3 = arm.hand_frame * entry.curl_axis
	var thumb_axis: Vector3 = arm.auto_thumb_axis if entry.thumb_axis == Vector3.ZERO \
			else arm.hand_frame * entry.thumb_axis
	for f: int in FINGER_COUNT:
		var axis: Vector3 = thumb_axis if f == THUMB_FINGER else finger_axis
		for j: int in JOINT_COUNT:
			var k: int = f * JOINT_COUNT + j
			arm.curl_axes[k] = (arm.finger_in_hand[k].inverse() * axis).normalized()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child: Node in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


func _set_layers(node: Node) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = 1 << (data.render_layer - 1)
		if node is GeometryInstance3D:
			(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_set_layers(child)


func _to_radians(degrees: Vector3) -> Vector3:
	return Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))


func _euler_quat(degrees: Vector3) -> Quaternion:
	return Basis.from_euler(_to_radians(degrees)).get_rotation_quaternion()


# --- Gun ------------------------------------------------------------------------------------------

func _show_gun(gun_id: StringName) -> void:
	for id: StringName in _gun_models:
		(_gun_models[id] as Node3D).visible = (id == gun_id)
	_active_gun = _gun_entries.get(gun_id) as ViewmodelGunData
	if _active_gun == null:
		return
	if _arms_root != null:
		_arms_root.transform = Transform3D(
				Basis.from_euler(_to_radians(_active_gun.arms_root_rotation_degrees)) * _fbx_basis()
				* Basis.from_scale(Vector3.ONE * _active_gun.arms_scale),
				_active_gun.arms_root_position)
		_set_curl_axes(_grip, _active_gun)
		_set_curl_axes(_free, _active_gun)
	(_magazine.mesh as BoxMesh).size = _active_gun.magazine_size
	(_shell.mesh as BoxMesh).size = _active_gun.shell_size
	# A switch drops any running timeline; the free hand blends back to the substance layer.
	_phase = Phase.IDLE
	_motion_prop = ViewmodelHandKey.Prop.SUBSTANCE
	_substance_away = false


## Shot kick (snaps to full, eases back) and the dip of the raise after a switch (Unity GunFeedback).
func _update_gun_pose(delta: float) -> void:
	if _active_gun == null:
		return
	_kick_elapsed += delta
	_raise_elapsed += delta
	var kick: float = 0.0
	if _active_gun.settle_seconds > 0.0:
		kick = 1.0 - smoothstep(0.0, 1.0, _kick_elapsed / _active_gun.settle_seconds)
	var raise: float = 0.0
	if _active_gun.raise_seconds > 0.0 and _raise_elapsed < _active_gun.raise_seconds:
		raise = 1.0 - smoothstep(0.0, 1.0, _raise_elapsed / _active_gun.raise_seconds)
	_gun_pivot.position = _active_gun.hold_position + Vector3(
			_kick_side * _active_gun.kick_side * kick,
			-_active_gun.raise_dip_depth * raise,
			_active_gun.kick_back * kick)
	_gun_pivot.basis = Basis.from_euler(_to_radians(Vector3(
			_active_gun.kick_pitch_degrees * kick - _active_gun.raise_dip_degrees * raise,
			0.0,
			-_kick_side * _active_gun.kick_roll_degrees * kick)))


func _on_gun_switched(gun_data: GunData) -> void:
	_show_gun(gun_data.gun_id)
	_kick_elapsed = 1e9
	_raise_elapsed = 0.0


func _on_shot_fired(_gun_data: GunData) -> void:
	play_recoil()


func _on_reloaded(_gun_id: StringName) -> void:
	_begin(Phase.FINISH)


# --- Free hand: substance layer -------------------------------------------------------------------

func _is_consuming(kind: StringName) -> bool:
	return substances != null and substances.is_consuming(kind)


func _count(kind: StringName) -> int:
	return substances.get_count(kind) if substances != null else 1


## Unity SubstanceHandMotion: rest / raised / swap / empty poses of the free hand, camera space.
func _update_hand_layer(delta: float, reloading: bool = false) -> void:
	var held: ViewmodelSubstanceData = _prop_entries.get(_held_kind) as ViewmodelSubstanceData
	if held == null:
		return
	var target: StringName = &""
	for kind: StringName in _prop_entries:
		if _is_consuming(kind) and not _was_consuming[kind]:
			target = kind
	if target == _held_kind:
		target = &""
	if target == &"" and not _is_consuming(_held_kind):
		for kind: StringName in _prop_entries:
			if kind != _held_kind and _is_consuming(kind):
				target = kind
	if target != &"":
		_held_kind = target
		_swap_phase = Swap.LOWER
	var wanted: bool = _swap_phase == Swap.NONE and _is_consuming(_held_kind) and not reloading
	if wanted:
		_raise = move_toward(_raise, 1.0, delta / maxf(data.raise_seconds, 0.001))
	else:
		_raise = move_toward(_raise, 0.0, delta / maxf(data.lower_seconds, 0.001))
	if _swap_phase != Swap.NONE and _motion_prop != ViewmodelHandKey.Prop.SUBSTANCE:
		_shown_kind = _held_kind
		_swap_phase = Swap.NONE
		_swap_depth = 0.0
	elif _swap_phase == Swap.LOWER:
		_swap_depth = move_toward(_swap_depth, 1.0, delta / maxf(data.swap_lower_seconds, 0.001))
		if _swap_depth >= 1.0:
			_shown_kind = _held_kind
			_swap_phase = Swap.RAISE
	elif _swap_phase == Swap.RAISE:
		_swap_depth = move_toward(_swap_depth, 0.0, delta / maxf(data.swap_raise_seconds, 0.001))
		if _swap_depth <= 0.0:
			_swap_phase = Swap.NONE
	var empty_target: float = 0.0 if _count(_shown_kind) > 0 else 1.0
	_empty = move_toward(_empty, empty_target, delta / maxf(data.empty_seconds, 0.001))
	for kind: StringName in _prop_entries:
		_was_consuming[kind] = _is_consuming(kind)
	var shown: ViewmodelSubstanceData = _prop_entries[_shown_kind]
	var rest: HandSample = HandSample.blend(
			HandSample.new(shown.rest_position, _euler_quat(shown.rest_rotation_degrees), shown.rest_curl),
			HandSample.new(data.empty_position, _euler_quat(data.empty_rotation_degrees), data.empty_curl),
			_ease(_empty), ViewmodelHandKey.Prop.SUBSTANCE)
	var at: HandSample = HandSample.blend(rest,
			HandSample.new(shown.raised_position, _euler_quat(shown.raised_rotation_degrees), shown.raised_curl),
			_ease(_raise), ViewmodelHandKey.Prop.SUBSTANCE)
	_hand_pose = HandSample.blend(at,
			HandSample.new(data.lowered_position, _euler_quat(data.lowered_rotation_degrees), data.lowered_curl),
			_ease(_swap_depth), ViewmodelHandKey.Prop.SUBSTANCE)


# --- Free hand: reload timeline -------------------------------------------------------------------

## Polls the gun (it has no reload-start signal) and starts the reload timeline; a shotgun restarts
## its shell cycle every shell_cycle_seconds. Returns whether the current gun is reloading.
func _poll_reload() -> bool:
	var gun: Gun = weapon_holder.get_current_gun() if weapon_holder != null else null
	var reloading: bool = gun != null and gun.is_reloading()
	if reloading and (not _was_reloading or gun != _reload_gun):
		_substance_away = false
		_begin(Phase.RELOAD)
	elif reloading and _phase == Phase.RELOAD and _active_gun != null and _active_gun.shell_reload \
			and _segment_elapsed >= _active_gun.shell_cycle_seconds:
		_begin(Phase.RELOAD)
	_was_reloading = reloading
	_reload_gun = gun if reloading else null
	return reloading


func _begin(phase: Phase) -> void:
	if _active_gun == null:
		return
	_entry_pose = _output
	_entry = 0.0
	_weight = 1.0
	_phase = phase
	_segment_elapsed = 0.0
	_progress = 0.0


func _reload_period() -> float:
	if _active_gun.shell_reload:
		return _active_gun.shell_cycle_seconds
	var gun: Gun = weapon_holder.get_current_gun() if weapon_holder != null else null
	return gun.data.reload_time if gun != null else 1.0


## Unity ArmMotion.Update: the reload timeline over the substance layer (both in gun-pivot space).
func _update_motion(delta: float, reloading: bool) -> void:
	var pivot: Transform3D = _gun_pivot.transform
	var pivot_inverse: Quaternion = pivot.basis.get_rotation_quaternion().inverse()
	_baseline = HandSample.new(pivot.affine_inverse() * _hand_pose.position, pivot_inverse * _hand_pose.rotation,
			_hand_pose.curl, ViewmodelHandKey.Prop.SUBSTANCE)
	if not _has_baseline:
		_layer = _baseline
		_entry_pose = _baseline
		_has_baseline = true
	if _active_gun == null:
		_output = _baseline
		return
	if _phase == Phase.RELOAD and not reloading:
		_phase = Phase.IDLE
	if _phase != Phase.IDLE:
		var finish: bool = _phase == Phase.FINISH
		_segment_elapsed += delta
		var duration: float = _active_gun.finish_seconds if finish else _reload_period()
		var raw: float = _segment_elapsed / duration if duration > 0.0 else 1.0
		_progress = clampf(raw, 0.0, 1.0)
		var key_time: float = _progress
		if not finish and not _active_gun.shell_reload:
			key_time = _warp(_progress, _active_gun.reload_in_at)
		var keys: Array[ViewmodelHandKey] = _active_gun.finish_keys if finish else _active_gun.reload_keys
		var sample: HandSample = _sample_keys(keys, key_time)
		var prop: int = sample.prop
		if not finish:
			if prop != ViewmodelHandKey.Prop.SUBSTANCE:
				_substance_away = true
			elif _substance_away:
				prop = ViewmodelHandKey.Prop.NONE
		_entry = move_toward(_entry, 1.0, delta * _active_gun.blend_in_speed)
		_motion_prop = prop
		_layer = HandSample.blend(_entry_pose, sample, _ease(_entry), prop)
		_weight = 1.0
		if finish and raw >= 1.0:
			_phase = Phase.IDLE
	else:
		_weight = move_toward(_weight, 0.0, delta * _active_gun.blend_out_speed)
		_motion_prop = ViewmodelHandKey.Prop.SUBSTANCE
		_substance_away = false
	_output = HandSample.blend(_baseline, _layer, _ease(_weight), _motion_prop)


## Magazine reloads: the timeline's halfway point is reached at reload_in_at of the reload.
static func _warp(progress: float, reload_in_at: float) -> float:
	if not (reload_in_at > 0.0 and reload_in_at < 1.0):
		return progress
	if progress <= reload_in_at:
		return 0.5 * progress / reload_in_at
	return 0.5 + 0.5 * (progress - reload_in_at) / (1.0 - reload_in_at)


func _sample_keys(keys: Array[ViewmodelHandKey], time: float) -> HandSample:
	if keys.is_empty():
		return _baseline
	var last: int = keys.size() - 1
	if time <= keys[0].time:
		return _from_key(keys[0])
	if time >= keys[last].time:
		return _from_key(keys[last])
	var i: int = 0
	while i < last - 1 and time >= keys[i + 1].time:
		i += 1
	var a: ViewmodelHandKey = keys[i]
	var b: ViewmodelHandKey = keys[i + 1]
	var span: float = b.time - a.time
	var eased: float = _ease((time - a.time) / span if span > 0.0 else 1.0)
	return HandSample.new(a.position.lerp(b.position, eased),
			_euler_quat(a.rotation_degrees).slerp(_euler_quat(b.rotation_degrees), eased),
			a.curl.lerp(b.curl, eased), a.prop)


func _from_key(key: ViewmodelHandKey) -> HandSample:
	return HandSample.new(key.position, _euler_quat(key.rotation_degrees), key.curl, key.prop)


static func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


# --- Posing ---------------------------------------------------------------------------------------

## Rebuilds the whole pose from the rest pose: both arms, the fingers and the props.
func _pose() -> void:
	if _active_gun == null:
		return
	var pivot: Transform3D = _gun_pivot.global_transform
	var pivot_basis: Basis = pivot.basis.orthonormalized()
	var free_wrist: Vector3 = pivot * _output.position
	var free_frame: Basis = pivot_basis * Basis(_output.rotation)
	if _skeleton != null:
		_reset_arm(_grip)
		_reset_arm(_free)
		_pose_arm(_grip, pivot * _active_gun.grip_position,
				pivot_basis * Basis.from_euler(_to_radians(_active_gun.grip_rotation_degrees)),
				pivot_basis * _active_gun.grip_pole, _active_gun.grip_curl)
		free_wrist = _pose_arm(_free, free_wrist, free_frame,
				global_transform.basis.orthonormalized() * data.free_hand_pole, _output.curl)
	_place_props(_output.prop, free_wrist, free_frame)


func _reset_arm(arm: Arm) -> void:
	_skeleton.set_bone_pose_rotation(arm.upper, arm.rest_upper)
	_skeleton.set_bone_pose_rotation(arm.forearm, arm.rest_forearm)
	_skeleton.set_bone_pose_rotation(arm.hand, arm.rest_hand)
	for k: int in arm.fingers.size():
		_skeleton.set_bone_pose_rotation(arm.fingers[k], arm.rest_fingers[k])


## Solves one arm toward a world wrist target and hand frame, then curls its fingers. Returns the
## world wrist position reached (the target, or the reachable point toward it).
func _pose_arm(arm: Arm, target_world: Vector3, frame_world: Basis, pole_world: Vector3, curl: Vector3) -> Vector3:
	var skeleton_xf: Transform3D = _skeleton.global_transform
	var to_skeleton: Basis = skeleton_xf.basis.orthonormalized().inverse()
	var target: Vector3 = skeleton_xf.affine_inverse() * target_world
	var pole: Vector3 = to_skeleton * pole_world
	var frame: Basis = to_skeleton * frame_world
	var shoulder: Vector3 = _global_pose(arm.upper).origin
	var elbow_now: Vector3 = _global_pose(arm.forearm).origin
	var wrist_now: Vector3 = _global_pose(arm.hand).origin
	var upper_length: float = shoulder.distance_to(elbow_now)
	var lower_length: float = elbow_now.distance_to(wrist_now)
	# Two-bone solve (Unity TwoBoneIk.Solve).
	var longest: float = (upper_length + lower_length) * clampf(_active_gun.reach_limit, EPSILON, 1.0)
	var shortest: float = maxf(maxf(absf(upper_length - lower_length),
			MIN_REACH_FRACTION * (upper_length + lower_length)), EPSILON)
	var to_target: Vector3 = target - shoulder
	var distance: float = to_target.length()
	var direction: Vector3 = to_target / distance if distance > EPSILON else pole.normalized()
	var reachable: float = maxf(shortest, minf(distance, longest))
	var wrist: Vector3 = shoulder + direction * reachable
	var along: float = (reachable * reachable + upper_length * upper_length - lower_length * lower_length) \
			/ (2.0 * reachable)
	var height: float = sqrt(maxf(0.0, upper_length * upper_length - along * along))
	var bend: Vector3 = pole - direction * pole.dot(direction)
	if bend.length_squared() > EPSILON * EPSILON:
		bend = bend.normalized()
	else:
		bend = direction.cross(Vector3.UP).normalized()
	var elbow: Vector3 = shoulder + direction * along + bend * height
	# Aim the upper arm, then the forearm, by world-space shortest arcs (bone-axis agnostic).
	_aim_bone(arm.upper, elbow_now - shoulder, elbow - shoulder)
	var elbow_position: Vector3 = _global_pose(arm.forearm).origin
	var forearm_vector: Vector3 = wrist - elbow_position
	_aim_bone(arm.forearm, _global_pose(arm.hand).origin - elbow_position, forearm_vector)
	var hand_world: Basis = (frame * arm.hand_frame.inverse()).orthonormalized()
	var follow: float = _active_gun.forearm_twist_follow
	if follow > 0.0 and forearm_vector.length_squared() > EPSILON * EPSILON:
		# The forearm takes a share of the twist the wrist needs from its rest relation to the forearm.
		var forearm_rotation: Quaternion = _global_pose(arm.forearm).basis.get_rotation_quaternion()
		var to_forearm: Quaternion = forearm_rotation.inverse()
		var axis: Vector3 = (to_forearm * forearm_vector).normalized()
		var relative: Quaternion = to_forearm * hand_world.get_rotation_quaternion() * arm.rest_hand.inverse()
		var projected: float = relative.x * axis.x + relative.y * axis.y + relative.z * axis.z
		var twist: float = wrapf(2.0 * atan2(projected, relative.w), -PI, PI)
		_set_global_rotation(arm.forearm, forearm_rotation * Quaternion(axis, follow * twist))
	_set_global_rotation(arm.hand, hand_world.get_rotation_quaternion())
	var weights: Vector3 = _active_gun.curl_joint_weights
	for f: int in FINGER_COUNT:
		var amount: float = curl.x if f == INDEX_FINGER else (curl.z if f == THUMB_FINGER else curl.y)
		for j: int in JOINT_COUNT:
			var k: int = f * JOINT_COUNT + j
			_skeleton.set_bone_pose_rotation(arm.fingers[k],
					arm.rest_fingers[k] * Quaternion(arm.curl_axes[k], deg_to_rad(amount * weights[j])))
	return skeleton_xf * wrist


func _aim_bone(bone: int, current: Vector3, desired: Vector3) -> void:
	if current.length_squared() < EPSILON * EPSILON or desired.length_squared() < EPSILON * EPSILON:
		return
	var a: Vector3 = current.normalized()
	var b: Vector3 = desired.normalized()
	if a.dot(b) > 0.999999:
		return
	var turn: Quaternion = Quaternion(a, b)
	_set_global_rotation(bone, turn * _global_pose(bone).basis.get_rotation_quaternion())


## Bone pose in skeleton space from the current local poses (independent of the skeleton's update).
func _global_pose(bone: int) -> Transform3D:
	var result: Transform3D = _skeleton.get_bone_pose(bone)
	var parent: int = _skeleton.get_bone_parent(bone)
	while parent >= 0:
		result = _skeleton.get_bone_pose(parent) * result
		parent = _skeleton.get_bone_parent(parent)
	return result


func _set_global_rotation(bone: int, rotation_skeleton: Quaternion) -> void:
	var parent: int = _skeleton.get_bone_parent(bone)
	var parent_rotation: Quaternion = Quaternion.IDENTITY
	if parent >= 0:
		parent_rotation = _global_pose(parent).basis.get_rotation_quaternion()
	_skeleton.set_bone_pose_rotation(bone, (parent_rotation.inverse() * rotation_skeleton).normalized())


## Shows the props the motion asks for and places each in the free hand's frame (world).
func _place_props(prop: int, wrist: Vector3, frame: Basis) -> void:
	var magazine: bool = prop == ViewmodelHandKey.Prop.MAGAZINE
	var shell: bool = prop == ViewmodelHandKey.Prop.SHELL
	var substance_shown: bool = prop == ViewmodelHandKey.Prop.SUBSTANCE and _count(_shown_kind) > 0
	_magazine.visible = magazine
	_shell.visible = shell
	if magazine:
		_magazine.global_transform = Transform3D(
				frame * Basis.from_euler(_to_radians(_active_gun.magazine_rotation_degrees)),
				wrist + frame * _active_gun.magazine_offset)
	if shell:
		_shell.global_transform = Transform3D(
				frame * Basis.from_euler(_to_radians(_active_gun.shell_rotation_degrees)),
				wrist + frame * _active_gun.shell_offset)
	for kind: StringName in _props:
		var wrapper: Node3D = _props[kind]
		var entry: ViewmodelSubstanceData = _prop_entries[kind]
		var visible_now: bool = substance_shown and kind == _shown_kind
		wrapper.visible = visible_now
		if visible_now:
			wrapper.global_transform = Transform3D(
					frame * Basis.from_euler(_to_radians(entry.prop_rotation_degrees))
					* Basis.from_scale(Vector3.ONE * entry.prop_scale),
					wrist + frame * entry.prop_offset)
		var fx: Array = _prop_fx[kind]
		var idle: CPUParticles3D = fx[0]
		var extra: CPUParticles3D = fx[1]
		idle.emitting = data.fx_enabled and visible_now
		extra.emitting = data.fx_enabled and visible_now and _raise >= entry.fx_raised_threshold
