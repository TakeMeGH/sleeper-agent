class_name HeartRateScreen
extends CanvasLayer
## Heart-rate vignette and field of view (story 014). White vignette + wider FOV above the rest band,
## black vignette + narrower FOV below it, pulsing near the limits and harder during the danger countdown.
##
## LAYER: own CanvasLayer (data.layer, 2): above AbilityLook (1), below the HUD bar (3). The overlay shader
## only outputs colour + alpha, it does not read the screen.
## PRIORITY 56: after GunFeel 50 and AbilityLook 55, before the Hud mirror cameras 100.
## FOV is an additive offset (remove-and-re-add), like GunFeel and AbilityLook.
##
## MODEL: one signed "heat" value, +1 = full high side, -1 = full low side, 0 = invisible. The target is
## computed from the rate and eased with factor 1 - exp(-dt / response_seconds) in REAL seconds, so the
## colour never snaps when the rate crosses from one side to the other (it passes through 0).
## INVALID DATA: the whole effect stays neutral (no vignette, no FOV change, no pulse), so bad rate ranges
## can never produce NaN.
## PULSE: displayed = smoothed x (1 - depth x (0.5 + 0.5 x sin(phase))), phase += 2 PI x pulse_rate x dt.
## Proximity p (0..1) rises across the warn band next to a limit; depth = p x pulse_depth_max at
## pulse_per_second; while the danger countdown runs depth = pulse_depth_countdown at
## pulse_per_second_countdown. Depth is eased like the heat so a switch does not pop.

## Group of nodes with a pausable camera mirror (Hud, Viewmodel); each has sync_camera().
const CAMERA_MIRROR_GROUP: StringName = &"camera_mirrors"
## Heat and depth below this magnitude snap to exactly 0 when their target is 0.
const SNAP_EPSILON: float = 0.0001

@export var data: HeartRateScreenData
@export var heart: HeartRate
## Player camera that receives the FOV offset.
@export var camera: Camera3D
## Gives the bar height ratio so the overlay covers exactly the world view.
@export var hud: Hud
## Optional; only used for HeartRateScreenData.StackMode.LARGER.
@export var ability_look: AbilityLook

var _clock: RealClock = RealClock.new()
var _rect: ColorRect
var _material: ShaderMaterial
var _heat: float = 0.0
var _depth: float = 0.0
var _phase: float = 0.0
var _pulse_rate: float = 0.0
var _pulse_factor: float = 1.0
var _intensity: float = 0.0
var _color: Color = Color(0, 0, 0, 1)
var _applied_fov: float = 0.0
var _fov_offset: float = 0.0
var _data_valid: bool = false
var _ended: bool = false


func _ready() -> void:
	if data == null or data.shader == null:
		push_error("HeartRateScreen needs data with a shader.")
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 56
	layer = data.layer
	var errors: PackedStringArray = data.validate()
	for message: String in errors:
		push_error("HeartRateScreenData: %s" % message)
	_data_valid = errors.is_empty()
	_build_rect()
	if heart != null:
		heart.run_ended.connect(on_run_ended)
		_ended = heart.has_ended()
	_apply()


func _exit_tree() -> void:
	_apply_fov(0.0)


func _process(delta: float) -> void:
	tick(_clock.step(delta))


## True when the data passed validate(). When false the whole effect stays neutral.
func is_data_valid() -> bool:
	return _data_valid


## Target vignette and FOV for a rate (no easing): {intensity, color, fov_offset}. fov_offset includes
## camera_motion_scale.
func compute_target(rate: float) -> Dictionary:
	return _values_for_heat(_heat_for_rate(rate))


## Vignette alpha strength actually drawn: eased, pulsed and stacked with the ability look.
func get_vignette_intensity() -> float:
	return _intensity


## Eased intensity before the pulse.
func get_smoothed_intensity() -> float:
	return absf(_heat) * (data.high_intensity if _heat >= 0.0 else data.low_intensity)


## Colour of the vignette now (black on the low side, white on the high side).
func get_vignette_color() -> Color:
	return _color


## Current additive FOV offset in degrees (includes camera_motion_scale).
func get_fov_offset() -> float:
	return _fov_offset


## Current pulse rate in pulses per second (0 when not pulsing).
func get_pulse_rate() -> float:
	return _pulse_rate


## Current eased pulse depth 0..1 (0 = no pulse).
func get_pulse_depth() -> float:
	return _depth


## Run ended: pulse off, vignette 0 and FOV offset removed at once; stays neutral.
func on_run_ended(_reason: StringName) -> void:
	_ended = true
	_heat = 0.0
	_depth = 0.0
	_pulse_rate = 0.0
	_apply()
	# The Hud / viewmodel cameras are pausable and the tree pauses with the run end: push the final fov once.
	if is_inside_tree():
		get_tree().call_group(CAMERA_MIRROR_GROUP, &"sync_camera")


