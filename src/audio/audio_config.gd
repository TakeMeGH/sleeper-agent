class_name AudioConfig
extends Resource
## All audio tuning: clip lists, volumes (linear 0-1), pitch ranges, distances, fades and thresholds.
## Times are real seconds; distances metres; speeds m/s. Data file: assets/data/audio/audio_config.tres.

@export_group("Buses")
@export var sfx_bus: StringName = &"SFX"
@export var music_bus: StringName = &"Music"

@export_group("Guns")
@export var guns: Array[GunAudioData] = []
@export var dry_click_clips: Array[AudioStream] = []
@export_range(0.0, 1.0, 0.01) var dry_click_volume: float = 0.7
## Voices for 2D sounds other than the gun rings (substance taken and the like).
@export var voices_2d: int = 12
## Gun voice rings (Unity GunFeedback): one ring per kind, shared by all guns; a full ring cuts its oldest sound.
## Sizes are the largest value of each key among Unity's weapon feel files.
@export var shot_voices: int = 15
@export var tail_voices: int = 2
@export var thump_voices: int = 2
@export var reload_voices: int = 3
@export var dry_click_voices: int = 2

@export_group("Impacts")
@export var voice_cap_3d: int = 8
@export var min_distance: float = 2.0
@export var max_distance: float = 40.0
@export var flesh_per_shot: int = 1
@export var kill_per_shot: int = 1
@export var surface_sounds_per_shot: int = 2
@export var flesh_clips: Array[AudioStream] = []
@export_range(0.0, 1.0, 0.01) var flesh_volume: float = 0.8
@export_range(0.0, 0.5, 0.01) var flesh_pitch_variation: float = 0.08
@export var kill_clips: Array[AudioStream] = []
@export_range(0.0, 1.0, 0.01) var kill_volume: float = 0.9
@export_range(0.0, 0.5, 0.01) var kill_pitch_variation: float = 0.05
@export var surface_clips: Array[AudioStream] = []
@export_range(0.0, 1.0, 0.01) var surface_volume: float = 0.5
@export_range(0.0, 0.5, 0.01) var surface_pitch_variation: float = 0.1

@export_group("Substances")
@export var consume_fade_in_seconds: float = 0.05
@export var consume_fade_out_seconds: float = 0.25
@export var consume_sounds: Array[ConsumeSoundData] = []
@export var substance_taken_clip: AudioStream
@export_range(0.0, 1.0, 0.01) var substance_taken_volume: float = 0.8

@export_group("Heart rate")
@export var heart_low_clip: AudioStream
@export var heart_high_clip: AudioStream
@export_range(0.0, 1.0, 0.01) var heart_low_max_volume: float = 0.8
@export_range(0.0, 1.0, 0.01) var heart_high_max_volume: float = 0.8
## Seconds for the loop volume to follow the rate.
@export var heart_response_seconds: float = 0.6
## Rate where the low loop is still silent, and where it is at full volume.
@export var heart_low_silent_at: float = 60.0
@export var heart_low_full_at: float = 10.0
## Rate where the high loop is still silent, and where it is at full volume.
@export var heart_high_silent_at: float = 100.0
@export var heart_high_full_at: float = 190.0
@export var heart_curve_exponent: float = 1.0
## Fade-out length when the run ends.
@export var heart_end_fade_seconds: float = 0.8

@export_group("Footsteps and landing")
@export var footstep_clip: AudioStream
@export_range(0.0, 1.0, 0.01) var footstep_volume: float = 0.6
@export var footstep_min_speed: float = 1.0
@export var footstep_fade_in_seconds: float = 0.08
@export var footstep_fade_out_seconds: float = 0.15
@export var landing_clip: AudioStream
@export_range(0.0, 1.0, 0.01) var landing_volume: float = 0.8
## A fall at least this high (metres) plays the landing sound; a dive landing always does.
@export var min_fall_height: float = 1.0

@export_group("Music")
@export var combat_clip: AudioStream
@export_range(0.0, 1.0, 0.01) var combat_volume: float = 0.5
@export var boss_clip: AudioStream
@export_range(0.0, 1.0, 0.01) var boss_volume: float = 0.5
@export var crossfade_seconds: float = 2.0
## Fade-in of the combat loop at the start of the run.
@export var music_start_fade_seconds: float = 0.5
## How often the music director looks for a live boss (real seconds).
@export var boss_poll_seconds: float = 0.25


## Sound data for a gun id, or null if none.
func get_gun_audio(gun_id: StringName) -> GunAudioData:
	for entry: GunAudioData in guns:
		if entry.gun_id == gun_id:
			return entry
	return null


## Consume sound for a substance kind, or null if none.
func get_consume_sound(kind: StringName) -> ConsumeSoundData:
	for entry: ConsumeSoundData in consume_sounds:
		if entry.substance_id == kind:
			return entry
	return null
