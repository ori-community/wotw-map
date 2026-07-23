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


static func format_duration(total_seconds: float) -> String:
	var hours := floori(total_seconds / 3600.0)
	var minutes := floori(fmod(total_seconds, 3600.0) / 60.0)
	var seconds := fmod(total_seconds, 60.0)
	var deciseconds := fmod(total_seconds, 1.0) * 10.0
	
	if hours > 0:
		return "%d:%02d:%02d.%1d" % [hours, minutes, seconds, deciseconds]
	else:
		return "%d:%02d.%1d" % [minutes, seconds, deciseconds]
