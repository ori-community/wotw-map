extends GridContainer
class_name StatsAreasView


var stream: EventsStream:
	set(value):
		stream = value
		if is_node_ready():
			_update_stats_area_views()
var _stats_area_views: Array[StatsAreaView] = []


func _ready() -> void:
	for area in [
		EventsStream.GameArea.Marsh,
		EventsStream.GameArea.Hollow,
		EventsStream.GameArea.Glades,
		EventsStream.GameArea.Wellspring,
		EventsStream.GameArea.Woods,
		EventsStream.GameArea.Reach,
		EventsStream.GameArea.Depths,
		EventsStream.GameArea.Pools,
		EventsStream.GameArea.Wastes,
		EventsStream.GameArea.Ruins,
		EventsStream.GameArea.Willow,
		EventsStream.GameArea.Burrows,
	]:
		var view := preload("res://scenes/StatsAreaView.tscn").instantiate()
		view.area = area
		add_child(view)
		_stats_area_views.push_back(view)
	_update_stats_area_views()


func _update_stats_area_views() -> void:
	for view in _stats_area_views:
		view.stream = stream
