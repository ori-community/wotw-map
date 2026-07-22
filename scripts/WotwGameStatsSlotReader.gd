extends RefCounted
class_name WotwGameStatsSlotReader


class DiscoveredItem:
	extends RefCounted
	
	var icon: IconProvider.MapIconType
	var label: String
	var x: float
	var y: float
	var collected_at: float  # NAN = not collected
	
	func _init(p_icon: IconProvider.MapIconType, p_label: String, p_x: float, p_y: float, p_collected_at: float) -> void:
		icon = p_icon
		label = p_label
		x = p_x
		y = p_y
		collected_at = p_collected_at


class AreaStats:
	extends RefCounted

	var in_game_time_spent: float = 0.0
	var deaths: int = 0
	var pickups_collected: int = 0


var in_game_time: float = 0.0
var time_lost_to_deaths: float = 0.0
var discovered_items: Dictionary[int, DiscoveredItem]
var area_stats: Dictionary[int, AreaStats]
var stream: EventsStream = EventsStream.new()


func set_json_data(json: Dictionary) -> void:
	discovered_items.clear()
	for item_id in json.discovered_items.keys():
		var item_dict: Dictionary = json.discovered_items[item_id]
		discovered_items.set(int(item_id), DiscoveredItem.new(
			int(item_dict.type),
			item_dict.label,
			item_dict.x,
			item_dict.y,
			NAN if item_dict.collected_at == null else item_dict.collected_at
		))


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
				var reason := reader.read_u32() as EventsStream.DisplacementReason
				var from := Vector2(reader.read_f32(), reader.read_f32())
				var to := Vector2(reader.read_f32(), reader.read_f32())
				var time_lost := reader.read_f32()

				time_lost_to_deaths += time_lost

				current_segment.points.push_back(from)
				current_segment.in_game_times.push_back(last_event_time)
				if !current_segment_finalized:
					stream.segments.push_back(current_segment)

				current_segment = EventsStream.PathSegment.new()
				current_segment_finalized = false

				current_segment.points.push_back(to)
				current_segment.in_game_times.push_back(last_event_time)

				# Populate virtual death stats
				if reason == EventsStream.DisplacementReason.Death:
					var stat_values := stream.get_current_area_death_stat_values()

					if stat_values != null:
						stat_values.add_value(in_game_time, stat_values.current_value() + 1)

			2:  # TimelineEntryEvent
				var _id := reader.read_u64()
				var _label := reader.read_string_with_length()
				var _icon := reader.read_u8()
				var _type := reader.read_u8()

			3:  # TimelineEntryEndEvent
				var _id := reader.read_u64()
				var _type := reader.read_u8()
				
			4:  # StatEvent
				var stat := reader.read_u8() as EventsStream.GameStat
				var value := reader.read_f32()
				stream.stat_values[stat].add_value(last_event_time, value)

	# If there's still a segment active, add it
	if !current_segment_finalized && !current_segment.points.is_empty():
		stream.segments.push_back(current_segment)

	stream.in_game_time_end = last_event_time
