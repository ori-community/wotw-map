extends TextureRect
class_name FadingBackgroundImageTextureRect


var _tween: Tween = null


func _ready() -> void:
	self_modulate.a = 0.0
	
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color.WHITE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func fade_out_and_free() -> void:
	if _tween != null:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color(1.0, 1.0, 1.0, 0.0), 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await _tween.finished
	queue_free()
