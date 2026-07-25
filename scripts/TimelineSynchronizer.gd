extends RefCounted
class_name TimelineSynchronizer


signal changed(time: float, active: bool)


var stream: EventsStream
var time_relative: float:
	set(value):
		time = value * stream.in_game_time_end
	get():
		return time / stream.in_game_time_end
var time: float:
	set(value):
		time = value
		changed.emit(time, active)
var active: bool:
	set(value):
		active = value
		changed.emit(time, active)


func _init(p_stream: EventsStream) -> void:
	stream = p_stream
