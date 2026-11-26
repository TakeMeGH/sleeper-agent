class_name Gun
extends Node
## One gun's runtime state (magazine, spare ammo, cooldown, reload) and hitscan firing.

## Emitted whenever magazine or spare changes. spare is -1 for infinite spare ammo.
signal ammo_changed(magazine: int, spare: int)
## Emitted when a reload completes (a shell reload: when it filled the magazine or ran out of spare;
## a shot that interrupts a shell reload emits none).
signal reloaded
## Emitted for each shell a shell-by-shell reload loads.
signal shell_loaded
## Emitted for each shot that fires.
signal shot_fired
## Emitted when the trigger is pulled on an empty gun that cannot reload (dry click; sound is story 012).
signal dry_fired
## Emitted for every ray that hits something. damageable: the collider (or parent) has take_hit().
## killed: that hit took the target's health to zero. direction is the unit shot direction.
signal shot_hit(position: Vector3, normal: Vector3, collider: Object, damageable: bool, killed: bool, direction: Vector3)

var data: GunData
var magazine: int = 0
var spare: int = 0

## Multiplier on the data's spread (set each frame by the player from heart rate).
var spread_multiplier: float = 1.0
## Aim tremor offset (yaw, pitch) in degrees added to every shot direction.
var tremor_degrees: Vector2 = Vector2.ZERO

## Player time source (set by WeaponHolder, or found by group). Null = world time.
var player_time: PlayerTime

var _cooldown: float = 0.0
var _last_delta: float = 0.0
var _reload_left: float = 0.0
var _reloading: bool = false
# Shell reload: shells this reload will load in total, and shells loaded so far.
var _shells_total: int = 0
var _shells_loaded: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Sets up the gun from its data with a full magazine and starting spare ammo.
func setup(gun_data: GunData) -> void:
	data = gun_data
	magazine = data.magazine_size
	spare = 0 if data.infinite_spare else data.starting_spare
	_rng.randomize()


func _physics_process(delta: float) -> void:
	if player_time == null:
		player_time = PlayerTime.find_for(self)
	if player_time != null:
		delta = player_time.scale_delta(delta)
	# The overshoot past zero is kept (negative cooldown) so the fire rate is exact; set in try_fire.
	_cooldown -= delta
	_last_delta = delta
	if _cooldown < -_last_delta:
		_cooldown = -_last_delta
	if _reloading:
		_reload_left -= delta
		if is_shell_reload():
			while _reloading and _reload_left <= 0.0:
				_load_shell()
		elif _reload_left <= 0.0:
			_finish_reload()


## True when this gun reloads shell by shell.
func is_shell_reload() -> bool:
	return data != null and data.shell_load_time > 0.0


## True while a reload is in progress.
func is_reloading() -> bool:
	return _reloading


## Player-time seconds until the next shot is allowed (0.0 when ready).
func get_cooldown_left() -> float:
	return maxf(_cooldown, 0.0)


## Player-time seconds until the running reload finishes (0.0 when not reloading).
func get_reload_left() -> float:
	if not _reloading:
		return 0.0
	if is_shell_reload():
		return maxf(_reload_left, 0.0) + float(_shells_total - _shells_loaded - 1) * data.shell_load_time
	return maxf(_reload_left, 0.0)


## Reload progress 0-1 (0 = just started); -1 when not reloading. Read by the audio for reload sound points.
func get_reload_progress() -> float:
	if not _reloading:
		return -1.0
	if is_shell_reload():
		var total: float = float(maxi(_shells_total, 1)) * data.shell_load_time
		return clampf(1.0 - get_reload_left() / total, 0.0, 1.0)
	return clampf(1.0 - _reload_left / maxf(data.reload_time, 0.001), 0.0, 1.0)


## Spare ammo for display; -1 means infinite.
func get_spare_display() -> int:
	return -1 if data.infinite_spare else spare


