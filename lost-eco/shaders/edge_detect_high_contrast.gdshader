shader_type canvas_item;
render_mode unshaded;

// Sobel 3x3 sobre captura de pantalla (requiere BackBufferCopy en el CanvasLayer).
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
uniform float edge_strength : hint_range(0.5, 6.0) = 3.0;
uniform float threshold : hint_range(0.0, 0.5) = 0.08;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.04;
uniform vec4 silhouette_color : source_color = vec4(1.0, 0.95, 0.15, 1.0);
uniform vec4 background_color : source_color = vec4(0.01, 0.01, 0.04, 1.0);
uniform vec4 accent_color : source_color = vec4(0.95, 0.2, 0.25, 1.0);

float sample_luma(vec2 uv) {
	return dot(texture(SCREEN_TEXTURE, uv).rgb, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 px = vec2(1.0) / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 uv = SCREEN_UV;
	float tl = sample_luma(uv + vec2(-px.x, -px.y));
	float tc = sample_luma(uv + vec2(0.0, -px.y));
	float tr = sample_luma(uv + vec2(px.x, -px.y));
	float ml = sample_luma(uv + vec2(-px.x, 0.0));
	float mr = sample_luma(uv + vec2(px.x, 0.0));
	float bl = sample_luma(uv + vec2(-px.x, px.y));
	float bc = sample_luma(uv + vec2(0.0, px.y));
	float br = sample_luma(uv + vec2(px.x, px.y));

	float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
	float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;
	float edge = sqrt(gx * gx + gy * gy) * edge_strength;
	float mask = smoothstep(threshold, threshold + edge_softness, edge);

	vec3 base = texture(SCREEN_TEXTURE, uv).rgb;
	float warm = max(base.r - base.g, 0.0) + max(base.b - base.g, 0.0) * 0.5;
	vec3 edge_col = mix(silhouette_color.rgb, accent_color.rgb, clamp(warm * 2.0, 0.0, 1.0));
	vec3 out_rgb = mix(background_color.rgb, edge_col, mask);
	COLOR = vec4(out_rgb, 1.0);
}