## Advances the easing and pulse by real_delta real seconds and writes the shader and FOV.
func tick(real_delta: float) -> void:
	if data == null or _ended or not _data_valid:
		return
	var rate: float = heart.get_rate() if heart != null else data.rest_low_rate
	var k: float = 1.0 if data.response_seconds <= 0.0 else 1.0 - exp(-real_delta / data.response_seconds)
	var heat_target: float = _heat_for_rate(rate)
	_heat = lerpf(_heat, heat_target, k)
	if heat_target == 0.0 and absf(_heat) < SNAP_EPSILON:
		_heat = 0.0
	var wanted_depth: float = 0.0
	_pulse_rate = 0.0
	var counting_down: bool = heart != null and heart.get_countdown_left() > 0.0
	if counting_down:
		wanted_depth = data.pulse_depth_countdown
		_pulse_rate = data.pulse_per_second_countdown
	else:
		wanted_depth = _proximity(rate) * data.pulse_depth_max
		_pulse_rate = data.pulse_per_second
	_depth = lerpf(_depth, wanted_depth, k)
	if wanted_depth == 0.0 and _depth < SNAP_EPSILON:
		_depth = 0.0
	_phase = fposmod(_phase + TAU * _pulse_rate * real_delta, TAU)
	_apply()


func _proximity(rate: float) -> float:
	if rate >= data.rest_high_rate:
		return clampf((rate - (data.high_full_rate - data.warn_high_band)) / data.warn_high_band, 0.0, 1.0)
	return clampf(((data.low_full_rate + data.warn_low_band) - rate) / data.warn_low_band, 0.0, 1.0)


## Signed heat for a rate: +0..1 high side, -0..-1 low side, 0 in the rest band.
func _heat_for_rate(rate: float) -> float:
	if rate > data.rest_high_rate:
		var t_high: float = clampf((rate - data.rest_high_rate) / (data.high_full_rate - data.rest_high_rate), 0.0, 1.0)
		return pow(t_high, data.curve_exponent)
	if rate < data.rest_low_rate:
		var t_low: float = clampf((data.rest_low_rate - rate) / (data.rest_low_rate - data.low_full_rate), 0.0, 1.0)
		return -pow(t_low, data.curve_exponent)
	return 0.0


func _values_for_heat(heat: float) -> Dictionary:
	var w: float = absf(heat)
	if heat >= 0.0:
		return {&"intensity": w * data.high_intensity, &"color": data.high_color,
			&"fov_offset": w * data.high_fov_delta * data.camera_motion_scale}
	return {&"intensity": w * data.low_intensity, &"color": data.low_color,
		&"fov_offset": w * data.low_fov_delta * data.camera_motion_scale}


func _apply() -> void:
	var values: Dictionary = _values_for_heat(_heat)
	_pulse_factor = 1.0 - _depth * (0.5 + 0.5 * sin(_phase))
	var drawn: float = (values[&"intensity"] as float) * _pulse_factor
	if data.stack_mode == HeartRateScreenData.StackMode.LARGER and ability_look != null:
		var ability: Dictionary = ability_look.get_current_values()
		drawn = maxf(drawn - (ability[&"vignette"] as float), 0.0)
	_intensity = drawn
	_color = values[&"color"]
	_fov_offset = values[&"fov_offset"]
	if _rect != null:
		_rect.visible = _intensity > 0.0
		var high: bool = _heat >= 0.0
		_material.set_shader_parameter(&"intensity", _intensity)
		_material.set_shader_parameter(&"vignette_color", Vector3(_color.r, _color.g, _color.b))
		_material.set_shader_parameter(&"inner_radius", data.high_inner_radius if high else data.low_inner_radius)
		_material.set_shader_parameter(&"outer_radius", data.high_outer_radius if high else data.low_outer_radius)
	_apply_fov(_fov_offset)


func _build_rect() -> void:
	_material = ShaderMaterial.new()
	_material.shader = data.shader
	_material.set_shader_parameter(&"smoothness", data.vignette_smoothness)
	_rect = ColorRect.new()
	_rect.name = "VignetteRect"
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	if hud != null and hud.data != null:
		_rect.anchor_bottom = 1.0 - hud.data.bar_height_ratio
	else:
		push_warning("HeartRateScreen: hud not set, the vignette covers the whole screen including the HUD bar.")
	_rect.offset_bottom = 0.0
	_rect.resized.connect(_on_rect_resized)
	add_child(_rect)
	_on_rect_resized()


func _on_rect_resized() -> void:
	_material.set_shader_parameter(&"rect_size", Vector2(maxf(_rect.size.x, 1.0), maxf(_rect.size.y, 1.0)))


func _apply_fov(fov_offset: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	if is_equal_approx(fov_offset, _applied_fov):
		return
	camera.fov = camera.fov - _applied_fov + fov_offset
	_applied_fov = fov_offset
