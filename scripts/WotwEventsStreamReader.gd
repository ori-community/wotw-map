extends RefCounted
class_name WotwEventsStreamReader


var stream: EventsStream = EventsStream.new()

## Reads events from a chunk of event data and appends it to the stored
## events (segments, timeline_entries, map_entries)
func append_events(data: PackedByteArray) -> void:
	var reader := StreamReader.new(data)
	
	var current_segment: EventsStream.PathSegment
	var current_segment_finalized := false  # Whether current_segment was added to the segments list
	
	# If we don't have any segments yet, create a new one
	if stream.segments.is_empty():
		current_segment = EventsStream.PathSegment.new()
	else:
		current_segment = stream.segments[stream.segments.size() - 1]
		current_segment_finalized = true
	
	var last_event_time: float = stream.in_game_time_end
	while reader.available():
		var event_type := reader.read_u32()
		last_event_time = reader.read_f32()
		
		assert(last_event_time >= stream.in_game_time_end, "Non-linear events stream detected")
		
		match event_type:
			0:  # PositionEvent
				var position := Vector2(reader.read_f32(), reader.read_f32())
				current_segment.points.push_back(position)
				current_segment.in_game_times.push_back(last_event_time)
			1:  # DisplacementEvent
				var _type := reader.read_u32()
				var from := Vector2(reader.read_f32(), reader.read_f32())
				var to := Vector2(reader.read_f32(), reader.read_f32())
				var _time_lost := reader.read_f32()
				
				current_segment.points.push_back(from)
				current_segment.in_game_times.push_back(last_event_time)
				if !current_segment_finalized:
					stream.segments.push_back(current_segment)
				
				current_segment = EventsStream.PathSegment.new()
				current_segment_finalized = false
				
				current_segment.points.push_back(to)
				current_segment.in_game_times.push_back(last_event_time)
			2:  # TimelineEntryEvent
				var _label := reader.read_string_with_length()
				var _icon := reader.read_string_with_length()
			3:  # MapEntryEvent
				var _label := reader.read_string_with_length()
				var _icon := reader.read_string_with_length()
			4:  # StatEvent
				var stat := reader.read_u8() as EventsStream.GameStat
				var value := reader.read_i32()
				if (stat == EventsStream.GameStat.Health || stat == EventsStream.GameStat.Energy) && value == 999.0:
					continue
				stream.stat_values[stat].add_value(last_event_time, value)
	
	# If there's still a segment active, add it
	if !current_segment_finalized && !current_segment.points.is_empty():
		stream.segments.push_back(current_segment)
	
	stream.in_game_time_end = last_event_time
