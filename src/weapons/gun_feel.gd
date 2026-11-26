class_name GunFeel
extends Node
## Shooting feel: forgiving camera recoil and shake (an additive offset that always returns to zero),
## muzzle flash on the viewmodel layer, hit and kill feedback, impacts, blood, kill push and hitstop.
## Reads WeaponHolder signals only; it never touches ammo, and never writes the player's look angles.
##
## Camera offset: the kick is added to the Camera3D local rotation after DiveState wrote its pose
## (process_priority 50 runs after it) and removed again before the next add, so the aim, which lives in
## the player yaw and Head pitch, is never changed.

## Emitted for every ray that hit a damageable target. killed is true for the shot that killed it.
signal hit_confirmed(killed: bool)
## Emitted when the trigger is pulled on an empty gun (hook for the sound in story 012).
signal dry_clicked

@export var data: GunFeelSet
@export var effects_data: ImpactEffectsData
@export var holder: WeaponHolder
@export var camera: Camera3D
@export var viewmodel: Viewmodel
## Owner of Engine.time_scale; hitstop is requested through it. Optional.
@export var shift_ability: ShiftAbility
## Debug only: keep the muzzle flash shown for at least this many frames (capture scenes).
@export var debug_flash_hold_frames: int = 0

var _entries: Dictionary = {}  # StringName gun_id -> GunFeelData
var _effects: ImpactEffects
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _kick: Vector2 = Vector2.ZERO  # x yaw, y pitch, degrees
var _kick_entry: GunFeelData
var _shake_left: float = 0.0
var _shake_total: float = 1.0
var _shake_entry: GunFeelData
var _shake_sign: float = 1.0
var _shake_rotation: Vector3 = Vector3.ZERO  # degrees (pitch, yaw, roll)
var _fov_left: float = 0.0
var _fov_entry: GunFeelData
var _applied_rotation: Vector3 = Vector3.ZERO
var _applied_position: Vector3 = Vector3.ZERO
var _applied_fov: float = 0.0
var _written_rotation: Vector3 = Vector3.ZERO
var _written_position: Vector3 = Vector3.ZERO
var _flash: MeshInstance3D
var _flash_materials: Array[StandardMaterial3D] = []
var _flash_left: float = 0.0
var _flash_hold: int = 0
var _clock: RealClock = RealClock.new()
var _player_time: PlayerTime
var _dry_clicks: int = 0
var _hits: int = 0
var _kills: int = 0


func _ready() -> void:
	# After DiveState (priority 0) wrote the camera pose, before the mirror cameras (100) copy it.
	process_priority = 50
	_rng.randomize()
	if data == null or holder == null or camera == null:
		push_error("GunFeel needs data, holder and camera.")
		set_process(false)
		return
	for entry: GunFeelData in data.guns:
		_entries[entry.gun_id] = entry
	if effects_data != null:
		_effects = ImpactEffects.new()
		_effects.name = "ImpactEffects"
		_effects.data = effects_data
		add_child(_effects)
		if holder.exclude_body != null:
			_effects.exclude = [holder.exclude_body.get_rid()]
	_build_muzzle_flash()
	holder.shot_fired.connect(_on_shot_fired)
	holder.shot_hit.connect(_on_shot_hit)
	holder.dry_fired.connect(_on_dry_fired)
	holder.gun_switched.connect(_on_gun_switched)


func _exit_tree() -> void:
	_remove_applied_offset()


func _process(delta: float) -> void:
	tick(delta)


