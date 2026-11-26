class_name DropPickup
extends Node3D
## A floating pickup left by a dead enemy. Collected when the player comes within pickup_radius:
## ammo goes to WeaponHolder.add_spare_ammo, coffee/cigarettes to SubstanceInventory.add_substance.
##
## Port of Unity AmmoDrops / DoseDrops: the pickup rests hover_height above the floor found by a ray under the
## drop position, bobs (sin(age * bob_speed) * bob_height), spins about the vertical axis, and blinks for its
## last blink_time seconds. Ammo is the drop_ammo model tinted per gun; coffee and cigarette are their own
## models with an additive glow quad facing the camera. Every look value comes from DropData.
## Node layout: DropPickup (resting point) > Visual (bob) > Spin (turn) > model; Visual > Glow.

signal collected(kind: StringName)

const GROUP_AMMO: StringName = &"drop_ammo"
const GROUP_DOSE: StringName = &"drop_dose"

var kind: StringName = &"smg"
var _data: DropData
var _age: float = 0.0
var _visual: Node3D
var _spin: Node3D
var _model: Node3D
var _glow: MeshInstance3D
var _player: Node3D


## Creates a pickup of the given kind over world_position under parent: snapped to the floor below (or
## world_position itself when the probe finds none), raised by hover_height. Enforces the pickup cap.
static func spawn(parent: Node, pickup_kind: StringName, world_position: Vector3, drop_data: DropData) -> DropPickup:
	var pickup: DropPickup = DropPickup.new()
	pickup.kind = pickup_kind
	pickup._data = drop_data
	parent.add_child(pickup)
	pickup.global_position = pickup._snap_to_floor(world_position) + Vector3(0.0, drop_data.hover_height, 0.0)
	pickup._enforce_cap()
	return pickup


## True for smg/shotgun pickups.
func is_ammo() -> bool:
	return kind == &"smg" or kind == &"shotgun"


## Returns the age in seconds.
func get_age() -> float:
	return _age


## True while the pickup is in its blinking seconds (the last blink_time).
func is_blinking() -> bool:
	return _data.blink_time > 0.0 and _data.pickup_lifetime - _age <= _data.blink_time


## The resting point (hover_height above the floor), without the bob.
func get_rest_position() -> Vector3:
	return global_position


func _ready() -> void:
	add_to_group(GROUP_AMMO if is_ammo() else GROUP_DOSE)
	_build_visual()
	_present()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _data.pickup_lifetime:
		queue_free()
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
	# Unity: nothing is collected once the run has ended.
	var run_over: bool = _player != null and _player.get("heart_rate") != null \
			and (_player.get("heart_rate") as HeartRate).has_ended()
	if _player != null and not run_over:
		var offset: Vector3 = _player.global_position - global_position
		if Vector2(offset.x, offset.z).length() <= _data.pickup_radius \
				and absf(offset.y) <= _data.pickup_height_tolerance and collect(_player):
			return
	_present()


## Gives the pickup to the player. Returns false (pickup stays) when nothing could be added, for example full inventory.
func collect(player: Node) -> bool:
	var added: int = 0
	if is_ammo():
		var holder: WeaponHolder = player.get("weapon_holder") as WeaponHolder
		if holder != null:
			var rounds: int = _data.smg_rounds if kind == &"smg" else _data.shotgun_rounds
			added = holder.add_spare_ammo(kind, rounds)
	else:
		var inventory: SubstanceInventory = player.get_node_or_null("SubstanceInventory") as SubstanceInventory
		if inventory != null:
			added = inventory.add_substance(kind, _data.dose_amount)
	if added <= 0:
		return false
	_play_pickup_sound()
	collected.emit(kind)
	set_physics_process(false)
	remove_from_group(GROUP_AMMO)
	remove_from_group(GROUP_DOSE)
	queue_free()
	return true


