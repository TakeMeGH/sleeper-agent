class_name Crosshair
extends Control
## Screen-centre crosshair with a hit marker (white X) and a distinct, larger red kill marker.
## Drawn with _draw; Hud re-centres it on the world view through its anchors.

## GunFeel that reports hits (its data holds the colours and sizes).
@export var gun_feel: GunFeel

var _hit_left: float = 0.0
var _kill_left: float = 0.0
var _clock: RealClock = RealClock.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(&"crosshair")
	if gun_feel != null:
		gun_feel.hit_confirmed.connect(_on_hit_confirmed)


func _process(delta: float) -> void:
	# Real time: a hitstop must not make the marker last longer. Stepped every frame to keep the clock fresh.
	var real_delta: float = _clock.step(delta)
	if _hit_left > 0.0 or _kill_left > 0.0:
		_hit_left = maxf(_hit_left - real_delta, 0.0)
		_kill_left = maxf(_kill_left - real_delta, 0.0)
		queue_redraw()


## Flashes the hit marker (or the kill marker when killed is true).
func show_marker(killed: bool) -> void:
	if gun_feel == null or gun_feel.data == null:
		return
	if killed:
		_kill_left = gun_feel.data.kill_marker_seconds
	else:
		_hit_left = gun_feel.data.hit_marker_seconds
	queue_redraw()


## Which marker is showing: &"kill", &"hit" or &"none".
func get_marker_state() -> StringName:
	if _kill_left > 0.0:
		return &"kill"
	if _hit_left > 0.0:
		return &"hit"
	return &"none"


func _draw() -> void:
	if gun_feel == null or gun_feel.data == null:
		return
	var d: GunFeelSet = gun_feel.data
	var c: Vector2 = size * 0.5
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(c + direction * d.crosshair_gap, c + direction * (d.crosshair_gap + d.crosshair_length),
				d.crosshair_color, d.crosshair_thickness)
	draw_circle(c, d.crosshair_thickness * 0.5, d.crosshair_color)
	if _kill_left > 0.0:
		_draw_x(c, d.kill_marker_gap, d.kill_marker_length, d.kill_marker_color, d.marker_thickness)
	elif _hit_left > 0.0:
		_draw_x(c, d.hit_marker_gap, d.hit_marker_length, d.hit_marker_color, d.marker_thickness)


func _draw_x(c: Vector2, gap: float, length: float, color: Color, thickness: float) -> void:
	for direction: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var unit: Vector2 = direction.normalized()
		draw_line(c + unit * gap, c + unit * (gap + length), color, thickness)


func _on_hit_confirmed(killed: bool) -> void:
	show_marker(killed)
