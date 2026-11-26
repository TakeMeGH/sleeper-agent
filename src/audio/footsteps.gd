class_name Footsteps
extends AudioEmitter
## Footstep loop while walking on the floor above a speed threshold, and the landing sound after a dive
## landing or a long fall (once per landing).

@export var config: AudioConfig
@export var body: CharacterBody3D
@export var dive_state: DiveState

var _steps: LoopVoice
var _landing_player: AudioStreamPlayer
var _airborne: bool = false
var _peak_y: float = 0.0
var _dive_pending: bool = false
var _walking: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_steps = LoopVoice.new()
	add_child(_steps)
	_steps.setup(config.footstep_clip, config.sfx_bus, config.footstep_volume)
	_steps.started.connect(func() -> void: _record(&"footsteps_start", _steps.player.stream, _steps.get_volume_db()))
	_steps.stopped.connect(func() -> void: _record(&"footsteps_stop", _steps.player.stream, _steps.get_volume_db()))
	_landing_player = AudioStreamPlayer.new()
	_landing_player.bus = config.sfx_bus
	_landing_player.stream = config.landing_clip
	add_child(_landing_player)
	if dive_state != null:
		dive_state.dive_started.connect(func(_direction: Vector3) -> void: _dive_pending = true)
		dive_state.dive_ended.connect(func() -> void: _dive_pending = false)


func _physics_process(_delta: float) -> void:
	if body == null:
		return
	var on_floor: bool = body.is_on_floor()
	# Real velocity is in world-delta units; divide by the player-time multiplier for the visible speed.
	var velocity: Vector3 = body.get_real_velocity() / maxf(PlayerTime.multiplier_for(self), PlayerTime.MIN_MULTIPLIER)
	var diving: bool = dive_state != null and dive_state.is_diving()
	update_state(on_floor, Vector2(velocity.x, velocity.z).length(), diving, body.global_position.y)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Advances the footstep fade. real_delta is in real seconds.
func tick(real_delta: float) -> void:
	_steps.tick(real_delta)


## One physics sample: floor contact, horizontal speed, whether a dive is running and the body height.
## Starts / stops the footstep loop and detects landings. Public so a probe can drive it.
func update_state(on_floor: bool, horizontal_speed: float, diving: bool, height: float) -> void:
	var want_walk: bool = on_floor and not diving and horizontal_speed > config.footstep_min_speed
	if want_walk != _walking:
		_walking = want_walk
		if _walking:
			_steps.fade_to(1.0, config.footstep_fade_in_seconds)
		else:
			_steps.fade_to(0.0, config.footstep_fade_out_seconds)
	if on_floor:
		if _airborne:
			_airborne = false
			on_landed(_peak_y - height, _dive_pending)
	else:
		if not _airborne:
			_airborne = true
			_peak_y = height
		else:
			_peak_y = maxf(_peak_y, height)


## Plays the landing sound if the fall was high enough or followed a dive. Once per call.
func on_landed(fall_height: float, after_dive: bool) -> void:
	_dive_pending = false
	if not after_dive and fall_height < config.min_fall_height:
		return
	_landing_player.volume_db = linear_to_db(maxf(config.landing_volume, 0.0001))
	_landing_player.play()
	_record(&"landing", config.landing_clip, _landing_player.volume_db)


## True while the footstep loop is active (including its fade-out).
func is_footsteps_playing() -> bool:
	return _steps.is_active()


## True while the player is considered walking (fade-in requested).
func is_walking() -> bool:
	return _walking


## Footstep loop level 0-1.
func get_footstep_level() -> float:
	return _steps.get_level()
