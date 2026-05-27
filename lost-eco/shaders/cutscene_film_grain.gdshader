shader_type canvas_item;

uniform float strength : hint_range(0.0, 0.25) = 0.06;
uniform float time_sec = 0.0;

void fragment() {
	float n = fract(sin(dot(UV * 1200.0 + time_sec, vec2(12.9898, 78.233))) * 43758.5453);
	float grain = (n - 0.5) * strength;
	COLOR = vec4(vec3(grain), abs(grain) * 2.0);
}
