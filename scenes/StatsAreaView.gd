extends PanelContainer
class_name StatsAreaView


signal sort_requested


const BACKGROUND_IMAGES := [
	preload("res://assets/areas/0.jpg"),
	preload("res://assets/areas/1.jpg"),
	preload("res://assets/areas/2.jpg"),
	preload("res://assets/areas/3.jpg"),
	preload("res://assets/areas/4.jpg"),
	preload("res://assets/areas/5.jpg"),
	preload("res://assets/areas/6.jpg"),
	preload("res://assets/areas/7.jpg"),
	preload("res://assets/areas/8.jpg"),
	preload("res://assets/areas/9.jpg"),
	preload("res://assets/areas/10.jpg"),
	preload("res://assets/areas/11.jpg"),
]


@onready var stats_area_visits_bar: StatsAreaVisitsBar = %StatsAreaVisitsBar
@onready var background_image: TextureRect = %BackgroundImage
@onready var time_stat_view: StatView = %TimeStatView
@onready var deaths_stat_view: StatView = %DeathsStatView
@onready var pickups_stat_view: StatView = %PickupsStatView
@onready var area_name_label: Label = %AreaNameLabel


@export var area: EventsStream.GameArea = EventsStream.GameArea.Void:
	set(value):
		area = value
		if is_node_ready():
			_update_background_image()
			_update_area_name_label()

var stream: EventsStream:
	set(value):
		stream = value
		if is_node_ready():
			_update_stats_area_visits_bar()
			_update_stat_views()
var sort_priority: float = 0.0:
	set(value):
		sort_priority = value
		sort_requested.emit()


func _ready() -> void:
	_update_background_image()
	_update_stats_area_visits_bar()
	_update_stat_views()
	_update_area_name_label()


func _update_background_image() -> void:
	background_image.texture = BACKGROUND_IMAGES[area]


func _update_stats_area_visits_bar() -> void:
	stats_area_visits_bar.area = area
	stats_area_visits_bar.stream = stream


func _update_stat_views() -> void:
	if stream == null:
		return
	
	deaths_stat_view.stat_value = str(int(stream.get_area_death_stat_values(area).current_value()))

	var area_in_game_time := stream.get_area_in_game_time_stat_values(area).current_value()
	sort_priority = area_in_game_time
	time_stat_view.stat_value = StatView.format_duration(area_in_game_time)

	var pickups_collected := int(stream.get_area_pickups_collected_stat_values(area).current_value())
	var pickups_total := int(stream.get_area_pickups_total_stat_values(area).current_value())
	pickups_stat_view.stat_value = "%d / %d" % [pickups_collected, pickups_total]


func _update_area_name_label() -> void:
	area_name_label.text = EventsStream.get_long_area_name(area).to_upper()
