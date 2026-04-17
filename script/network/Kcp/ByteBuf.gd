class_name ByteBuf
extends RefCounted

var _buffer: PackedByteArray = PackedByteArray()


func _init(capacity: int = 0) -> void:
	if capacity > 0:
		_buffer.resize(capacity)


func Length() -> int:
	return _buffer.size()


func ToArray() -> PackedByteArray:
	var copy: PackedByteArray = PackedByteArray()
	copy.resize(_buffer.size())
	var index: int = 0
	while index < _buffer.size():
		copy[index] = _buffer[index]
		index += 1
	return copy


func SetBytes(data: PackedByteArray) -> void:
	_buffer = PackedByteArray()
	_buffer.resize(data.size())
	var index: int = 0
	while index < data.size():
		_buffer[index] = data[index]
		index += 1