## Fires from the camera. Returns true if a shot was fired. An empty gun starts a reload instead.
func try_fire(camera: Camera3D, exclude: Array[RID]) -> bool:
	if _cooldown > 0.0:
		return false
	if _reloading:
		# A shot interrupts a shell reload once a shell is in (Unity); a magazine reload cannot be interrupted.
		if not is_shell_reload() or magazine <= 0:
			return false
		_reloading = false
	if magazine <= 0:
		start_reload()
		if not _reloading:
			# Nothing to reload with: dry click, rate limited by the fire rate.
			_cooldown = 1.0 / data.fire_rate
			dry_fired.emit()
		return false
	magazine -= 1
	# Keep at most one tick of leftover so the rate is exact but never banks an extra shot.
	_cooldown = 1.0 / data.fire_rate + maxf(_cooldown, -_last_delta)
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var origin: Vector3 = camera.global_position
	for i: int in data.pellets:
		_fire_ray(space, camera.global_transform.basis, origin, exclude)
	shot_fired.emit()
	ammo_changed.emit(magazine, get_spare_display())
	if magazine <= 0:
		start_reload()
	return true


## Starts a reload if the magazine is not full and spare ammo is available.
func start_reload() -> void:
	if _reloading or magazine >= data.magazine_size:
		return
	if not data.infinite_spare and spare <= 0:
		return
	_reloading = true
	if is_shell_reload():
		var needed: int = data.magazine_size - magazine
		_shells_total = needed if data.infinite_spare else mini(needed, spare)
		_shells_loaded = 0
		_reload_left = data.shell_load_time
	else:
		_reload_left = data.reload_time


## Cancels an in-progress reload (used when switching away).
func cancel_reload() -> void:
	_reloading = false


## Adds spare ammo (no effect on infinite-ammo guns). Returns the amount actually added.
func add_spare_ammo(amount: int) -> int:
	if data.infinite_spare or amount <= 0:
		return 0
	var added: int = mini(amount, data.max_spare - spare)
	if added <= 0:
		return 0
	spare += added
	ammo_changed.emit(magazine, spare)
	return added


func _load_shell() -> void:
	magazine += 1
	if not data.infinite_spare:
		spare -= 1
	_shells_loaded += 1
	shell_loaded.emit()
	ammo_changed.emit(magazine, get_spare_display())
	if magazine >= data.magazine_size or (not data.infinite_spare and spare <= 0):
		_reloading = false
		reloaded.emit()
	else:
		_reload_left += data.shell_load_time


func _finish_reload() -> void:
	_reloading = false
	var needed: int = data.magazine_size - magazine
	var taken: int = needed if data.infinite_spare else mini(needed, spare)
	magazine += taken
	if not data.infinite_spare:
		spare -= taken
	reloaded.emit()
	ammo_changed.emit(magazine, get_spare_display())


func _fire_ray(space: PhysicsDirectSpaceState3D, basis: Basis, origin: Vector3, exclude: Array[RID]) -> void:
	if tremor_degrees != Vector2.ZERO:
		basis = basis * Basis.from_euler(Vector3(deg_to_rad(tremor_degrees.y), deg_to_rad(tremor_degrees.x), 0.0))
	var direction: Vector3 = -basis.z
	if data.spread_degrees > 0.0:
		var spread: float = deg_to_rad(data.spread_degrees * spread_multiplier)
		var angle: float = _rng.randf() * TAU
		var radius: float = sqrt(_rng.randf()) * spread
		direction = (basis * Vector3(cos(angle) * sin(radius), sin(angle) * sin(radius), -cos(radius))).normalized()
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, origin + direction * data.max_range)
	query.exclude = exclude
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit["collider"]
	var target: Object = null
	if collider.has_method("take_hit"):
		target = collider
	elif collider is Node and (collider as Node).get_parent() != null \
			and (collider as Node).get_parent().has_method("take_hit"):
		target = (collider as Node).get_parent()
	var killed: bool = false
	var damageable: bool = false
	if target != null:
		var was_dead: bool = target.has_method("is_dead") and bool(target.call("is_dead"))
		if not was_dead:
			# A pellet that reaches an already dead body is not a damageable hit.
			damageable = true
			target.call("take_hit", data.damage, direction * data.pushback)
			killed = target.has_method("is_dead") and bool(target.call("is_dead"))
	shot_hit.emit(hit["position"], hit["normal"], collider, damageable, killed, direction)
