shader_type canvas_item;
// Repaints the purple robe in another hue and leaves the rest (skin, trim, belts) as drawn.

uniform float target_hue = 0.3;
uniform float robe_hue = 0.72;
uniform float hue_range = 0.08;
uniform float saturation = 2.4;

vec3 rgb_to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 hsv = rgb_to_hsv(color.rgb);
	if (abs(hsv.x - robe_hue) < hue_range && hsv.y > 0.12) {
		hsv.x = target_hue;
		hsv.y = min(1.0, hsv.y * saturation);
		color.rgb = hsv_to_rgb(hsv);
	}
	COLOR = color;
}
