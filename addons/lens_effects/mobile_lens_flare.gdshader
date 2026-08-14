shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 sun_uv = vec2(0.5);
uniform vec4 sun_color : source_color = vec4(1.0, 0.88, 0.63, 0.55);
uniform float visibility : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.7;
uniform float ray_strength : hint_range(0.0, 2.0) = 0.35;
uniform float flare_strength : hint_range(0.0, 2.0) = 0.45;

float soft_disc(vec2 point, vec2 center, float radius, float softness, float aspect) {
	vec2 delta = point - center;
	delta.x *= aspect;
	return 1.0 - smoothstep(radius, radius + softness, length(delta));
}

float ring(vec2 point, vec2 center, float radius, float width, float aspect) {
	vec2 delta = point - center;
	delta.x *= aspect;
	return 1.0 - smoothstep(width, width * 2.0, abs(length(delta) - radius));
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 delta = UV - sun_uv;
	delta.x *= aspect;
	float distance_to_sun = length(delta);
	float angle = atan(delta.y, delta.x);

	float core = exp(-distance_to_sun * 72.0);
	float glow = exp(-distance_to_sun * 11.0) * 0.38;
	float streak = exp(-abs(delta.y) * 145.0) * exp(-abs(delta.x) * 4.0);
	float star = pow(abs(cos(angle * 4.0)), 28.0) * exp(-distance_to_sun * 6.0);
	star += pow(abs(cos(angle * 7.0 + 0.35)), 42.0) * exp(-distance_to_sun * 9.0) * 0.45;

	vec2 center = vec2(0.5);
	vec2 axis = center - sun_uv;
	float ghost_a = soft_disc(UV, center + axis * 0.28, 0.018, 0.025, aspect);
	float ghost_b = ring(UV, center + axis * 0.72, 0.045, 0.012, aspect);
	float ghost_c = soft_disc(UV, center - axis * 0.38, 0.028, 0.045, aspect);
	float ghosts = ghost_a * 0.32 + ghost_b * 0.22 + ghost_c * 0.18;

	float rays = (star + streak * 0.52) * ray_strength;
	float flares = ghosts * flare_strength;
	float strength = (core * 1.35 + glow + rays + flares) * intensity * visibility;
	vec3 warm = sun_color.rgb;
	vec3 spectral = mix(warm, vec3(0.52, 0.74, 1.0), clamp(ghosts * 0.75, 0.0, 0.6));
	COLOR = vec4(spectral * strength, strength * sun_color.a);
}
