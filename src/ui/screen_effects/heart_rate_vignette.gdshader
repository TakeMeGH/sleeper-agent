// canvas_item_ui_heart_rate_vignette.gdshader (story 014, heart-rate vignette)
//
// Full-rect alpha overlay for the heart-rate vignette: black at a low rate,
// white at a high rate. Put it on a ColorRect on its own CanvasLayer (layer 2),
// above the world, viewmodel and ability look, below the HUD. It does NOT read
// the screen; it only outputs COLOR = vec4(vignette_color, alpha), so the
// engine blends it over whatever is below.
//
// CONTRACT: every uniform is already eased (and pulsed) by the driving script;
// this shader does no easing and no timing. At intensity 0 the output alpha is
// exactly 0.0, so the rect may stay visible permanently (or be hidden by the
// script as an optimisation).
//
// DISTANCE METRIC: p = (UV - 0.5) * (rect_size / min(rect_size.x, rect_size.y)),
// i.e. the rect-local position from the centre, stretched along the long axis
// so one unit is the same number of pixels on both axes (round, not oval).
// dist = length(p) / (0.5 * length(rect_size / min(rect_size))) so dist is
// 0.0 at the centre and exactly 1.0 at the four rect corners. The middle of the
// short edges is at 0.5 / corner_len (about 0.43 on 16:9) and the middle of the
// long edges at about 0.87 on 16:9.
//
// FALLOFF: t = clamp((dist - inner_radius) / (outer_radius - inner_radius), 0, 1);
// falloff = pow(smoothstep(0, 1, t), mix(3.0, 1.0, smoothness)).
// 0 inside inner_radius, 1 at and beyond outer_radius. Low smoothness keeps the
// centre clear longer and gives a tighter, harder band at the edge; smoothness 1
// is a plain smoothstep ramp.
// alpha = clamp(intensity * falloff, 0, 1).
//
// Target: Forward+ (also fine on Mobile/Compatibility). One pass, no loops, no
// texture reads, no branches.
shader_type canvas_item;

group_uniforms vignette;
// 0..1, 0 = nothing drawn (alpha exactly 0). Eased and pulsed by the script.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
// Black for a low heart rate, white for a high one.
uniform vec3 vignette_color : source_color = vec3(0.0);
// Distance from the centre (corner = 1.0) where the vignette starts.
uniform float inner_radius : hint_range(0.0, 2.0) = 0.5;
// Distance from the centre (corner = 1.0) where the vignette reaches full strength.
uniform float outer_radius : hint_range(0.0, 2.0) = 1.05;
// Falloff shape, Unity URP "smoothness" (0.6 typical). Higher = softer ramp.
uniform float smoothness : hint_range(0.01, 1.0) = 0.6;
// Pixel size of the ColorRect, used to keep the vignette round, not oval.
uniform vec2 rect_size = vec2(1280.0, 576.0);
group_uniforms;

// Exponent range for the falloff curve: at smoothness 0 the exponent is
// CURVE_POWER_SHARP, at smoothness 1 it is CURVE_POWER_SOFT (plain smoothstep).
const float CURVE_POWER_SHARP = 3.0;
const float CURVE_POWER_SOFT = 1.0;
// Lower bound of the radius span so inner >= outer cannot divide by zero.
const float MIN_SPAN = 0.0001;

void fragment() {
	// Stretch the long axis so distances are isotropic in pixels.
	vec2 scale = rect_size / max(min(rect_size.x, rect_size.y), 1.0);
	vec2 p = (UV - vec2(0.5)) * scale;
	// Half diagonal of the stretched rect = distance of a corner from the centre.
	float corner = 0.5 * length(scale);
	float dist = length(p) / corner;

	float t = clamp((dist - inner_radius) / max(outer_radius - inner_radius, MIN_SPAN), 0.0, 1.0);
	float s = smoothstep(0.0, 1.0, t);
	float falloff = pow(s, mix(CURVE_POWER_SHARP, CURVE_POWER_SOFT, clamp(smoothness, 0.0, 1.0)));

	COLOR = vec4(vignette_color, clamp(intensity * falloff, 0.0, 1.0));
}
