shader_type canvas_item;

// Muerte cinematográfica: monocromo, viñeta negra y aberración cromática.
uniform float bleed : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic : hint_range(0.0, 0.04) = 0.018;
uniform float desaturate : hint_range(0.0, 1.0) = 0.85;
uniform float vignette_power : hint_range(0.5, 4.0) = 2.4;
uniform vec4 bleed_color : source_color = vec4(0.008, 0.004, 0.012, 1.0);
uniform vec4 mono_tint : source_color = vec4(0.55, 0.52, 0.58, 1.0);

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.15;
	float vignette = pow(smoothstep(0.2, 1.05, dist), vignette_power);

	vec2 ab = vec2(chromatic * bleed, 0.0);
	vec3 base_rgb;
	base_rgb.r = texture(TEXTURE, UV + ab).r;
	base_rgb.g = texture(TEXTURE, UV).g;
	base_rgb.b = texture(TEXTURE, UV - ab).b;

	float lum = dot(base_rgb, vec3(0.299, 0.587, 0.114));
	vec3 mono = vec3(lum) * mono_tint.rgb;
	vec3 mixed = mix(base_rgb, mono, desaturate * bleed);

	vec3 out_rgb = mix(mixed, bleed_color.rgb, vignette * bleed);
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(out_rgb, alpha);
}
