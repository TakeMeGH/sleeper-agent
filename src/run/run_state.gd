class_name RunState
extends Node
## Run state: wave reached, enemies left, kills, time survived, how the run ended, and the session best.
## The session best lives in a static variable: it survives the scene reload for a restart but is never
## written to disk, so it resets when the game process exits.

## Emitted once when the run ends, after the totals are final and the session best is updated.
signal run_ended(reason: StringName)

## Wave number shown by the HUD (the spawner writes it).
@export var wave: int = 1
## Enemies left in the wave (the spawner writes it).
@export var enemies_left: int = 8
## Seconds survived so far. Advances while `counting` is true.
@export var time_survived: float = 0.0
## Whether time_survived advances (stops at run end).
@export var counting: bool = true
## Heart rate whose run_ended ends the run (optional).
@export var heart: HeartRate
## Spawner whose enemy_killed events are counted (optional).
@export var spawner: WaveSpawner

## Best run of this session: {"time": float, "wave": int, "kills": int}; empty before the first run ends.
static var _session_best: Dictionary = {}

var _kills: int = 0
var _ended: bool = false
var _end_reason: StringName = &""
var _was_new_best: bool = false


func _ready() -> void:
	if heart != null:
		heart.run_ended.connect(end_run)
	if spawner != null:
		spawner.enemy_killed.connect(_on_enemy_killed)


func _process(delta: float) -> void:
	if counting:
		time_survived += delta


## Ends the run with a reason (HeartRate.REASON_*): freezes the time, updates the session best, emits run_ended.
## Ignored when the run already ended.
func end_run(reason: StringName) -> void:
	if _ended:
		return
	_ended = true
	counting = false
	_end_reason = reason
	var result: Dictionary = {"time": time_survived, "wave": wave, "kills": _kills}
	_was_new_best = _session_best.is_empty() or is_better(result, _session_best)
	if _was_new_best:
		_session_best = result
	run_ended.emit(reason)


## True once the run has ended.
func has_ended() -> bool:
	return _ended


## Kills so far this run.
func get_kills() -> int:
	return _kills


## Wave reached (the current wave number).
func get_wave() -> int:
	return wave


## Seconds survived (frozen at run end).
func get_time_survived() -> float:
	return time_survived


## How the run ended (&"passed_out" / &"heart_attack"), or &"" while it runs.
func get_end_reason() -> StringName:
	return _end_reason


## The session best as {"time", "wave", "kills"}; empty before any run has ended.
func get_session_best() -> Dictionary:
	return _session_best.duplicate()


## True when the run that just ended beat the session best (or was the first).
func was_new_best() -> bool:
	return _was_new_best


## Debug/probe: sets kills, time survived and wave so a short capture shows non-trivial numbers (0 = leave as is).
func debug_set_totals(kills: int, seconds: float, wave_reached: int) -> void:
	if kills > 0:
		_kills = kills
	if seconds > 0.0:
		time_survived = seconds
	if wave_reached > 0:
		wave = wave_reached


## Forgets the session best (probes and tests).
static func clear_session_best() -> void:
	_session_best = {}


## Primary comparison: more time survived; a tie goes to more waves, then more kills.
static func is_better(a: Dictionary, b: Dictionary) -> bool:
	var keys: Array[String] = ["time", "wave", "kills"]
	for key: String in keys:
		var av: float = float(a.get(key, 0.0))
		var bv: float = float(b.get(key, 0.0))
		if av > bv:
			return true
		if av < bv:
			return false
	return false


func _on_enemy_killed(_enemy: EnemyBase) -> void:
	if not _ended:
		_kills += 1
