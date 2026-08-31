extends Control
class_name StatsTimelineView


class TimelineEntryViewWithMetadata:
	extends RefCounted

	var view: TimelineEntryView
	var entry: EventsStream.TimelineEntry

	func _init(p_view: TimelineEntryView, p_entry: EventsStream.TimelineEntry) -> void:
		view = p_view
		entry = p_entry


const MAX_TIME_MARKER_COUNT: int = 6


@export var icon_provider: IconProvider = preload("res://assets/wotw_icons.tres")
@export var lane_height_ability: float = 80.0
@export var lane_height_custom: float = 50.0


@onready var timeline_sync_container: TimelineSyncContainer = %TimlineSyncContainer
@onready var timeline_entry_container: Control = %TimelineEntryContainer
@onready var time_marker_container: Control = %TimeMarkerContainer


var timeline_synchronizer: TimelineSynchronizer:
	set(value):
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.disconnect(_on_timeline_synchronizer_changed)
		timeline_synchronizer = value
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.connect(_on_timeline_synchronizer_changed)
		
		if is_node_ready():
			_update_timeline()

var _entry_views_with_metadata: Array[TimelineEntryViewWithMetadata] = []
var _in_game_time_end: float = 0.0
var _time_markers: Array[TimeMarker] = []
var _cursor_time_marker: TimeMarker = null
var _timeline_max_x: float = 0.0


func _ready() -> void:
	_update_timeline()
	timeline_sync_container.offset_right = -lane_height_ability


func _update_timeline() -> void:
	timeline_sync_container.timeline_synchronizer = timeline_synchronizer
	
	for view_and_metadata in _entry_views_with_metadata:
		view_and_metadata.view.queue_free()
	_entry_views_with_metadata.clear()
	
	if timeline_synchronizer == null:
		return
	var stream := timeline_synchronizer.stream

	_in_game_time_end = stream.in_game_time_end

	for entry in stream.timeline_entries.entries:
		var entry_view := preload("res://scenes/TimelineEntryView.tscn").instantiate() as TimelineEntryView
		entry_view.texture = icon_provider.get_icon_texture_or_default(entry.icon)
		entry_view.tooltip_title = entry.label

		if entry.has_end():
			entry_view.tooltip_description = "%s - %s" % [
				StringUtils.format_time(entry.in_game_time),
				StringUtils.format_time(entry.in_game_time_end),
			]
		else:
			entry_view.tooltip_description = StringUtils.format_time(entry.in_game_time)
		
		entry_view.size.y = lane_height_ability
		_entry_views_with_metadata.push_back(TimelineEntryViewWithMetadata.new(entry_view, entry))
	_update_layout()


func _update_layout() -> void:
	_timeline_max_x = size.x - max(lane_height_ability, lane_height_custom)  # This is to leave space for icons on the right side
	
	var abilities_y_end := _layout_entries_with_type(EventsStream.TimelineEntry.Type.Ability, lane_height_ability, 0.0)
	var custom_y_end := _layout_entries_with_type(EventsStream.TimelineEntry.Type.Custom, lane_height_custom, abilities_y_end + 16.0)

	custom_minimum_size.y = custom_y_end + 32.0  # 32px for time markers
	_update_time_markers.call_deferred()


func _layout_entries_with_type(type: EventsStream.TimelineEntry.Type, lane_height: float, y_start: float) -> float:
	var timeline_lane_widths: Array[float] = [-1.0]  # The maximum x coordinates each lane is occupied up to
	
	for entry_view_with_metadata in _entry_views_with_metadata:
		if entry_view_with_metadata.entry.type != type:
			continue
		
		var entry_view := entry_view_with_metadata.view
		var entry := entry_view_with_metadata.entry

		entry_view.texture = icon_provider.get_icon_texture_or_default(entry.icon)
		entry_view.size.y = lane_height

		entry_view.position.x = remap(entry.in_game_time, 0.0, _in_game_time_end, 0.0, _timeline_max_x)
		if entry.has_end():
			entry_view.entry_width = remap(entry.in_game_time_end - entry.in_game_time, 0.0, _in_game_time_end, 0.0, _timeline_max_x)
		
		if !entry_view.is_inside_tree():
			timeline_entry_container.add_child(entry_view)

		var entry_end_x := entry_view.position.x + entry_view.size.x
		var found_lane := false
		for i in range(timeline_lane_widths.size()):
			if timeline_lane_widths[i] + 2 < entry_view.position.x:
				entry_view.position.y = y_start + i * lane_height
				timeline_lane_widths[i] = entry_end_x
				found_lane = true
				break
		
		if found_lane:
			continue
		
		timeline_lane_widths.push_back(entry_end_x)
		entry_view.position.y = y_start + (timeline_lane_widths.size() - 1) * lane_height
	
	return y_start + timeline_lane_widths.size() * lane_height


func _update_time_markers() -> void:
	var marker_interval := 1.0
	var predefined_marker_intervals := [
		60 * 60.0,
		30 * 60.0,
		20 * 60.0,
		15 * 60.0,
		10 * 60.0,
		5 * 60.0,
		60.0,
		30.0,
		15.0,
		5.0,
	]
	
	while _in_game_time_end / marker_interval > MAX_TIME_MARKER_COUNT:
		if predefined_marker_intervals.is_empty():
			marker_interval += 60 * 60.0  # Try out 1h intervals
		else:
			marker_interval = predefined_marker_intervals.pop_back()
	
	var marker_count = floori(_in_game_time_end / marker_interval)
	
	while _time_markers.size() > marker_count:
		_time_markers.pop_back().queue_free()
	while _time_markers.size() < marker_count:
		var marker := preload("res://scenes/TimeMarker.tscn").instantiate() as TimeMarker
		marker.modulate.a = 0.3
		marker.position.y = 0
		time_marker_container.add_child(marker)
		_time_markers.push_back(marker)
	
	for i in range(marker_count):
		var marker := _time_markers[i]
		var time := (i + 1) * marker_interval
		
		marker.size.y = size.y
		marker.position.x = remap(time, 0.0, _in_game_time_end, 0.0, _timeline_max_x)
		marker.time_value = StatView.format_duration(time, false)
	
	if _cursor_time_marker != null:
		_update_cursor_time_marker()


func _on_timeline_synchronizer_changed(_time: float, active: bool) -> void:
	if active:
		if _cursor_time_marker == null:
			_cursor_time_marker = preload("res://scenes/TimeMarker.tscn").instantiate() as TimeMarker
			time_marker_container.add_child(_cursor_time_marker)
		_update_cursor_time_marker()
	elif _cursor_time_marker != null:
		_cursor_time_marker.queue_free()
		_cursor_time_marker = null


func _update_cursor_time_marker() -> void:
	_cursor_time_marker.size.y = size.y
	if _in_game_time_end == 0.0:
		_cursor_time_marker.position.x = 0.0
	else:
		_cursor_time_marker.position.x = remap(timeline_synchronizer.time, 0.0, _in_game_time_end, 0.0, _timeline_max_x)
	_cursor_time_marker.time_value = StatView.format_duration(timeline_synchronizer.time, false)


func _on_resized() -> void:
	if is_node_ready():
		_update_layout()
