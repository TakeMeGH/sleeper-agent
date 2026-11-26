class_name HitArcsDebug
extends Node
## Debug only (capture scenes): injects hits through PlayerController.take_hit from positions given
## relative to the player (player-local: -z = ahead, -x = left, +z = behind), again every few frames
## so the arcs stay visible for a screenshot. Damage 0 leaves the heart rate alone.

@export var player: PlayerController
## Player-local source offsets.
@export var offsets: PackedVector3Array = PackedVector3Array()
## Physics frame of the first injection.
@export var first_frame: int = 5
## Re-inject every this many physics frames (0 = once).
@export var repeat_every_frames: int = 20

var _frames: int = 0


func _physics_process(_delta: float) -> void:
	_frames += 1
	if player == null or _frames < first_frame:
		return
	var since: int = _frames - first_frame
	if since == 0 or (repeat_every_frames > 0 and since % repeat_every_frames == 0):
		for offset: Vector3 in offsets:
			player.take_hit(0.0, Vector3.ZERO, player.to_global(offset))
