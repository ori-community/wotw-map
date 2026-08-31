extends TextureRect
class_name FadingBackgroundImageTextureRect


var _tween: Tween = null


func _ready() -> void:
	self_modulate.a = 0.0
	
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color.WHITE, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(0.75)


func fade_out_and_free() -> void:
	if _tween != null:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await _tween.finished
	queue_free()
