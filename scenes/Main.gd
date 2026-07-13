extends Control

@onready var wotw_map: WotwMap = %WotwMap
@onready var graph_view: GraphView = %GraphView
@onready var events_view: EventsView = %EventsView
@onready var time_slider: HSlider = %TimeSlider
@onready var speed_slider: HSlider = %SpeedSlider
@onready var play_button: TextureButton = %PlayButton
@onready var speed_label: Label = %SpeedLabel
@onready var time_label: Label = %TimeLabel
@onready var follow_player_button: CheckButton = %FollowPlayerButton

var _is_playing = false:
	set(value):
		_is_playing = value
		if value:
			play_button.texture_normal = preload("res://assets/ui/Pause.svg")
		else:
			play_button.texture_normal = preload("res://assets/ui/Play.svg")
var _is_dragging_any_slider = false
var _javascript_call_object: JavaScriptObject = null


func _on_javascript_call(args: Array) -> void:
	if args.size() < 1:
		push_error("At least one argument required")
		return
	
	match args[0]:
		"echo":
			print(args.slice(1))
		"set_window_scale":
			get_window().content_scale_factor = args[1]
		"load_save_files":
			var save_files = args[1]
			print("Loading %d save file(s)" % save_files.length)
			
			for index in range(save_files.length):
				var save_file_name: String = save_files[index].name
				var save_file_data := JavaScriptBridge.js_buffer_to_packed_byte_array(save_files[index].data)
				print("Loading save file: ", save_file_name)
				var save_file_reader := WotwSaveFileReader.new(save_file_data)
				_load_game_stats(save_file_reader.game_stats_slot_reader)
		_:
			push_error("Unknown IPC command: %s" % args[0])


func _ready() -> void:
	if OS.has_feature("web"):
		_javascript_call_object = JavaScriptBridge.create_callback(_on_javascript_call)
		var window = JavaScriptBridge.get_interface("window")
		window.__godotBridge.call = _javascript_call_object
		window.__godotBridge.onGodotReady()
		print("Godot JavaScript bridge ready")
	else:
		# Dev mode: Load file from filesystem directly
		# In production, the "load_save_file" IPC call is used
		var save_file_reader := WotwSaveFileReader.new(FileAccess.get_file_as_bytes("C:/Users/Timo/AppData/Local/Ori and the Will of The Wisps/saveFile1.uberstate"))
		_load_game_stats(save_file_reader.game_stats_slot_reader)
	
	speed_label.text = str(speed_slider.value, "x")
	update_time_label()


func _load_game_stats(reader: WotwGameStatsSlotReader) -> void:
	events_view.stream = reader.stream
	time_slider.max_value = reader.stream.in_game_time_end
	graph_view.stream = reader.stream


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
			var speed := minf(current_map_center.distance_to(target_map_center) * 0.01, 5)
			wotw_map.map_in_game_center_position = current_map_center.lerp(target_map_center, clampf(delta * speed, minf(5 * delta, 1.0)  , 1.0))


func update_time_label() -> void:
	time_label.text = str(StringUtils.format_time(time_slider.value), " / ", StringUtils.format_time(time_slider.max_value))


func _on_time_slider_value_changed(value: float) -> void:
	update_time_label()
	events_view.slice_end_time = value


func _on_button_pressed() -> void:
	follow_player_button.button_pressed = false
	wotw_map.zoom_to_map_bounds()


func _on_time_slider_drag_started() -> void:
	_is_dragging_any_slider = true


func _on_time_slider_drag_ended(_value_changed: bool) -> void:
	_is_dragging_any_slider = false


func _on_speed_slider_value_changed(value: float) -> void:
	speed_label.text = str(value, "x")


func _on_button_beginning_pressed() -> void:
	time_slider.value = 0


func _on_button_end_pressed() -> void:
	time_slider.value = time_slider.max_value


func _on_button_play_pressed() -> void:
	_is_playing = !_is_playing


func _on_wotw_map_map_dragged() -> void:
	follow_player_button.button_pressed = false


func _on_follow_player_button_toggled(toggled_on: bool) -> void:
	wotw_map.zoom_to_cursor = !toggled_on


func _on_short_trails_button_toggled(toggled_on: bool) -> void:
	events_view.fade_out = toggled_on
