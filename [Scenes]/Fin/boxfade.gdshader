shader_type spatial;

// 渐变色
uniform vec4 color_bottom : source_color = vec4(0.2, 0.4, 0.8, 1.0);   // 起点颜色（蓝）
uniform vec4 color_top    : source_color = vec4(0.9, 0.2, 0.2, 1.0);   // 终点颜色（红）

// 渐变方向（模型空间或世界空间，取决于 use_world_space）
uniform vec3 gradient_direction = vec3(0.0, 1.0, 0.0);

// 进度计算：progress = dot(pos, direction) * scale + offset，然后 clamp 到 0..1
uniform float gradient_scale  = 1.0;   // 默认适配边长 1 的立方体
uniform float gradient_offset = 0.5;   // 使 [-0.5, 0.5] 映射为 [0, 1]

// 是否使用世界空间（勾选后渐变方向固定在世界坐标轴，不随物体旋转）
uniform bool use_world_space = false;

varying float gradient;

void vertex() {
	// 决定采样坐标
	vec3 pos = VERTEX;                      // 模型空间（局部坐标）
	if (use_world_space) {
		pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;   // 世界空间坐标
	}

	// 计算渐变进度
	float progress = dot(pos, gradient_direction) * gradient_scale + gradient_offset;
	gradient = clamp(progress, 0.0, 1.0);
}

void fragment() {
	ALBEDO = mix(color_bottom.rgb, color_top.rgb, gradient);
	ALPHA  = mix(color_bottom.a, color_top.a, gradient);
}