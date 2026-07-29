extends TextureRect
class_name TimeMarker


@export var time_value: String:
	set(value):
		time_value = value
		
		if is_node_ready():
			_update_label()


@onready var label: Label = %Label


func _ready() -> void:
	_update_label()


func _update_label() -> void:
	label.text = time_value
