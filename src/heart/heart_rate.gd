class_name HeartRate
extends Node
## The player's only vital. Rate falls continuously, five zones, pass-out / heart-attack countdowns.
## Knows nothing about weapons or UI: others read signals and modifier getters.

## Zones by rate. Boundaries: below slow_from = LOW; [slow_from, normal_from) = SLOW;
## [normal_from, fast_from) = NORMAL; [fast_from, heart_attack_above] = FAST; above = HIGH.
enum Zone { LOW, SLOW, NORMAL, FAST, HIGH }

## Run-end reasons passed to run_ended.
const REASON_PASSED_OUT: StringName = &"passed_out"
const REASON_HEART_ATTACK: StringName = &"heart_attack"

## Emitted whenever the rate changes (including the continuous fall).
signal heart_rate_changed(rate: float)
## Emitted when the rate crosses into another zone.
signal zone_changed(zone: Zone, previous_zone: Zone)
## Emitted while a danger countdown runs (seconds_left > 0) and once with 0.0 / empty reason when it resets.
signal danger_countdown_changed(seconds_left: float, reason: StringName)
## Emitted exactly once when the run ends; reason is REASON_PASSED_OUT or REASON_HEART_ATTACK.
signal run_ended(reason: StringName)

@export var data: HeartRateData

var _rate: float = 0.0
var _zone: Zone = Zone.NORMAL
var _ended: bool = false
var _countdown_reason: StringName = &""
var _countdown_elapsed: float = 0.0
var _tremor_phase: float = 0.0
var _limit_min: float = -INF
var _limit_max: float = INF


func _ready() -> void:
	_rate = data.resting_rate
	_zone = _zone_for(_rate)


func _physics_process(delta: float) -> void:
	if _ended:
		return
	_tremor_phase += TAU * _tremor_frequency() * delta
	_set_rate(_rate - data.drop_per_second * delta)
	_tick_countdown(delta)


## Lowers the rate by damage * bpm_per_damage.
func apply_hit(damage: float) -> void:
	change_rate(-damage * data.bpm_per_damage)


## Raises (positive) or lowers (negative) the rate by delta bpm. Ignored after the run ended.
func change_rate(delta: float) -> void:
	if _ended:
		return
	_set_rate(_rate + delta)


## Current rate in bpm.
func get_rate() -> float:
	return _rate


## Current zone.
func get_zone() -> Zone:
	return _zone


## True once the run has ended.
func has_ended() -> bool:
	return _ended


## Seconds left on the active danger countdown, or 0.0 when none is active.
func get_countdown_left() -> float:
	if _countdown_reason == &"":
		return 0.0
	return maxf(_countdown_total() - _countdown_elapsed, 0.0)


## Aim spread multiplier: below 1 in the slow zone, 1 elsewhere.
func get_aim_spread_multiplier() -> float:
	return data.slow_zone_spread_scale if _zone == Zone.SLOW else 1.0


## Movement speed multiplier: above 1 in the fast zone, 1 elsewhere.
func get_speed_multiplier() -> float:
	return data.fast_zone_speed_multiplier if _zone == Zone.FAST else 1.0


## Aim tremor as a (yaw, pitch) offset in degrees; zero outside the fast zone.
func get_aim_tremor() -> Vector2:
	if _zone != Zone.FAST:
		return Vector2.ZERO
	var amplitude: float = lerpf(data.tremor_amplitude_min, data.tremor_amplitude_max, _fast_progress())
	return Vector2(sin(_tremor_phase), cos(_tremor_phase * data.tremor_pitch_phase_ratio)) * amplitude


## True in the slow zone (read by story 006).
func is_slow_motion_available() -> bool:
	return _zone == Zone.SLOW


## True in the fast zone (read by story 006).
func is_superspeed_available() -> bool:
	return _zone == Zone.FAST


## Holds the rate inside [min_rate, max_rate] (tighter than the data range), so no LOW/HIGH zone and
## no countdown can start. The current rate is pulled inside at once. Used by the tutorial opening.
func set_rate_limits(min_rate: float, max_rate: float) -> void:
	_limit_min = minf(min_rate, max_rate)
	_limit_max = maxf(min_rate, max_rate)
	if not _ended:
		_set_rate(_rate)


## Removes the limits set by set_rate_limits.
func clear_rate_limits() -> void:
	_limit_min = -INF
	_limit_max = INF


## True while set_rate_limits is in force.
func has_rate_limits() -> bool:
	return _limit_min > -INF or _limit_max < INF


## The active limits as (min, max); (-INF, INF) when none.
func get_rate_limits() -> Vector2:
	return Vector2(_limit_min, _limit_max)


func _set_rate(value: float) -> void:
	var clamped: float = clampf(value, maxf(data.min_rate, _limit_min), minf(data.max_rate, _limit_max))
	if is_equal_approx(clamped, _rate):
		return
	_rate = clamped
	heart_rate_changed.emit(_rate)
	var zone: Zone = _zone_for(_rate)
	if zone != _zone:
		var previous: Zone = _zone
		_zone = zone
		zone_changed.emit(_zone, previous)
		if _countdown_reason != &"" and not _in_danger_zone(zone):
			_countdown_reason = &""
			_countdown_elapsed = 0.0
			danger_countdown_changed.emit(0.0, &"")


func _in_danger_zone(zone: Zone) -> bool:
	return zone == Zone.LOW or zone == Zone.HIGH


func _zone_for(rate: float) -> Zone:
	if rate < data.slow_from:
		return Zone.LOW
	if rate < data.normal_from:
		return Zone.SLOW
	if rate < data.fast_from:
		return Zone.NORMAL
	if rate <= data.heart_attack_above:
		return Zone.FAST
	return Zone.HIGH


func _fast_progress() -> float:
	return clampf(inverse_lerp(data.fast_from, data.heart_attack_above, _rate), 0.0, 1.0)


func _tremor_frequency() -> float:
	if _zone != Zone.FAST:
		return data.tremor_frequency_min
	return lerpf(data.tremor_frequency_min, data.tremor_frequency_max, _fast_progress())


func _countdown_total() -> float:
	return data.pass_out_seconds if _countdown_reason == REASON_PASSED_OUT else data.heart_attack_seconds


func _tick_countdown(delta: float) -> void:
	var wanted: StringName = &""
	if _zone == Zone.LOW:
		wanted = REASON_PASSED_OUT
	elif _zone == Zone.HIGH:
		wanted = REASON_HEART_ATTACK
	if wanted != _countdown_reason:
		_countdown_reason = wanted
		_countdown_elapsed = 0.0
		if wanted == &"":
			danger_countdown_changed.emit(0.0, &"")
			return
	if wanted == &"":
		return
	# Story 006: the danger countdown counts REAL seconds (physics delta is game time, so undo time_scale).
	if Engine.time_scale > 0.0:
		_countdown_elapsed += delta / Engine.time_scale
	if _countdown_elapsed >= _countdown_total():
		_ended = true
		danger_countdown_changed.emit(0.0, &"")
		run_ended.emit(wanted)
		return
	danger_countdown_changed.emit(get_countdown_left(), wanted)
