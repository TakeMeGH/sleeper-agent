class_name AudioEmitter
extends Node
## Base for the audio nodes: keeps a real-time clock and an observable record of every sound event,
## so a headless probe can see which stream played for which event.

## Emitted for every sound event (one-shots, loop starts/stops, crossfades).
signal sound_played(event_id: StringName, stream_path: String, volume_db: float)

const MAX_LOG_ENTRIES: int = 256

var _event_log: Array[Dictionary] = []
var _clock: RealClock = RealClock.new()


## Records an event and emits sound_played. position is stored for 3D sounds.
func _record(event_id: StringName, stream: AudioStream, volume_db: float, position: Vector3 = Vector3.ZERO) -> void:
	var path: String = "" if stream == null else stream.resource_path
	_event_log.append({&"event": event_id, &"stream": path, &"volume_db": volume_db, &"position": position})
	if _event_log.size() > MAX_LOG_ENTRIES:
		_event_log.pop_front()
	sound_played.emit(event_id, path, volume_db)


## Recorded events, oldest first. Keys: event, stream, volume_db, position.
func get_event_log() -> Array[Dictionary]:
	return _event_log


## Clears the recorded events.
func clear_event_log() -> void:
	_event_log.clear()


## Number of recorded events with this id.
func get_event_count(event_id: StringName) -> int:
	var count: int = 0
	for entry: Dictionary in _event_log:
		if entry[&"event"] == event_id:
			count += 1
	return count


## The latest recorded event with this id, or an empty Dictionary.
func get_last_event(event_id: StringName) -> Dictionary:
	for i: int in range(_event_log.size() - 1, -1, -1):
		if _event_log[i][&"event"] == event_id:
			return _event_log[i]
	return {}
