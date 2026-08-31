extends Sprite2D
class_name FadeInSprite


func _ready() -> void:
	create_tween()\
		.tween_property(self, "self_modulate", Color.WHITE, 0.2)\
		.from(Color.TRANSPARENT)
