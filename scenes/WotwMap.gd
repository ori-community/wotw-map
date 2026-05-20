extends Control
class_name WotwMap


signal map_in_game_center_changed(center: Vector2)
signal map_dragged


@export var in_game_map_bounds: Rect2 = Rect2(Vector2(-2023, -4656), Vector2(4405, 1233))
@export var zoom_to_cursor: bool = true


@onready var origin: Node2D = %Origin
@onready var in_game_origin: Node2D = %InGameOrigin
@onready var slot: Node2D = %Slot


const SCROLL_ZOOM_SPEED := 0.04

var _nodes_to_reparent_to_in_game_origin: Array[Node] = []
var _is_dragging: bool = false
var _map_in_game_center_position_cache: Vector2 = Vector2(0, 0)  ## Cache to recenter the map when the control is resized
var map_in_game_center_position: Vector2:
	set(value):
		_map_in_game_center_position_cache = value
		if is_node_ready():
			_update_map_position(value)
		map_in_game_center_changed.emit(value)
	get():
		return in_game_origin.to_local(get_global_rect().get_center())
var map_scale: float:
	set(value):
		if is_node_ready():
			var current_center = map_in_game_center_position
			origin.scale.x = value
			origin.scale.y = value
			_update_map_position(current_center)
	get():
		return origin.scale.x
		
func _ready() -> void:
	for node in _nodes_to_reparent_to_in_game_origin:
		node.reparent(slot, false)
	_nodes_to_reparent_to_in_game_origin.clear()
	
	_map_in_game_center_position_cache = map_in_game_center_position
		
	# Add @tool to this script and reload the scene in the editor
	# to regenerate map tile sprites.
	if Engine.is_editor_hint() && get_child_count() == 0:
		_editor_create_map_tiles()
		

func _editor_create_map_tiles() -> void:
	for x in range(36):
		for y in range(9):
			var resource_path := "res://assets/wotw-map-tiles/tile-%d_%d.png" % [x, y]
			
			if !ResourceLoader.exists(resource_path):
				continue
			
			var sprite := Sprite2D.new()
			sprite.texture = load(resource_path)
			sprite.name = "Tile-%d-%d" % [x, y]
			sprite.centered = false
			add_child(sprite)
			sprite.set_owner(get_tree().get_edited_scene_root())
			sprite.global_position = Vector2(x * 512, y * 512)


func get_in_game_mouse_position() -> Vector2:
	return in_game_origin.get_local_mouse_position()


func _zoom_around_screen_position(screen_position: Vector2, factor: float) -> void:
	var local_position := origin.to_local(screen_position)
	origin.scale *= factor
	var global_position_after := origin.to_global(local_position)
	origin.position += screen_position - global_position_after
	map_in_game_center_changed.emit(map_in_game_center_position)


func _zoom(factor: float) -> void:
	var screen_center := get_global_rect().get_center()
	var local_position := origin.to_local(screen_center)
	origin.scale *= factor
	var global_position_after := origin.to_global(local_position)
	origin.position += screen_center - global_position_after


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MouseButton.MOUSE_BUTTON_LEFT:
				_is_dragging = event.pressed
			MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
				if zoom_to_cursor:
					_zoom_around_screen_position(get_global_mouse_position(), 1.0 - SCROLL_ZOOM_SPEED)
					map_dragged.emit()
				else:
					_zoom(1.0 - SCROLL_ZOOM_SPEED)
			MouseButton.MOUSE_BUTTON_WHEEL_UP:
				if zoom_to_cursor:
					_zoom_around_screen_position(get_global_mouse_position(), 1.0 + SCROLL_ZOOM_SPEED)
					map_dragged.emit()
				else:
					_zoom(1.0 + SCROLL_ZOOM_SPEED)

	elif event is InputEventMouseMotion:
		if _is_dragging:
			origin.position += event.relative
			map_in_game_center_changed.emit(map_in_game_center_position)
			map_dragged.emit()


func _on_resized() -> void:
	map_in_game_center_position = _map_in_game_center_position_cache

	
func _update_map_position(center: Vector2):
	var position_offset := get_global_rect().get_center() - in_game_origin.to_global(center)
	origin.position += position_offset

func _process(delta: float) -> void:
	# Clamp map to drag limits
	if !_is_dragging:
		var current_map_in_game_center_position := map_in_game_center_position
		var map_bounds_bottom_left := in_game_map_bounds.position
		var map_bounds_top_right := in_game_map_bounds.end

		var is_out_of_drag_bounds_x := current_map_in_game_center_position.x < map_bounds_bottom_left.x || current_map_in_game_center_position.x > map_bounds_top_right.x
		var is_out_of_drag_bounds_y := current_map_in_game_center_position.y > map_bounds_top_right.y || current_map_in_game_center_position.y < map_bounds_bottom_left.y
		
		if is_out_of_drag_bounds_x || is_out_of_drag_bounds_y:
			var clamped_map_center_position = Vector2(
				clampf(current_map_in_game_center_position.x, map_bounds_bottom_left.x, map_bounds_top_right.x),
				clampf(current_map_in_game_center_position.y, map_bounds_bottom_left.y, map_bounds_top_right.y),
			)
			
			var new_position := current_map_in_game_center_position.lerp(clamped_map_center_position, delta * 20.0)
			
			if clamped_map_center_position.is_equal_approx(new_position):
				map_in_game_center_position = clamped_map_center_position
			else:
				map_in_game_center_position = new_position


func _on_map_in_game_center_changed(center: Vector2) -> void:
	_map_in_game_center_position_cache = center


func _on_child_entered_tree(node: Node) -> void:
	if !node.is_in_group("MapOrigin"):
		if is_node_ready():
			node.reparent(slot, false)
		else:
			_nodes_to_reparent_to_in_game_origin.push_back(node)


func transition_view(in_game_center: Vector2, target_map_scale: float = map_scale) -> void:
	create_tween().tween_property(self, "map_in_game_center_position", in_game_center, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(self, "map_scale", target_map_scale, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func zoom_to_bounds(in_game_bounds: Rect2) -> void:
	var screen_rect = in_game_origin.global_transform * in_game_bounds

	var scale_x = origin.scale.x / (screen_rect.size.x / self.size.x)
	var scale_y = origin.scale.y / (screen_rect.size.y / self.size.y)
	var min_scale = min(scale_x, scale_y)
	
	transition_view(in_game_bounds.get_center(), min_scale)


func zoom_to_points(in_game_points: Array[Vector2]):
	match in_game_points.size():
		0:
			push_error("in_game_points was empty")
			return
		1:
			transition_view(in_game_points[0])
			return
		_:
			var rect:= Rect2(in_game_points[0], Vector2.ZERO)
			
			for point in in_game_points.slice(1):
				rect = rect.expand(point)
			
			zoom_to_bounds(rect)


func zoom_to_map_bounds():
	zoom_to_bounds(in_game_map_bounds)
	
