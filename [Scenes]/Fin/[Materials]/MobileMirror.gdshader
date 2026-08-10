shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform sampler2D reflection_texture : source_color, filter_linear;
uniform vec3 reflection_tint : source_color = vec3(0.88, 0.95, 1.0);
uniform vec3 frame_color : source_color = vec3(0.055, 0.075, 0.095);
uniform float brightness : hint_range(0.5, 1.5) = 0.95;
uniform float frame_width : hint_range(0.0, 0.15) = 0.035;
uniform float fragment_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 reflection_uv = vec2(1.0 - SCREEN_UV.x, SCREEN_UV.y);
	vec3 reflected_color = texture(reflection_texture, reflection_uv).rgb;
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float frame = 0.0;
	if (frame_width > 0.0001) {
		frame = 1.0 - smoothstep(0.0, frame_width, edge_distance);
	}
	ALBEDO = mix(reflected_color * reflection_tint * brightness, frame_color, frame);
	ALPHA = fragment_alpha;
}
