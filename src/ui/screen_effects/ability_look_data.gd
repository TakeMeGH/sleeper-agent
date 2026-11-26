class_name AbilityLookData
extends Resource
## All tuning for the ability screen look (story 013). Values come from the Unity ability_look.json
## unless the build notes say otherwise.

@export var slow_motion: AbilityLookProfile
@export var superspeed: AbilityLookProfile
## Shader that does the grade (src/ui/screen_effects/ability_look.gdshader).
@export var shader: Shader
@export_group("Layers")
## CanvasLayer.layer order (explicit, never sibling order): world -1, viewmodel overlay 0,
## ability look (this `layer`) 1, story 014 heart-rate vignette `heart_vignette_layer` 2 (its OWN
## CanvasLayer), HUD bar and crosshair `hud_layer` 3 (set in hud.tscn and the Hud node of each scene), run end 30.
@export var layer: int = 1
## Reserved for story 014 (not used by this story's code).
@export var heart_vignette_layer: int = 2
## Documentation of where the HUD sits (the HUD scenes carry the value).
@export var hud_layer: int = 3
## Layer of the start/end flash: above the HUD and every overlay (Unity AbilityTint sorting order 100).
@export var flash_layer: int = 40
## Unity keep_start_end_flash: true keeps the start/end flash on top of the sustained look.
@export var keep_start_end_flash: bool = true
@export var vignette_smoothness: float = 0.6
@export var vignette_color: Color = Color.BLACK
@export_group("Audio")
## Buses the filters and pitch shift are added to (not Master).
@export var audio_buses: Array[StringName] = [&"SFX", &"Music"]
@export var neutral_lowpass_hz: float = 22000.0
@export var neutral_highpass_hz: float = 10.0
## Pitch-shift FFT size (AudioEffectPitchShift.FFTSize).
@export_enum("256:0", "512:1", "1024:2", "2048:3", "4096:4") var pitch_fft_size: int = 2
