extends Node


@onready var viewport: SubViewport = %Viewport


func render(stream: EventsStream, resolution_scale: float = 1.0) -> Image:
	viewport.size_2d_override = Vector2(1380, 1000)
	var stats_view := preload("res://scenes/StatsView.tscn").instantiate()
	stats_view.timeline_synchronizer = TimelineSynchronizer.new(stream)
	viewport.add_child(stats_view)
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	
	viewport.size_2d_override.y = stats_view.get_rect().size.y
	viewport.size = viewport.size_2d_override * resolution_scale
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	
	var image := viewport.get_texture().get_image()
	
	stats_view.queue_free()
	return image
