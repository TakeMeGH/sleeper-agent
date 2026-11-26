class_name TargetDummy
extends StaticBody3D
## Test target: exposes take_hit(), flashes, and shows its running damage total.

@export var idle_color: Color = Color(0.3, 0.6, 0.9)
@export var hit_color: Color = Color(1.0, 0.2, 0.2)
@export var flash_time: float = 0.1

## Health; 0 = invulnerable (never dies). When it reaches zero the dummy dies (is_dead) and is removed.
@export var max_health: float = 0.0
## Seconds a dead dummy stays before it is removed.
@export var death_linger_seconds: float = 0.3

var total_damage: float = 0.0
var _dead: bool = false
var hit_count: int = 0

var _material: StandardMaterial3D = StandardMaterial3D.new()

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $Label


func _ready() -> void:
	_material.albedo_color = idle_color
	mesh.material_override = _material
	_update_label()


## Called by guns on a hit. direction.length() is the pushback strength.
func take_hit(damage: float, direction: Vector3) -> void:
	if _dead:
		return
	total_damage += damage
	hit_count += 1
	print("%s hit: damage %.1f pushback %.1f (total %.1f)" % [name, damage, direction.length(), total_damage])
	_update_label()
	if max_health > 0.0 and total_damage >= max_health:
		_dead = true
		await get_tree().create_timer(death_linger_seconds).timeout
		if is_instance_valid(self):
			queue_free()
		return
	_material.albedo_color = hit_color
	await get_tree().create_timer(flash_time).timeout
	if is_instance_valid(self):
		_material.albedo_color = idle_color


## True once the dummy has taken max_health damage (never for max_health 0).
func is_dead() -> bool:
	return _dead


func _update_label() -> void:
	label.text = "hits %d  dmg %.0f" % [hit_count, total_damage]
