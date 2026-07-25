extends GridContainer
class_name StatsAreasView


@onready var vbox_1: VBoxContainer = %VBox1
@onready var vbox_2: VBoxContainer = %VBox2


var timeline_synchronizer: TimelineSynchronizer:
	set(value):
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.disconnect(_on_timeline_synchronizer_changed)
		timeline_synchronizer = value
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.connect(_on_timeline_synchronizer_changed)
		
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
		_stats_area_views.push_back(view)
	
	_update_stats_area_views()


func _update_stats_area_views() -> void:
	for view in _stats_area_views:
		view.timeline_synchronizer = timeline_synchronizer
	
	_stats_area_views.sort_custom(
		func(a: StatsAreaView, b: StatsAreaView):
			return a.sort_priority > b.sort_priority
	)

	for i in range(_stats_area_views.size()):
		var view := _stats_area_views[i]

		if view.is_inside_tree():
			view.get_parent().remove_child(view)

		if i < 6:
			vbox_1.add_child(view)
		else:
			vbox_2.add_child(view)


func _on_timeline_synchronizer_changed(time: float, active: bool) -> void:
	if active:
		var highlighted_area := int(timeline_synchronizer.stream.stat_values[EventsStream.GameStat.CurrentArea].value_at_time(time))
		for area_view in _stats_area_views:
			area_view.dim = area_view.area != highlighted_area
	else:
		for area_view in _stats_area_views:
			area_view.dim = false
