class_name MusicDirector
extends AudioEmitter
## Combat music loop through the run; while a boss is alive the boss loop crossfades in and the combat loop
## fades out, and back when the last boss dies. Fades use real time, so slow motion never stretches them.

const TRACK_COMBAT: StringName = &"combat"
const TRACK_BOSS: StringName = &"boss"

@export var config: AudioConfig

## When true the director looks for live BossEnemy nodes (group "enemies"); set_boss_alive turns this off.
var poll_enabled: bool = true

var _combat: LoopVoice
var _boss: LoopVoice
var _boss_alive: bool = false
var _poll_left: float = 0.0
var _track: StringName = TRACK_COMBAT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_combat = LoopVoice.new()
	_boss = LoopVoice.new()
	add_child(_combat)
	add_child(_boss)
	# The combat loop keeps running (silent) during a boss so it resumes in place; the boss loop restarts.
	_combat.setup(config.combat_clip, config.music_bus, config.combat_volume, false)
	_boss.setup(config.boss_clip, config.music_bus, config.boss_volume, true)
	_combat.fade_to(1.0, config.music_start_fade_seconds)
	_record(&"music_combat_start", config.combat_clip, _combat.get_volume_db())


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Advances polling and the crossfade. real_delta is in real seconds.
func tick(real_delta: float) -> void:
	if poll_enabled:
		_poll_left -= real_delta
		if _poll_left <= 0.0:
			_poll_left = config.boss_poll_seconds
			set_boss_state(_find_boss())
	_combat.tick(real_delta)
	_boss.tick(real_delta)


## Forces the boss state and stops polling (for probes and cutscenes). Starts the crossfade.
func set_boss_alive(alive: bool) -> void:
	poll_enabled = false
	set_boss_state(alive)


## Starts the crossfade for a boss state change (no-op if unchanged).
func set_boss_state(alive: bool) -> void:
	if alive == _boss_alive:
		return
	_boss_alive = alive
	if alive:
		_track = TRACK_BOSS
		_boss.fade_to(1.0, config.crossfade_seconds)
		_combat.fade_to(0.0, config.crossfade_seconds)
		_record(&"crossfade_to_boss", config.boss_clip, _boss.get_volume_db())
	else:
		_track = TRACK_COMBAT
		_boss.fade_to(0.0, config.crossfade_seconds)
		_combat.fade_to(1.0, config.crossfade_seconds)
		_record(&"crossfade_to_combat", config.combat_clip, _combat.get_volume_db())


## The track the music is heading to: &"combat" or &"boss".
func get_current_track() -> StringName:
	return _track


## True while a boss is considered alive.
func is_boss_alive() -> bool:
	return _boss_alive


## Track level 0-1 (relative to the track's volume) for &"combat" or &"boss".
func get_track_level(track: StringName) -> float:
	return (_boss if track == TRACK_BOSS else _combat).get_level()


## Track player volume in dB (-80 silent).
func get_track_volume_db(track: StringName) -> float:
	return (_boss if track == TRACK_BOSS else _combat).get_volume_db()


## True while the track's player is running.
func is_track_playing(track: StringName) -> bool:
	return (_boss if track == TRACK_BOSS else _combat).is_active()


func _find_boss() -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if node is BossEnemy:
			return true
	return false
