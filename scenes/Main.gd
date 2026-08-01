extends Control


enum Page {
	Stats,
	Map,
}


@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var stats_button: Button = %StatsButton
@onready var map_button: Button = %MapButton
@onready var copy_image_button: Button = %CopyImageButton


var _javascript_call_object: JavaScriptObject = null
var _current_page: Page = Page.Stats:
	set(value):
		_current_page = value
		if is_node_ready():
			_load_page()
			_update_button_visibilities()
var _timeline_synchronizer: TimelineSynchronizer = null
var _page_node: Control = null


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
				_timeline_synchronizer = TimelineSynchronizer.new(save_file_reader.game_stats_slot_reader.stream)
		"load_game_stats_slot_data":
			var slot_data = JavaScriptBridge.js_buffer_to_packed_byte_array(args[1]) as PackedByteArray
			print("Loading game stats slot data (length = %d)" % slot_data.size())
			var reader := WotwGameStatsSlotReader.new()
			reader.append_events(slot_data)
			_timeline_synchronizer = TimelineSynchronizer.new(reader.stream)
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
		_timeline_synchronizer = TimelineSynchronizer.new(save_file_reader.game_stats_slot_reader.stream)
	
	_load_page()
	_update_button_visibilities()


func _update_button_visibilities() -> void:
	map_button.visible = _current_page == Page.Stats
	stats_button.visible = _current_page == Page.Map
	copy_image_button.visible = _current_page == Page.Stats


func _load_page() -> void:
	if _page_node != null:
		_page_node.queue_free()
		_page_node = null
	
	match _current_page:
		Page.Stats:
			var stats_view: StatsView = load("res://scenes/StatsView.tscn").instantiate()
			stats_view.timeline_synchronizer = _timeline_synchronizer
			_page_node = stats_view
		Page.Map:
			var map_view: WotwMapView = load("res://scenes/WotwMapView.tscn").instantiate()
			map_view.timeline_synchronizer = _timeline_synchronizer
			_page_node = map_view
	
	if _page_node != null:
		scroll_container.add_child(_page_node)


func _on_copy_image_button_pressed() -> void:
	var image := await StatsImageRenderer.render(_timeline_synchronizer.stream)
	
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		var png_buffer := image.save_png_to_buffer()
		
		var js_buffer = JavaScriptBridge.create_object("ArrayBuffer", png_buffer.size())
		var js_array = JavaScriptBridge.create_object("Uint8Array", js_buffer)
		for byte_i in range(png_buffer.size()):
			js_array[byte_i] = png_buffer[byte_i]
		
		window.__godotBridge.copyImageToClipboard(js_buffer)
	else:
		image.save_png("C:/Users/Timo/screenshot.png")


func _on_map_button_pressed() -> void:
	_current_page = Page.Map


func _on_stats_button_pressed() -> void:
	_current_page = Page.Stats