## Advances the kick, shake, FOV punch and flash by delta seconds and applies them to the camera.
## Called every frame; probes may call it directly.
func tick(delta: float) -> void:
	var real_delta: float = _clock.step(delta)
	# Kick recovery, shake and FOV punch run on player time; the flash stays on real time.
	if _player_time == null:
		_player_time = PlayerTime.find_for(self)
	if _player_time != null:
		delta = _player_time.scale_delta(delta)
	if _kick_entry != null:
		var speed_pitch: float = _kick_entry.max_pitch_degrees / maxf(_kick_entry.recovery_seconds, 0.01)
		var speed_yaw: float = _kick_entry.max_yaw_degrees / maxf(_kick_entry.recovery_seconds, 0.01)
		_kick.y = move_toward(_kick.y, 0.0, speed_pitch * delta)
		_kick.x = move_toward(_kick.x, 0.0, speed_yaw * delta)
	_shake_rotation = Vector3.ZERO
	var shake_position: Vector3 = Vector3.ZERO
	if _shake_left > 0.0 and _shake_entry != null:
		_shake_left = maxf(_shake_left - delta, 0.0)
		var envelope: float = _shake_left / _shake_total
		var phase: float = (_shake_total - _shake_left) * _shake_entry.shake_frequency * TAU
		_shake_rotation = Vector3(
				sin(phase + 1.3) * _shake_entry.shake_pitch_degrees,
				sin(phase * 1.1 + 2.1) * _shake_entry.shake_yaw_degrees,
				sin(phase * 0.9) * _shake_entry.shake_roll_degrees) * envelope * _shake_sign
		shake_position = Vector3(sin(phase * 1.2), sin(phase + 0.7), 0.0) \
				* _shake_entry.shake_position * envelope
	var fov_offset: float = 0.0
	if _fov_left > 0.0 and _fov_entry != null:
		_fov_left = maxf(_fov_left - delta, 0.0)
		fov_offset = _fov_entry.fov_punch_degrees * sin(PI * _fov_left / maxf(_fov_entry.fov_punch_seconds, 0.001))
	if _flash_left > 0.0 or _flash_hold > 0:
		# The flash lasts its real length, not the whole hitstop.
		_flash_left -= real_delta
		_flash_hold = maxi(_flash_hold - 1, 0)
		if _flash_left <= 0.0 and _flash_hold <= 0 and _flash != null:
			_flash.visible = false
	var rotation_offset: Vector3 = Vector3(
			deg_to_rad(_kick.y + _shake_rotation.x),
			deg_to_rad(_kick.x + _shake_rotation.y),
			deg_to_rad(_shake_rotation.z))
	_apply_camera_offset(rotation_offset, shake_position, fov_offset)


## Camera kick offset in degrees (x yaw, y pitch). Returns to (0, 0) after the recovery time.
func get_kick_offset() -> Vector2:
	return _kick


## Current shake rotation in degrees (pitch, yaw, roll); zero when the shake is over.
func get_shake_offset() -> Vector3:
	return _shake_rotation


## Rotation (radians, pitch/yaw/roll) currently added to the camera's local rotation.
func get_applied_camera_rotation() -> Vector3:
	return _applied_rotation


## True while the muzzle flash is shown.
func is_muzzle_flash_visible() -> bool:
	return _flash != null and _flash.visible


## Dry clicks since start.
func get_dry_click_count() -> int:
	return _dry_clicks


## Shots that hit a damageable target since start.
func get_hit_count() -> int:
	return _hits


## Kills since start.
func get_kill_count() -> int:
	return _kills


## Bullet holes alive.
func get_bullet_hole_count() -> int:
	return _effects.get_bullet_hole_count() if _effects != null else 0


## Bullet hole cap.
func get_bullet_hole_cap() -> int:
	return _effects.get_bullet_hole_cap() if _effects != null else 0


## Blood splats alive.
func get_splat_count() -> int:
	return _effects.get_splat_count() if _effects != null else 0


## Blood splat cap.
func get_splat_cap() -> int:
	return _effects.get_splat_cap() if _effects != null else 0


## Real seconds of hitstop left.
func get_hitstop_left() -> float:
	return shift_ability.get_hitstop_left() if shift_ability != null else 0.0


## Largest hitstop that can be pending at once (data).
func get_hitstop_cap() -> float:
	return data.hitstop_max_seconds if data != null else 0.0


## Fire presses buffered by the weapon holder and not yet consumed.
func get_buffered_input_count() -> int:
	return holder.get_buffered_input_count() if holder != null else 0


## The pooled effects node (probes read pool sizes from it).
func get_effects() -> ImpactEffects:
	return _effects


func _on_shot_fired(gun_data: GunData) -> void:
	var entry: GunFeelData = _entries.get(gun_data.gun_id) as GunFeelData
	if entry == null:
		return
	_kick_entry = entry
	_kick.y = minf(_kick.y + entry.kick_pitch_degrees, entry.max_pitch_degrees)
	_kick.x = clampf(_kick.x + _rng.randf_range(-1.0, 1.0) * entry.kick_yaw_degrees,
			-entry.max_yaw_degrees, entry.max_yaw_degrees)
	_shake_entry = entry
	_shake_left = entry.shake_seconds
	_shake_total = maxf(entry.shake_seconds, 0.001)
	_shake_sign = -1.0 if _rng.randf() < 0.5 else 1.0
	_fov_entry = entry
	_fov_left = entry.fov_punch_seconds
	_show_muzzle_flash(entry)


