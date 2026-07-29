extends Control
class_name StatsTimelineView


var timeline_synchronizer: TimelineSynchronizer:
	set(value):
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.disconnect(_on_timeline_synchronizer_changed)
		timeline_synchronizer = value
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.connect(_on_timeline_synchronizer_changed)
		
		if is_node_ready():
			_update_timeline()


func _update_timeline() -> void:
	pass


func _on_timeline_synchronizer_changed(_time: float, _active: bool) -> void:
	pass
