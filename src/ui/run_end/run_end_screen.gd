class_name RunEndScreen
extends CanvasLayer
## Results screen shown over the frozen game when the run ends: how it ended, time survived, wave, kills,
## session best, and a PLAY AGAIN button (or the `restart_run` action). Runs in PROCESS_MODE_ALWAYS so it
## works while the tree is paused.

## Emitted the moment the run ends, before the optional delay (story 018 plays its collapse/fade sequence
## between this and `results_shown`; raise `RunEndData.show_delay_seconds` to make room for it).
signal run_end_requested(reason: StringName)
## Emitted when the screen becomes visible and the tree is paused.
signal results_shown(reason: StringName)
## Emitted just before the run scene reloads.
signal restart_started

@export var data: RunEndData
@export var run_state: RunState
## Optional fade layer (story 018): a restart fades fully to black before the scene reloads.
@export var screen_fade: ScreenFade
## False when RunFlow (story 018) shows the results at the end of the death sequence instead.
@export var show_on_run_end: bool = true

var _shown: bool = false
var _restarting: bool = false
var _shown_at_msec: int = 0
## Process frame in which show_results() ran: restart input of that same frame is ignored, so the
## Enter or click that skipped the death tip can never also restart, whatever the node order.
var _shown_frame: int = -1
var _scale: float = 1.0
var _panel: PanelContainer
var _reason_label: Label
var _time_value: Label
var _wave_value: Label
var _kills_value: Label
var _best_label: Label
var _new_best_label: Label
var _button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if data == null or run_state == null:
		push_error("RunEndScreen needs data and run_state assigned.")
		return
	layer = data.layer
	_build_ui()
	run_state.run_ended.connect(_on_run_ended)


func _input(event: InputEvent) -> void:
	if _shown and event.is_action_pressed(&"restart_run") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if _guard_passed():
			restart_run()


## True while the results screen is visible.
func is_shown() -> bool:
	return _shown


## Starts a fresh run now: time scale 1, unpause, reload the run scene (the player recaptures the mouse).
## Probes call this directly; the button and the `restart_run` action go through the input guard first.
func restart_run() -> void:
	if _restarting:
		return
	_restarting = true
	restart_started.emit()
	if screen_fade != null:
		await screen_fade.fade_to_black(screen_fade.data.restart_fade_out_seconds)
		if not is_inside_tree():
			return
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


## Shows the results now (normally called from the run-end signal).
func show_results() -> void:
	if _shown:
		return
	_fill()
	_fit_panel()
	_shown = true
	_shown_at_msec = Time.get_ticks_msec()
	_shown_frame = Engine.get_process_frames()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	results_shown.emit(run_state.get_end_reason())


## Safety net: shrinks the panel (never enlarges) so it stays inside 90% of the viewport.
func _fit_panel() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var need: Vector2 = _panel.get_combined_minimum_size()
	var fit: float = minf(1.0, minf(view.x * 0.9 / need.x, view.y * 0.9 / need.y))
	_panel.pivot_offset = need * 0.5
	_panel.scale = Vector2(fit, fit)


func _on_run_ended(reason: StringName) -> void:
	run_end_requested.emit(reason)
	if not show_on_run_end:
		return
	if data.show_delay_seconds > 0.0:
		# process_always = true, ignore_time_scale = true: real seconds, not game time.
		await get_tree().create_timer(data.show_delay_seconds, true, false, true).timeout
		if not is_inside_tree():
			return
	show_results()


func _guard_passed() -> bool:
	if Engine.get_process_frames() == _shown_frame:
		return false
	return float(Time.get_ticks_msec() - _shown_at_msec) / 1000.0 >= data.restart_input_guard


func _on_button_pressed() -> void:
	if _guard_passed():
		restart_run()


