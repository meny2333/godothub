extends Control

const STAGE_COLORS: Array[Color] = [
	Color("#e2ad4f"),
	Color("#6f8fa8"),
	Color("#f4d58a"),
	Color("#b7e4e8"),
]
const SKY_COLORS: Array[Color] = [
	Color("#151922"),
	Color("#111a25"),
	Color("#211b24"),
	Color("#11191d"),
]

var stage_index: int = 0
var _target_stage: int = 0
var _transition: float = 1.0
var _elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_stage(value: int) -> void:
	_target_stage = clampi(value, 0, 3)
	if _target_stage == stage_index:
		return
	_transition = 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	if _transition < 1.0:
		_transition = minf(_transition + delta * 2.8, 1.0)
		if _transition >= 1.0:
			stage_index = _target_stage
	queue_redraw()

func _draw() -> void:
	var active_stage: int = _target_stage if _transition > 0.45 else stage_index
	var accent: Color = STAGE_COLORS[active_stage]
	var sky: Color = SKY_COLORS[active_stage]
	draw_rect(Rect2(Vector2.ZERO, size), sky)
	_draw_horizon(accent, active_stage)
	_draw_echo_path(accent)
	_draw_particles(accent, active_stage)
	if _transition < 1.0:
		var veil_alpha: float = sin(_transition * PI) * 0.36
		draw_rect(Rect2(Vector2.ZERO, size), Color(accent, veil_alpha))

func _draw_horizon(accent: Color, active_stage: int) -> void:
	var horizon_y: float = size.y * 0.62
	var far_color: Color = Color(accent.darkened(0.62), 0.42)
	var near_color: Color = Color(accent.darkened(0.78), 0.86)
	for index: int in range(10):
		var width: float = size.x / 9.0
		var left: float = index * width - width * 0.4
		var wave: float = sin(float(index) * 1.71 + _elapsed * 0.08) * 34.0
		var peak: float = horizon_y - 70.0 - wave - float((index + active_stage) % 3) * 34.0
		var polygon: PackedVector2Array = PackedVector2Array([
			Vector2(left, horizon_y + 80.0),
			Vector2(left + width * 0.5, peak),
			Vector2(left + width * 1.25, horizon_y + 80.0),
		])
		draw_colored_polygon(polygon, far_color)
	if active_stage == 2:
		_draw_arch(accent, horizon_y)
	elif active_stage == 3:
		_draw_mirror_shards(accent, horizon_y)
	else:
		var floor_polygon: PackedVector2Array = PackedVector2Array([
			Vector2(0.0, size.y),
			Vector2(size.x, size.y),
			Vector2(size.x * 0.64, horizon_y),
			Vector2(size.x * 0.37, horizon_y),
		])
		draw_colored_polygon(floor_polygon, near_color)
	for line_index: int in range(7):
		var ratio: float = float(line_index) / 6.0
		var y_position: float = lerpf(horizon_y, size.y, ratio * ratio)
		draw_line(Vector2(0.0, y_position), Vector2(size.x, y_position), Color(accent, 0.05), 1.0)

func _draw_arch(accent: Color, horizon_y: float) -> void:
	var center: Vector2 = Vector2(size.x * 0.73, horizon_y - 34.0)
	for ring: int in range(5):
		var radius: float = 42.0 + float(ring) * 13.0
		draw_arc(center, radius, PI, TAU, 48, Color(accent, 0.34 - float(ring) * 0.05), 8.0)
	draw_rect(Rect2(center + Vector2(-88.0, 0.0), Vector2(22.0, 130.0)), Color(accent, 0.32))
	draw_rect(Rect2(center + Vector2(66.0, 0.0), Vector2(22.0, 130.0)), Color(accent, 0.32))

func _draw_mirror_shards(accent: Color, horizon_y: float) -> void:
	for index: int in range(14):
		var seed: float = float(index) * 1.93
		var center: Vector2 = Vector2(
			size.x * (0.28 + fmod(seed * 0.17, 0.68)),
			horizon_y + 20.0 + fmod(seed * 47.0, maxf(size.y - horizon_y - 60.0, 40.0))
		)
		var shard_size: float = 12.0 + fmod(seed * 11.0, 26.0)
		var shard: PackedVector2Array = PackedVector2Array([
			center + Vector2(-shard_size, shard_size * 0.35),
			center + Vector2(shard_size * 0.2, -shard_size),
			center + Vector2(shard_size, shard_size * 0.55),
		])
		draw_colored_polygon(shard, Color(accent, 0.08 + float(index % 3) * 0.035))
		draw_polyline(shard + PackedVector2Array([shard[0]]), Color(accent, 0.28), 1.0)

func _draw_echo_path(accent: Color) -> void:
	var base_y: float = size.y * 0.74
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(9):
		var ratio: float = float(index) / 8.0
		var x_position: float = lerpf(size.x * 0.06, size.x * 0.94, ratio)
		var y_position: float = base_y + sin(ratio * TAU * 1.35 + _elapsed * 0.16) * size.y * 0.055
		points.append(Vector2(x_position, y_position))
	for echo_index: int in range(3, -1, -1):
		var echo_points: PackedVector2Array = PackedVector2Array()
		var offset: Vector2 = Vector2(float(echo_index) * 12.0, float(echo_index) * 7.0)
		for point: Vector2 in points:
			echo_points.append(point + offset)
		var alpha: float = 0.11 + float(3 - echo_index) * 0.1
		draw_polyline(echo_points, Color(accent, alpha), 2.0 + float(3 - echo_index), true)
	var pulse: float = (sin(_elapsed * 2.0) + 1.0) * 0.5
	var marker: Vector2 = points[5]
	draw_circle(marker + Vector2(34.0, 20.0), 5.0 + pulse * 2.0, Color(accent, 0.18))
	draw_circle(marker, 4.0 + pulse, accent)

func _draw_particles(accent: Color, active_stage: int) -> void:
	for index: int in range(22):
		var seed: float = float(index) * 17.47 + float(active_stage) * 8.1
		var x_position: float = fmod(seed * 41.0 + _elapsed * (2.0 + float(index % 4)), size.x + 80.0) - 40.0
		var y_position: float = fmod(seed * 29.0, maxf(size.y * 0.7, 1.0))
		var radius: float = 1.0 + float(index % 3)
		draw_circle(Vector2(x_position, y_position), radius, Color(accent, 0.08 + float(index % 4) * 0.025))