# The per-frame look (Unity DoseDrops.Present / AmmoDrops.Present): bob, spin, blink.
func _present() -> void:
	_visual.position.y = sin(_age * _data.bob_speed) * _data.bob_height
	# Unity's positive Y turn is clockwise seen from above; Godot's positive rotation.y is counter-clockwise.
	_spin.rotation.y = -deg_to_rad(_age * _data.spin_speed_degrees)
	var visible_now: bool = true
	if is_blinking():
		var into_blink: float = _data.blink_time - (_data.pickup_lifetime - _age)
		visible_now = floori(into_blink * _data.blink_rate * 2.0) % 2 == 0
	if is_ammo() or _data.dose_blink_hides_model:
		_spin.visible = visible_now
	if _glow != null:
		_glow.visible = visible_now


func _snap_to_floor(position_over_floor: Vector3) -> Vector3:
	var world: World3D = get_world_3d()
	if world == null:
		return position_over_floor
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			position_over_floor + Vector3.UP * _data.floor_probe_up,
			position_over_floor + Vector3.DOWN * _data.floor_probe_down, _data.floor_collision_mask)
	query.collide_with_areas = false
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return position_over_floor
	return hit[&"position"] as Vector3


func _play_pickup_sound() -> void:
	var stream: AudioStream = _data.get_pickup_sound(kind)
	var host: Node = get_parent()
	if stream == null or host == null:
		return
	var voice: AudioStreamPlayer = AudioStreamPlayer.new()
	voice.name = "PickupSound"
	voice.stream = stream
	voice.bus = _data.pickup_sound_bus
	voice.volume_db = linear_to_db(maxf(_data.pickup_volume, 0.0001))
	host.add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()


func _enforce_cap() -> void:
	var group: StringName = GROUP_AMMO if is_ammo() else GROUP_DOSE
	var cap: int = _data.ammo_cap if is_ammo() else _data.dose_cap
	var members: Array[Node] = get_tree().get_nodes_in_group(group)
	while members.size() > cap:
		var oldest: DropPickup = null
		for m: Node in members:
			var p: DropPickup = m as DropPickup
			if p != null and (oldest == null or p._age > oldest._age):
				oldest = p
		if oldest == null:
			break
		members.erase(oldest)
		oldest.remove_from_group(group)
		oldest.queue_free()


func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_spin = Node3D.new()
	_spin.name = "Spin"
	_visual.add_child(_spin)
	var scene: PackedScene = _data.get_model(kind)
	if scene != null:
		var model: Node = scene.instantiate()
		if model is Node3D:
			_model = model as Node3D
			_model.rotation_degrees = _data.fbx_rotation_degrees
			_model.scale = _data.ammo_model_scale if is_ammo() else _data.dose_model_scale
		_spin.add_child(model)
		_apply_material(model, _material())
	if not is_ammo() and _data.glow_size > 0.0:
		_glow = MeshInstance3D.new()
		_glow.name = "Glow"
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2.ONE * _data.glow_size
		_glow.mesh = quad
		_glow.material_override = _glow_material()
		_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_glow.position.y = _data.get_glow_height(kind)
		_visual.add_child(_glow)


# The model material: shared for the doses, a tinted copy per gun for ammo (Unity AmmoDrops _BaseColor tint).
func _material() -> Material:
	if _data.model_material == null:
		return null
	if not is_ammo():
		return _data.model_material
	var key: String = "tint:%s" % kind
	if not _data.runtime_materials.has(key):
		var tinted: Material = _data.model_material.duplicate()
		if tinted is BaseMaterial3D:
			(tinted as BaseMaterial3D).albedo_color = _data.get_color(kind)
		_data.runtime_materials[key] = tinted
	return _data.runtime_materials[key] as Material


# Additive, unlit, camera-facing, two-sided, no depth write (Unity Particles Unlit, Blend Additive, Cull Off).
func _glow_material() -> Material:
	var key: String = "glow:%s" % kind
	if not _data.runtime_materials.has(key):
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_texture = _data.glow_texture
		m.albedo_color = _data.get_glow_color(kind)
		_data.runtime_materials[key] = m
	return _data.runtime_materials[key] as Material


func _apply_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if material != null:
			mesh_instance.material_override = material
		if not _data.cast_shadows:
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_apply_material(child, material)
