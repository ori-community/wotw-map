extends RefCounted
class_name WotwSaveFileReader


const SAVE_META_FILE_MAGIC := 1
const SAVE_META_FILE_VERSION := 3
const SLOT_ID_SAVE_FILE_GAME_STATS := 1


var _data: PackedByteArray
var _reader: StreamReader
var game_stats_slot_reader := WotwGameStatsSlotReader.new()


func _init(data: PackedByteArray) -> void:
	_data = data
	_reader = StreamReader.new(_data)
	
	_read_save_file_slots()


func _read_save_file_slots():
	var magic_number := _reader.read_u32()
	
	if magic_number != SAVE_META_FILE_MAGIC:
		push_error("Save file did not start with magic byte")
		return PackedByteArray()
	
	var version := _reader.read_u32()
	
	if version != SAVE_META_FILE_VERSION:
		push_error("Incompatible save file version %s" % version)
		return PackedByteArray()
	
	var _guid_a := _reader.read_u32()
	var _guid_b := _reader.read_u32()
	var _guid_c := _reader.read_u32()
	var _guid_d := _reader.read_u32()
	
	var slots_count := _reader.read_u32()
	for i in range(slots_count):
		var slot_id := _reader.read_u8()
		var slot_length := _reader.read_u64()
		
		match slot_id:
			SLOT_ID_SAVE_FILE_GAME_STATS:
				var cursor_before := _reader.get_cursor()
				var _json_string := _reader.read_string_with_length()
				var json_length := _reader.get_cursor() - cursor_before
				game_stats_slot_reader.append_events(_reader.read_slice(slot_length - json_length))
				return
			_:
				_reader.skip(slot_length)
	
	push_error("Save file did not contain a SaveFileGameStatsEvents slot")
