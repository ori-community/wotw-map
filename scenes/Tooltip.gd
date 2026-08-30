extends PanelContainer
class_name Tooltip


func _enter_tree() -> void:
	visible = false

	get_parent_control().mouse_entered.connect(_on_parent_mouse_entered)
	get_parent_control().mouse_exited.connect(_on_parent_mouse_exited)


func _on_parent_mouse_entered() -> void:
	show_tooltip()


func _on_parent_mouse_exited() -> void:
	hide_tooltip()


func show_tooltip() -> void:
	_update_position()
	visible = true


func hide_tooltip() -> void:
	visible = false


func _update_position() -> void:
	var parent_rect := get_parent_control().get_rect()
	var self_rect := get_rect()

	position.x = -(self_rect.size.x - parent_rect.size.x) / 2.0
	position.y = parent_rect.size.y + 8.0

	global_position.x = clampf(
		global_position.x,
		0.0,
		get_viewport_rect().size.x - self_rect.size.x
	)