func _fill() -> void:
	var reason: StringName = run_state.get_end_reason()
	_reason_label.text = data.reason_heart_attack if reason == HeartRate.REASON_HEART_ATTACK else data.reason_passed_out
	_time_value.text = format_time(run_state.get_time_survived())
	_wave_value.text = str(run_state.get_wave())
	_kills_value.text = str(run_state.get_kills())
	var best: Dictionary = run_state.get_session_best()
	_best_label.text = "%s: %s" % [data.best_label, data.best_line.format({
		"time": format_time(float(best.get("time", 0.0))),
		"wave": int(best.get("wave", 0)),
		"kills": int(best.get("kills", 0)),
	})]
	_new_best_label.visible = run_state.was_new_best()


## Formats seconds as m:ss.
static func format_time(seconds: float) -> String:
	var whole: int = int(seconds)
	return "%d:%02d" % [floori(seconds / 60.0), whole % 60]


func _build_ui() -> void:
	_scale = get_viewport().get_visible_rect().size.y / data.reference_height
	var overlay: ColorRect = ColorRect.new()
	overlay.color = data.overlay_color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(_s(data.panel_width), 0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = data.panel_color
	style.border_color = data.panel_border_color
	style.set_border_width_all(_s(data.panel_border_width))
	style.set_corner_radius_all(_s(data.panel_corner_radius))
	style.set_content_margin_all(_s(data.panel_padding))
	_panel.add_theme_stylebox_override(&"panel", style)
	center.add_child(_panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", _s(data.row_spacing))
	_panel.add_child(box)

	box.add_child(_make_label(data.title, _s(data.title_font_size), data.title_color))
	_reason_label = _make_label("", _s(data.reason_font_size), data.reason_color)
	box.add_child(_reason_label)
	box.add_child(_spacer(_s(data.section_spacing) - _s(data.row_spacing)))
	_time_value = _add_stat(box, data.time_label)
	_wave_value = _add_stat(box, data.wave_label)
	_kills_value = _add_stat(box, data.kills_label)
	box.add_child(_spacer(_s(data.section_spacing) - _s(data.row_spacing)))
	_best_label = _make_label("", _s(data.best_font_size), data.best_color)
	box.add_child(_best_label)
	_new_best_label = _make_label(data.new_best_text, _s(data.new_best_font_size), data.new_best_color)
	box.add_child(_new_best_label)
	box.add_child(_spacer(_s(data.section_spacing) - _s(data.row_spacing)))

	_button = Button.new()
	_button.text = data.restart_button
	_button.custom_minimum_size = Vector2(_s(data.button_width), _s(data.button_height))
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.add_theme_font_size_override(&"font_size", _s(data.button_font_size))
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		_button.add_theme_color_override(color_name, data.button_text_color)
	_button.add_theme_stylebox_override(&"normal", _button_style(data.button_color, data.button_border_color))
	_button.add_theme_stylebox_override(&"hover", _button_style(data.button_highlight_color, data.button_border_color))
	_button.add_theme_stylebox_override(&"pressed", _button_style(data.button_border_color, data.button_border_color))
	_button.add_theme_stylebox_override(&"focus", _button_style(data.button_highlight_color, data.button_focus_border_color, false))
	_button.focus_mode = Control.FOCUS_NONE
	_button.pressed.connect(_on_button_pressed)
	box.add_child(_button)
	var prompt: Label = _make_label(data.restart_prompt, _s(data.prompt_font_size), data.prompt_color)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(prompt)


## Scales a reference-canvas size (Unity 1080p) to the current viewport height.
func _s(value: int) -> int:
	return maxi(roundi(float(value) * _scale), 1)


func _add_stat(box: VBoxContainer, label_text: String) -> Label:
	box.add_child(_make_label(label_text, _s(data.label_font_size), data.label_color))
	var value: Label = _make_label("", _s(data.value_font_size), data.value_color)
	box.add_child(value)
	return value


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _spacer(height: int) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, maxi(height, 0))
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _button_style(fill: Color, border: Color, filled: bool = true) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.draw_center = filled
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(_s(data.button_border_width))
	style.set_corner_radius_all(_s(data.panel_corner_radius))
	return style
