class_name ReloadSoundPart
extends Resource
## One sound inside a reload (magazine out, magazine in, rack, shell...), with what triggers it.

## What plays the part: a point in the reload, each loaded shell, or the reload's finish (Unity ReloadFinished:
## the rack or pump plays only for a reload that completed, after any magazine-in).
enum Trigger { FRACTION, SHELL, FINISH }

## Event id suffix, for example &"mag_out"; the played event is "reload_<gun>_<event_id>".
@export var event_id: StringName = &""
@export var trigger: Trigger = Trigger.FRACTION
## Point in the reload (0 = start, 1 = end) where the sound plays (trigger FRACTION only).
@export_range(0.0, 1.0, 0.01) var fraction: float = 0.0
## Takes rotated without repeating back to back.
@export var clips: Array[AudioStream] = []
## Volume override (linear); negative uses the gun's reload_volume (shell inserts use Unity shell_load_volume).
@export var volume: float = -1.0
