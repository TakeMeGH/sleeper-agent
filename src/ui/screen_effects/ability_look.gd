class_name AbilityLook
extends CanvasLayer
## Slow-motion / superspeed screen feel: a full-screen grade shader over the world view, an additive
## camera FOV offset and low-pass / high-pass / pitch effects on the SFX and Music buses.
##
## LAYER ORDER (explicit CanvasLayer.layer numbers, not sibling order): world -1, viewmodel overlay 0,
## THIS look 1 (data `layer`), story 014 heart-rate vignette 2 (its OWN CanvasLayer), HUD bar and crosshair 3,
## run end 30. The grade covers only the world rect above the HUD bar.
## FOV: additive offset, same remove-and-re-add pattern as GunFeel. GunFeel runs at process_priority 50,
## this node at 55, the HUD mirror cameras at 100; other writers just add or subtract their own part.
## Each kind has a progress 0..1 (moved in REAL seconds by the ease times) and weight = smoothstep(progress).
## Output = neutral + sum over kinds of weight x (profile - neutral). Cutoffs blend in log space.

const KIND_SLOW_MOTION: StringName = &"slow_motion"
const KIND_SUPERSPEED: StringName = &"superspeed"
const EFFECT_NAMES: Dictionary = {
	&"lowpass": &"AbilityLookLowPass",
	&"highpass": &"AbilityLookHighPass",
	&"pitch": &"AbilityLookPitch",
}
const EFFECT_KEYS: Array[StringName] = [&"lowpass", &"highpass", &"pitch"]

@export var data: AbilityLookData
@export var shift_ability: ShiftAbility
## Optional; run end also eases the look out (ShiftAbility already ends the effect on run end).
@export var heart: HeartRate
## Player camera that receives the FOV offset.
@export var camera: Camera3D
## Gives the bar height ratio so the grade covers exactly the world view.
@export var hud: Hud

var _progress: Dictionary = {KIND_SLOW_MOTION: 0.0, KIND_SUPERSPEED: 0.0}
var _targets: Dictionary = {KIND_SLOW_MOTION: false, KIND_SUPERSPEED: false}
var _clock: RealClock = RealClock.new()
var _rect: ColorRect
var _material: ShaderMaterial
var _applied_fov: float = 0.0
var _buses: Array[Dictionary] = []
# Start/end flash (Unity AbilityTint): its own CanvasLayer above everything, faded linearly in real time.
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect
var _flash_color: Color = Color(1.0, 1.0, 1.0, 0.0)
var _flash_seconds: float = 0.0
var _flash_elapsed: float = 0.0


func _ready() -> void:
	if data == null or data.shader == null or data.slow_motion == null or data.superspeed == null:
		push_error("AbilityLook needs data with shader, slow_motion and superspeed.")
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 55
	layer = data.layer
	_build_rect()
	_build_flash()
	_setup_audio()
	if shift_ability != null:
		shift_ability.ability_started.connect(on_ability_started)
		shift_ability.ability_ended.connect(on_ability_ended)
	if heart != null:
		heart.run_ended.connect(on_run_ended)
	_apply(_compute_values())


func _exit_tree() -> void:
	_apply_fov(0.0)
	_teardown_audio()


func _process(delta: float) -> void:
	tick(_clock.step(delta))


# get_layer() is inherited from CanvasLayer and returns the layer number this look draws on.

## Eased weight 0..1 of a kind (KIND_SLOW_MOTION or KIND_SUPERSPEED); 0 for an unknown kind.
func get_weight(kind: StringName) -> float:
	if not _progress.has(kind):
		return 0.0
	return smoothstep(0.0, 1.0, _progress[kind] as float)


## Start easing a kind in (ShiftAbility.ability_started).
func on_ability_started(kind: StringName) -> void:
	if _targets.has(kind):
		_targets[kind] = true
		var profile: AbilityLookProfile = _profile(kind)
		play_flash(profile.start_flash_color, profile.start_flash_seconds)


## Start easing a kind out from its current weight (ShiftAbility.ability_ended).
func on_ability_ended(kind: StringName) -> void:
	if _targets.has(kind):
		_targets[kind] = false
		var profile: AbilityLookProfile = _profile(kind)
		play_flash(profile.end_flash_color, profile.end_flash_seconds)


## Shows a full-screen flash of color (alpha = peak opacity) fading out linearly over seconds (real time).
## A new flash replaces the one still fading. Skipped when the data does not keep the start/end flash.
func play_flash(color: Color, seconds: float) -> void:
	if not data.keep_start_end_flash or seconds <= 0.0 or color.a <= 0.0:
		return
	_flash_color = color
	_flash_seconds = seconds
	_flash_elapsed = 0.0
	_update_flash(0.0)


## Current flash opacity (0 when none is showing).
func get_flash_alpha() -> float:
	return _flash_rect.color.a if _flash_rect != null and _flash_rect.visible else 0.0


