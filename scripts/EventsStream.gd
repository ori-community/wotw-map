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
	TimeLost,
	Teleports,
	Deaths,
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
	InGameTimeMarsh,
	InGameTimeHollow,
	InGameTimeGlades,
	InGameTimeWellspring,
	InGameTimeWoods,
	InGameTimeReach,
	InGameTimeDepths,
	InGameTimePools,
	InGameTimeWastes,
	InGameTimeRuins,
	InGameTimeWillow,
	InGameTimeBurrows,
	PickupsFrequency,
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
	
	func current_value_in_game_time() -> float:
		if in_game_times.is_empty():
			return 0.0
		return in_game_times[in_game_times.size() - 1]
	
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
	
	### Returns the delta of the value at index vs the previous value
	func delta_at(index: int) -> float:
		var value := values[index]
		var previous_value := values[index - 1] if index > 0 else 0.0
		return value - previous_value

	func start_time() -> float:
		return in_game_times[0]
	
	func end_time() -> float:
		return in_game_times[in_game_times.size() - 1]
	
	func index_at_time(in_game_time: float, before: bool = true) -> int:
		return in_game_times.bsearch(in_game_time, before)
	
	func value_at_time(in_game_time: float, before: bool = true) -> float:
		if values.is_empty():
			return 0.0
		return values[clampi(index_at_time(in_game_time, before) - 1, 0, values.size() - 1)]


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

	enum Type {
		Ability,
		Custom,
	}
	
	var in_game_time: float
	var in_game_time_end: float = NAN
	var label: String
	var icon: IconProvider.MapIconType
	var type: Type
	
	func _init(p_in_game_time: float, p_label: String, p_icon: IconProvider.MapIconType, p_type: Type) -> void:
		in_game_time = p_in_game_time
		label = p_label
		icon = p_icon
		type = p_type
	
	func has_end() -> bool:
		return !is_nan(in_game_time_end)


class TimelineEntries:
	extends RefCounted

	var entries: Array[TimelineEntry] = []
	
	func index_at_time(in_game_time: float, before: bool = true) -> int:
		return entries.bsearch_custom(
			in_game_time,
			func(a: TimelineEntry, b: TimelineEntry):
				return a.in_game_time < b.in_game_time,
			before,
		)


# Events in here are always sorted by in-game time and are only appended to!

const PICKUPS_FREQUENCY_SAMPLE_INTERVAL := 5.0
const PICKUPS_FREQUENCY_ROLLING_AVERAGE := 20.0

var in_game_time_end: float = 0.0  ## The in-game time of the most recent event
var segments: Array[PathSegment] = []
var timeline_entries: TimelineEntries = TimelineEntries.new()
var stat_values: Dictionary[GameStat, StatValues] = {}


func _init() -> void:
	for stat in GameStat.values():
		var values := StatValues.new()
		stat_values[stat] = values


### Sample missing data points in the PickupsFrequency stat
func sample_pickups_frequency() -> void:
	var ppm_stat_values := stat_values[GameStat.PickupsFrequency]
	var pickups_collected_stat_values := stat_values[GameStat.PickupsCollected]

	while ppm_stat_values.current_value_in_game_time() < in_game_time_end - PICKUPS_FREQUENCY_SAMPLE_INTERVAL:
		var sample_in_game_time := ppm_stat_values.current_value_in_game_time() + PICKUPS_FREQUENCY_SAMPLE_INTERVAL
		var sum := 0.0

		var pickups_collected_index := pickups_collected_stat_values.index_at_time(sample_in_game_time) - 1
		if pickups_collected_index == pickups_collected_stat_values.values.size():
			pickups_collected_index -= 1

		while pickups_collected_index >= 0:
			var pickup_in_game_time := pickups_collected_stat_values.in_game_times[pickups_collected_index]

			if pickup_in_game_time < sample_in_game_time - PICKUPS_FREQUENCY_ROLLING_AVERAGE:
				break

			sum +=  pickups_collected_stat_values.delta_at(pickups_collected_index)
			pickups_collected_index -= 1
		
		ppm_stat_values.add_value(sample_in_game_time, sum)


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


func get_area_in_game_time_stat_values(area: GameArea) -> StatValues:
	match area:
		GameArea.Marsh:
			return stat_values[GameStat.InGameTimeMarsh]
		GameArea.Hollow:
			return stat_values[GameStat.InGameTimeHollow]
		GameArea.Glades:
			return stat_values[GameStat.InGameTimeGlades]
		GameArea.Wellspring:
			return stat_values[GameStat.InGameTimeWellspring]
		GameArea.Woods:
			return stat_values[GameStat.InGameTimeWoods]
		GameArea.Reach:
			return stat_values[GameStat.InGameTimeReach]
		GameArea.Depths:
			return stat_values[GameStat.InGameTimeDepths]
		GameArea.Pools:
			return stat_values[GameStat.InGameTimePools]
		GameArea.Wastes:
			return stat_values[GameStat.InGameTimeWastes]
		GameArea.Ruins:
			return stat_values[GameStat.InGameTimeRuins]
		GameArea.Willow:
			return stat_values[GameStat.InGameTimeWillow]
		GameArea.Burrows:
			return stat_values[GameStat.InGameTimeBurrows]
	return null


static func get_area_name(area: GameArea) -> String:
	match area:
		GameArea.Marsh:
			return "Marsh"
		GameArea.Hollow:
			return "Hollow"
		GameArea.Glades:
			return "Glades"
		GameArea.Wellspring:
			return "Wellspring"
		GameArea.Woods:
			return "Woods"
		GameArea.Reach:
			return "Reach"
		GameArea.Depths:
			return "Depths"
		GameArea.Pools:
			return "Pools"
		GameArea.Wastes:
			return "Wastes"
		GameArea.Ruins:
			return "Ruins"
		GameArea.Willow:
			return "Willow"
		GameArea.Burrows:
			return "Burrows"
	return "-"


static func get_long_area_name(area: GameArea) -> String:
	match area:
		GameArea.Marsh:
			return "Inkwater Marsh"
		GameArea.Hollow:
			return "Kwolok's Hollow"
		GameArea.Glades:
			return "Wellspring Glades"
		GameArea.Wellspring:
			return "The Wellspring"
		GameArea.Woods:
			return "Silent Woods"
		GameArea.Reach:
			return "Baur's Reach"
		GameArea.Depths:
			return "Mouldwood Depths"
		GameArea.Pools:
			return "Luma Pools"
		GameArea.Wastes:
			return "Windswept Wastes"
		GameArea.Ruins:
			return "Windtorn Ruins"
		GameArea.Willow:
			return "Willow's End"
		GameArea.Burrows:
			return "Midnight Burrows"
	return "-"
