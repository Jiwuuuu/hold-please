//based on "Minimal CRT Shader" by blitpxl — godotshaders.com/shader/minimal-crt-shader/ (CC0)
//modified for hold, please: added barrel curvature + vignette, toned defaults down
shader_type canvas_item;
uniform sampler2D ST : hint_screen_texture, filter_linear_mipmap;
uniform vec4 scanline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 flicker_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float scanlines_count = 4.0;
uniform float scanlines_intensity = 0.04;
uniform float flicker_speed = 30.0;
uniform float flicker_intensity : hint_range(0.0, 1.0, 0.001) = 0.015;
uniform float color_offset = 1.2;
uniform float blur = 0.1;
uniform vec2 warp_amount = vec2(0.045, 0.06);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;

//bend the screen uv like an old curved tube
vec2 warp(vec2 uv) {
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta, delta);
	return uv + delta * delta2 * warp_amount * 2.0;
}

void fragment() {
	vec2 suv = warp(SCREEN_UV);

	//outside the curved glass is black
	if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec2 pixel_size = 1.0 / vec2(textureSize(ST, 0));
		float offset = color_offset * pixel_size.x;

		//chromatic aberration
		float channel_r = textureLod(ST, suv + vec2(offset, 0.0), blur).r;
		float channel_g = textureLod(ST, suv, blur).g;
		float channel_b = textureLod(ST, suv + vec2(-offset, 0.0), blur).b;
		vec4 aberrate = vec4(channel_r, channel_g, channel_b, 1.0);

		//scanline flicker
		float mix_value = sin((UV.y - (TIME * flicker_speed)) * 10.0) * flicker_intensity;
		vec4 flicker = mix(aberrate, flicker_color, mix_value);

		//scanlines
		float scanlines = sin(FRAGCOORD.y * scanlines_count) * scanlines_intensity;
		vec4 final = mix(flicker, scanline_color, scanlines);

		//soft darkening toward the corners
		vec2 v = suv * (1.0 - suv);
		float vig = clamp(pow(v.x * v.y * 15.0, 0.25), 0.0, 1.0);
		final.rgb *= mix(1.0, vig, vignette_strength);

		COLOR = final;
	}
}
