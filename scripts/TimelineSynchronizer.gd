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
		_emit_changed()
var active: bool:
	set(value):
		active = value
		_emit_changed()

var _block_changed_signal: bool = false


func _emit_changed() -> void:
	if !_block_changed_signal:
		changed.emit(time, active)


func set_active_and_time(p_active: bool, p_time: float):
	_block_changed_signal = true
	active = p_active
	time = p_time
	_block_changed_signal = false
	_emit_changed()


func _init(p_stream: EventsStream) -> void:
	stream = p_stream
