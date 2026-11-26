class_name ViewmodelHandKey
extends Resource
## One key of a free-hand timeline (a gun's reload or finish motion), ported from the Unity
## arms_reload_keys / arms_finish_keys. Gun-pivot space, Godot axes (-Z forward), pouch keys resolved.

## Props the hand can hold from this key on.
enum Prop { NONE = 0, MAGAZINE = 1, SHELL = 2, SUBSTANCE = 3 }

## Position on the timeline, 0 to 1.
@export var time: float = 0.0
## Wrist position, metres, gun-pivot space.
@export var position: Vector3 = Vector3.ZERO
## Hand frame rotation, degrees (YXZ Euler; identity = fingers forward, palm down).
@export var rotation_degrees: Vector3 = Vector3.ZERO
## Finger curl, degrees: x index, y middle/ring/pinky, z thumb.
@export var curl: Vector3 = Vector3.ZERO
## What the hand holds from this key on.
@export var prop: Prop = Prop.NONE
