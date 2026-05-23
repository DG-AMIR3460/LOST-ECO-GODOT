shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

// 0 = Normal, 1 = Protanopia, 2 = Deuteranopia, 3 = Tritanopia
uniform int mode = 0;

vec3 apply_protanopia(vec3 color) {
	mat3 matrix = mat3(
		vec3(0.56667, 0.43333, 0.0),
		vec3(0.55833, 0.44167, 0.0),
		vec3(0.0, 0.24167, 0.75833)
	);
	return color * matrix;
}

vec3 apply_deuteranopia(vec3 color) {
	mat3 matrix = mat3(
		vec3(0.625, 0.375, 0.0),
		vec3(0.7, 0.3, 0.0),
		vec3(0.0, 0.3, 0.7)
	);
	return color * matrix;
}

vec3 apply_tritanopia(vec3 color) {
	mat3 matrix = mat3(
		vec3(0.95, 0.05, 0.0),
		vec3(0.0, 0.43333, 0.56667),
		vec3(0.0, 0.475, 0.525)
	);
	return color * matrix;
}

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	if (mode == 0) {
		COLOR = vec4(screen_color.rgb, 1.0);
	} else if (mode == 1) {
		COLOR = vec4(apply_protanopia(screen_color.rgb), 1.0);
	} else if (mode == 2) {
		COLOR = vec4(apply_deuteranopia(screen_color.rgb), 1.0);
	} else {
		COLOR = vec4(apply_tritanopia(screen_color.rgb), 1.0);
	}
}
