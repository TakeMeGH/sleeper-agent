class_name LoopVoice
extends Node
## One looping stream with a real-time fade. Level is 0-1 of max_volume; the player starts when the level
## rises above zero and (optionally) stops when it is back at zero. The owner calls tick() with real seconds.

## Emitted when the player starts playing.
signal started
## Emitted when the player stops after fading to silence.
signal stopped

const SILENT_DB: float = -80.0
const EPSILON: float = 0.0005

var player: AudioStreamPlayer
var max_volume: float = 1.0
var stop_when_silent: bool = true

var _level: float = 0.0
var _target: float = 0.0
var _rate: float = 0.0
var _response: float = 0.0
var _active: bool = false


## Creates the player. max_volume_linear is the linear volume at level 1.
func setup(stream: AudioStream, bus: StringName, max_volume_linear: float, stop_on_silence: bool = true) -> void:
	player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = SILENT_DB
	add_child(player)
	max_volume = max_volume_linear
	stop_when_silent = stop_on_silence


## Linear fade to a level (0-1) over real seconds; 0 seconds jumps.
func fade_to(target: float, seconds: float) -> void:
	_target = clampf(target, 0.0, 1.0)
	_response = 0.0
	if seconds <= 0.0:
		_level = _target
		_rate = 0.0
	else:
		_rate = absf(_target - _level) / seconds
	_apply()


## Follows a level with exponential smoothing (reaches about 99% in response_seconds).
func follow(target: float, response_seconds: float) -> void:
	_target = clampf(target, 0.0, 1.0)
	_response = maxf(response_seconds, 0.001)
	_apply()


## Advances the fade by real seconds.
func tick(real_delta: float) -> void:
	if _response > 0.0:
		_level += (_target - _level) * (1.0 - exp(-real_delta * 4.6 / _response))
		if absf(_target - _level) < EPSILON * 0.5:
			_level = _target
	elif _rate > 0.0:
		_level = move_toward(_level, _target, _rate * real_delta)
	_apply()


## Current level 0-1 (relative to max_volume).
func get_level() -> float:
	return _level


## Level the voice is heading to.
func get_target() -> float:
	return _target


## Current player volume in dB (-80 when silent).
func get_volume_db() -> float:
	return player.volume_db


## Current linear volume (level x max_volume).
func get_linear_volume() -> float:
	return _level * max_volume


## True between start and stop (the player is active).
func is_active() -> bool:
	return _active


## Path of the stream, or "".
func get_stream_path() -> String:
	return "" if player == null or player.stream == null else player.stream.resource_path


func _apply() -> void:
	if player == null:
		return
	var audible: bool = _level > EPSILON
	if not _active and (audible or _target > EPSILON or not stop_when_silent):
		_active = true
		player.play()
		started.emit()
	player.volume_db = linear_to_db(_level * max_volume) if audible else SILENT_DB
	if _active and stop_when_silent and not audible and _target <= EPSILON:
		_active = false
		player.stop()
		stopped.emit()
