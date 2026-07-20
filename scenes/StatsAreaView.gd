extends PanelContainer
class_name StatsAreaView


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


@export var area_id: int = 0:
	set(value):
		area_id = value
		if is_node_ready():
			_update_background_image()

var stream: EventsStream:
	set(value):
		stream = value
		if is_node_ready():
			_update_stats_area_visits_bar()


func _ready() -> void:
	_update_background_image()
	_update_stats_area_visits_bar()


func _update_background_image() -> void:
	background_image.texture = BACKGROUND_IMAGES[area_id]


func _update_stats_area_visits_bar() -> void:
	stats_area_visits_bar.area_id = area_id
	stats_area_visits_bar.stream = stream
