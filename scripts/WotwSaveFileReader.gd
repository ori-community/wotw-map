extends RefCounted
class_name WotwSaveFileReader


const SAVE_META_FILE_MAGIC := 1
const SAVE_META_FILE_VERSION := 2
const SLOT_ID_SAVE_FILE_GAME_STATS_EVENTS := 6


var _data: PackedByteArray
var _reader: StreamReader


func _init(data: PackedByteArray) -> void:
	_data = data
	_reader = StreamReader.new(_data)


func read_events_stream() -> PackedByteArray:
	var magic_number := _reader.read_i32()
	
	if magic_number != SAVE_META_FILE_MAGIC:
		push_error("Save file did not start with magic byte")
		return PackedByteArray()
	
	var version := _reader.read_i32()
	
	if version != SAVE_META_FILE_VERSION:
		push_error("Incompatible save file version %s" % version)
		return PackedByteArray()
	
	var _guid_a := _reader.read_i32()
	var _guid_b := _reader.read_i32()
	var _guid_c := _reader.read_i32()
	var _guid_d := _reader.read_i32()
	
	var slots_count := _reader.read_i32()
	for i in range(slots_count):
		var slot_id := _reader.read_i32()
		var slot_length := _reader.read_u32()
		
		if slot_id != SLOT_ID_SAVE_FILE_GAME_STATS_EVENTS:
			_reader.skip(slot_length)
			continue
		
		var slot_data := _reader.read_slice(slot_length)
		return slot_data
	
	push_error("Save file did not contain a SaveFileGameStatsEvents slot")
	return PackedByteArray()
