class_name GunAudioData
extends Resource
## Per-gun sound data: shot takes, optional tail and thump layers, and the reload sounds.

@export var gun_id: StringName = &""
@export_group("Shot")
@export var shot_clips: Array[AudioStream] = []
@export_range(0.0, 1.0, 0.01) var shot_volume: float = 0.8
@export_range(0.0, 0.5, 0.01) var shot_pitch_variation: float = 0.05
@export_range(0.0, 0.5, 0.01) var shot_volume_variation: float = 0.1
@export_subgroup("Tail layer")
@export var use_tail: bool = false
@export var tail_clips: Array[AudioStream] = []
@export_range(0.0, 1.0, 0.01) var tail_volume: float = 0.5
@export_subgroup("Thump layer")
@export var use_thump: bool = false
@export var thump_clips: Array[AudioStream] = []
@export_range(0.0, 1.0, 0.01) var thump_volume: float = 0.2
@export_group("Reload")
@export_range(0.0, 1.0, 0.01) var reload_volume: float = 0.8
@export var reload_parts: Array[ReloadSoundPart] = []
