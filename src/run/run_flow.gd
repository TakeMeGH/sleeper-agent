class_name RunFlow
extends Node
## Orchestrates the death sequence (story 018): run end -> collapse -> hold -> fade to black -> tip on
## black -> results on black. It takes over showing the results from RunEndScreen (`show_on_run_end` is
## switched off here), so the results appear only at the end of the sequence. All timing is real time.

## Emitted when the flow moves to another stage (names: idle, collapse, hold, fade, tip, results).
signal stage_changed(stage: StringName, previous_stage: StringName)

const STAGE_IDLE: StringName = &"idle"
const STAGE_COLLAPSE: StringName = &"collapse"
const STAGE_HOLD: StringName = &"hold"
const STAGE_FADE: StringName = &"fade"
const STAGE_TIP: StringName = &"tip"
const STAGE_RESULTS: StringName = &"results"

@export var data: DeathFlowData
@export var run_end_screen: RunEndScreen
@export var collapse: DeathCollapse
@export var fade: ScreenFade
@export var tip: DeathTip
## Crosshair control to hide the moment the run ends.
@export var crosshair: Control
## Print stage changes (RUNFLOW stage=... frame=...).
@export var log_events: bool = false
@export_group("Debug")
## Stage to stay in instead of leaving it: &"hold" (rest pose, no fade) or &"tip" (the tip never ends).
@export var debug_hold_stage: StringName = &""

var _stage: StringName = STAGE_IDLE
var _hold_elapsed: float = 0.0
var _clock: RealClock = RealClock.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if run_end_screen == null or data == null:
		push_error("RunFlow needs data and run_end_screen assigned.")
		return
	run_end_screen.show_on_run_end = false
	run_end_screen.run_end_requested.connect(_on_run_end_requested)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Current stage name: idle, collapse, hold, fade, tip, results.
func get_stage() -> StringName:
	return _stage


## True from the run end until the results are shown.
func is_running() -> bool:
	return _stage != STAGE_IDLE and _stage != STAGE_RESULTS


## Starts the sequence (normally called from RunEndScreen.run_end_requested).
func start(reason: StringName = &"") -> void:
	if _stage != STAGE_IDLE:
		return
	if crosshair != null:
		crosshair.visible = false
	_set_stage(STAGE_COLLAPSE)
	if collapse == null:
		_on_collapse_finished()
		return
	# Connected before start(): a zero-length collapse finishes inside start().
	collapse.finished.connect(_on_collapse_finished, CONNECT_ONE_SHOT)
	if not collapse.start(reason):
		if collapse.finished.is_connected(_on_collapse_finished):
			collapse.finished.disconnect(_on_collapse_finished)
		_on_collapse_finished()


## Advances the hold timer by real seconds (the other stages run on their own nodes' clocks).
func tick(real_delta: float) -> void:
	if _stage != STAGE_HOLD:
		return
	_hold_elapsed += real_delta
	if _hold_elapsed >= data.death_hold_seconds and debug_hold_stage != STAGE_HOLD:
		_begin_fade()


func _on_run_end_requested(reason: StringName) -> void:
	start(reason)


func _on_collapse_finished() -> void:
	_hold_elapsed = 0.0
	_set_stage(STAGE_HOLD)


func _begin_fade() -> void:
	_set_stage(STAGE_FADE)
	if fade != null:
		await fade.fade_to_black(data.death_fade_seconds)
	if not is_inside_tree() or _stage != STAGE_FADE:
		return
	_begin_tip()


func _begin_tip() -> void:
	_set_stage(STAGE_TIP)
	if tip == null:
		_show_results()
		return
	tip.debug_hold = debug_hold_stage == STAGE_TIP
	tip.tip_finished.connect(_show_results, CONNECT_ONE_SHOT)
	tip.show_tip()


func _show_results() -> void:
	if _stage == STAGE_RESULTS:
		return
	_set_stage(STAGE_RESULTS)
	run_end_screen.show_results()


func _set_stage(next: StringName) -> void:
	var previous: StringName = _stage
	_stage = next
	if log_events:
		print("RUNFLOW stage=%s frame=%d" % [next, Engine.get_process_frames()])
	stage_changed.emit(next, previous)
