class_name WeaponHolder
extends Node3D
## Owns the player's guns, reads fire/switch/reload input and relays gun signals.

## Emitted when the magazine or spare ammo of a gun changes. spare is -1 for infinite.
signal ammo_changed(gun_id: StringName, magazine: int, spare: int)
## Emitted when the active gun changes (also once at start).
signal gun_switched(data: GunData)
## Emitted when a gun finishes reloading.
signal reloaded(gun_id: StringName)
## Emitted for each shell a shell-by-shell reload loads (the shotgun).
signal shell_loaded(gun_id: StringName)
## Emitted when the active gun fires a shot.
signal shot_fired(data: GunData)
## Emitted when the trigger is pulled on an empty gun that cannot reload (dry click hook).
signal dry_fired(data: GunData)
## Relays Gun.shot_hit for every ray that hit something (see Gun for the arguments).
signal shot_hit(position: Vector3, normal: Vector3, collider: Object, damageable: bool, killed: bool, direction: Vector3)

@export var gun_definitions: Array[GunData] = []
@export var camera: Camera3D
## Body excluded from hitscan rays (the player).
@export var exclude_body: CollisionObject3D
## Real seconds a fire press waits for a shot to become possible (hitstop cap 0.12 s plus a margin).
@export var fire_buffer_seconds: float = 0.25
## Player time source handed to every gun (optional; guns find the scene's PlayerTime when null).
@export var player_time: PlayerTime

var guns: Array[Gun] = []
var current_index: int = -1

## Aim modifiers pushed in by the player (heart rate); copied to the active gun just before each shot.
var aim_spread_multiplier: float = 1.0
var aim_tremor_degrees: Vector2 = Vector2.ZERO

var _skip_fire: bool = false
## Fire presses seen by _unhandled_input that have not produced a shot yet. During hitstop the physics
## rate is very low, so a press polled with is_action_just_pressed could be missed. A press is kept until
## a shot fires or fire_buffer_seconds of real time pass.
var _fire_buffered: int = 0
var _fire_buffer_expiry_usec: int = 0


func _ready() -> void:
	for gun_data: GunData in gun_definitions:
		var gun: Gun = Gun.new()
		gun.name = String(gun_data.gun_id)
		gun.player_time = player_time
		add_child(gun)
		gun.setup(gun_data)
		gun.ammo_changed.connect(_on_gun_ammo_changed.bind(gun))
		gun.reloaded.connect(_on_gun_reloaded.bind(gun))
		gun.shell_loaded.connect(func() -> void: shell_loaded.emit(gun.data.gun_id))
		gun.shot_fired.connect(_on_gun_shot_fired.bind(gun))
		gun.dry_fired.connect(_on_gun_dry_fired.bind(gun))
		gun.shot_hit.connect(_on_gun_shot_hit)
		guns.append(gun)
	if not guns.is_empty():
		switch_to(0)


func _physics_process(_delta: float) -> void:
	if current_index < 0:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_skip_fire = true
		_fire_buffered = 0
		return
	if _skip_fire:
		# The click that recaptured the mouse must not fire a shot.
		_skip_fire = false
		_fire_buffered = 0
		return
	var gun: Gun = guns[current_index]
	if _fire_buffered > 0 and Time.get_ticks_usec() > _fire_buffer_expiry_usec:
		_fire_buffered = 0
	var buffered: bool = _fire_buffered > 0
	var wants_fire: bool = buffered or Input.is_action_just_pressed(&"fire") \
		or (gun.data.automatic and Input.is_action_pressed(&"fire"))
	if wants_fire:
		var exclude: Array[RID] = []
		if exclude_body != null:
			exclude.append(exclude_body.get_rid())
		gun.spread_multiplier = aim_spread_multiplier
		gun.tremor_degrees = aim_tremor_degrees
		var fired: bool = gun.try_fire(camera, exclude)
		# Keep a buffered press while the gun is busy (cooldown, reload); drop it once it shot or ran dry.
		if fired or gun.magazine <= 0:
			_fire_buffered = 0


func _unhandled_input(event: InputEvent) -> void:
	if guns.is_empty():
		return
	if event.is_action_pressed(&"fire") and not event.is_echo():
		buffer_fire_press()
	if event.is_action_pressed(&"weapon_1"):
		switch_to(0)
	elif event.is_action_pressed(&"weapon_2"):
		switch_to(1)
	elif event.is_action_pressed(&"weapon_3"):
		switch_to(2)
	elif event.is_action_pressed(&"weapon_next"):
		switch_to(posmod(current_index + 1, guns.size()))
	elif event.is_action_pressed(&"weapon_prev"):
		switch_to(posmod(current_index - 1, guns.size()))
	elif event.is_action_pressed(&"reload") and current_index >= 0:
		guns[current_index].start_reload()


## Remembers one fire press until a shot fires or fire_buffer_seconds of real time pass
## (called for every fire press event).
func buffer_fire_press() -> void:
	_fire_buffered += 1
	_fire_buffer_expiry_usec = Time.get_ticks_usec() + int(fire_buffer_seconds * 1000000.0)


## Number of fire presses still waiting for a shot.
func get_buffered_input_count() -> int:
	return _fire_buffered


## Makes the gun at index active. Ignored if out of range or already active.
func switch_to(index: int) -> void:
	if index < 0 or index >= guns.size() or index == current_index:
		return
	if current_index >= 0:
		guns[current_index].cancel_reload()
	current_index = index
	var gun: Gun = guns[current_index]
	gun_switched.emit(gun.data)
	ammo_changed.emit(gun.data.gun_id, gun.magazine, gun.get_spare_display())
	if gun.magazine <= 0:
		gun.start_reload()


## Returns the active gun, or null if there are none.
func get_current_gun() -> Gun:
	return null if current_index < 0 else guns[current_index]


## Adds spare ammo to the gun with the given id (&"smg" or &"shotgun"). Returns the amount added.
func add_spare_ammo(gun_id: StringName, amount: int) -> int:
	for gun: Gun in guns:
		if gun.data.gun_id == gun_id:
			var added: int = gun.add_spare_ammo(amount)
			if gun == get_current_gun() and gun.magazine <= 0:
				gun.start_reload()
			return added
	return 0


func _on_gun_ammo_changed(magazine: int, spare: int, gun: Gun) -> void:
	ammo_changed.emit(gun.data.gun_id, magazine, spare)


func _on_gun_reloaded(gun: Gun) -> void:
	reloaded.emit(gun.data.gun_id)


func _on_gun_shot_fired(gun: Gun) -> void:
	shot_fired.emit(gun.data)


func _on_gun_dry_fired(gun: Gun) -> void:
	dry_fired.emit(gun.data)


func _on_gun_shot_hit(position: Vector3, normal: Vector3, collider: Object, damageable: bool,
		killed: bool, direction: Vector3) -> void:
	shot_hit.emit(position, normal, collider, damageable, killed, direction)
