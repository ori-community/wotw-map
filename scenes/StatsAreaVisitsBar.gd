extends Control
class_name StatsAreaVisitsBar


class Segment:
	extends RefCounted

	var start_relative: float
	var end_relative: float

	func _init(p_start_relative: float):
		start_relative = p_start_relative


var stream: EventsStream:
	set(value):
		stream = value
		_reload_segments()
var _segments: Array[Segment] = []


func _reload_segments() -> void:
	_segments.clear()

	var stat_values := stream.stat_values[EventsStream.GameStat.CurrentArea]
	var active_segment: Segment = null

	for i in range(stat_values.in_game_times.size()):
		var in_game_time := stat_values.in_game_times[i]

		var value := stat_values.values[i]
		if value != 0:  # TODO: Hardcoded area ID
			if active_segment != null:
				active_segment.end_relative = inverse_lerp(0.0, stream.in_game_time_end, in_game_time)
				_segments.push_back(active_segment)
				active_segment = null
		elif active_segment == null:
			active_segment = Segment.new(inverse_lerp(0.0, stream.in_game_time_end, in_game_time))

	if active_segment != null:
		active_segment.end_relative = 1.0
		_segments.push_back(active_segment)


func _draw() -> void:
	var rect_size := get_rect().size
	for segment in _segments:
		var x_start_absolute := segment.start_relative * rect_size.x
		var width_absolute := segment.end_relative * rect_size.x - x_start_absolute

		draw_rect(
			Rect2(x_start_absolute, 0.0, width_absolute, rect_size.y),
			Color(0.494, 0.776, 0.976),
		)
