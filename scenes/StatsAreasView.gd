extends GridContainer
class_name StatsAreasView


var stream: EventsStream:
	set(value):
		stream = value
		if is_node_ready():
			_update_stats_area_views()
var _stats_area_views: Array[StatsAreaView] = []


func _ready() -> void:
	for area_id in range(12):
		var view := preload("res://scenes/StatsAreaView.tscn").instantiate()
		view.area_id = area_id
		add_child(view)
		_stats_area_views.push_back(view)
	_update_stats_area_views()


func _update_stats_area_views() -> void:
	for view in _stats_area_views:
		view.stream = stream
