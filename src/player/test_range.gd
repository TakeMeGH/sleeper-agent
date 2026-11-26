extends Node3D
## Test range: debug hooks for captures. The StatusBar HUD shows ammo, heart rate and substances.

## Debug only: action pressed from _ready so a capture can hold a button. Empty = off.
@export var debug_hold_action: StringName = &""
## Debug only: seconds to hold debug_hold_action; 0 = hold for the whole run.
@export var debug_hold_seconds: float = 0.0

## Debug only: physics frame at which one shot is fired and a reload started (via Gun). -1 = off.
@export var debug_reload_after_frames: int = -1
## Debug only: gun index selected at start (0 pistol, 1 SMG, 2 shotgun). -1 = leave default.
@export var debug_gun_index: int = -1
## Debug only: place the player at debug_player_position facing debug_player_yaw_degrees.
@export var debug_override_player_pose: bool = false
@export var debug_player_position: Vector3 = Vector3.ZERO
@export var debug_player_yaw_degrees: float = 0.0
## Debug only: heart rate set at start through HeartRate.change_rate. Negative = leave at resting.
## The rate then drifts down 3 bpm per second like normal.
@export var debug_heart_rate: float = -1.0
## Debug only: re-apply debug_heart_rate every physics frame so the rate does not drift (captures).
@export var debug_hold_heart_rate: bool = false

## Debug only: physics frame at which ShiftAbility.try_activate() is called. -1 = off.
@export var debug_shift_after_frames: int = -1

## Debug only: physics frame at which DiveState.try_start(debug_dive_input) is called. 0 = off.
@export var debug_dive_after_frames: int = 0
## Debug only: dive input in move_left/right/forward/back space (x right, y back); ZERO = forward.
@export var debug_dive_input: Vector2 = Vector2.ZERO
## Debug only: fire the equipped gun every physics frame while a dive runs (Gun API, no input events).
@export var debug_fire_during_dive: bool = false

## Debug only: physics frame at which one shot is fired through the Gun API (no input). -1 = off.
@export var debug_fire_after_frames: int = -1
## Debug only: health given to every TargetDummy at start (0 = leave invulnerable).
@export var debug_dummy_health: float = 0.0

## Debug only: GunFeel keeps the muzzle flash visible for this many frames (capture scenes).
@export var debug_flash_hold_frames: int = 0

var _debug_hold_elapsed: float = 0.0
var _debug_frames: int = 0

@onready var holder: WeaponHolder = $Player/Head/Camera3D/WeaponHolder
@onready var heart: HeartRate = $Player/HeartRate
@onready var dive: DiveState = $Player/DiveState


func _ready() -> void:
	dive.phase_changed.connect(_on_dive_phase_changed)
	if debug_hold_action != &"":
		Input.action_press(debug_hold_action)
	if debug_override_player_pose:
		var player: Node3D = $Player
		player.global_position = debug_player_position
		player.rotation_degrees.y = debug_player_yaw_degrees
	if debug_flash_hold_frames > 0:
		($Player/Head/Camera3D/GunFeel as GunFeel).debug_flash_hold_frames = debug_flash_hold_frames
	if debug_dummy_health > 0.0:
		for child: Node in get_children():
			if child is TargetDummy:
				(child as TargetDummy).max_health = debug_dummy_health
	if debug_gun_index >= 0:
		holder.switch_to(debug_gun_index)
	if debug_heart_rate >= 0.0:
		heart.change_rate(debug_heart_rate - heart.get_rate())


func _physics_process(delta: float) -> void:
	_debug_frames += 1
	if debug_hold_heart_rate and debug_heart_rate >= 0.0:
		heart.change_rate(debug_heart_rate - heart.get_rate())
	if debug_dive_after_frames > 0 and _debug_frames == debug_dive_after_frames:
		var player: PlayerController = $Player as PlayerController
		var speed_multiplier: float = player.heart_rate.get_speed_multiplier()
		if player.shift_ability != null:
			speed_multiplier *= player.shift_ability.get_speed_multiplier()
		dive.try_start(debug_dive_input, speed_multiplier)
	if debug_fire_during_dive and dive.is_diving():
		var dive_gun: Gun = holder.get_current_gun()
		if dive_gun != null:
			var exclude: Array[RID] = [($Player as CollisionObject3D).get_rid()]
			dive_gun.try_fire(holder.camera, exclude)
	if debug_shift_after_frames >= 0 and _debug_frames == debug_shift_after_frames:
		($Player/ShiftAbility as ShiftAbility).try_activate()
	if debug_fire_after_frames >= 0 and _debug_frames == debug_fire_after_frames:
		var fire_gun: Gun = holder.get_current_gun()
		if fire_gun != null:
			var fire_exclude: Array[RID] = [($Player as CollisionObject3D).get_rid()]
			fire_gun.try_fire(holder.camera, fire_exclude)
	if debug_reload_after_frames >= 0 and _debug_frames == debug_reload_after_frames:
		var gun: Gun = holder.get_current_gun()
		if gun != null:
			gun.try_fire(holder.camera, [])
			gun.start_reload()
	if debug_hold_action != &"" and debug_hold_seconds > 0.0:
		_debug_hold_elapsed += delta
		if _debug_hold_elapsed >= debug_hold_seconds:
			Input.action_release(debug_hold_action)


func _on_dive_phase_changed(phase: DiveState.Phase, _previous: DiveState.Phase) -> void:
	print("DIVE phase=%s frame=%d" % [DiveState.Phase.keys()[phase], _debug_frames])
