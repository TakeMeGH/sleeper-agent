extends Node
## Test-scene helper (capture only): places one pickup per kind on the floor a few physics frames after the
## level loads, so the drop look can be captured next to the player.

## Pickup tuning (assets/data/drops/drops.tres).
@export var drop_data: DropData
## Kinds to place, one per position (same index).
@export var kinds: Array[StringName] = [&"smg", &"coffee", &"cigarette"]
## World positions over the floor (the pickup snaps down to the floor and hovers).
@export var positions: PackedVector3Array = PackedVector3Array()
## Physics frames to wait for the level before placing.
@export var wait_frames: int = 10
## Starting age of every pickup in seconds (to capture a later moment, for example the blink).
@export var start_age: float = 0.0
## Hides the first-person arms and gun so they do not cover the pickups.
@export var hide_viewmodel: bool = true
## Head pitch in degrees (negative looks down).
@export var head_pitch_degrees: float = -20.0


func _ready() -> void:
	for i: int in wait_frames:
		await get_tree().physics_frame
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player != null:
		var head: Node3D = player.get_node_or_null("Head") as Node3D
		if head != null:
			head.rotation_degrees.x = head_pitch_degrees
		var viewmodel: Node3D = player.get_node_or_null("Head/Camera3D/Viewmodel") as Node3D
		if viewmodel != null and hide_viewmodel:
			viewmodel.visible = false
	var host: Node = get_parent()
	for i: int in mini(kinds.size(), positions.size()):
		var pickup: DropPickup = DropPickup.spawn(host, kinds[i], positions[i], drop_data)
		pickup.set(&"_age", start_age)
		print("TEST_DROPS placed %s rest=%s" % [kinds[i], pickup.get_rest_position()])
