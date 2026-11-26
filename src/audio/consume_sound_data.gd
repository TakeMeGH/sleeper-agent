class_name ConsumeSoundData
extends Resource
## The looping sound heard while one substance kind is held.

@export var substance_id: StringName = &""
@export var clip: AudioStream
@export_range(0.0, 1.0, 0.01) var volume: float = 0.8
