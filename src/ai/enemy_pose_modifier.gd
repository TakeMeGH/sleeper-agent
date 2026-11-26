class_name EnemyPoseModifier
extends SkeletonModifier3D
## Bends chosen bones about the skeleton's X axis after the animation has been applied (hit jolt, reload lean).
## Child of the Skeleton3D. Positive angle = lean forward (the imported rig is rotated -90 degrees about X).

## Bone name (StringName) -> degrees about the skeleton X axis. Parents must be listed before children.
var bone_angles: Dictionary = {}
## Aim turn (applied before the bends): aim_bone turns so the barrel points at aim_point, at most
## aim_max_degrees, scaled by aim_weight (0-1). The barrel is barrel_in_hand (the muzzle node in hand_bone's frame,
## skeleton units) carried by hand_bone. aim_point is in world space.
var aim_bone: StringName = &""
var hand_bone: StringName = &""
var barrel_in_hand: Transform3D = Transform3D()
var aim_point: Vector3 = Vector3.ZERO
var aim_weight: float = 0.0
var aim_max_degrees: float = 0.0
## Degrees the aim turn applied on the last update (for probes).
var last_aim_degrees: float = 0.0


func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return
	_apply_aim(skeleton)
	for bone_name: Variant in bone_angles:
		var angle: float = float(bone_angles[bone_name])
		if absf(angle) < 0.01:
			continue
		var index: int = skeleton.find_bone(String(bone_name))
		if index < 0:
			continue
		var pose: Transform3D = skeleton.get_bone_global_pose(index)
		var bend: Basis = Basis(Vector3.RIGHT, deg_to_rad(angle))
		skeleton.set_bone_global_pose(index, Transform3D(bend * pose.basis, pose.origin))


func _apply_aim(skeleton: Skeleton3D) -> void:
	last_aim_degrees = 0.0
	if aim_weight <= 0.0 or aim_max_degrees <= 0.0:
		return
	var spine: int = skeleton.find_bone(String(aim_bone))
	var hand: int = skeleton.find_bone(String(hand_bone))
	if spine < 0 or hand < 0:
		return
	var barrel: Transform3D = skeleton.get_bone_global_pose(hand) * barrel_in_hand
	var forward: Vector3 = barrel.basis.z.normalized()
	var want: Vector3 = skeleton.global_transform.affine_inverse() * aim_point - barrel.origin
	if want.length_squared() < 0.0000001 or forward.length_squared() < 0.5:
		return
	want = want.normalized()
	var angle: float = forward.angle_to(want)
	var axis: Vector3 = forward.cross(want)
	if angle < 0.0001 or axis.length_squared() < 0.0000001:
		return
	var turn: float = minf(angle, deg_to_rad(aim_max_degrees)) * clampf(aim_weight, 0.0, 1.0)
	var pose: Transform3D = skeleton.get_bone_global_pose(spine)
	skeleton.set_bone_global_pose(spine, Transform3D(Basis(axis.normalized(), turn) * pose.basis, pose.origin))
	last_aim_degrees = rad_to_deg(turn)
