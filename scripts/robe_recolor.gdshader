shader_type canvas_item;
// Repaints the purple robe in another colour and leaves the rest (skin, trim, belts) as drawn.

// Hue, saturation and value of the new colour.
uniform vec3 new_color = vec3(0.3, 0.5, 0.5);
uniform float robe_hue = 0.72;
uniform float hue_range = 0.08;
// Saturation of the drawn robe, so the new colour keeps its light and shade.
uniform float robe_saturation = 0.3;

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
		hsv.x = new_color.x;
		hsv.y = min(1.0, hsv.y * new_color.y / robe_saturation);
		color.rgb = hsv_to_rgb(hsv);
	}
	COLOR = color;
}
