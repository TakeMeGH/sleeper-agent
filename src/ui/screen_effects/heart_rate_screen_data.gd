class_name HeartRateScreenData
extends Resource
## Tuning for the heart-rate vignette and field of view (story 014). Values from the Unity
## heart_rate_screen.json plus camera_motion_scale (player_comfort.json), layer and stack mode.

## Photosensitivity safety cap: no pulse rate may exceed this many pulses per second.
## This is the one allowed literal; it is a safety limit, not a tuning value.
const MAX_PULSES_PER_SECOND: float = 3.0

## How the heart vignette combines with the vignette of story 013 (ability look).
enum StackMode {
	## Draw the heart vignette as computed, on top of the ability look.
	BLEND,
	## Draw only the amount by which the heart vignette exceeds the ability look vignette.
	LARGER,
}

@export var shader: Shader
@export var stack_mode: StackMode = StackMode.BLEND
## CanvasLayer number (1 = ability look, 3 = HUD bar).
@export var layer: int = 2
@export_group("Rate bands")
@export var rest_low_rate: float = 60.0
@export var rest_high_rate: float = 100.0
@export var low_full_rate: float = 10.0
@export var high_full_rate: float = 190.0
@export var curve_exponent: float = 1.0
@export_group("Response")
## Real seconds of the exponential approach.
@export var response_seconds: float = 0.6
@export_range(0.01, 1.0) var vignette_smoothness: float = 0.6
## Scales the FOV change: 0 = the FOV never changes, 1 = full.
@export_range(0.0, 1.0) var camera_motion_scale: float = 1.0
@export_group("Pulse")
@export var warn_low_band: float = 30.0
@export var warn_high_band: float = 30.0
@export_range(0.0, 1.0) var pulse_depth_max: float = 0.5
@export_range(0.0, 1.0) var pulse_depth_countdown: float = 0.7
@export_range(0.0, 3.0) var pulse_per_second: float = 1.0
@export_range(0.0, 3.0) var pulse_per_second_countdown: float = 2.0
@export_group("Low rate (black)")
@export_range(0.0, 1.0) var low_intensity: float = 0.6
@export var low_color: Color = Color(0, 0, 0, 1)
@export var low_fov_delta: float = -8.0
@export var low_inner_radius: float = 0.4
@export var low_outer_radius: float = 1.0
@export_group("High rate (white)")
@export_range(0.0, 1.0) var high_intensity: float = 0.25
@export var high_color: Color = Color(1, 1, 1, 1)
@export var high_fov_delta: float = 20.0
@export var high_inner_radius: float = 0.5
@export var high_outer_radius: float = 1.05


## Returns one message per problem; an empty array means the data is valid.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not (pulse_per_second >= 0.0 and pulse_per_second <= MAX_PULSES_PER_SECOND):
		errors.append("pulse_per_second %s is outside 0..%s." % [pulse_per_second, MAX_PULSES_PER_SECOND])
	if not (pulse_per_second_countdown >= 0.0 and pulse_per_second_countdown <= MAX_PULSES_PER_SECOND):
		errors.append("pulse_per_second_countdown %s is outside 0..%s." % [pulse_per_second_countdown, MAX_PULSES_PER_SECOND])
	if low_full_rate >= rest_low_rate:
		errors.append("low_full_rate must be below rest_low_rate.")
	if rest_high_rate >= high_full_rate:
		errors.append("rest_high_rate must be below high_full_rate.")
	if rest_low_rate > rest_high_rate:
		errors.append("rest_low_rate must not exceed rest_high_rate.")
	if curve_exponent <= 0.0:
		errors.append("curve_exponent must be above 0.")
	if response_seconds < 0.0:
		errors.append("response_seconds must not be negative.")
	if warn_low_band <= 0.0 or warn_high_band <= 0.0:
		errors.append("warn bands must be above 0.")
	if pulse_depth_max < 0.0 or pulse_depth_max > 1.0 or pulse_depth_countdown < 0.0 or pulse_depth_countdown > 1.0:
		errors.append("pulse depths must be within 0..1.")
	if camera_motion_scale < 0.0 or camera_motion_scale > 1.0:
		errors.append("camera_motion_scale must be within 0..1.")
	if low_inner_radius >= low_outer_radius or high_inner_radius >= high_outer_radius:
		errors.append("inner radius must be below outer radius.")
	return errors
