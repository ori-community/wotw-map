extends Node2D
class_name DiscoveredItemsView


var discovered_items: Dictionary[int, WotwGameStatsSlotReader.DiscoveredItem] = {}


var _map_icons: Dictionary[int, MapIcon] = {}


func _update_map_icons() -> void:
	for icon in _map_icons.values():
		icon.queue_free()
	_map_icons.clear()
	
