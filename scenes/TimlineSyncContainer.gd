extends MarginContainer
class_name TimelineSyncContainer


var timeline_synchronizer: TimelineSynchronizer

var _active: bool = false


func _update_timeline_synchronizer_time() -> void:
	timeline_synchronizer.time_relative = inverse_lerp(0.0, size.x, get_local_mouse_position().x)


func _gui_input(event: InputEvent) -> void:
	if !_active:
		return

	if event is InputEventMouseMotion:
		_update_timeline_synchronizer_time()


func _on_mouse_entered() -> void:
	_active = true
	timeline_synchronizer.active = true


func _on_mouse_exited() -> void:
	_active = false
	timeline_synchronizer.active = false
