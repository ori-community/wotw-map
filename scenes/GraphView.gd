extends Control
class_name GraphView


var lines: Array[Line2D] = []
var stream: EventsStream:
	set(value):
		stream = value
		_recreate_lines()


func _recreate_lines() -> void:
	for line in lines:
		line.queue_free()
	lines.clear()
	
	#_render_graph(EventsStream.GameStat.Health, Color.GREEN)
	#_render_graph(EventsStream.GameStat.MaxHealth, Color.SEA_GREEN)
	
	# _render_graph(EventsStream.GameStat.Energy, Color.DEEP_SKY_BLUE)
	# _render_graph(EventsStream.GameStat.MaxEnergy, Color.DODGER_BLUE)
	
	_render_graph(EventsStream.GameStat.PickupsCollectedDepths, Color.ORANGE)
	# _render_graph(EventsStream.GameStat.KeystonesCollected, Color.RED)


func _render_graph(stat: EventsStream.GameStat, color: Color) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = color
	lines.push_back(line)
	add_child(line)
	
	var stat_values := stream.stat_values[stat]
	var last_y: float = 0.0
	for i in range(stat_values.in_game_times.size()):
		var in_game_time := stat_values.in_game_times[i]
		var value := stat_values.values[i]
		
		line.add_point(
			Vector2(
				remap(in_game_time, 0.0, stream.in_game_time_end, 0.0, size.x),
				last_y
			)
		)
		
		last_y = remap(value, 0.0, stat_values.max_value, size.y, 0.0)
		line.add_point(
			Vector2(
				remap(in_game_time, 0.0, stream.in_game_time_end, 0.0, size.x),
				last_y
			)
		)


func _on_resized() -> void:
	if stream != null:
		_recreate_lines()
