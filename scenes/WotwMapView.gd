extends Control
class_name WotwMapView


@onready var wotw_map: WotwMap = %WotwMap
@onready var events_view: EventsView = %EventsView
@onready var time_slider: HSlider = %TimeSlider
@onready var speed_slider: HSlider = %SpeedSlider
@onready var play_button: TextureButton = %PlayButton
@onready var speed_label: Label = %SpeedLabel
@onready var time_label: Label = %TimeLabel
@onready var follow_player_button: CheckButton = %FollowPlayerButton

var timeline_synchronizer: TimelineSynchronizer:
	set(value):
		timeline_synchronizer = value
		
		if is_node_ready():
			_update_child_timeline_synchronizers()

var _is_playing = false:
	set(value):
		_is_playing = value
		if value:
			play_button.texture_normal = preload("res://assets/ui/pause.svg")
		else:
			play_button.texture_normal = preload("res://assets/ui/play.svg")
var _is_dragging_any_slider = false


func _ready() -> void:
	speed_label.text = str(speed_slider.value, "x")
	_update_child_timeline_synchronizers()
	_update_time_label()


func _update_child_timeline_synchronizers() -> void:
	events_view.stream = timeline_synchronizer.stream
	time_slider.max_value = timeline_synchronizer.stream.in_game_time_end


func _process(delta: float) -> void:
	# Time progress
	if _is_playing && !_is_dragging_any_slider:
		time_slider.value += delta * speed_slider.value
		if time_slider.value >= time_slider.max_value:
			_is_playing = false
	
	# Follow players
	if follow_player_button.button_pressed:
		var current_map_center := wotw_map.map_in_game_center_position
		var target_map_center := events_view.stream.get_position_at_time(time_slider.value, current_map_center)

		if current_map_center.is_equal_approx(target_map_center):
			wotw_map.map_in_game_center_position = target_map_center
		else:
			var distance := current_map_center.distance_to(target_map_center)
			var speed := maxf(distance * 0.02, 5.0)
			# This causes the camera to pan instantly if the distance is too long (e.g. when the player teleported)
			var lerp_factor := (1.0 - 150.0 / distance) if distance > 400.0 else clampf(delta * speed, minf(5.0 * delta, 1.0), 1.0)
			wotw_map.map_in_game_center_position = current_map_center.lerp(target_map_center, lerp_factor)


func _update_time_label() -> void:
	time_label.text = str(StringUtils.format_time(time_slider.value), " / ", StringUtils.format_time(time_slider.max_value))


func _on_time_slider_value_changed(value: float) -> void:
	_update_time_label()
	events_view.slice_end_time = value


func _on_time_slider_drag_started() -> void:
	_is_dragging_any_slider = true


func _on_time_slider_drag_ended(_value_changed: bool) -> void:
	_is_dragging_any_slider = false


func _on_speed_slider_value_changed(value: float) -> void:
	speed_label.text = str(value, "x")


func _on_wotw_map_map_dragged() -> void:
	follow_player_button.button_pressed = false


func _on_follow_player_button_toggled(toggled_on: bool) -> void:
	wotw_map.zoom_to_cursor = !toggled_on


func _on_short_trails_button_toggled(toggled_on: bool) -> void:
	events_view.fade_out = toggled_on


func _on_button_zoom_to_fit_pressed() -> void:
	follow_player_button.button_pressed = false
	wotw_map.zoom_to_map_bounds()


func _on_play_button_pressed() -> void:
	_is_playing = !_is_playing


func _on_to_beginning_button_pressed() -> void:
	time_slider.value = 0


func _on_to_end_button_pressed() -> void:
	time_slider.value = time_slider.max_value
