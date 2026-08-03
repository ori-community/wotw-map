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
@onready var ori_running_texture_rect: TextureRect = %OriRunningTextureRect
@onready var background_image_container: Control = %BackgroundImageContainer


var timeline_synchronizer: TimelineSynchronizer:
	set(value):
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.disconnect(_on_timeline_synchronizer_changed)
		timeline_synchronizer = value
		if timeline_synchronizer != null:
			timeline_synchronizer.changed.connect(_on_timeline_synchronizer_changed)
		
		if is_node_ready():
			_update_views()
var _background_image_area: EventsStream.GameArea = EventsStream.GameArea.Void:
	set(value):
		if value == _background_image_area:
			return
		
		_background_image_area = value
		
		if is_node_ready():
			_transition_area_background_image()
var _background_image_texture_rect: FadingBackgroundImageTextureRect = null
var _ori_running_tween: Tween = null
var _background_image_transition_blocked_for: float = 0.0
var _background_image_transition_queued: bool = false


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


func _on_timeline_synchronizer_changed(time: float, active: bool) -> void:
	_update_stat_views()
	
	if active:
		_background_image_area = int(timeline_synchronizer.stream.stat_values[EventsStream.GameStat.CurrentArea].value_at_time(time, true)) as EventsStream.GameArea
	else:
		_background_image_area = EventsStream.GameArea.Void


func _process(delta: float) -> void:
	if _background_image_transition_blocked_for > 0.0:
		_background_image_transition_blocked_for -= delta
		if _background_image_transition_blocked_for <= 0.0 && _background_image_transition_queued:
			_background_image_transition_queued = false
			_transition_area_background_image()


func _transition_area_background_image() -> void:
	if _background_image_transition_blocked_for > 0.0:
		_background_image_transition_queued = true
		return
	_background_image_transition_blocked_for = 0.2
	
	if _background_image_texture_rect != null:
		_background_image_texture_rect.fade_out_and_free()
		_background_image_texture_rect = null
	
	if _background_image_area == EventsStream.GameArea.Void:
		if _ori_running_tween != null:
			_ori_running_tween.kill()
		_ori_running_tween = ori_running_texture_rect.create_tween()
		_ori_running_tween.tween_property(ori_running_texture_rect, "self_modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		_background_image_texture_rect = preload("res://scenes/FadingBackgroundImageTextureRect.tscn").instantiate()
		_background_image_texture_rect.texture = StatsAreaView.BACKGROUND_IMAGES[_background_image_area]
		background_image_container.add_child(_background_image_texture_rect)
		
		if _ori_running_tween != null:
			_ori_running_tween.kill()
		_ori_running_tween = ori_running_texture_rect.create_tween()
		_ori_running_tween.tween_property(ori_running_texture_rect, "self_modulate:a", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
