extends Line2D
class_name PathSegmentLine


@export var width_curve_when_max_length_time_enabled: Curve


var slice_start_time: float = 0.0:  ## Display from this time in seconds
	set(value):
		slice_start_time = value
		_update_line()
var slice_end_time: float = INF:  ## Display up until this time in seconds
	set(value):
		slice_end_time = value
		_update_line()
var segment: EventsStream.PathSegment = null:
	set(value):
		segment = value
		_update_line()
var max_length_time: float = INF:  ## Clip the segment to a max length in seconds
	set(value):
		max_length_time = value
		_update_line()


func _ready() -> void:
	_update_line()


## Returns the index of the first segment point that is supposed to be visible
func _get_start_index() -> int:
	var actual_start := maxf(slice_start_time, slice_end_time - max_length_time)
	
	if actual_start == 0.0:
		return 0
	
	return maxi(0, segment.in_game_times.bsearch(actual_start, false) - 1)


## Returns the index of the last segment point that is supposed to be visible
func _get_end_index() -> int:
	if slice_end_time == INF:
		return segment.in_game_times.size() - 1
	
	return maxi(0, segment.in_game_times.bsearch(slice_end_time, false) - 1)
	

func _update_line() -> void:
	if !is_node_ready() || segment == null:
		return

	if segment.start_time() > slice_end_time || slice_start_time > segment.end_time():
		visible = false
		return
	
	var new_points := segment.points.slice(_get_start_index(), _get_end_index())
	
	if new_points.is_empty():
		visible = false
		return
	
	width_curve = null if max_length_time == INF else width_curve_when_max_length_time_enabled
	visible = true
	points = new_points
