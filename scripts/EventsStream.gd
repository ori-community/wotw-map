extends RefCounted
class_name EventsStream


enum GameStat {
	PickupsCollected,
	PickupsTotal,
	Keystones,
	KeystonesCollected,
	SpiritLight,
	SpiritLightCollected,
	SpiritLightSpent,
	GorlekOre,
	GorlekOreCollected,
	GorlekOreSpent,
	ShardSlots,
	Health,
	MaxHealth,
	Energy,
	MaxEnergy,
	PickupsCollectedMarsh,
	PickupsTotalMarsh,
	PickupsCollectedHollow,
	PickupsTotalHollow,
	PickupsCollectedGlades,
	PickupsTotalGlades,
	PickupsCollectedWellspring,
	PickupsTotalWellspring,
	PickupsCollectedWoods,
	PickupsTotalWoods,
	PickupsCollectedReach,
	PickupsTotalReach,
	PickupsCollectedDepths,
	PickupsTotalDepths,
	PickupsCollectedPools,
	PickupsTotalPools,
	PickupsCollectedWastes,
	PickupsTotalWastes,
	PickupsCollectedRuins,
	PickupsTotalRuins,
	PickupsCollectedWillow,
	PickupsTotalWillow,
	PickupsCollectedBurrows,
	PickupsTotalBurrows,
	PickupsCollectedShop,
	PickupsTotalShop,
}


class StatValues:
	extends RefCounted
	
	var min_value: int
	var max_value: int
	var values: PackedFloat32Array = PackedFloat32Array()
	var in_game_times: PackedFloat32Array = PackedFloat32Array()
	
	func add_value(in_game_time: float, value: int) -> void:
		if values.is_empty():
			min_value = value
			max_value = value
		else:
			min_value = mini(min_value, value)
			max_value = maxi(max_value, value)
		
		in_game_times.push_back(in_game_time)
		values.push_back(value)
	
	func start_time() -> float:
		return in_game_times[0]
	
	func end_time() -> float:
		return in_game_times[in_game_times.size() - 1]
	
	func index_at_time(in_game_time: float, before: bool = true) -> int:
		return in_game_times.bsearch(in_game_time, before)


class PathSegment:
	extends RefCounted
	
	var points: PackedVector2Array = PackedVector2Array()
	var in_game_times: PackedFloat32Array = PackedFloat32Array()
	
	func start_time() -> float:
		return in_game_times[0]
	
	func end_time() -> float:
		return in_game_times[in_game_times.size() - 1]
	
	func index_at_time(in_game_time: float, before: bool = true) -> int:
		return in_game_times.bsearch(in_game_time, before)


class TimelineEntry:
	extends RefCounted
	
	var in_game_time: float
	var label: String
	var icon: String
	
	func _init(p_in_game_time: float, p_label: String, p_icon: String) -> void:
		in_game_time = p_in_game_time
		label = p_label
		icon = p_icon


class MapEntry:
	extends RefCounted
	
	var in_game_time: float
	var label: String
	var icon: String
	var x: float
	var y: float
	
	func _init(p_in_game_time: float, p_label: String, p_icon: String, p_x: float, p_y: float) -> void:
		in_game_time = p_in_game_time
		label = p_label
		icon = p_icon
		x = p_x
		y = p_y

# Events in here are always sorted by in-game time and are only appended to!

var in_game_time_end: float = 0.0  ## The in-game time of the most recent event
var segments: Array[PathSegment] = []
var timeline_entries: Array[TimelineEntry] = []
var map_entries: Array[MapEntry] = []
var stat_values: Dictionary[GameStat, StatValues] = {}


func _init() -> void:
	for stat in GameStat.values():
		stat_values[stat] = StatValues.new()


### Returns the PathSegment that contains the given timestamp, or null if no
### segment exists at the given timestamp.
func get_path_segment_at(in_game_time: float) -> EventsStream.PathSegment:
	var index := segments.find_custom(
		func (seg: EventsStream.PathSegment) -> bool:
			return in_game_time >= seg.start_time() && in_game_time <= seg.end_time()
	)
	
	return segments[index] if index >= 0 else null


### Returns the position at the given timestamp or default if there is no
### segment at the given timestamp.
func get_position_at_time(in_game_time: float, default: Vector2 = Vector2.ZERO) -> Vector2:
	var segment := get_path_segment_at(in_game_time)
	if segment == null:
		return default
	return segment.points[segment.index_at_time(in_game_time)]
