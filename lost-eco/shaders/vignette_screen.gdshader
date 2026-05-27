shader_type canvas_item;

// Viñeta procedural (sin TEXTURE) — oscurece bordes, centro transparente.
uniform float intensity : hint_range(0.0, 1.0) = 0.65;
uniform float softness : hint_range(0.05, 1.5) = 0.42;
uniform float aspect_ratio : hint_range(0.5, 2.5) = 1.777;
uniform vec4 tint : source_color = vec4(0.01, 0.008, 0.035, 1.0);

void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.x *= aspect_ratio;
	float dist = length(centered) * 2.0;
	float vignette = smoothstep(1.0 - softness, 1.0, dist) * intensity;
	COLOR = vec4(tint.rgb, vignette);
}
