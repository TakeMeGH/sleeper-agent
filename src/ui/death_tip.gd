class_name DeathTip
extends CanvasLayer
## One tip, centred on the black screen after death (story 018). Fades in, holds, fades out; Enter
## (`restart_run`) or a mouse click skips it. It never starts a restart: the input is consumed here and
## the results screen (with its own restart guard) is not shown yet.

## Emitted when a tip begins fading in.
signal tip_shown(text: String)
## Emitted when the tip is gone (finished or skipped), or at once when there is nothing to show.
signal tip_finished

enum Stage { IDLE, FADE_IN, HOLD, FADE_OUT }

@export var data: DeathFlowData
@export var tips: TipListData
## Debug: stay in HOLD forever (capture scenes).
@export var debug_hold: bool = false

## The last tip shown, remembered for the session (survives scene reloads).
static var _last_tip: String = ""

var _stage: Stage = Stage.IDLE
var _elapsed: float = 0.0
var _label: Label
var _clock: RealClock = RealClock.new()
var _tip_override: PackedStringArray = PackedStringArray()
var _use_override: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if data == null:
		push_error("DeathTip needs data assigned.")
		return
	layer = data.tip_layer
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override(&"font_size", data.tip_font_size)
	_label.add_theme_color_override(&"font_color", data.tip_color)
	_label.modulate.a = 0.0
	center.add_child(_label)
	_fit_width()
	get_viewport().size_changed.connect(_fit_width)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


func _input(event: InputEvent) -> void:
	if _stage == Stage.IDLE:
		return
	var pressed: bool = event.is_action_pressed(&"restart_run") and not event.is_echo()
	var clicked: bool = false
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		clicked = button.pressed and (button.button_index == MOUSE_BUTTON_LEFT or button.button_index == MOUSE_BUTTON_RIGHT)
	if pressed or clicked:
		get_viewport().set_input_as_handled()
		skip()


## Replaces the tip list (probes; an empty array = no tips).
func set_tip_list_override(list: PackedStringArray) -> void:
	_tip_override = list
	_use_override = true


## Picks the next tip: random among the list, never the one shown last (unless it is the only one).
## roll (0..1) replaces the random number for probes (negative = random). "" when the list is empty.
func pick_tip(roll: float = -1.0) -> String:
	var list: PackedStringArray = PackedStringArray()
	if _use_override:
		list = _tip_override
	elif tips != null:
		list = tips.tips
	var candidates: PackedStringArray = PackedStringArray()
	for text: String in list:
		if text != "" and text != _last_tip:
			candidates.append(text)
	if candidates.is_empty():
		for text: String in list:
			if text != "":
				candidates.append(text)
	if candidates.is_empty():
		return ""
	var r: float = randf() if roll < 0.0 else clampf(roll, 0.0, 0.999999)
	return candidates[int(r * float(candidates.size()))]


## Starts the tip. Returns false (and emits tip_finished) when there is no tip or the tip time is 0.
func show_tip(roll: float = -1.0) -> bool:
	var text: String = pick_tip(roll)
	if data == null or text == "" or data.tip_hold_seconds <= 0.0:
		tip_finished.emit()
		return false
	_last_tip = text
	_label.text = text
	_stage = Stage.FADE_IN
	_elapsed = 0.0
	_label.modulate.a = 0.0
	tip_shown.emit(text)
	return true


## Ends the tip now (Enter, click). Does nothing when no tip is showing.
func skip() -> void:
	if _stage == Stage.IDLE:
		return
	_stage = Stage.IDLE
	_label.modulate.a = 0.0
	tip_finished.emit()


## True while a tip is on screen (fading in, held, or fading out).
func is_showing() -> bool:
	return _stage != Stage.IDLE


## Current stage name: idle, fade_in, hold, fade_out.
func get_stage_name() -> StringName:
	return StringName(String(Stage.keys()[_stage]).to_lower())


## Current tip alpha 0..1.
func get_alpha() -> float:
	return 0.0 if _label == null else _label.modulate.a


## Text currently set on the label.
func get_text() -> String:
	return "" if _label == null else _label.text


## Forgets the last tip (session memory).
static func clear_memory() -> void:
	_last_tip = ""


## Advances the fade/hold by real seconds.
func tick(real_delta: float) -> void:
	if _stage == Stage.IDLE:
		return
	_elapsed += real_delta
	match _stage:
		Stage.FADE_IN:
			_label.modulate.a = _ratio(_elapsed, data.tip_fade_in_seconds)
			if _elapsed >= data.tip_fade_in_seconds:
				_stage = Stage.HOLD
				_elapsed = 0.0
				_label.modulate.a = 1.0
		Stage.HOLD:
			if not debug_hold and _elapsed >= data.tip_hold_seconds:
				_stage = Stage.FADE_OUT
				_elapsed = 0.0
		Stage.FADE_OUT:
			_label.modulate.a = 1.0 - _ratio(_elapsed, data.tip_fade_out_seconds)
			if _elapsed >= data.tip_fade_out_seconds:
				skip()


func _ratio(elapsed: float, seconds: float) -> float:
	return 1.0 if seconds <= 0.0 else clampf(elapsed / seconds, 0.0, 1.0)


func _fit_width() -> void:
	if _label == null:
		return
	_label.custom_minimum_size.x = get_viewport().get_visible_rect().size.x * data.tip_width_ratio
