class_name HintBox
extends CanvasLayer
## Draws the tutorial hint: one line centred just above the status bar, a pulsing box (amber, red for
## danger) around each HUD part the hint explains, and the small skip line with its hold-progress bar.
## Display only: TutorialHost tells it what to show and ticks it with real time.

var _data: TutorialData
var _hud: Hud
var _canvas: Control
var _column: VBoxContainer
var _hint_label: Label
var _skip_label: Label
var _bar_holder: Control
var _bar_back: ColorRect
var _bar_fill: ColorRect

var _targets: Array[StringName] = []
var _danger: bool = false
var _shown: bool = false
var _skip_progress: float = 0.0
var _time: float = 0.0
var _applied_scale: float = -1.0


## Builds the nodes. Call once after adding to the tree.
func setup(data: TutorialData) -> void:
	_data = data
	layer = data.canvas_layer
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_boxes)
	add_child(_canvas)
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.alignment = BoxContainer.ALIGNMENT_END
	_canvas.add_child(_column)
	_hint_label = _make_label(data.text_color)
	_column.add_child(_hint_label)
	_skip_label = _make_label(data.skip_text_color)
	_column.add_child(_skip_label)
	_bar_holder = Control.new()
	_bar_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_column.add_child(_bar_holder)
	_bar_back = ColorRect.new()
	_bar_back.color = data.skip_bar_back_color
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_holder.add_child(_bar_back)
	_bar_fill = ColorRect.new()
	_bar_fill.color = data.skip_bar_fill_color
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_holder.add_child(_bar_fill)
	_canvas.visible = false


## Points the box at the HUD whose parts it outlines (null = no boxes, text only).
func set_hud(hud: Hud) -> void:
	_hud = hud


## Shows a hint line with boxes around the target HUD parts.
func show_hint(text: String, skip_text: String, targets: Array[StringName], danger: bool) -> void:
	_hint_label.text = text
	_skip_label.text = skip_text
	_targets = targets.duplicate()
	_danger = danger
	_shown = true
	_skip_progress = 0.0
	_applied_scale = -1.0
	_canvas.visible = true
	_layout()


## Hides the hint, the boxes and the skip line.
func hide_hint() -> void:
	_shown = false
	_canvas.visible = false


## Skip-hold progress 0-1 shown on the small bar.
func set_skip_progress(progress: float) -> void:
	_skip_progress = clampf(progress, 0.0, 1.0)


## True while a hint is on screen.
func is_hint_visible() -> bool:
	return _shown


## The hint line currently shown.
func get_hint_text() -> String:
	return _hint_label.text if _hint_label != null else ""


## Ids of the HUD parts currently boxed.
func get_targets() -> Array[StringName]:
	return _targets


## Whether the current box is the red danger box.
func is_danger() -> bool:
	return _danger


## Current pulse alpha of the box (0.35-1.0 by data).
func get_pulse_alpha() -> float:
	return lerpf(_data.pulse_min_alpha, 1.0, 0.5 + 0.5 * sin(TAU * _data.pulse_hz * _time))


## Global rect of the hint text block (probe: must stay clear of the danger countdown).
func get_text_rect() -> Rect2:
	return _column.get_global_rect() if _column != null else Rect2()


## Advances the pulse by real seconds and redraws.
func tick(real_delta: float) -> void:
	if not _shown or _data == null:
		return
	_time += real_delta
	_layout()
	_bar_fill.size.x = _bar_back.size.x * _skip_progress
	_canvas.queue_redraw()


func _make_label(color: Color) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", _data.outline_color)
	return label


func _ui_scale() -> float:
	return get_viewport().get_visible_rect().size.y / _data.reference_height


func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var ui: float = _ui_scale()
	if not is_equal_approx(ui, _applied_scale):
		_applied_scale = ui
		_apply_font(_hint_label, _data.font_size, ui)
		_apply_font(_skip_label, _data.skip_font_size, ui)
		_column.add_theme_constant_override(&"separation", roundi(_data.skip_gap * ui))
		_bar_holder.custom_minimum_size = Vector2(_data.skip_bar_width * ui, _data.skip_bar_height * ui)
		_bar_back.size = _bar_holder.custom_minimum_size
		_bar_fill.size = Vector2(0.0, _bar_holder.custom_minimum_size.y)
	var width: float = minf(_data.text_max_width * ui, view.x * 0.95)
	_column.size = Vector2(width, 0.0)
	var height: float = _column.get_combined_minimum_size().y
	_column.size = Vector2(width, height)
	var bottom: float = view.y
	if is_instance_valid(_hud):
		var bar: Rect2 = _hud.get_tutorial_target_rect(&"status_bar")
		if bar.size != Vector2.ZERO:
			bottom = bar.position.y
	_column.position = Vector2((view.x - width) * 0.5, bottom - _data.text_bottom_margin * ui - height)


func _apply_font(label: Label, reference_size: int, ui: float) -> void:
	var px: int = maxi(roundi(float(reference_size) * ui), 1)
	label.add_theme_font_size_override(&"font_size", px)
	label.add_theme_constant_override(&"outline_size", maxi(roundi(float(px) * _data.outline_width * _data.outline_scale), 1))


func _draw_boxes() -> void:
	if not _shown or not is_instance_valid(_hud):
		return
	var ui: float = _ui_scale()
	var color: Color = _data.danger_box_color if _danger else _data.box_color
	color.a *= get_pulse_alpha()
	for id: StringName in _targets:
		var rect: Rect2 = _hud.get_tutorial_target_rect(id)
		if rect.size == Vector2.ZERO:
			continue
		_canvas.draw_rect(rect.grow(_data.box_padding * ui), color, false, maxf(_data.box_thickness * ui, 1.0))
