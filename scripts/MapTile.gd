@tool
extends Resource
class_name MapTile


@export var x: int
@export var y: int
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_NO_INSTANCE_STATE) var texture: Texture2D:
	set(value):
		texture = value
		if Engine.is_editor_hint():
			if value == null:
				texture_path = ""
			else:
				texture_path = ResourceUID.path_to_uid(value.resource_path)
	get():
		if texture != null:
			return texture
		if texture_path.is_empty():
			return null
		return load(texture_path)
@export_storage var texture_path: String = "":
	set(value):
		if value == texture_path:
			return
		texture_path = value

		if Engine.is_editor_hint():
			texture = load(texture_path)
