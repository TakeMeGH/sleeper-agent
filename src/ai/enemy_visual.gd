class_name EnemyVisual
extends Node3D
## Rigged human model of one enemy (story 020): skin + texture, locomotion blend (idle / weak walk / run with
## foot-matched time scale), one-shot attack (full body for melee, upper body for ranged and boss), hand prop
## with muzzle point, muzzle flash and tracers, stagger jolt, reload pose and a code-driven death fall.
## Built by EnemyBase when EnemyData.visual is set. All numbers come from EnemyVisualData.

## Emitted when an attack clip is started.
signal attack_started

const LOCO_IDLE: StringName = &"idle"
const LOCO_WALK: StringName = &"walk"
const LOCO_RUN: StringName = &"run"
const PARAM_LOCO: StringName = &"parameters/loco/transition_request"
const PARAM_SCALE: StringName = &"parameters/loco_scale/scale"
const PARAM_ATTACK_REQUEST: StringName = &"parameters/attack_shot/request"
const PARAM_ATTACK_ACTIVE: StringName = &"parameters/attack_shot/active"

var _data: EnemyVisualData
var _pivot: Node3D
var _model: Node3D
var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _tree: AnimationTree
var _modifier: EnemyPoseModifier
var _body_materials: Array[StandardMaterial3D] = []
var _plates: Array[Node3D] = []
var _aim_point: Vector3 = Vector3.ZERO
var _aim_requested: bool = false
var _has_aim_point: bool = false
var _aim_weight: float = 0.0
var _attachment: BoneAttachment3D
var _prop_mount: Node3D
var _prop: Node3D
var _muzzle: Node3D
var _flash_mesh: MeshInstance3D
var _tracers: Array[MeshInstance3D] = []
var _tracer_left: PackedFloat32Array = PackedFloat32Array()
var _tracer_next: int = 0
var _muzzle_flash_left: float = 0.0
var _locomotion: StringName = LOCO_IDLE
var _attack_clip: StringName = &""
var _height_factor: float = 1.0
var _skin_index: int = -1
var _stagger_left: float = 0.0
var _jolt: float = 0.0
var _reloading: bool = false
var _reload_amount: float = 0.0
var _push_lean: float = 0.0
var _push_lean_target: float = 0.0
var _push_lean_blend: float = 0.2
var _dead: bool = false
var _last_attack_frame: int = -1
var _hold_left: float = -1.0
var _loop_flags: Dictionary = {}
var _upper_bones: Array[StringName] = []
var _flash_amount: float = 0.0
var _attack_age: float = 1000000.0


## Builds the model scaled to target_height metres. attack_clip_override replaces EnemyVisualData.attack_clip
## (ranged kinds pass their gun's clip). Call once, after the node is in the tree.
func setup(visual_data: EnemyVisualData, target_height: float, attack_clip_override: StringName = &"") -> void:
	_data = visual_data
	_attack_clip = attack_clip_override if attack_clip_override != &"" else _data.attack_clip
	_height_factor = target_height / maxf(_data.source_height, 0.01)
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	var scene: PackedScene = _data.base_scene
	if not _data.skin_scenes.is_empty():
		_skin_index = _data.forced_skin_index
		if _skin_index < 0 or _skin_index >= _data.skin_scenes.size():
			_skin_index = randi() % _data.skin_scenes.size()
		scene = _data.skin_scenes[_skin_index]
	if scene == null:
		push_error("EnemyVisual: no model scene")
		return
	_model = scene.instantiate() as Node3D
	_model.scale = Vector3.ONE * _height_factor
	_model.rotation_degrees.y = _data.model_yaw_degrees
	_pivot.add_child(_model)
	_skeleton = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	_anim_player = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_apply_material(_model, _data.skin_material if _skin_index >= 0 else _data.body_material)
	if _skeleton == null or _anim_player == null:
		push_error("EnemyVisual: model has no skeleton or AnimationPlayer")
		return
	_build_plates()
	_set_loops()
	_collect_upper_bones()
	_build_tree()
	_modifier = EnemyPoseModifier.new()
	_modifier.name = "PoseModifier"
	_skeleton.add_child(_modifier)
	_build_tracers()


