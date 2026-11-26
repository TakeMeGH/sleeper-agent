class_name SubstanceInventory
extends Node
## Holds the player's coffee and cigarette counts and applies their heart-rate ramp while the
## matching input is held. Polls input (never consumes events), so firing and moving are unaffected.

const KIND_COFFEE: StringName = &"coffee"
const KIND_CIGARETTE: StringName = &"cigarette"
const KINDS: Array[StringName] = [KIND_COFFEE, KIND_CIGARETTE]

## Emitted when a count changes (use, add, cap).
signal count_changed(kind: StringName, count: int)
## Emitted when the player starts consuming a kind (button down with count > 0).
signal consume_started(kind: StringName)
## Emitted when consuming stops (released, ran out, or run ended).
signal consume_ended(kind: StringName)

## Heart rate that receives the ramp (injected in the scene, no singleton).
@export var heart_rate: HeartRate
## One SubstanceData per kind.
@export var substances: Array[SubstanceData] = []

var _data: Dictionary[StringName, SubstanceData] = {}
var _counts: Dictionary[StringName, int] = {}
var _progress: Dictionary[StringName, float] = {}
var _active: StringName = &""
var _held_time: float = 0.0
var _player_time: PlayerTime


func _ready() -> void:
	for s: SubstanceData in substances:
		_data[s.kind] = s
		_counts[s.kind] = s.start_count
		_progress[s.kind] = 0.0


func _physics_process(delta: float) -> void:
	# Consuming runs on player time: progress, held ramp time and the bpm it adds (story 016).
	if _player_time == null:
		_player_time = PlayerTime.find_for(self)
	if _player_time != null:
		delta = _player_time.scale_delta(delta)
	tick(delta, _is_held(KIND_COFFEE), _is_held(KIND_CIGARETTE))


## Advances one step with explicit held states (callable from tests/probes).
## Rules: while a kind is consumed the other is ignored until release (first pressed wins; coffee
## wins a same-frame tie). The ramp keeps growing across units while held and resets on release.
## Hold progress toward the next unit is kept on release. Nothing happens once the run has ended.
func tick(delta: float, coffee_held: bool, cigarette_held: bool) -> void:
	if heart_rate != null and heart_rate.has_ended():
		_stop()
		return
	var held: Dictionary[StringName, bool] = {KIND_COFFEE: coffee_held, KIND_CIGARETTE: cigarette_held}
	if _active != &"" and not held[_active]:
		_stop()
	if _active == &"":
		for kind: StringName in KINDS:
			if held[kind] and get_count(kind) > 0:
				_start(kind)
				break
	if _active == &"":
		return
	var d: SubstanceData = _data[_active]
	if heart_rate != null:
		heart_rate.change_rate(d.bpm_per_second(_held_time) * delta)
	_held_time += delta
	_progress[_active] += delta
	if _progress[_active] >= d.seconds_per_item:
		_progress[_active] -= d.seconds_per_item
		_counts[_active] -= 1
		count_changed.emit(_active, _counts[_active])
		if _counts[_active] <= 0:
			_progress[_active] = 0.0
			_stop()


## Adds amount units of kind, capped at the data's max_count. Returns the amount actually added
## (0 for unknown kind, non-positive amount, or full). Emits count_changed when it changes.
func add_substance(kind: StringName, amount: int) -> int:
	if not _data.has(kind) or amount <= 0:
		return 0
	var before: int = _counts[kind]
	_counts[kind] = mini(before + amount, _data[kind].max_count)
	var added: int = _counts[kind] - before
	if added > 0:
		count_changed.emit(kind, _counts[kind])
	return added


## Units left of kind (0 for unknown kind).
func get_count(kind: StringName) -> int:
	return _counts.get(kind, 0)


## Progress 0-1 toward using up the current unit of kind.
func get_hold_progress(kind: StringName) -> float:
	if not _data.has(kind):
		return 0.0
	return _progress[kind] / _data[kind].seconds_per_item


## True while kind is being consumed.
func is_consuming(kind: StringName) -> bool:
	return _active == kind and kind != &""


## The SubstanceData for kind, or null.
func get_substance_data(kind: StringName) -> SubstanceData:
	return _data.get(kind)


func _is_held(kind: StringName) -> bool:
	return _data.has(kind) and Input.is_action_pressed(_data[kind].input_action)


func _start(kind: StringName) -> void:
	_active = kind
	_held_time = 0.0
	consume_started.emit(kind)


func _stop() -> void:
	if _active == &"":
		return
	var kind: StringName = _active
	_active = &""
	_held_time = 0.0
	consume_ended.emit(kind)
