@tool
extends VBoxContainer
class_name StatView


@onready var stat_value_label: Label = $StatValueLabel
@onready var stat_name_label: Label = $StatNameLabel


@export var stat_value: String = "0":
	set(value):
		stat_value = value
		if is_node_ready():
			_update_stat_value_label()
@export var stat_name: String = "Stat":
	set(value):
		stat_name = value
		if is_node_ready():
			_update_stat_name_label()


func _ready() -> void:
	_update_stat_name_label()
	_update_stat_value_label()


func _update_stat_value_label() -> void:
	stat_value_label.text = stat_value


func _update_stat_name_label() -> void:
	stat_name_label.text = stat_name
