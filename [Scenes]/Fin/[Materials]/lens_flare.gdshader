shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add, fog_disabled;

// Screen-space lens flare rendered on a full-screen quad pinned to the camera.
// The flare is built from a radial glow plus several offset "ghost" blobs
// stretched along the axis from the screen center to the flare origin, which
// is the classic anamorphic lens-flare look.

uniform vec4 flare_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform float intensity : hint_range(0.0, 5.0) = 1.4;
uniform float ghost_strength : hint_range(0.0, 1.0) = 0.55;
uniform float halo_radius : hint_range(0.05, 0.9) = 0.35;
uniform vec2 flare_center = vec2(0.5, 0.42);
uniform float stretch : hint_range(0.0, 1.0) = 0.35;

varying float view_aspect;

float blob(vec2 uv, vec2 center, float radius, float soft) {
	vec2 d = uv - center;
	d.x /= max(0.05, view_aspect);
	float r = length(d);
	return 1.0 - smoothstep(radius * (1.0 - soft), radius, r);
}

void vertex() {
	// Pin the quad in front of the camera so the flare tracks the view.
	view_aspect = max(0.05, VIEWPORT_SIZE.x / max(0.05, VIEWPORT_SIZE.y));
}

void fragment() {
	vec2 uv = UV;

	// Main radial glow around the flare center.
	float glow = blob(uv, flare_center, halo_radius * 1.8, 0.75);

	// Secondary halo ring hugging the flare center.
	float ring = blob(uv, flare_center, halo_radius, 0.25) * 0.6;

	// Axis from screen center to flare origin; ghosts sit along it.
	vec2 axis = normalize(flare_center - vec2(0.5));
	float axis_len = length(flare_center - vec2(0.5));

	// Ghost blobs at fractional positions along the axis (classic flare).
	float ghosts = 0.0;
	for (int i = 0; i < 4; i++) {
		float t = float(i + 1) / 4.0;
		vec2 gpos = vec2(0.5) + axis * axis_len * t * 1.6;
		float g = blob(uv, gpos, halo_radius * 0.16 * (1.0 + t * 0.5), 0.6);
		// Color shifts slightly along the axis.
		float tint = 0.85 + t * 0.35;
		ghosts += g * tint * ghost_strength;
	}

	// Anamorphic horizontal streak through the center.
	vec2 sd = uv - vec2(0.5);
	sd.x *= view_aspect;
	float streak = exp(-abs(sd.x) * (4.0 - stretch * 3.0)) * exp(-sd.y * sd.y * 90.0) * 0.35;

	// Fade the whole flare at the screen borders.
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge_alpha = smoothstep(0.0, 0.12, edge);

	float alpha = (glow + ring * 0.5 + ghosts + streak) * intensity * edge_alpha;
	ALBEDO = flare_color.rgb;
	EMISSION = flare_color.rgb * intensity;
	ALPHA = alpha;
}
