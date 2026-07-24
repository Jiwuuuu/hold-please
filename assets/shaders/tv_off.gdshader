shader_type canvas_item;
//old tv power-off: the picture squashes to a bright horizontal line, then
//the line collapses sideways into a dot and dies. progress 0 = normal
//screen, 1 = black. the power-on runs the same shader backwards.

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	float p = clamp(progress, 0.0, 1.0);
	//phase a squashes vertically, phase b collapses the line to a dot
	float pa = clamp(p / 0.65, 0.0, 0.995);
	float pb = clamp((p - 0.65) / 0.35, 0.0, 1.0);

	vec2 uv = SCREEN_UV;
	uv.y = (uv.y - 0.5) / (1.0 - pa) + 0.5;
	uv.x = (uv.x - 0.5) / (1.0 - pb * 0.995) + 0.5;

	vec3 col = vec3(0.0);
	if (uv.y >= 0.0 && uv.y <= 1.0 && uv.x >= 0.0 && uv.x <= 1.0) {
		col = texture(screen, uv).rgb;
		//the squashed picture burns brighter, faking the bright line
		col *= 1.0 + pa * 4.0;
		//warm-up wobble while the set is mid transition
		col *= 1.0 - 0.15 * step(0.001, p) * hash(floor(TIME * 60.0));
	}
	//the dot dies out at the very end
	col *= 1.0 - smoothstep(0.7, 1.0, pb);
	COLOR = vec4(col, 1.0);
}
