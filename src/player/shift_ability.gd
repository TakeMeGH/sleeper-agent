class_name ShiftAbility
extends Node
## Shift ability: slow motion in the slow heart-rate zone, superspeed in the fast zone.
## Timing: durations and cooldown count REAL seconds. _process delta is scaled by Engine.time_scale,
## so real seconds = delta / Engine.time_scale (a time scale of 0 counts as 0 real seconds).
## Slow motion runs the world at slow_time_scale; the player runs on player_time_scale (PlayerTime, story 016).
## Once started an effect runs to its duration even if the heart rate leaves the zone.

const KIND_SLOW_MOTION: StringName = &"slow_motion"
const KIND_SUPERSPEED: StringName = &"superspeed"
const INPUT_ACTION: StringName = &"shift_ability"

## Emitted when an effect starts; kind is KIND_SLOW_MOTION or KIND_SUPERSPEED.
signal ability_started(kind: StringName)
## Emitted when an effect ends (duration over or run ended).
signal ability_ended(kind: StringName)
## Emitted when the cooldown starts, on every tick while it runs, and with 0.0 when it is over.
signal cooldown_changed(seconds_left: float)

@export var data: ShiftAbilityData
@export var heart_rate: HeartRate

var _active_kind: StringName = &""
var _effect_left: float = 0.0
var _cooldown_left: float = 0.0
## Hitstop (story 011): this class is the only writer of Engine.time_scale, so the freeze is composed
## here with the slow-motion scale. Timed in real microseconds (Time.get_ticks_usec).
var _hitstop_end_usec: int = 0
var _hitstop_scale: float = 1.0
var _hitstop_cap: float = 0.0
var _clock: RealClock = RealClock.new()


func _ready() -> void:
	Engine.time_scale = 1.0
	if heart_rate != null:
		heart_rate.run_ended.connect(_on_run_ended)


func _exit_tree() -> void:
	_hitstop_end_usec = 0
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	if _hitstop_end_usec > 0 and Time.get_ticks_usec() >= _hitstop_end_usec:
		_hitstop_end_usec = 0
		_apply_time_scale()
	if Input.is_action_just_pressed(INPUT_ACTION):
		try_activate()
	# Real seconds; RealClock avoids the jump on the frame hitstop changes the time scale.
	tick(_clock.step(delta))


## Advances the effect and cooldown by real_delta unscaled seconds (probes may call it directly).
func tick(real_delta: float) -> void:
	if is_active():
		_effect_left -= real_delta
		if _effect_left <= 0.0:
			_end_effect(true)
	elif _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - real_delta, 0.0)
		cooldown_changed.emit(_cooldown_left)


## Starts the effect that fits the current heart-rate zone. Returns false (and does nothing) during
## an effect or cooldown, after the run ended, or in a zone without an effect.
func try_activate() -> bool:
	if is_active() or _cooldown_left > 0.0 or heart_rate == null or heart_rate.has_ended():
		return false
	if heart_rate.is_slow_motion_available():
		_active_kind = KIND_SLOW_MOTION
		_effect_left = data.slow_seconds
	elif heart_rate.is_superspeed_available():
		_active_kind = KIND_SUPERSPEED
		_effect_left = data.superspeed_seconds
	else:
		return false
	_apply_time_scale()
	ability_started.emit(_active_kind)
	return true


## Freezes the game (time scale hitstop_time_scale x the slow-motion scale) for seconds of REAL time.
## A request while a freeze runs adds to what is left but the total never exceeds max_seconds.
func request_hitstop(seconds: float, max_seconds: float, hitstop_time_scale: float) -> void:
	if seconds <= 0.0 or max_seconds <= 0.0:
		return
	var total: float = minf(get_hitstop_left() + seconds, max_seconds)
	_hitstop_end_usec = Time.get_ticks_usec() + int(total * 1000000.0)
	_hitstop_scale = clampf(hitstop_time_scale, 0.001, 1.0)
	_hitstop_cap = max_seconds
	_apply_time_scale()


## Real seconds of hitstop left (0.0 when none).
func get_hitstop_left() -> float:
	if _hitstop_end_usec <= 0:
		return 0.0
	return maxf(float(_hitstop_end_usec - Time.get_ticks_usec()) / 1000000.0, 0.0)


## The cap passed with the last hitstop request (0.0 before any).
func get_hitstop_cap() -> float:
	return _hitstop_cap


## Move speed multiplier: superspeed_multiplier while superspeed is active, else 1.0.
func get_speed_multiplier() -> float:
	return data.superspeed_multiplier if _active_kind == KIND_SUPERSPEED else 1.0


## True while an effect runs.
func is_active() -> bool:
	return _active_kind != &""


## Kind of the running effect, or an empty name when none.
func get_active_kind() -> StringName:
	return _active_kind


## Real seconds of cooldown left (0.0 when ready or an effect is running).
func get_cooldown_left() -> float:
	return _cooldown_left


## Real seconds left on the running effect (0.0 when none).
func get_effect_left() -> float:
	return maxf(_effect_left, 0.0) if is_active() else 0.0


## The one place Engine.time_scale is written: slow motion x hitstop.
func _apply_time_scale() -> void:
	var scale_value: float = 1.0
	if _active_kind == KIND_SLOW_MOTION:
		scale_value = data.slow_time_scale
	if _hitstop_end_usec > 0:
		scale_value *= _hitstop_scale
	Engine.time_scale = scale_value


func _end_effect(start_cooldown: bool) -> void:
	var kind: StringName = _active_kind
	_active_kind = &""
	_effect_left = 0.0
	_apply_time_scale()
	ability_ended.emit(kind)
	if start_cooldown:
		_cooldown_left = data.cooldown_seconds
		cooldown_changed.emit(_cooldown_left)


func _on_run_ended(_reason: StringName) -> void:
	if is_active():
		_end_effect(false)
	_hitstop_end_usec = 0
	Engine.time_scale = 1.0
