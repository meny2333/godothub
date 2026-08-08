extends Control

const STAGE_COLORS: Array[Color] = [
	Color("#e8b554"),
	Color("#87a9bf"),
	Color("#f1d28e"),
	Color("#bdebf0"),
]

var stage_index: int = 0
var unlock_flash: float = 0.0:
	set(value):
		unlock_flash = clampf(value, 0.0, 1.0)
		queue_redraw()
var _elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_stage(value: int) -> void:
	stage_index = clampi(value, 0, STAGE_COLORS.size() - 1)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	var accent: Color = STAGE_COLORS[stage_index]
	_draw_dial(accent)
	_draw_mirror_edges(accent)
	_draw_reflection_sweep(accent)
	if unlock_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.78, 0.96, 1.0, unlock_flash * 0.72))

func _draw_dial(accent: Color) -> void:
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.48)
	var radius: float = minf(size.x * 0.34, 360.0)
	draw_arc(center, radius, PI * 1.08, PI * 1.92, 64, Color(accent, 0.15), 1.0)
	for index: int in range(15):
		var ratio: float = float(index) / 14.0
		var angle: float = lerpf(PI * 1.08, PI * 1.92, ratio)
		var inner: Vector2 = center + Vector2.from_angle(angle) * (radius - 8.0)
		var outer: Vector2 = center + Vector2.from_angle(angle) * radius
		var alpha: float = 0.42 if index % 7 == 0 else 0.16
		draw_line(inner, outer, Color(accent, alpha), 1.0)

func _draw_mirror_edges(accent: Color) -> void:
	var left_shard: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(size.x * 0.16, 0.0),
		Vector2(size.x * 0.08, size.y * 0.42),
		Vector2(size.x * 0.19, size.y),
		Vector2(0.0, size.y),
	])
	var right_shard: PackedVector2Array = PackedVector2Array([
		Vector2(size.x, 0.0),
		Vector2(size.x * 0.87, 0.0),
		Vector2(size.x * 0.94, size.y * 0.38),
		Vector2(size.x * 0.84, size.y),
		Vector2(size.x, size.y),
	])
	draw_colored_polygon(left_shard, Color(0.72, 0.86, 0.92, 0.055))
	draw_colored_polygon(right_shard, Color(0.72, 0.86, 0.92, 0.045))
	draw_polyline(left_shard, Color(accent, 0.22), 1.0, true)
	draw_polyline(right_shard, Color(accent, 0.18), 1.0, true)
	for index: int in range(6):
		var y_position: float = size.y * (0.12 + float(index) * 0.15)
		var length: float = 38.0 + float(index % 3) * 18.0
		draw_line(Vector2(0.0, y_position), Vector2(length, y_position - 28.0), Color(0.82, 0.93, 0.96, 0.14), 1.0)
		draw_line(Vector2(size.x, y_position + 12.0), Vector2(size.x - length, y_position - 18.0), Color(0.82, 0.93, 0.96, 0.11), 1.0)

func _draw_reflection_sweep(accent: Color) -> void:
	var sweep_width: float = 110.0
	var cycle: float = fmod(_elapsed * 92.0, size.x + sweep_width * 2.0) - sweep_width
	var sweep: PackedVector2Array = PackedVector2Array([
		Vector2(cycle - sweep_width, size.y),
		Vector2(cycle, 0.0),
		Vector2(cycle + sweep_width * 0.28, 0.0),
		Vector2(cycle - sweep_width * 0.72, size.y),
	])
	draw_colored_polygon(sweep, Color(accent.lightened(0.5), 0.055))
