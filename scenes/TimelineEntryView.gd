extends Control
class_name TimelineEntryView


@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			_update_texture_rect_texture()
@export var tooltip_title: String:
	set(value):
		tooltip_title = value
		if is_node_ready():
			_update_tooltip_labels()
@export var tooltip_description: String:
	set(value):
		tooltip_description = value
		if is_node_ready():
			_update_tooltip_labels()
@export var entry_width: float = 0.0:
	set(value):
		entry_width = value
		if is_node_ready():
			_update_panel_container_size()
			_update_texture_rect_position()
			_update_control_size()
			_update_texture_rect_opacity()


@onready var panel_container: PanelContainer = %PanelContainer
@onready var texture_rect: TextureRect = %TextureRect
@onready var tooltip_title_label: Label = %TooltipTitleLabel
@onready var tooltip_description_label: Label = %TooltipDescriptionLabel


func _ready() -> void:
	_update_texture_rect_texture()
	_update_texture_rect_size()
	_update_panel_container_size()
	_update_texture_rect_position()
	_update_control_size()
	_update_tooltip_labels()


func _update_control_size() -> void:
	size.x = texture_rect.position.x + texture_rect.size.x


func _update_texture_rect_texture() -> void:
	texture_rect.texture = texture


func _update_texture_rect_size() -> void:
	texture_rect.size.y = size.y - 4
	texture_rect.size.x = texture_rect.size.y


func _update_texture_rect_opacity() -> void:
	texture_rect.modulate.a = 1.0 if entry_width == 0.0 else 0.5


func _update_panel_container_size() -> void:
	panel_container.size.y = size.y
	panel_container.size.x = entry_width


func _on_resized() -> void:
	if is_node_ready():
		_update_texture_rect_size()


func _update_texture_rect_position() -> void:
	texture_rect.position.y = 2
	
	if panel_container.size.x > texture_rect.size.x:
		texture_rect.position.x = panel_container.size.x - texture_rect.size.x
	else:
		texture_rect.position.x = 0


func _update_tooltip_labels() -> void:
	tooltip_title_label.text = tooltip_title
	tooltip_description_label.text = tooltip_description
