class_name DangerCountdownLabel
extends Label
## Small number under the crosshair: seconds left (5..1) on the pass-out / heart-attack countdown.
## Uses the status bar countdown colour (HudData.highlight_color). Hidden when the countdown stops
## and after the run ends. The countdown itself is real-time (HeartRate), so no clock is needed here.

@export var data: HitArcsData
## Status bar whose HudData supplies the colour.
@export var hud: Hud
@export var heart: HeartRate
## The number sits below this control's rect centre.
@export var crosshair: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	visible = false
	if data != null:
		add_theme_font_size_override(&"font_size", data.countdown_font_size)
		add_theme_constant_override(&"outline_size", data.countdown_outline_size)
		add_theme_color_override(&"font_outline_color", data.countdown_outline_color)
	if hud != null and hud.data != null:
		add_theme_color_override(&"font_color", hud.data.highlight_color)
	if heart != null:
		heart.danger_countdown_changed.connect(on_countdown_changed)
		heart.run_ended.connect(on_run_ended)


func _process(_delta: float) -> void:
	if visible:
		_reposition()


## Signal receiver for HeartRate.danger_countdown_changed (0.0 / empty reason = countdown stopped).
func on_countdown_changed(seconds_left: float, reason: StringName) -> void:
	if (heart != null and heart.has_ended()) or seconds_left <= 0.0 or reason == &"":
		_hide_number()
		return
	text = str(ceili(seconds_left))
	reset_size()
	visible = true
	_reposition()


## Run end: the number hides.
func on_run_ended(_reason: StringName) -> void:
	_hide_number()


## True while the number is showing.
func is_shown() -> bool:
	return visible


## The number currently shown, or "" when hidden.
func get_shown_text() -> String:
	return text if visible else ""


func _hide_number() -> void:
	visible = false
	text = ""


func _reposition() -> void:
	var offset_y: float = data.countdown_offset_y if data != null else 0.0
	var centre: Vector2 = get_parent_area_size() * 0.5
	if crosshair != null:
		centre = crosshair.get_global_rect().get_center()
	global_position = centre + Vector2(-size.x * 0.5, offset_y - size.y * 0.5)