## Run ended: ease every look out from where it is.
func on_run_ended(_reason: StringName) -> void:
	for kind: StringName in _targets:
		_targets[kind] = false


## Advances the easing by real_delta real seconds and writes shader, FOV and audio.
func tick(real_delta: float) -> void:
	if data == null:
		return
	for kind: StringName in _progress:
		var profile: AbilityLookProfile = _profile(kind)
		var p: float = _progress[kind]
		if _targets[kind]:
			p += real_delta / maxf(profile.ease_in_seconds, 0.001)
		else:
			p -= real_delta / maxf(profile.ease_out_seconds, 0.001)
		_progress[kind] = clampf(p, 0.0, 1.0)
	_update_flash(real_delta)
	_apply(_compute_values())


## Current blended output: saturation, contrast, exposure, tint (Color), vignette, ca, fov_offset,
## lowpass_hz, highpass_hz, pitch.
func get_current_values() -> Dictionary:
	return _compute_values()


func _profile(kind: StringName) -> AbilityLookProfile:
	return data.slow_motion if kind == KIND_SLOW_MOTION else data.superspeed


func _compute_values() -> Dictionary:
	# Unity units, neutral 0 (saturation / contrast -100..100, exposure in EV).
	var sat: float = 0.0
	var con: float = 0.0
	var expo: float = 0.0
	var tint: Vector3 = Vector3.ONE
	var vig: float = 0.0
	var ca: float = 0.0
	var fov: float = 0.0
	var lp_log: float = log(data.neutral_lowpass_hz)
	var hp_log: float = log(data.neutral_highpass_hz)
	var pitch: float = 1.0
	for kind: StringName in _progress:
		var w: float = get_weight(kind)
		if w <= 0.0:
			continue
		var p: AbilityLookProfile = _profile(kind)
		sat += w * p.saturation
		con += w * p.contrast
		expo += w * p.post_exposure
		tint += w * (Vector3(p.tint.r, p.tint.g, p.tint.b) - Vector3.ONE)
		vig += w * p.vignette_intensity
		ca += w * p.chromatic_aberration
		fov += w * p.fov_delta_degrees
		lp_log += w * (log(p.lowpass_hz) - log(data.neutral_lowpass_hz))
		hp_log += w * (log(p.highpass_hz) - log(data.neutral_highpass_hz))
		pitch += w * (p.pitch_scale - 1.0)
	return {
		&"saturation": sat, &"contrast": con, &"exposure": expo,
		&"tint": Color(tint.x, tint.y, tint.z), &"vignette": minf(vig, 1.0), &"ca": minf(ca, 1.0),
		&"fov_offset": fov, &"lowpass_hz": exp(lp_log), &"highpass_hz": exp(hp_log), &"pitch": pitch,
	}


func _apply(values: Dictionary) -> void:
	if _rect != null:
		_rect.visible = get_weight(KIND_SLOW_MOTION) + get_weight(KIND_SUPERSPEED) > 0.0
	if _material != null:
		var tint: Color = values[&"tint"]
		_material.set_shader_parameter(&"saturation", values[&"saturation"])
		_material.set_shader_parameter(&"contrast", values[&"contrast"])
		_material.set_shader_parameter(&"post_exposure", values[&"exposure"])
		_material.set_shader_parameter(&"tint", Vector3(tint.r, tint.g, tint.b))
		_material.set_shader_parameter(&"vignette_intensity", values[&"vignette"])
		_material.set_shader_parameter(&"chromatic_aberration", values[&"ca"])
	_apply_fov(values[&"fov_offset"])
	_apply_audio(values)


func _build_rect() -> void:
	_material = ShaderMaterial.new()
	_material.shader = data.shader
	_material.set_shader_parameter(&"vignette_smoothness", data.vignette_smoothness)
	var vc: Color = data.vignette_color
	_material.set_shader_parameter(&"vignette_color", Vector3(vc.r, vc.g, vc.b))
	_rect = ColorRect.new()
	_rect.name = "GradeRect"
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	if hud != null and hud.data != null:
		_rect.anchor_bottom = 1.0 - hud.data.bar_height_ratio
	else:
		push_warning("AbilityLook: hud not set, the grade covers the whole screen including the HUD bar.")
	_rect.offset_bottom = 0.0
	_rect.resized.connect(_on_rect_resized)
	add_child(_rect)
	_on_rect_resized()


func _build_flash() -> void:
	_flash_layer = CanvasLayer.new()
	_flash_layer.name = "AbilityFlash"
	_flash_layer.layer = data.flash_layer
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.name = "FlashRect"
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.visible = false
	_flash_layer.add_child(_flash_rect)


func _update_flash(real_delta: float) -> void:
	if _flash_rect == null:
		return
	if _flash_seconds <= 0.0:
		_flash_rect.visible = false
		return
	_flash_elapsed += real_delta
	var t: float = _flash_elapsed / _flash_seconds
	if t >= 1.0:
		_flash_rect.visible = false
		_flash_seconds = 0.0
		return
	var c: Color = _flash_color
	c.a *= 1.0 - t
	_flash_rect.color = c
	_flash_rect.visible = true