func _on_shot_hit(position: Vector3, normal: Vector3, collider: Object, damageable: bool,
		killed: bool, direction: Vector3) -> void:
	if not damageable:
		if _effects != null:
			var corpse: Object = collider
			if corpse != null and not corpse.has_method("corpse_hit") and corpse is Node:
				corpse = (corpse as Node).get_parent()
			if corpse != null and corpse.has_method("corpse_hit") and bool(corpse.call("is_dead")):
				# A shot into a dead body: blood and a push, no hit marker, no kill.
				_effects.spawn_blood_hit(position, normal, direction, false)
				var gun_now: Gun = holder.get_current_gun()
				var strength: float = (gun_now.data.pushback if gun_now != null else 1.0) * data.kill_push_speed_per_pushback
				corpse.call("corpse_hit", direction, strength)
			else:
				_effects.spawn_wall_impact(position, normal)
		return
	_hits += 1
	hit_confirmed.emit(killed)
	if _effects != null:
		_effects.spawn_blood_hit(position, normal, direction, killed)
		_effects.spawn_splats(position, direction, killed)
	if not killed:
		return
	_kills += 1
	var gun: Gun = holder.get_current_gun()
	var entry: GunFeelData = _entries.get(gun.data.gun_id) as GunFeelData if gun != null else null
	_push_body(collider, direction, gun)
	if shift_ability != null and entry != null:
		shift_ability.request_hitstop(entry.hitstop_seconds, data.hitstop_max_seconds, data.hitstop_time_scale)


func _push_body(collider: Object, direction: Vector3, gun: Gun) -> void:
	var body: Object = collider
	if body != null and not body.has_method("apply_death_push") and body is Node:
		body = (body as Node).get_parent()
	if body == null or not body.has_method("apply_death_push"):
		return
	var pushback: float = gun.data.pushback if gun != null else 1.0
	body.call("apply_death_push", direction.normalized() * pushback * data.kill_push_speed_per_pushback)


func _on_dry_fired(_gun_data: GunData) -> void:
	_dry_clicks += 1
	dry_clicked.emit()


func _on_gun_switched(_gun_data: GunData) -> void:
	if _flash != null:
		_flash.visible = false
	_flash_left = 0.0


func _build_muzzle_flash() -> void:
	if viewmodel == null or data.muzzle_textures.is_empty():
		return
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	for texture: Texture2D in data.muzzle_textures:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		# Unity: a plain quad in the gun pivot's frame (not a billboard), depth tested, so the gun body hides the part
		# behind it and the flash reads as leaving the barrel.
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_texture = ImpactEffects.make_alpha_texture(texture)
		_flash_materials.append(material)
	_flash = MeshInstance3D.new()
	_flash.name = "MuzzleFlash"
	_flash.mesh = quad
	_flash.layers = 1 << (viewmodel.get_render_layer() - 1)
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.visible = false
	viewmodel.get_gun_pivot().add_child(_flash)


func _show_muzzle_flash(entry: GunFeelData) -> void:
	if _flash == null:
		return
	var material: StandardMaterial3D = _flash_materials[_rng.randi() % _flash_materials.size()]
	material.albedo_color = entry.muzzle_flash_color
	_flash.material_override = material
	_flash.position = entry.muzzle_offset + Vector3(0.0, 0.0, -entry.muzzle_flash_forward)
	# A random roll per shot (Unity), so the flame does not always point the same way.
	_flash.rotation = Vector3(0.0, 0.0, _rng.randf() * TAU)
	_flash.scale = Vector3.ONE * entry.muzzle_flash_size * _rng.randf_range(0.8, 1.2)
	_flash.visible = true
	_flash_left = entry.muzzle_flash_seconds
	_flash_hold = debug_flash_hold_frames


## Adds the offsets to the camera. Anything another system wrote to the camera since our last write
## (DiveState rewrites the pose every frame while diving) is kept as the new base.
func _apply_camera_offset(rotation_offset: Vector3, position_offset: Vector3, fov_offset: float) -> void:
	if rotation_offset == Vector3.ZERO and position_offset == Vector3.ZERO and fov_offset == 0.0 \
			and _applied_rotation == Vector3.ZERO and _applied_position == Vector3.ZERO and _applied_fov == 0.0:
		return
	var base_rotation: Vector3 = camera.rotation
	var base_position: Vector3 = camera.position
	if camera.rotation.is_equal_approx(_written_rotation):
		base_rotation -= _applied_rotation
	if camera.position.is_equal_approx(_written_position):
		base_position -= _applied_position
	camera.rotation = base_rotation + rotation_offset
	camera.position = base_position + position_offset
	camera.fov = camera.fov - _applied_fov + fov_offset
	_written_rotation = camera.rotation
	_written_position = camera.position
	_applied_rotation = rotation_offset
	_applied_position = position_offset
	_applied_fov = fov_offset


func _remove_applied_offset() -> void:
	if camera == null or not is_instance_valid(camera):
		return
	_apply_camera_offset(Vector3.ZERO, Vector3.ZERO, 0.0)
