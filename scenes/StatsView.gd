extends VBoxContainer
class_name StatsView


@onready var stats_timeline_view: StatsTimelineView = %StatsTimelineView
@onready var stats_areas_view: StatsAreasView = %StatsAreasView
@onready var time_stat_view: StatView = %TimeStatView
@onready var deaths_stat_view: StatView = %DeathsStatView
@onready var time_lost_stat_view: StatView = %TimeLostStatView
@onready var teleports_stat_view: StatView = %TeleportsStatView
@onready var pickups_per_minute_stat_view: StatView = %PickupsPerMinuteStatView
@onready var pickups_stat_view: StatView = %PickupsStatView


var timeline_synchronizer: TimelineSynchronizer:
	set(value):
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.disconnect(_on_timeline_synchronizer_changed)
		timeline_synchronizer = value
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.connect(_on_timeline_synchronizer_changed)
		
		if is_node_ready():
			_update_views()


func _ready() -> void:
	_update_views()


func _update_stat_views() -> void:
	if timeline_synchronizer == null:
		return
	var stream := timeline_synchronizer.stream
	
	if timeline_synchronizer.active:
		time_stat_view.stat_value = StatView.format_duration(timeline_synchronizer.time)
		deaths_stat_view.stat_value = str(int(stream.stat_values[EventsStream.GameStat.Deaths].value_at_time(timeline_synchronizer.time)))
		time_lost_stat_view.stat_value = StatView.format_duration(stream.stat_values[EventsStream.GameStat.TimeLost].value_at_time(timeline_synchronizer.time))
		teleports_stat_view.stat_value = str(int(stream.stat_values[EventsStream.GameStat.Teleports].value_at_time(timeline_synchronizer.time)))
		
		if timeline_synchronizer.time > 0.0:
			pickups_per_minute_stat_view.stat_value = "%.1f" % (stream.stat_values[EventsStream.GameStat.PickupsCollected].value_at_time(timeline_synchronizer.time) / (timeline_synchronizer.time / 60.0))
		else:
			pickups_per_minute_stat_view.stat_value = "0.0"

		pickups_stat_view.stat_value = "%d / %d" % [
			int(stream.stat_values[EventsStream.GameStat.PickupsCollected].value_at_time(timeline_synchronizer.time)),
			int(stream.stat_values[EventsStream.GameStat.PickupsTotal].value_at_time(timeline_synchronizer.time))
		]
	else:
		time_stat_view.stat_value = StatView.format_duration(stream.in_game_time_end)
		deaths_stat_view.stat_value = str(int(stream.stat_values[EventsStream.GameStat.Deaths].current_value()))
		time_lost_stat_view.stat_value = StatView.format_duration(stream.stat_values[EventsStream.GameStat.TimeLost].current_value())
		teleports_stat_view.stat_value = str(int(stream.stat_values[EventsStream.GameStat.Teleports].current_value()))
		if stream.in_game_time_end == 0.0:
			pickups_per_minute_stat_view.stat_value = "%.1f" % 0.0
		else:
			pickups_per_minute_stat_view.stat_value = "%.1f" % (stream.stat_values[EventsStream.GameStat.PickupsCollected].current_value() / (stream.in_game_time_end / 60.0))
		pickups_stat_view.stat_value = "%d / %d" % [
			int(stream.stat_values[EventsStream.GameStat.PickupsCollected].current_value()),
			int(stream.stat_values[EventsStream.GameStat.PickupsTotal].current_value())
		]


func _update_views() -> void:
	stats_areas_view.timeline_synchronizer = timeline_synchronizer
	stats_timeline_view.timeline_synchronizer = timeline_synchronizer
	
	_update_stat_views()


func _on_timeline_synchronizer_changed(_time: float, _active: bool) -> void:
	_update_stat_views()
