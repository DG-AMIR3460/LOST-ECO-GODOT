shader_type canvas_item;

uniform vec2 player_pos = vec2(0.5, 0.5);
uniform float light_radius : hint_range(0.0, 1.0) = 0.15;
uniform float edge_softness : hint_range(0.01, 0.3) = 0.08;
uniform vec4 fog_color : source_color = vec4(0.1, 0.1, 0.18, 0.95);

void fragment() {
	float dist = distance(UV, player_pos);
	float alpha = smoothstep(light_radius, light_radius + edge_softness, dist);
	COLOR = fog_color * alpha;
}
