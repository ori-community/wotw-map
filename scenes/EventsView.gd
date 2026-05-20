extends Node2D
class_name EventsView


const PathSegmentLineScene := preload("res://scenes/PathSegmentLine.tscn")


@onready var segment_lines_container: Node2D = %SegmentLinesContainer
@onready var player_view: Node2D = %PlayerView


var slice_start_time: float = 0.0:
	set(value):
		slice_start_time = value
		for line in segment_lines:
			line.slice_start_time = value 
		_update_player_position()
var slice_end_time: float = 0.0:
	set(value):
		slice_end_time = value
		for line in segment_lines:
			line.slice_end_time = value 
		_update_player_position()
var fade_out: bool = true:
	set(value):
		fade_out = value
		for line in segment_lines:
			line.max_length_time = 30.0 if value else INF
var stream: EventsStream = null:
	set(value):
		stream = value
		_update_segment_lines()
		_update_player_position()
var segment_lines: Array[PathSegmentLine] = []


func _ready() -> void:
	_update_segment_lines()


func _update_segment_lines() -> void:
	if !is_node_ready():
		return
	
	for line in segment_lines:
		line.queue_free()
	
	if stream == null:
		return
	
	for segment in stream.segments:
		var line: PathSegmentLine = PathSegmentLineScene.instantiate()
		line.slice_start_time = slice_start_time
		line.slice_end_time = slice_end_time
		line.segment = segment
		segment_lines_container.add_child(line)
		segment_lines.push_back(line)


func _update_player_position() -> void:
	player_view.position = stream.get_position_at_time(slice_end_time)
