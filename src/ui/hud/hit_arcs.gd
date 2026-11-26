class_name HitArcs
extends Control
## Red arcs on a ring around the crosshair that point (in the horizontal plane) at where a hit came from.
## Front = top of the ring, right = right, behind = bottom. Arcs store the world source position and are
## re-aimed every frame, so they follow the player's turn. Runs in real time (RealClock) and keeps
## processing while the tree is paused at run end so showing arcs finish fading.

@export var data: HitArcsData
## Player whose hit_taken signal feeds the arcs; its yaw is the reference forward.
@export var player: PlayerController
## Used for the reference forward only when no player is set.
@export var camera: Camera3D
## Run end stops new arcs.
@export var heart: HeartRate
## The ring is centred on this control's rect centre.
@export var crosshair: Control

# Each arc: {angle_degrees: float, alpha: float, source: Vector3, age: float}
var _arcs: Array[Dictionary] = []
var _ended: bool = false
var _clock: RealClock = RealClock.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if player != null:
		player.hit_taken.connect(on_hit_taken)
	if heart != null:
		heart.run_ended.connect(on_run_ended)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Ages the arcs by real seconds, drops finished ones and re-aims the rest at their sources.
func tick(real_delta: float) -> void:
	if data == null:
		return
	for i: int in range(_arcs.size() - 1, -1, -1):
		var arc: Dictionary = _arcs[i]
		arc["age"] = float(arc["age"]) + real_delta
		if float(arc["age"]) >= data.arc_hold_seconds + data.arc_fade_seconds:
			_arcs.remove_at(i)
			continue
		arc["alpha"] = _alpha_for_age(float(arc["age"]))
		arc["angle_degrees"] = get_arc_angle_for(arc["source"] as Vector3)
	queue_redraw()


## Signal receiver for PlayerController.hit_taken. A null source (no attacker position) is ignored silently.
func on_hit_taken(_damage: float, source_position: Variant) -> void:
	if source_position is Vector3:
		add_hit(source_position as Vector3)


## Shows (or refreshes) an arc pointing at a world position. Ignored after the run has ended.
func add_hit(source_position: Vector3) -> void:
	if _ended or data == null:
		return
	var angle: float = get_arc_angle_for(source_position)
	for arc: Dictionary in _arcs:
		if absf(wrapf(angle - float(arc["angle_degrees"]), -180.0, 180.0)) <= data.merge_angle:
			arc["age"] = 0.0
			arc["alpha"] = 1.0
			arc["source"] = source_position
			arc["angle_degrees"] = angle
			queue_redraw()
			return
	if _arcs.size() >= maxi(data.arc_pool_size, 1):
		var oldest: int = 0
		for i: int in _arcs.size():
			if float(_arcs[i]["age"]) > float(_arcs[oldest]["age"]):
				oldest = i
		_arcs.remove_at(oldest)
	_arcs.append({"angle_degrees": angle, "alpha": 1.0, "source": source_position, "age": 0.0})
	queue_redraw()


## Ring angle in degrees for a world position: 0 = front, 90 = right, -90 = left, +-180 = behind.
## Horizontal plane only. Returns 0.0 when there is no reference node or the source is directly above/below.
func get_arc_angle_for(source: Vector3) -> float:
	var reference: Node3D = player if player != null else camera
	if reference == null:
		return 0.0
	var forward: Vector3 = -reference.global_basis.z
	forward.y = 0.0
	var to_source: Vector3 = source - reference.global_position
	to_source.y = 0.0
	if forward.length_squared() < 0.000001 or to_source.length_squared() < 0.000001:
		return 0.0
	return rad_to_deg(-forward.signed_angle_to(to_source, Vector3.UP))


## Arcs now showing, as copies: {angle_degrees, alpha, source, age}.
func get_active_arcs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for arc: Dictionary in _arcs:
		result.append(arc.duplicate())
	return result


## Configured pool size (most arcs at once).
func get_pool_size() -> int:
	return maxi(data.arc_pool_size, 1) if data != null else 0


## Run end: no new arcs; the showing ones keep fading.
func on_run_ended(_reason: StringName) -> void:
	_ended = true


func _alpha_for_age(age: float) -> float:
	if age <= data.arc_hold_seconds:
		return 1.0
	return clampf(1.0 - (age - data.arc_hold_seconds) / maxf(data.arc_fade_seconds, 0.001), 0.0, 1.0)


func _draw() -> void:
	if data == null or _arcs.is_empty():
		return
	var centre: Vector2 = size * 0.5
	if crosshair != null:
		centre = crosshair.get_global_rect().get_center() - global_position
	var half_span: float = deg_to_rad(data.arc_span_degrees) * 0.5
	for arc: Dictionary in _arcs:
		var alpha: float = float(arc["alpha"])
		# Screen angle 0 is +x and grows clockwise (y down); ring angle 0 (front) is up, so subtract 90.
		var middle: float = deg_to_rad(float(arc["angle_degrees"]) - 90.0)
		var outline: Color = data.arc_outline_color
		outline.a *= alpha
		var fill: Color = data.arc_color
		fill.a *= alpha
		draw_arc(centre, data.ring_radius, middle - half_span, middle + half_span, data.arc_point_count,
				outline, data.arc_thickness + data.arc_outline_width * 2.0, true)
		draw_arc(centre, data.ring_radius, middle - half_span, middle + half_span, data.arc_point_count,
				fill, data.arc_thickness, true)
