extends GridContainer
class_name StatsAreasView


@onready var vbox_1: VBoxContainer = %VBox1
@onready var vbox_2: VBoxContainer = %VBox2


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
		_stats_area_views.push_back(view)
	
	_update_stats_area_views()


func _update_stats_area_views() -> void:
	for view in _stats_area_views:
		view.stream = stream
	
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
