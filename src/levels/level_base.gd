class_name LevelBase
extends Node3D
## One level: geometry with generated trimesh collision, a runtime-baked navigation mesh, a player
## start, `spawn_point` / `firing_spot` markers and a LevelExit. Loaded into the Game scene by LevelRotation.
## Opened on its own (for example from the editor) it wraps itself in the game scene at this level.

const GAME_SCENE_PATH: String = "res://src/run/game.tscn"
const GROUP_COLLISION: StringName = &"generated_collision"
## Push data per prop kind (matched by PushablePropData.scene_token against the prop scene path).
const PUSH_DATA_PATHS: Array[String] = [
	"res://assets/data/levels/table_push.tres",
	"res://assets/data/levels/loose_prop_push.tres",
	"res://assets/data/levels/railing_push.tres",
]
## Visual-only props (bottles, bowls) in this group ride on the nearest PushableProp table once the level is built.
const GROUP_TABLE_DECOR: StringName = &"table_decor"

## Id used by LevelRotation (matches `level_ids` in levels.tres).
@export var level_id: StringName = &""
@export var nav_region: NavigationRegion3D
@export var player_start: Marker3D
@export var level_exit: LevelExit
## The level FBX meshes have inverted winding (story 009 made their materials double-sided). The Compatibility
## renderer (web) still culls those faces in the shadow pass, so roofs and walls leak light and cast blocky
## shadows; casting double-sided shadows from every level mesh fixes it on all renderers.
@export var double_sided_shadows: bool = true


func _ready() -> void:
	if get_tree().get_first_node_in_group(&"game") == null:
		_launch_in_game.call_deferred()
		return
	_convert_pushables()
	_attach_table_decor()
	if double_sided_shadows:
		for mesh: Node in find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = mesh as MeshInstance3D
			if instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
				instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	for node: Node in nav_region.get_children():
		if node.is_in_group(GROUP_COLLISION):
			for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
				if (mesh as MeshInstance3D).mesh == null:
					continue
				if not _is_under_pushable(mesh):
					(mesh as MeshInstance3D).create_trimesh_collision()
	nav_region.bake_navigation_mesh(false)
	var polygons: int = nav_region.navigation_mesh.get_polygon_count()
	print("LEVEL %s nav polygons=%d" % [level_id, polygons])
	if polygons == 0:
		push_error("LevelBase %s: navigation bake produced no polygons" % level_id)


## World transform the player is placed at when the level loads (position + yaw).
func get_player_start_transform() -> Transform3D:
	return player_start.global_transform


## The level's exit trigger.
func get_exit() -> LevelExit:
	return level_exit


## The level's pushable props (tables, bins).
func get_pushable_props() -> Array[PushableProp]:
	var result: Array[PushableProp] = []
	for prop: PushableProp in PushableProp.get_all(get_tree()):
		if is_ancestor_of(prop):
			result.append(prop)
	return result


func _is_under_pushable(node: Node) -> bool:
	var parent: Node = node.get_parent()
	while parent != null and parent != self:
		if parent is PushableProp:
			return true
		parent = parent.get_parent()
	return false


## Wraps every imported prop scene whose path matches a PushablePropData token in a PushableProp
## (kinematic box collider from the mesh bounds). They are not static colliders, so the navmesh bake skips them.
func _convert_pushables() -> void:
	var specs: Array[PushablePropData] = []
	for path: String in PUSH_DATA_PATHS:
		var spec: PushablePropData = load(path) as PushablePropData
		if spec == null:
			push_error("LevelBase %s: push data %s did not load" % [level_id, path])
			continue
		specs.append(spec)
	var found: Array[Node3D] = []
	for node: Node in nav_region.find_children("*", "Node3D", true, false):
		if node.scene_file_path != "":
			found.append(node as Node3D)
	for source: Node3D in found:
		if _is_under_pushable(source):
			continue
		for spec: PushablePropData in specs:
			if source.scene_file_path.contains(spec.scene_token):
				_wrap_pushable(source, spec)
				break


func _wrap_pushable(source: Node3D, spec: PushablePropData) -> void:
	var world: Transform3D = source.global_transform
	var inverse: Transform3D = world.affine_inverse()
	var box: AABB
	var first: bool = true
	var meshes: Array[Node] = source.find_children("*", "MeshInstance3D", true, false)
	if source is MeshInstance3D:
		meshes.append(source)
	for mesh: Node in meshes:
		if (mesh as MeshInstance3D).mesh == null:
			continue
		var part: AABB = (inverse * (mesh as MeshInstance3D).global_transform) * (mesh as MeshInstance3D).mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	if first:
		return
	var center: Vector3 = box.get_center()
	var pivot: Vector3 = Vector3(center.x, 0.0, center.z)
	var parent: Node = source.get_parent()
	var prop: PushableProp = PushableProp.new()
	prop.name = source.name
	parent.remove_child(source)
	parent.add_child(prop)
	prop.global_transform = Transform3D(world.basis, world * pivot)
	prop.add_child(source)
	source.transform = Transform3D(Basis.IDENTITY, -pivot)
	prop.configure(spec, AABB(Vector3(-box.size.x * 0.5, box.position.y, -box.size.z * 0.5), box.size))


func _launch_in_game() -> void:
	var game: Node = (load(GAME_SCENE_PATH) as PackedScene).instantiate()
	game.set(&"start_level_id", level_id)
	var tree: SceneTree = get_tree()
	tree.root.add_child(game)
	tree.current_scene = game
	queue_free()


## Reparents every `table_decor` node (bottles, bowls: visual only, no collider) under the PushableProp
## nearest to it on the floor plane, keeping its world transform, so it moves with the table.
func _attach_table_decor() -> void:
	var tables: Array[PushableProp] = get_pushable_props()
	if tables.is_empty():
		return
	for node: Node in get_tree().get_nodes_in_group(GROUP_TABLE_DECOR):
		if not is_ancestor_of(node):
			continue
		var decor: Node3D = node as Node3D
		var best: PushableProp = null
		var best_distance: float = INF
		for table: PushableProp in tables:
			var offset: Vector3 = table.global_position - decor.global_position
			var distance: float = Vector2(offset.x, offset.z).length_squared()
			if distance < best_distance:
				best_distance = distance
				best = table
		decor.reparent(best, true)
