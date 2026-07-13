extends Node2D
class_name MapIcon


@export var icon_provider: IconProvider = preload("res://assets/wotw_icons.tres")
@export var icon_type: IconProvider.MapIconType:
	set(value):
		icon_type = value
		_update_icon()
@export var label_text: String:
	set(value):
		label.text = value
	get():
		return label.text


@onready var icon: TextureRect = %Icon
@onready var label: Label = %Label


func _ready() -> void:
	_update_icon()


func _update_icon() -> void:
	icon.texture = icon_provider.get_icon_texture_or_default(icon_type)
