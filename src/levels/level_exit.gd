class_name LevelExit
extends Area3D
## Level exit trigger. Closed (red, not triggerable) until open() is called; open it shows a green
## light and walking in asks the game to travel to the next level.

signal opened
signal player_entered

## Trigger box size (Unity: 3 x 3 x 3, centred 1.5 m up).
@export var trigger_size: Vector3 = Vector3(3.0, 3.0, 3.0)
@export var closed_color: Color = Color(0.7, 0.1, 0.08, 1.0)
@export var open_color: Color = Color(0.15, 1.0, 0.3, 1.0)
@export var closed_energy: float = 0.4
@export var open_energy: float = 2.5
@export var light_range: float = 8.0

var _open: bool = false
var _material: StandardMaterial3D
var _light: OmniLight3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = false
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = trigger_size
	shape.shape = box
	shape.position = Vector3(0.0, trigger_size.y * 0.5, 0.0)
	add_child(shape)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.emission_enabled = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = trigger_size
	mesh.mesh = box_mesh
	mesh.material_override = _material
	mesh.position = shape.position
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	_light = OmniLight3D.new()
	_light.omni_range = light_range
	_light.position = Vector3(0.0, trigger_size.y * 0.6, 0.0)
	add_child(_light)
	body_entered.connect(_on_body_entered)
	_apply_look()


## Opens the exit: green light, walking in now triggers travel.
func open() -> void:
	if _open:
		return
	_open = true
	set_deferred(&"monitoring", true)
	_apply_look()
	opened.emit()


## Closes the exit again (used when a level loads).
func close() -> void:
	_open = false
	set_deferred(&"monitoring", false)
	_apply_look()


## True once the exit is open and triggerable.
func is_exit_open() -> bool:
	return _open


func _apply_look() -> void:
	if _material == null:
		return
	var color: Color = open_color if _open else closed_color
	_material.albedo_color = Color(color, 0.22 if _open else 0.12)
	_material.emission = color
	_material.emission_energy_multiplier = open_energy if _open else closed_energy
	_light.light_color = color
	_light.light_energy = open_energy if _open else closed_energy


func _on_body_entered(body: Node3D) -> void:
	if not _open or not body.is_in_group(&"player"):
		return
	player_entered.emit()
	var game: Node = get_tree().get_first_node_in_group(&"game")
	if game != null and game.has_method(&"travel_to_next_level"):
		game.call_deferred(&"travel_to_next_level")
