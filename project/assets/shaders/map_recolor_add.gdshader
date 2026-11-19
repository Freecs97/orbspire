shader_type canvas_item;
render_mode blend_add;
// ADD version: dark parts vanish, bright parts glow (galaxy icons over the
// universe picture, so a galaxy's dark centre doesn't show as a black disc).
// Map art recolour (galaxies, solar systems, planets). NOT used for characters,
// bosses, enemies or orbs (orbs keep their fixed colours).
//
// Colour is random VISUAL diversity. Affinity is gameplay, shown by the orb icon
// and the label. A blue planet can be a Fire world. Do NOT infer affinity from colour.
//
// hue_shift turns every colour round the colour wheel (0-1 = one full turn).
// Greys and whites have no hue, so stars stay white. sat_mul / val_mul vary the
// saturation and brightness a little. circle_mask cuts a soft circle out of the
// picture (the planet pictures have a fake checkerboard behind the planet).

uniform float hue_shift = 0.0;
uniform float sat_mul = 1.0;
uniform float val_mul = 1.0;
uniform bool circle_mask = false;
uniform vec2 mask_center = vec2(0.5, 0.5);
uniform float mask_radius = 0.45;
uniform float mask_feather = 0.015;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(tex.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	hsv.y = clamp(hsv.y * sat_mul, 0.0, 1.0);
	hsv.z = clamp(hsv.z * val_mul, 0.0, 1.0);
	float a = tex.a;
	if (circle_mask) {
		float d = distance(UV, mask_center);
		a *= 1.0 - smoothstep(mask_radius - mask_feather, mask_radius, d);
	}
	COLOR = vec4(hsv2rgb(hsv), a) * COLOR;
}
