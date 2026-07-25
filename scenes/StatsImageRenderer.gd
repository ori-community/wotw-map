extends Node


@onready var viewport: SubViewport = %Viewport


func render(stream: EventsStream, resolution_scale: float = 1.0) -> Image:
	var stats_areas_view := preload("res://scenes/StatsAreasView.tscn").instantiate()
	stats_areas_view.timeline_synchronizer = TimelineSynchronizer.new(stream)
	viewport.add_child(stats_areas_view)
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	
	viewport.size_2d_override = stats_areas_view.get_rect().size
	viewport.size = viewport.size_2d_override * resolution_scale
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	
	var image := viewport.get_texture().get_image()
	
	stats_areas_view.queue_free()
	return image
