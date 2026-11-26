class_name SpawnDoorData
extends Resource
## Timings of an enemy spawn door (canteen): which clips of the door FBX to play, when in the opening clip the
## first enemy of a group comes through, and how long the door stays open after the group's last member.
## The values live in assets/data/levels/spawn_door.tres. Used by SpawnDoor and WaveSpawner.

## Clip in each door FBX's AnimationPlayer that rattles the closed leaf, then bursts it open (1.5 s).
@export var open_animation: StringName = &"door_opening"
## Clip that swings the leaf back to the closed rest pose (1.0 s).
@export var close_animation: StringName = &"door_closing"
## Seconds into open_animation at which the group's first enemy spawns: the burst (the rattle ends at 1.04 s).
## The spawner starts the door this long before the group's first spawn.
@export var burst_time: float = 1.05
## Seconds after the group's last member spawns before the door starts closing.
@export var close_delay: float = 1.5
