shader_type canvas_item;

uniform float dawn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = UV;
	float horizon = smoothstep(0.12, 0.78, uv.y);

	vec3 night_top = vec3(0.03, 0.05, 0.14);
	vec3 night_hor = vec3(0.06, 0.10, 0.18);
	vec3 dawn_top = vec3(0.52, 0.42, 0.62);
	vec3 dawn_hor = vec3(0.95, 0.58, 0.32);

	vec3 sky = mix(night_hor, night_top, horizon);
	vec3 dawn_sky = mix(dawn_hor, dawn_top, horizon);
	sky = mix(sky, dawn_sky, dawn_progress);

	if (dawn_progress < 0.7) {
		vec2 cell = floor(uv * vec2(90.0, 50.0));
		float h = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453123);
		if (h > 0.93 && uv.y > 0.18) {
			float tw = 0.55 + 0.45 * sin(time_sec * 2.8 + h * 40.0);
			sky += vec3(0.92, 0.96, 1.0) * tw * (1.0 - dawn_progress) * 0.4;
		}
	}

	vec2 moon_pos = vec2(0.82, 0.2);
	float moon_d = length(uv - moon_pos);
	float moon = smoothstep(0.055, 0.038, moon_d);
	float moon_glow = smoothstep(0.2, 0.0, moon_d) * 0.3;
	sky += vec3(0.88, 0.9, 0.78) * (moon + moon_glow) * (1.0 - dawn_progress * 0.85);

	vec2 sun_pos = vec2(0.28 + dawn_progress * 0.08, 0.42 - dawn_progress * 0.12);
	float sun_d = length(uv - sun_pos);
	float sun = smoothstep(0.09, 0.04, sun_d) * dawn_progress;
	float sun_glow = smoothstep(0.38, 0.0, sun_d) * 0.55 * dawn_progress;
	sky += vec3(1.0, 0.78, 0.38) * (sun + sun_glow);

	float ground_glow = smoothstep(0.95, 0.55, uv.y) * dawn_progress * 0.12;
	sky += vec3(0.4, 0.55, 0.25) * ground_glow;

	COLOR = vec4(sky, 1.0);
}
