extends Control

var unlock_progress: float = 0.0:
	set(value):
		unlock_progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var _elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	set_process(true)

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var pulse: float = (sin(_elapsed * 2.4) + 1.0) * 0.5
	var glow_alpha: float = 0.09 + pulse * 0.07 + unlock_progress * 0.24
	for ring: int in range(4, 0, -1):
		draw_circle(center + Vector2(0.0, 12.0), 28.0 + float(ring) * 13.0, Color(0.65, 0.91, 0.96, glow_alpha / float(ring)))
	_draw_shackle(center)
	_draw_body(center)
	if unlock_progress > 0.48:
		_draw_release_shards(center)

func _draw_shackle(center: Vector2) -> void:
	var rotation_amount: float = ease(maxf((unlock_progress - 0.34) / 0.66, 0.0), -1.8) * 0.52
	var lift: float = unlock_progress * 14.0
	draw_set_transform(center + Vector2(-24.0, -25.0 - lift), rotation_amount, Vector2.ONE)
	draw_arc(Vector2(24.0, 0.0), 31.0, PI, TAU, 32, Color(0.8, 0.88, 0.9, 1.0), 10.0, true)
	draw_line(Vector2(-7.0, 0.0), Vector2(-7.0, 28.0), Color(0.8, 0.88, 0.9, 1.0), 10.0)
	draw_line(Vector2(55.0, 0.0), Vector2(55.0, 28.0), Color(0.8, 0.88, 0.9, 1.0), 10.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_body(center: Vector2) -> void:
	var body_rect: Rect2 = Rect2(center + Vector2(-45.0, -5.0), Vector2(90.0, 70.0))
	draw_style_box(_make_body_style(), body_rect)
	var key_center: Vector2 = center + Vector2(0.0, 24.0)
	draw_circle(key_center, 9.0, Color(0.03, 0.07, 0.09, 1.0))
	var key_stem: PackedVector2Array = PackedVector2Array([
		key_center + Vector2(-5.0, 5.0),
		key_center + Vector2(5.0, 5.0),
		key_center + Vector2(3.0, 24.0),
		key_center + Vector2(-3.0, 24.0),
	])
	draw_colored_polygon(key_stem, Color(0.03, 0.07, 0.09, 1.0))
	if unlock_progress > 0.12:
		draw_circle(key_center, 4.0 + unlock_progress * 8.0, Color(0.73, 0.94, 0.98, unlock_progress * 0.72))

func _make_body_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("#26353b").lerp(Color("#8edce6"), unlock_progress * 0.28)
	style.border_color = Color(0.72, 0.86, 0.9, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	return style

func _draw_release_shards(center: Vector2) -> void:
	var shard_progress: float = (unlock_progress - 0.48) / 0.52
	for index: int in range(10):
		var angle: float = float(index) / 10.0 * TAU + 0.2
		var start: Vector2 = center + Vector2.from_angle(angle) * 58.0
		var finish: Vector2 = center + Vector2.from_angle(angle) * (58.0 + shard_progress * (22.0 + float(index % 3) * 9.0))
		draw_line(start, finish, Color(0.73, 0.94, 0.98, shard_progress * 0.68), 2.0)
