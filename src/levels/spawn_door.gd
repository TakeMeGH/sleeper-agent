class_name SpawnDoor
extends Node3D
## An enemy door at a spawn point: one or more door FBX instances (the canteen's door_a / door_b pair), each with
## its own AnimationPlayer. Closed at rest; the WaveSpawner calls open() burst_time seconds before a group's first
## enemy spawns at spawn_point, and close_after() when the group's last member has spawned. Visual only: the leaves
## have no collider, so enemies and the navmesh pass through the doorway.
## Unity: WaveSpawner.GroupSpawning ("a door at that point can open on it"), LevelLayout spawn points at the doors.

const GROUP: StringName = &"spawn_door"

enum State { CLOSED, OPENING, OPEN, CLOSING }

@export var data: SpawnDoorData
## The spawn_point marker this door belongs to.
@export var spawn_point: Node3D
## Door FBX instances whose AnimationPlayers play the clips (both leaves of the pair).
@export var doors: Array[Node3D] = []

var _state: State = State.CLOSED
var _players: Array[AnimationPlayer] = []
## Bumped by every open(), so a close_after() timer from an earlier group does not shut a door a later group uses.
var _open_token: int = 0


func _ready() -> void:
	add_to_group(GROUP)
	for door: Node3D in doors:
		if door == null:
			continue
		for node: Node in door.find_children("*", "AnimationPlayer", true, false):
			_players.append(node as AnimationPlayer)
	if _players.is_empty():
		push_warning("SpawnDoor %s: no AnimationPlayer under its doors" % name)
	else:
		_players[0].animation_finished.connect(_on_animation_finished)


## The door at a spawn point marker, or null when that point has none.
static func find_for_point(tree: SceneTree, point: Node3D) -> SpawnDoor:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var door: SpawnDoor = node as SpawnDoor
		if door != null and door.spawn_point == point:
			return door
	return null


## Seconds between open() and the moment the leaves burst open (when the first enemy should come through).
func get_open_lead() -> float:
	return data.burst_time if data != null else 0.0


## Plays the opening clip from the start on every leaf. A door already opening or open stays as it is.
func open() -> void:
	_open_token += 1
	if _state == State.OPENING or _state == State.OPEN:
		return
	_play(data.open_animation)
	_state = State.OPENING


## Plays the closing clip, unless the door is already closed or closing.
func close() -> void:
	if _state == State.CLOSED or _state == State.CLOSING:
		return
	_play(data.close_animation)
	_state = State.CLOSING


## Closes the door after data.close_delay seconds (game time), unless open() is called again before then.
func close_after_delay() -> void:
	var token: int = _open_token
	await get_tree().create_timer(data.close_delay, false).timeout
	if is_inside_tree() and token == _open_token:
		close()


func get_state() -> State:
	return _state


## CLOSED / OPENING / OPEN / CLOSING, for logs.
func get_state_name() -> String:
	return State.keys()[_state]


func _play(animation: StringName) -> void:
	for player: AnimationPlayer in _players:
		if player.has_animation(animation):
			player.play(animation)
			player.seek(0.0, true)
		else:
			push_warning("SpawnDoor %s: %s has no clip %s" % [name, player.get_path(), animation])


func _on_animation_finished(animation: StringName) -> void:
	if animation == data.open_animation and _state == State.OPENING:
		_state = State.OPEN
	elif animation == data.close_animation and _state == State.CLOSING:
		_state = State.CLOSED
