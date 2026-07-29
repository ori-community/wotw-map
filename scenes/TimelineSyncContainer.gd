extends MarginContainer
class_name TimelineSyncContainer


@export var hover_delay: float = 0.0


@onready var timer: Timer = %Timer


var timeline_synchronizer: TimelineSynchronizer

var _active: bool = false
var _hovered_relative_time: float = 0.0


func _update_timeline_synchronizer_time() -> void:
	timeline_synchronizer.time_relative = _hovered_relative_time


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hovered_relative_time = inverse_lerp(0.0, size.x, get_local_mouse_position().x)

		if _active:
			_update_timeline_synchronizer_time()


func _on_mouse_entered() -> void:
	if hover_delay > 0.0:
		timer.start(hover_delay)
	else:
		_active = true
		timeline_synchronizer.active = true


func _on_mouse_exited() -> void:
	timer.stop()
	_active = false
	timeline_synchronizer.active = false


func _on_timer_timeout() -> void:
	_active = true
	timeline_synchronizer.active = true
	_update_timeline_synchronizer_time()
