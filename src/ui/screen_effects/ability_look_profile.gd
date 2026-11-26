class_name AbilityLookProfile
extends Resource
## Full-strength screen and audio look of one Shift ability (slow motion or superspeed).
## Grade values use Unity URP Color Adjustments units, as in Unity ability_look.json: saturation and contrast
## -100..100 (0 = neutral), post exposure in EV stops (0 = neutral, 1 = twice as bright), colour filter multiplies.
## Vignette and aberration are 0 = neutral.

@export_group("Timing")
## Real seconds from neutral to full strength after the ability starts.
@export var ease_in_seconds: float = 0.5
## Real seconds from full strength back to neutral after the ability ends.
@export var ease_out_seconds: float = 0.5
@export_group("Grade")
## URP saturation, -100 (grey) .. 100. 0 = neutral.
@export_range(-100.0, 100.0, 1.0) var saturation: float = 0.0
## URP contrast, -100 .. 100 (log-space around mid grey). 0 = neutral.
@export_range(-100.0, 100.0, 1.0) var contrast: float = 0.0
## URP post exposure in EV stops (linear x 2^EV). 0 = neutral.
@export_range(-5.0, 5.0, 0.05) var post_exposure: float = 0.0
## URP colour filter (linear multiply). White = neutral.
@export var tint: Color = Color.WHITE
@export_range(0.0, 1.0, 0.01) var vignette_intensity: float = 0.0
@export_range(0.0, 1.0, 0.01) var chromatic_aberration: float = 0.0
@export_group("Start and end flash")
## Full-screen flash when the ability starts (Unity abilities.json *_start tint; alpha = peak opacity).
@export var start_flash_color: Color = Color(1.0, 1.0, 1.0, 0.0)
## Real seconds the start flash fades out over (linearly).
@export var start_flash_seconds: float = 0.5
## Full-screen flash when the ability ends (Unity *_end tint).
@export var end_flash_color: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var end_flash_seconds: float = 0.35
@export_group("Camera")
## Added to the player camera field of view (degrees).
@export var fov_delta_degrees: float = 0.0
@export_group("Audio")
## Low-pass cutoff at full strength (Hz); the neutral value (data) means no filtering.
@export var lowpass_hz: float = 22000.0
## High-pass cutoff at full strength (Hz).
@export var highpass_hz: float = 10.0
## Pitch scale at full strength (1.0 = unchanged).
@export var pitch_scale: float = 1.0
