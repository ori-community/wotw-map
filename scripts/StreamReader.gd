extends RefCounted
class_name StreamReader


var _data: PackedByteArray
var _cursor: int = 0


func _init(data: PackedByteArray):
	_data = data


func read_i32() -> int:
	var value := _data.decode_s32(_cursor)
	_cursor += 4
	return value


func read_u8() -> int:
	var value := _data.decode_u8(_cursor)
	_cursor += 1
	return value


func read_u32() -> int:
	var value := _data.decode_u32(_cursor)
	_cursor += 4
	return value


func read_u64() -> int:
	var value := _data.decode_u64(_cursor)
	_cursor += 8
	return value


func read_f32() -> float:
	var value := _data.decode_float(_cursor)
	_cursor += 4
	return value


func read_slice(length: int) -> PackedByteArray:
	var slice := _data.slice(_cursor, _cursor + length)
	_cursor += length
	return slice


func read_string(length: int) -> String:
	var slice := read_slice(length)
	return slice.get_string_from_utf8()


func read_string_with_length() -> String:
	var length := read_u64()
	return read_string(length)


func skip(length: int) -> void:
	_cursor += length


func available() -> bool:
	return _cursor < _data.size()


func get_cursor() -> int:
	return _cursor
