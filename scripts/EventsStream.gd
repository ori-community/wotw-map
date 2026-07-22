extends RefCounted
class_name EventsStream


enum GameArea {
	Marsh,
	Hollow,
	Glades,
	Wellspring,
	Woods,
	Reach,
	Depths,
	Pools,
	Wastes,
	Ruins,
	Willow,
	Burrows,
	Shop,
	Void,
}

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
	CurrentArea,

	# Virtual stats that don't actually exist but get computed
	# from other events.
	DeathsMarsh,
	DeathsHollow,
	DeathsGlades,
	DeathsWellspring,
	DeathsWoods,
	DeathsReach,
	DeathsDepths,
	DeathsPools,
	DeathsWastes,
	DeathsRuins,
	DeathsWillow,
	DeathsBurrows,
	DeathsUnknown,
}


enum DisplacementReason {
	Unknown = 0,
	Teleporter = 1,
	Death = 2,
	Door = 3,
	Portal = 4,
}


class StatValues:
	extends RefCounted

	signal value_pushed(in_game_time: float, value: float)
	
	var min_value: float
	var max_value: float
	var values: PackedFloat32Array = PackedFloat32Array()
	var in_game_times: PackedFloat32Array = PackedFloat32Array()
	
	func current_value() -> float:
		if values.is_empty():
			return 0.0
		return values[values.size() - 1]

	func add_value(in_game_time: float, value: float) -> void:
		if values.is_empty():
			min_value = value
			max_value = value
		else:
			min_value = minf(min_value, value)
			max_value = maxf(max_value, value)
		
		in_game_times.push_back(in_game_time)
		values.push_back(value)

		value_pushed.emit(in_game_time, value)
	
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
		var values := StatValues.new()
		stat_values[stat] = values


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


func get_current_area() -> GameArea:
	return int(stat_values[GameStat.CurrentArea].current_value()) as GameArea


func get_area_death_stat_values(area: GameArea) -> StatValues:
	match area:
		GameArea.Marsh:
			return stat_values[GameStat.DeathsMarsh]
		GameArea.Hollow:
			return stat_values[GameStat.DeathsHollow]
		GameArea.Glades:
			return stat_values[GameStat.DeathsGlades]
		GameArea.Wellspring:
			return stat_values[GameStat.DeathsWellspring]
		GameArea.Woods:
			return stat_values[GameStat.DeathsWoods]
		GameArea.Reach:
			return stat_values[GameStat.DeathsReach]
		GameArea.Depths:
			return stat_values[GameStat.DeathsDepths]
		GameArea.Pools:
			return stat_values[GameStat.DeathsPools]
		GameArea.Wastes:
			return stat_values[GameStat.DeathsWastes]
		GameArea.Ruins:
			return stat_values[GameStat.DeathsRuins]
		GameArea.Willow:
			return stat_values[GameStat.DeathsWillow]
		GameArea.Burrows:
			return stat_values[GameStat.DeathsBurrows]
	return null


func get_current_area_death_stat_values() -> StatValues:
	return get_area_death_stat_values(get_current_area())


func get_area_pickups_collected_stat_values(area: GameArea) -> StatValues:
	match area:
		GameArea.Marsh:
			return stat_values[GameStat.PickupsCollectedMarsh]
		GameArea.Hollow:
			return stat_values[GameStat.PickupsCollectedHollow]
		GameArea.Glades:
			return stat_values[GameStat.PickupsCollectedGlades]
		GameArea.Wellspring:
			return stat_values[GameStat.PickupsCollectedWellspring]
		GameArea.Woods:
			return stat_values[GameStat.PickupsCollectedWoods]
		GameArea.Reach:
			return stat_values[GameStat.PickupsCollectedReach]
		GameArea.Depths:
			return stat_values[GameStat.PickupsCollectedDepths]
		GameArea.Pools:
			return stat_values[GameStat.PickupsCollectedPools]
		GameArea.Wastes:
			return stat_values[GameStat.PickupsCollectedWastes]
		GameArea.Ruins:
			return stat_values[GameStat.PickupsCollectedRuins]
		GameArea.Willow:
			return stat_values[GameStat.PickupsCollectedWillow]
		GameArea.Burrows:
			return stat_values[GameStat.PickupsCollectedBurrows]
	return null


func get_area_pickups_total_stat_values(area: GameArea) -> StatValues:
	match area:
		GameArea.Marsh:
			return stat_values[GameStat.PickupsTotalMarsh]
		GameArea.Hollow:
			return stat_values[GameStat.PickupsTotalHollow]
		GameArea.Glades:
			return stat_values[GameStat.PickupsTotalGlades]
		GameArea.Wellspring:
			return stat_values[GameStat.PickupsTotalWellspring]
		GameArea.Woods:
			return stat_values[GameStat.PickupsTotalWoods]
		GameArea.Reach:
			return stat_values[GameStat.PickupsTotalReach]
		GameArea.Depths:
			return stat_values[GameStat.PickupsTotalDepths]
		GameArea.Pools:
			return stat_values[GameStat.PickupsTotalPools]
		GameArea.Wastes:
			return stat_values[GameStat.PickupsTotalWastes]
		GameArea.Ruins:
			return stat_values[GameStat.PickupsTotalRuins]
		GameArea.Willow:
			return stat_values[GameStat.PickupsTotalWillow]
		GameArea.Burrows:
			return stat_values[GameStat.PickupsTotalBurrows]
	return null
