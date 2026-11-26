class_name ScreenFade
extends CanvasLayer
## The single fade layer (story 018): a full-screen black rect above the game view, HUD, crosshair and
## arcs, below the tip and the results. Runs in unscaled time and while the tree is paused.
## `await fade.fade_to_black(0.5)` / `await fade.fade_clear(0.4)` wait for the end of the fade.

## Emitted when a fade reaches its target; alpha is 1.0 (black) or 0.0 (clear).
signal fade_finished(alpha: float)
## Wakes waiters when a fade ends or is cancelled (private; waiters re-check their fade id).
signal _woke

@export var data: DeathFlowData

var _alpha: float = 0.0
var _from: float = 0.0
var _target: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0
var _fading: bool = false
var _fade_id: int = 0
var _rect: ColorRect
var _clock: RealClock = RealClock.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if data == null:
		push_error("ScreenFade needs data assigned.")
		return
	layer = data.fade_layer
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	set_alpha(1.0 if data.start_black else 0.0)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## Advances the running fade by real seconds (called every frame; probes may call it directly).
func tick(real_delta: float) -> void:
	if not _fading:
		return
	_elapsed += real_delta
	if _elapsed >= _duration:
		_finish()
		return
	_apply(lerpf(_from, _target, _elapsed / _duration))


## Fades to black over `seconds` (unscaled). 0 = at once. Awaitable.
func fade_to_black(seconds: float) -> void:
	var id: int = _begin(1.0, seconds)
	while _fading and _fade_id == id:
		await _woke


## Fades to clear over `seconds` (unscaled). 0 = at once. Awaitable.
func fade_clear(seconds: float) -> void:
	var id: int = _begin(0.0, seconds)
	while _fading and _fade_id == id:
		await _woke


## Sets the alpha now and cancels any fade (its waiters wake without fade_finished).
func set_alpha(alpha: float) -> void:
	_fading = false
	_fade_id += 1
	_apply(alpha)
	_woke.emit()


## Current alpha, 0 clear to 1 black.
func get_alpha() -> float:
	return _alpha


## True while a fade is running.
func is_fading() -> bool:
	return _fading


## True when the screen is fully black.
func is_black() -> bool:
	return _alpha >= 1.0


func _begin(target: float, seconds: float) -> int:
	var was_fading: bool = _fading
	_fading = false
	_fade_id += 1
	var id: int = _fade_id
	if was_fading:
		_woke.emit()
	_target = target
	if seconds <= 0.0 or is_equal_approx(_alpha, target):
		_apply(target)
		fade_finished.emit(target)
		return id
	_from = _alpha
	_duration = seconds
	_elapsed = 0.0
	_fading = true
	return id


func _finish() -> void:
	_fading = false
	_apply(_target)
	fade_finished.emit(_target)
	_woke.emit()


func _apply(alpha: float) -> void:
	_alpha = clampf(alpha, 0.0, 1.0)
	if _rect != null and data != null:
		var color: Color = data.fade_color
		color.a = _alpha * data.fade_color.a
		_rect.color = color
