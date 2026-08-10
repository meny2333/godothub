shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec4 color : source_color = vec4(0.35, 0.9, 1.0, 1.0);
uniform float ring_radius = 0.12;
uniform float intensity = 4.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float distance_to_center = length(centered_uv);
	float core = 1.0 - smoothstep(0.0, 0.72, distance_to_center);
	float ring_distance = abs(distance_to_center - ring_radius);
	float ring = 1.0 - smoothstep(0.0, 0.085, ring_distance);
	float edge = 1.0 - smoothstep(0.82, 1.0, distance_to_center);
	float alpha = (core * 0.75 + ring * 1.6) * edge * intensity;
	ALBEDO = color.rgb;
	EMISSION = color.rgb * 3.0 * intensity;
	ALPHA = alpha;
}
