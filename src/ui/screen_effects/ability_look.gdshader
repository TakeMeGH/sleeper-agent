// canvas_item_ui_ability_look.gdshader (story 013, ability screen feel; Unity parity pass 2026-11-26)
//
// Full-screen grade for the slow-motion / superspeed look, a port of Unity URP's post stack as the Unity game used
// it (tonemapping None, LDR grading): chromatic aberration -> vignette -> post exposure -> contrast (LogC, around
// ACEScc mid grey) -> colour filter -> saturation (Rec.709 luma), all in LINEAR colour. The screen texture is sRGB, so
// it is decoded first and encoded again at the end. Put it on a ColorRect on a CanvasLayer drawn AFTER the world and
// viewmodel and BEFORE the HUD. The rect covers only the world area: the grade samples SCREEN_UV, the vignette and
// aberration use the rect-local UV (centred on the world view).
//
// CONTRACT: every uniform is already eased by the driving script; this shader does no easing. Units are Unity's:
// saturation and contrast -100..100 (0 neutral), post_exposure in EV stops (0 neutral), tint is URP's colour filter
// (sRGB colour, white neutral). At neutral values each stage is skipped, so the output is an exact pass-through.
// Output alpha is always 1.0.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

group_uniforms grade;
// URP saturation, -100..100. 0 neutral.
uniform float saturation : hint_range(-100.0, 100.0) = 0.0;
// URP contrast, -100..100. 0 neutral.
uniform float contrast : hint_range(-100.0, 100.0) = 0.0;
// URP post exposure in EV stops (linear x 2^EV). 0 neutral.
uniform float post_exposure : hint_range(-5.0, 5.0) = 0.0;
// URP colour filter (sRGB colour; multiplied in linear). White neutral.
uniform vec3 tint : source_color = vec3(1.0);
group_uniforms;

group_uniforms vignette;
// 0..1, 0 neutral.
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
// Falloff sharpness, Unity URP "smoothness" (0.6 typical).
uniform float vignette_smoothness : hint_range(0.01, 1.0) = 0.6;
uniform vec3 vignette_color : source_color = vec3(0.0);
// Pixel size of the ColorRect, used to keep the vignette round, not oval.
uniform vec2 rect_size = vec2(1280.0, 576.0);
group_uniforms;

group_uniforms chromatic;
// 0..1, 0 neutral. Radial RGB split growing toward the edges.
uniform float chromatic_aberration : hint_range(0.0, 1.0) = 0.0;
// UV offset of the R/B channels at the rect corners when chromatic_aberration = 1.
uniform float chromatic_max_offset : hint_range(0.0, 0.05) = 0.012;
group_uniforms;

// URP Color.hlsl constants.
const vec3 LUMA_709 = vec3(0.2126729, 0.7151522, 0.0721750);
const float ACESCC_MIDGRAY = 0.4135884;
const float LOGC_CUT = 0.011361;
const float LOGC_A = 5.555556;
const float LOGC_B = 0.047996;
const float LOGC_C = 0.244161;
const float LOGC_D = 0.386036;
const float LOGC_E = 5.301883;
const float LOGC_F = 0.092819;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 linear_to_srgb(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

vec3 linear_to_logc(vec3 x) {
	vec3 lg = LOGC_C * (log(LOGC_A * x + LOGC_B) / log(10.0)) + LOGC_D;
	vec3 ln = LOGC_E * x + LOGC_F;
	return mix(ln, lg, step(vec3(LOGC_CUT), x));
}

vec3 logc_to_linear(vec3 x) {
	vec3 lg = (pow(vec3(10.0), (x - LOGC_D) / LOGC_C) - LOGC_B) / LOGC_A;
	vec3 ln = (x - LOGC_F) / LOGC_E;
	return mix(ln, lg, step(vec3(LOGC_E * LOGC_CUT + LOGC_F), x));
}

void fragment() {
	vec3 col;

	if (chromatic_aberration > 0.0) {
		// Offset direction from the rect centre. Length is 0.7071 at a corner,
		// so dividing by it makes the corner offset equal to the max offset.
		vec2 from_center = UV - vec2(0.5);
		vec2 offs = from_center * (chromatic_aberration * chromatic_max_offset / 0.70710678);
		// R is pushed outward, B inward, G stays put. Clamp to stay on the screen.
		float r = texture(screen_texture, clamp(SCREEN_UV + offs, vec2(0.0), vec2(1.0))).r;
		vec3 g_sample = texture(screen_texture, SCREEN_UV).rgb;
		float b = texture(screen_texture, clamp(SCREEN_UV - offs, vec2(0.0), vec2(1.0))).b;
		col = vec3(r, g_sample.g, b);
	} else {
		col = texture(screen_texture, SCREEN_UV).rgb;
	}

	bool grade = saturation != 0.0 || contrast != 0.0 || post_exposure != 0.0 || tint != vec3(1.0)
			|| vignette_intensity > 0.0;
	if (grade) {
		vec3 lin = srgb_to_linear(col);

		if (vignette_intensity > 0.0) {
			// URP: d = |uv - centre| x intensity, x aspect-corrected (rounded), factor = (1 - d.d)^(smoothness x 5).
			vec2 d = abs(UV - vec2(0.5)) * vignette_intensity;
			d.x *= rect_size.x / rect_size.y;
			float v = pow(clamp(1.0 - dot(d, d), 0.0, 1.0), vignette_smoothness * 5.0);
			lin *= mix(srgb_to_linear(vignette_color), vec3(1.0), v);
		}
		if (post_exposure != 0.0) {
			lin *= exp2(post_exposure);
		}
		if (contrast != 0.0) {
			vec3 lg = linear_to_logc(max(lin, vec3(0.0)));
			lg = (lg - ACESCC_MIDGRAY) * (1.0 + contrast / 100.0) + ACESCC_MIDGRAY;
			lin = logc_to_linear(lg);
		}
		if (tint != vec3(1.0)) {
			lin *= srgb_to_linear(tint);
		}
		lin = max(lin, vec3(0.0));
		if (saturation != 0.0) {
			float luma = dot(lin, LUMA_709);
			lin = max(vec3(luma) + (1.0 + saturation / 100.0) * (lin - vec3(luma)), vec3(0.0));
		}
		// Tonemapping None: LDR clamp.
		col = linear_to_srgb(clamp(lin, vec3(0.0), vec3(1.0)));
	}

	COLOR = vec4(col, 1.0);
}
