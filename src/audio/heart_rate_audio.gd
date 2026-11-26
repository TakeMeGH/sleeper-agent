class_name HeartRateAudio
extends AudioEmitter
## Two heart loops: low (rate below the normal band) and high (above it). Silent while the rate is in the
## band, rising to full volume at the end rates; follows the rate with smoothing and fades out on run end.

@export var config: AudioConfig
@export var heart: HeartRate

var _low: LoopVoice
var _high: LoopVoice
var _rate: float = 80.0
var _ended: bool = false


## Loop level 0-1 for a rate: x = low loop, y = high loop (fractions of each loop's full volume).
static func levels_for_rate(rate: float, cfg: AudioConfig) -> Vector2:
	var low_t: float = clampf(inverse_lerp(cfg.heart_low_silent_at, cfg.heart_low_full_at, rate), 0.0, 1.0)
	var high_t: float = clampf(inverse_lerp(cfg.heart_high_silent_at, cfg.heart_high_full_at, rate), 0.0, 1.0)
	return Vector2(pow(low_t, cfg.heart_curve_exponent), pow(high_t, cfg.heart_curve_exponent))


## Linear volume for a rate: x = low loop, y = high loop (level x the loop's max volume).
static func volumes_for_rate(rate: float, cfg: AudioConfig) -> Vector2:
	var levels: Vector2 = levels_for_rate(rate, cfg)
	return Vector2(levels.x * cfg.heart_low_max_volume, levels.y * cfg.heart_high_max_volume)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_low = LoopVoice.new()
	_high = LoopVoice.new()
	add_child(_low)
	add_child(_high)
	_low.setup(config.heart_low_clip, config.sfx_bus, config.heart_low_max_volume)
	_high.setup(config.heart_high_clip, config.sfx_bus, config.heart_high_max_volume)
	_low.started.connect(func() -> void: _record(&"heart_low_start", _low.player.stream, _low.get_volume_db()))
	_low.stopped.connect(func() -> void: _record(&"heart_low_stop", _low.player.stream, _low.get_volume_db()))
	_high.started.connect(func() -> void: _record(&"heart_high_start", _high.player.stream, _high.get_volume_db()))
	_high.stopped.connect(func() -> void: _record(&"heart_high_stop", _high.player.stream, _high.get_volume_db()))
	if heart != null:
		heart.heart_rate_changed.connect(on_heart_rate_changed)
		heart.run_ended.connect(on_run_ended)
		_rate = heart.get_rate()
		var start: Vector2 = levels_for_rate(_rate, config)
		_low.follow(start.x, 0.001)
		_high.follow(start.y, 0.001)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Moves both loops toward the volumes for the current rate. real_delta is in real seconds.
func tick(real_delta: float) -> void:
	if not _ended:
		var target: Vector2 = levels_for_rate(_rate, config)
		_low.follow(target.x, config.heart_response_seconds)
		_high.follow(target.y, config.heart_response_seconds)
	_low.tick(real_delta)
	_high.tick(real_delta)


## Sets the rate the loops follow.
func on_heart_rate_changed(rate: float) -> void:
	_rate = rate


## Fades both loops out and stops them; they stay stopped.
func on_run_ended(_reason: StringName) -> void:
	_ended = true
	_low.fade_to(0.0, config.heart_end_fade_seconds)
	_high.fade_to(0.0, config.heart_end_fade_seconds)
	_record(&"heart_run_ended", null, _low.get_volume_db())


## Low loop level 0-1 (relative to its full volume).
func get_low_level() -> float:
	return _low.get_level()


## High loop level 0-1 (relative to its full volume).
func get_high_level() -> float:
	return _high.get_level()


## Low loop player volume in dB (-80 silent).
func get_low_volume_db() -> float:
	return _low.get_volume_db()


## High loop player volume in dB (-80 silent).
func get_high_volume_db() -> float:
	return _high.get_volume_db()


## Low loop linear volume.
func get_low_linear() -> float:
	return _low.get_linear_volume()


## High loop linear volume.
func get_high_linear() -> float:
	return _high.get_linear_volume()


## True while the low / high loop player is running.
func is_low_playing() -> bool:
	return _low.is_active()


func is_high_playing() -> bool:
	return _high.is_active()


## True once the run has ended.
func has_ended() -> bool:
	return _ended