func _on_rect_resized() -> void:
	_material.set_shader_parameter(&"rect_size", Vector2(maxf(_rect.size.x, 1.0), maxf(_rect.size.y, 1.0)))


func _apply_fov(fov_offset: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	if is_equal_approx(fov_offset, _applied_fov):
		return
	camera.fov = camera.fov - _applied_fov + fov_offset
	_applied_fov = fov_offset


func _setup_audio() -> void:
	for bus_name: StringName in data.audio_buses:
		var bus: int = AudioServer.get_bus_index(bus_name)
		if bus < 0:
			push_warning("AbilityLook: audio bus %s not found." % bus_name)
			continue
		var entry: Dictionary = {
			&"bus": bus,
			&"lowpass": _find_or_add(bus, &"lowpass"),
			&"highpass": _find_or_add(bus, &"highpass"),
			&"pitch": _find_or_add(bus, &"pitch"),
		}
		_buses.append(entry)


## Returns the effect already on the bus with this name (reload case) or adds the new one.
func _find_or_add(bus: int, key: StringName) -> AudioEffect:
	var effect_name: StringName = EFFECT_NAMES[key]
	for i: int in AudioServer.get_bus_effect_count(bus):
		var existing: AudioEffect = AudioServer.get_bus_effect(bus, i)
		if existing.resource_name == String(effect_name):
			if existing is AudioEffectPitchShift:
				(existing as AudioEffectPitchShift).fft_size = data.pitch_fft_size as AudioEffectPitchShift.FFTSize
			return existing
	var fresh: AudioEffect
	match key:
		&"lowpass":
			fresh = AudioEffectLowPassFilter.new()
		&"highpass":
			fresh = AudioEffectHighPassFilter.new()
		_:
			var shift: AudioEffectPitchShift = AudioEffectPitchShift.new()
			shift.fft_size = data.pitch_fft_size as AudioEffectPitchShift.FFTSize
			fresh = shift
	fresh.resource_name = String(effect_name)
	_set_neutral(fresh)
	AudioServer.add_bus_effect(bus, fresh)
	AudioServer.set_bus_effect_enabled(bus, AudioServer.get_bus_effect_count(bus) - 1, false)
	return fresh


func _set_neutral(effect: AudioEffect) -> void:
	if effect is AudioEffectLowPassFilter:
		(effect as AudioEffectLowPassFilter).cutoff_hz = data.neutral_lowpass_hz
	elif effect is AudioEffectHighPassFilter:
		(effect as AudioEffectHighPassFilter).cutoff_hz = data.neutral_highpass_hz
	elif effect is AudioEffectPitchShift:
		(effect as AudioEffectPitchShift).pitch_scale = 1.0


func _set_effect_enabled(bus: int, effect: AudioEffect, enabled: bool) -> void:
	var idx: int = _effect_index(bus, effect)
	if idx >= 0 and AudioServer.is_bus_effect_enabled(bus, idx) != enabled:
		AudioServer.set_bus_effect_enabled(bus, idx, enabled)


func _effect_index(bus: int, effect: AudioEffect) -> int:
	for i: int in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) == effect:
			return i
	return -1


## Each effect is enabled only while its own value is away from neutral; at neutral it is also reset exactly.
func _apply_audio(values: Dictionary) -> void:
	var lp_on: bool = not is_equal_approx(values[&"lowpass_hz"], data.neutral_lowpass_hz)
	var hp_on: bool = not is_equal_approx(values[&"highpass_hz"], data.neutral_highpass_hz)
	var pitch_on: bool = not is_equal_approx(values[&"pitch"], 1.0)
	for entry: Dictionary in _buses:
		var bus: int = entry[&"bus"]
		var lp: AudioEffectLowPassFilter = entry[&"lowpass"]
		var hp: AudioEffectHighPassFilter = entry[&"highpass"]
		var ps: AudioEffectPitchShift = entry[&"pitch"]
		lp.cutoff_hz = values[&"lowpass_hz"] if lp_on else data.neutral_lowpass_hz
		hp.cutoff_hz = values[&"highpass_hz"] if hp_on else data.neutral_highpass_hz
		ps.pitch_scale = values[&"pitch"] if pitch_on else 1.0
		_set_effect_enabled(bus, lp, lp_on)
		_set_effect_enabled(bus, hp, hp_on)
		_set_effect_enabled(bus, ps, pitch_on)


## Restores neutral and removes the effects this node added (bus state outlives scene reloads).
func _teardown_audio() -> void:
	for entry: Dictionary in _buses:
		var bus: int = entry[&"bus"]
		for key: StringName in EFFECT_KEYS:
			var idx: int = _effect_index(bus, entry[key])
			if idx >= 0:
				AudioServer.remove_bus_effect(bus, idx)
	_buses.clear()