## Sets the speed (m/s, horizontal, without knockback) the enemy is walking at: picks idle, weak walk or run
## and scales the clip so the feet match the ground.
func update_locomotion(speed: float) -> void:
	if _dead or _tree == null:
		return
	var state: StringName = LOCO_IDLE
	var time_scale: float = 1.0
	if speed >= _data.walk_run_threshold:
		state = LOCO_RUN
		time_scale = clampf(speed / _data.run_reference_speed, _data.speed_scale_min, _data.speed_scale_max)
	elif speed >= _data.idle_speed_threshold:
		state = LOCO_WALK
		time_scale = clampf(speed / _data.walk_reference_speed, _data.speed_scale_min, _data.speed_scale_max)
	if state != _locomotion:
		_locomotion = state
		_tree.set(PARAM_LOCO, String(state))
	_tree.set(PARAM_SCALE, time_scale)


## Starts the attack clip (once per physics frame at most). Melee: full body; ranged and boss: upper body.
func play_attack() -> void:
	if _dead or _tree == null:
		return
	var frame: int = Engine.get_physics_frames()
	if frame == _last_attack_frame:
		return
	_last_attack_frame = frame
	# A burst plays the clip through instead of restarting it on every bullet.
	if _attack_age < get_attack_clip_length():
		return
	_attack_age = 0.0
	_tree.set(PARAM_ATTACK_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	attack_started.emit()


## Hit reaction: body lean and upper-body jolt that fade over EnemyVisualData.stagger_duration.
func play_stagger() -> void:
	if _dead:
		return
	_stagger_left = _data.stagger_duration
	_jolt = 1.0


## Leans the whole body forward by `degrees` (0 = upright) while pushing a prop, blending over `blend_seconds`.
func set_push_lean(degrees: float, blend_seconds: float) -> void:
	_push_lean_target = degrees
	_push_lean_blend = maxf(blend_seconds, 0.01)


## Shows (true) or ends (false) the reload pose: upper body bent over, gun tilted down.
func set_reloading(active: bool) -> void:
	_reloading = active


## White hit flash, amount 0-1 (emission on every body material).
func set_flash(amount: float) -> void:
	_flash_amount = clampf(amount, 0.0, 1.0)
	for material: StandardMaterial3D in _body_materials:
		material.emission_enabled = _flash_amount > 0.0
		material.emission = Color(1, 1, 1)
		material.emission_energy_multiplier = _flash_amount * _data.flash_energy


## Puts a prop (club, gun) in the right hand. position/rotation are in the hand bone's frame (the prop FBX
## files are authored at the palm), scale_factor multiplies the prop. Returns the instance or null.
func attach_prop(scene: PackedScene, position: Vector3, rotation_degrees_value: Vector3, scale_factor: float) -> Node3D:
	if _skeleton == null or scene == null:
		return null
	if _attachment == null:
		_attachment = BoneAttachment3D.new()
		_attachment.name = "HandAttachment"
		_attachment.bone_name = String(_data.hand_bone)
		_skeleton.add_child(_attachment)
		_prop_mount = Node3D.new()
		_prop_mount.name = "PropMount"
		# The rig node above the skeleton is scaled (100); cancel it so the prop keeps metres.
		var rig_scale: float = (_skeleton.get_parent() as Node3D).scale.x
		_prop_mount.scale = Vector3.ONE / maxf(rig_scale, 0.0001)
		_attachment.add_child(_prop_mount)
	_prop = scene.instantiate() as Node3D
	if _prop == null:
		return null
	_prop.position = position
	_prop.rotation_degrees = rotation_degrees_value
	_prop.scale = Vector3.ONE * scale_factor
	_prop_mount.add_child(_prop)
	_apply_material(_prop, _data.prop_material)
	var tips: Array[Node] = _prop.find_children("*_tip", "Node3D", true, false)
	if not tips.is_empty():
		_muzzle = tips[0] as Node3D
		_build_flash_mesh()
	return _prop


## Aim target (world, e.g. the player's chest) and whether the enemy is aiming. While aiming or while the attack clip
## plays, the upper body turns so the barrel points at the target (EnemyVisualData aim turn; Unity RangedPose/BossPose).
func set_aim_point(point: Vector3, aiming: bool) -> void:
	_aim_point = point
	_has_aim_point = true
	_aim_requested = aiming


## Degrees the aim turn applied on the last pose update (probes).
func get_aim_turn_degrees() -> float:
	return _modifier.last_aim_degrees if _modifier != null else 0.0


## Removes the armour plates (the boss's armour broke).
func remove_plates() -> void:
	for plate: Node3D in _plates:
		if is_instance_valid(plate):
			plate.queue_free()
	_plates.clear()


## Number of armour plates shown.
func get_plate_count() -> int:
	return _plates.size()


## True when a prop with a muzzle point is in the hand.
func has_muzzle() -> bool:
	return _muzzle != null and is_instance_valid(_muzzle)


## World position of the muzzle (the prop's tip node); the visual's origin when there is none.
func get_muzzle_position() -> Vector3:
	if has_muzzle():
		return _muzzle.global_position
	return global_position


## Shows the muzzle flash and one tracer from the muzzle to to_position (world). Plays nothing when dead.
func show_shot(from_position: Vector3, to_position: Vector3) -> void:
	if _dead:
		return
	if _flash_mesh != null:
		_muzzle_flash_left = _data.muzzle_flash_seconds
		_flash_mesh.visible = true
	if _tracers.is_empty():
		return
	var offset: Vector3 = to_position - from_position
	var length: float = minf(offset.length(), _data.tracer_max_length)
	if length < 0.05:
		return
	var dir: Vector3 = offset.normalized()
	var tracer: MeshInstance3D = _tracers[_tracer_next]
	_tracer_left[_tracer_next] = _data.tracer_seconds
	_tracer_next = (_tracer_next + 1) % _tracers.size()
	var up: Vector3 = Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT
	var basis: Basis = Basis.looking_at(dir, up) * Basis.from_scale(
		Vector3(_data.tracer_width, _data.tracer_width, length))
	tracer.global_transform = Transform3D(basis, from_position + dir * length * 0.5)
	tracer.visible = true


## Death: stops the animation (the body keeps its last pose) and tips the body over along fall_direction
## (world space) over death_fall_seconds.
func play_death(fall_direction: Vector3) -> void:
	if _dead:
		return
	_dead = true
	_reloading = false
	_jolt = 0.0
	if _modifier != null:
		_modifier.bone_angles = {}
		_modifier.aim_weight = 0.0
	if _tree != null:
		_tree.active = false
	var local_dir: Vector3 = global_basis.orthonormalized().inverse() * fall_direction
	local_dir.y = 0.0
	if local_dir.length() < 0.001:
		local_dir = Vector3(0, 0, 1)
	local_dir = local_dir.normalized()
	var axis: Vector3 = Vector3.UP.cross(local_dir).normalized()
	_pivot.rotation = Vector3.ZERO
	var tween: Tween = create_tween()
	tween.tween_method(_apply_fall.bind(axis), 0.0, 1.0, maxf(_data.death_fall_seconds, 0.01)) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Fades the whole body (model and props) to transparent over seconds.
func fade_out(seconds: float) -> void:
	var fade_materials: Array[StandardMaterial3D] = []
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null or mesh_instance in _tracers:
			continue
		for i: int in mesh_instance.mesh.get_surface_count():
			var source: StandardMaterial3D = mesh_instance.get_active_material(i) as StandardMaterial3D
			if source == null:
				continue
			var copy: StandardMaterial3D = source.duplicate() as StandardMaterial3D
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh_instance.set_surface_override_material(i, copy)
			fade_materials.append(copy)
	var tween: Tween = create_tween()
	tween.tween_method(_apply_fade.bind(fade_materials), 1.0, 0.0, maxf(seconds, 0.01))


## Probe/capture: holds the pose after seconds. kind is &"idle", &"walk", &"run" or &"attack"
## (fires the attack clip); the animation freezes once the time has passed.
func debug_hold(kind: StringName, seconds: float) -> void:
	if _tree == null:
		return
	if kind == &"attack":
		play_attack()
	else:
		_locomotion = kind
		_tree.set(PARAM_LOCO, String(kind))
		_tree.set(PARAM_SCALE, 1.0)
	_hold_left = seconds


## Name of the clip playing now: the attack clip while an attack plays, else the locomotion clip.
func get_current_clip_name() -> StringName:
	if is_attack_playing():
		return _attack_clip
	return get_locomotion_clip_name()


## Clip of the locomotion state (idle, walk or run).
func get_locomotion_clip_name() -> StringName:
	match _locomotion:
		LOCO_WALK:
			return _data.walk_clip
		LOCO_RUN:
			return _data.run_clip
	return _data.idle_clip


## Locomotion state: &"idle", &"walk" or &"run".
func get_locomotion_state() -> StringName:
	return _locomotion


## True while the attack one-shot is playing.
func is_attack_playing() -> bool:
	return _tree != null and bool(_tree.get(PARAM_ATTACK_ACTIVE))


## Seconds into the attack clip at which the hit lands.
func get_attack_hit_time() -> float:
	return _data.attack_clip_hit_time


## Length of the attack clip in seconds (0 when missing).
func get_attack_clip_length() -> float:
	if _anim_player == null or not _anim_player.has_animation(_attack_clip):
		return 0.0
	return _anim_player.get_animation(_attack_clip).length


## Name of the attack clip this visual uses.
func get_attack_clip() -> StringName:
	return _attack_clip


## Clip name -> loop mode (Animation.LoopMode) for every clip this visual uses.
func get_clip_loop_modes() -> Dictionary:
	return _loop_flags


## Height in metres the model was fitted to.
func get_model_height() -> float:
	return _data.source_height * _height_factor


## Index of the skin picked (-1 when the base model is used).
func get_skin_index() -> int:
	return _skin_index


## True once play_death was called.
func is_dead_pose() -> bool:
	return _dead


## The skeleton, for probes.
func get_skeleton() -> Skeleton3D:
	return _skeleton


func _process(delta: float) -> void:
	if _data == null:
		return
	_attack_age += delta
	if _muzzle_flash_left > 0.0:
		_muzzle_flash_left -= delta
		if _muzzle_flash_left <= 0.0 and _flash_mesh != null:
			_flash_mesh.visible = false
	for i: int in _tracers.size():
		if _tracer_left[i] > 0.0:
			_tracer_left[i] -= delta
			if _tracer_left[i] <= 0.0:
				_tracers[i].visible = false
	if _hold_left > 0.0:
		_hold_left -= delta
		if _hold_left <= 0.0 and _tree != null:
			_tree.active = false
	if _dead:
		return
	_stagger_left = maxf(_stagger_left - delta, 0.0)
	_jolt = _stagger_left / maxf(_data.stagger_duration, 0.001)
	_reload_amount = move_toward(_reload_amount, 1.0 if _reloading else 0.0,
		delta / maxf(_data.reload_blend_seconds, 0.01))
	_push_lean = move_toward(_push_lean, _push_lean_target,
		maxf(absf(_push_lean_target), absf(_push_lean)) * delta / _push_lean_blend)
	# Stagger leans back (+x); the push lean tips the body forward (toward -z, the facing direction).
	_pivot.rotation.x = deg_to_rad(_data.stagger_lean_degrees * _jolt - _push_lean)
	if _modifier != null and not _data.jolt_bones.is_empty():
		var angles: Dictionary = {}
		var per_bone: float = (_data.reload_lean_degrees * _reload_amount - _data.jolt_degrees * _jolt) \
			/ float(_data.jolt_bones.size())
		for bone: String in _data.jolt_bones:
			angles[bone] = per_bone
		_modifier.bone_angles = angles
	if _prop_mount != null:
		_prop_mount.rotation_degrees.x = _data.reload_prop_tilt_degrees * _reload_amount
	_update_aim(delta)


func _update_aim(delta: float) -> void:
	if _modifier == null:
		return
	var can_aim: bool = _data.aim_correction_max_degrees > 0.0 and _has_aim_point and has_muzzle() and not _reloading
	var target: float = 1.0 if can_aim and (_aim_requested or is_attack_playing()) else 0.0
	_aim_weight = move_toward(_aim_weight, target, delta / maxf(_data.aim_blend_seconds, 0.01))
	_modifier.aim_weight = _aim_weight * _aim_weight * (3.0 - 2.0 * _aim_weight)
	if _modifier.aim_weight <= 0.0:
		return
	# The muzzle in the hand bone's frame: the local transforms from the muzzle up to the bone attachment.
	var barrel: Transform3D = Transform3D()
	var node: Node = _muzzle
	while node != null and node != _attachment:
		barrel = (node as Node3D).transform * barrel
		node = node.get_parent()
	_modifier.barrel_in_hand = barrel
	_modifier.aim_point = _aim_point
	_modifier.aim_bone = _data.aim_bone
	_modifier.hand_bone = _data.hand_bone
	_modifier.aim_max_degrees = _data.aim_correction_max_degrees


func _apply_fall(amount: float, axis: Vector3) -> void:
	_pivot.basis = Basis(axis, amount * PI * 0.5)
	_pivot.position.y = _data.death_lift * amount


func _apply_fade(opacity: float, fade_materials: Array[StandardMaterial3D]) -> void:
	for material: StandardMaterial3D in fade_materials:
		var colour: Color = material.albedo_color
		colour.a = opacity
		material.albedo_color = colour


# Puts a copy of material on every surface under root (one copy per spawn, so the hit flash and the corpse fade
# stay per enemy). The FBX's own imported materials are replaced, not edited: they have no texture, a 0.906 grey
# albedo and vertex colour as albedo, none of which Unity's remapped URP/Lit materials use.
func _apply_material(root: Node, material: StandardMaterial3D) -> void:
	if material == null:
		push_error("EnemyVisual: no material for %s" % root.name)
		return
	var copy: StandardMaterial3D = material.duplicate() as StandardMaterial3D
	_body_materials.append(copy)
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for i: int in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(i, copy)


# Armour plates: a box per EnemyVisualData plate on a BoneAttachment3D of its bone, placed at the rest pose at the
# bone plus the offset in the model's frame (unrotated), as Unity's BossEnemySetup does in the root's space.
func _build_plates() -> void:
	var count: int = mini(_data.plate_bones.size(), mini(_data.plate_offsets.size(), _data.plate_sizes.size()))
	if count == 0:
		return
	var rig: Node3D = _skeleton.get_parent() as Node3D
	# Skeleton space -> model space (the rig node is rotated and scaled 100).
	var rig_xform: Transform3D = rig.transform * _skeleton.transform
	var material: StandardMaterial3D = StandardMaterial3D.new()
	if _data.plate_material != null:
		material = _data.plate_material.duplicate() as StandardMaterial3D
	for i: int in count:
		var bone: int = _skeleton.find_bone(_data.plate_bones[i])
		if bone < 0:
			push_error("EnemyVisual: no bone %s for a plate" % _data.plate_bones[i])
			continue
		var attachment: BoneAttachment3D = BoneAttachment3D.new()
		attachment.name = "Plate%d" % i
		attachment.bone_name = _data.plate_bones[i]
		_skeleton.add_child(attachment)
		var bone_model: Transform3D = rig_xform * _skeleton.get_bone_global_rest(bone)
		var plate_model: Transform3D = Transform3D(Basis(), bone_model.origin + _data.plate_offsets[i])
		var box: BoxMesh = BoxMesh.new()
		box.size = _data.plate_sizes[i]
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = box
		mesh_instance.material_override = material
		# The plate in the bone's frame: (model <- bone)^-1 * (model <- plate).
		mesh_instance.transform = bone_model.affine_inverse() * plate_model
		attachment.add_child(mesh_instance)
		_plates.append(attachment)


func _set_loops() -> void:
	var looping: Array[StringName] = [_data.idle_clip, _data.walk_clip, _data.run_clip]
	for clip: StringName in looping + [_attack_clip]:
		if not _anim_player.has_animation(clip):
			push_error("EnemyVisual: missing clip %s" % clip)
			continue
		var animation: Animation = _anim_player.get_animation(clip)
		animation.loop_mode = Animation.LOOP_LINEAR if clip in looping else Animation.LOOP_NONE
		_loop_flags[clip] = animation.loop_mode


func _collect_upper_bones() -> void:
	var root_index: int = _skeleton.find_bone(String(_data.upper_body_root_bone))
	if root_index < 0:
		return
	for i: int in _skeleton.get_bone_count():
		var walk: int = i
		while walk >= 0:
			if walk == root_index:
				_upper_bones.append(StringName(_skeleton.get_bone_name(i)))
				break
			walk = _skeleton.get_bone_parent(walk)


func _anim_node(clip: StringName) -> AnimationNodeAnimation:
	var node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	node.animation = clip
	return node


func _build_tree() -> void:
	var root: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
	root.add_node(&"idle", _anim_node(_data.idle_clip))
	root.add_node(&"walk", _anim_node(_data.walk_clip))
	root.add_node(&"run", _anim_node(_data.run_clip))
	var loco: AnimationNodeTransition = AnimationNodeTransition.new()
	loco.input_count = 3
	loco.set_input_name(0, "idle")
	loco.set_input_name(1, "walk")
	loco.set_input_name(2, "run")
	loco.xfade_time = _data.locomotion_blend_time
	root.add_node(&"loco", loco)
	root.add_node(&"loco_scale", AnimationNodeTimeScale.new())
	root.add_node(&"attack", _anim_node(_attack_clip))
	var shot: AnimationNodeOneShot = AnimationNodeOneShot.new()
	shot.fadein_time = _data.attack_blend_time
	shot.fadeout_time = _data.attack_blend_time
	if _data.attack_upper_body_only:
		shot.filter_enabled = true
		var prefix: String = String(_model.get_path_to(_skeleton))
		for bone: StringName in _upper_bones:
			shot.set_filter_path(NodePath("%s:%s" % [prefix, bone]), true)
	root.add_node(&"attack_shot", shot)
	root.connect_node(&"loco", 0, &"idle")
	root.connect_node(&"loco", 1, &"walk")
	root.connect_node(&"loco", 2, &"run")
	root.connect_node(&"loco_scale", 0, &"loco")
	root.connect_node(&"attack_shot", 0, &"loco_scale")
	root.connect_node(&"attack_shot", 1, &"attack")
	root.connect_node(&"output", 0, &"attack_shot")
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_tree.tree_root = root
	_model.add_child(_tree)
	_tree.anim_player = _tree.get_path_to(_anim_player)
	_tree.active = true


func _build_flash_mesh() -> void:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = _data.muzzle_flash_size * 0.5
	sphere.height = _data.muzzle_flash_size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = _data.muzzle_flash_color
	_flash_mesh = MeshInstance3D.new()
	_flash_mesh.name = "MuzzleFlash"
	_flash_mesh.mesh = sphere
	_flash_mesh.material_override = material
	_flash_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash_mesh.visible = false
	_muzzle.add_child(_flash_mesh)


func _build_tracers() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = _data.tracer_color
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	for i: int in maxi(_data.tracer_pool_size, 1):
		var tracer: MeshInstance3D = MeshInstance3D.new()
		tracer.name = "Tracer%d" % i
		tracer.mesh = box
		tracer.material_override = material
		tracer.top_level = true
		tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tracer.visible = false
		add_child(tracer)
		_tracers.append(tracer)
		_tracer_left.append(0.0)
