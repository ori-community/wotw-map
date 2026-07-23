extends Control
class_name StatsAreaVisitsBar


class Segment:
	extends RefCounted

	var in_game_time_start: float
	var in_game_time_end: float
	var thickness: Curve

	func _init(p_in_game_time_start: float):
		in_game_time_start = p_in_game_time_start


@export var area: EventsStream.GameArea:
	set(value):
		area = value
		if is_node_ready():
			_reload_segments()


@onready var lines_container: Control = %LinesContainer


var stream: EventsStream:
	set(value):
		stream = value
		if is_node_ready():
			_reload_segments()
var _segments: Array[Segment] = []
var _lines: Array[Line2D] = []


func _ready() -> void:
	_reload_segments()
	_on_resized()


func _reload_segments() -> void:
	_segments.clear()
	
	if stream == null:
		return

	var stat_values := stream.stat_values[EventsStream.GameStat.CurrentArea]
	var active_segment: Segment = null

	for i in range(stat_values.in_game_times.size()):
		var in_game_time := stat_values.in_game_times[i]

		var value := stat_values.values[i]
		if value != area:
			if active_segment != null:
				active_segment.in_game_time_end = in_game_time
				_segments.push_back(active_segment)
				active_segment = null
		elif active_segment == null:
			active_segment = Segment.new(in_game_time)

	if active_segment != null:
		active_segment.in_game_time_end = stream.in_game_time_end
		_segments.push_back(active_segment)
	
	_update_lines()


func _update_lines() -> void:
	for line in _lines:
		line.queue_free()
	_lines.clear()

	if stream == null:
		return

	var height := lines_container.size.y
	var absolute_width := get_rect().size.x
	var pickups_per_second_stat_values := stream.stat_values[EventsStream.GameStat.PickupsPerSecond]

	for segment in _segments:
		var line := Line2D.new()
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.default_color = Color(0.494, 0.776, 0.976)
		line.width = 3.0
		line.antialiased = true

		var x_start := inverse_lerp(0.0, stream.in_game_time_end, segment.in_game_time_start)
		var x_end := inverse_lerp(0.0, stream.in_game_time_end, segment.in_game_time_end)
		var width_absolute := x_end - x_start
		line.position = Vector2(x_start, height / 2.0)

		var line_segments := ceili(width_absolute * absolute_width * 0.5)
		var line_segment_width := width_absolute / float(line_segments)
		for i in range(line_segments):
			line.add_point(Vector2(line_segment_width * i, 0))
		
		line.width_curve = Curve.new()
		line.width_curve.min_domain = -4.0
		line.width_curve.max_domain = 5.0
		line.width_curve.min_value = 1.0
		line.width_curve.max_value = height / line.width

		var pickups_per_second_start_index := pickups_per_second_stat_values.index_at_time(segment.in_game_time_start, true)
		var pickups_per_second_end_index := pickups_per_second_stat_values.index_at_time(segment.in_game_time_end, false)
		for index in range(pickups_per_second_start_index, pickups_per_second_end_index + 1):
			# For the last segment, just repeat the previous value
			if index >= pickups_per_second_stat_values.values.size():
				index -= 1

			var value := pickups_per_second_stat_values.values[index]
			var in_game_time := pickups_per_second_stat_values.in_game_times[index]
			
			line.width_curve.add_point(
				Vector2(
					inverse_lerp(segment.in_game_time_start, segment.in_game_time_end, in_game_time),
					maxf(
						1.0,
						remap(value, 0.0, pickups_per_second_stat_values.max_value, line.width_curve.min_value, line.width_curve.max_value),
					)
				)
			)

		lines_container.add_child(line)
		_lines.push_back(line)


func _on_resized() -> void:
	if is_node_ready():
		lines_container.scale.x = get_rect().size.x
		_update_lines()
