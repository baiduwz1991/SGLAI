class_name StreamBuffer
extends RefCounted

var _buffer: PackedByteArray = PackedByteArray()
var _stream: StreamPeerBuffer = StreamPeerBuffer.new()

var CanWrite: bool = false
var CanRead: bool = false


func _init(buffer_size: int, can_write: bool, can_read: bool) -> void:
	if buffer_size < 0:
		buffer_size = 0
	_buffer.resize(buffer_size)
	_stream.data_array = _buffer
	SetOperate(can_write, can_read)


func SetOperate(can_write: bool, can_read: bool) -> void:
	CanWrite = can_write
	CanRead = can_read


func Size() -> int:
	return _buffer.size()


func WriteInt(value: int) -> void:
	_stream.put_32(value)


func WriteU8(value: int) -> void:
	_stream.put_u8(value & 0xff)


func WriteBuffer(data: PackedByteArray) -> void:
	if data.is_empty():
		return
	_stream.put_data(data)


func ReadInt(offset: int) -> int:
	if offset + 4 > _buffer.size():
		return 0
	return _buffer.decode_s32(offset)


func CopyFrom(src: PackedByteArray, src_offset: int, dst_offset: int, length: int) -> void:
	var index: int = 0
	while index < length and src_offset + index < src.size() and dst_offset + index < _buffer.size():
		_buffer[dst_offset + index] = src[src_offset + index]
		index += 1


func CopyTo(dst: PackedByteArray, src_offset: int, dst_offset: int, length: int) -> void:
	var index: int = 0
	while index < length and src_offset + index < _buffer.size() and dst_offset + index < dst.size():
		dst[dst_offset + index] = _buffer[src_offset + index]
		index += 1


func ToArray(start: int = 0, length: int = -1) -> PackedByteArray:
	var source: PackedByteArray = _stream.data_array
	if source.is_empty():
		return PackedByteArray()
	var copy_start: int = maxi(start, 0)
	var copy_len: int = length
	if copy_len < 0 or copy_start + copy_len > source.size():
		copy_len = source.size() - copy_start
	if copy_len <= 0:
		return PackedByteArray()
	return source.slice(copy_start, copy_start + copy_len)


func GetBuffer() -> PackedByteArray:
	return _stream.data_array


func ClearBuffer() -> void:
	var data: PackedByteArray = _stream.data_array
	var index: int = 0
	while index < data.size():
		data[index] = 0
		index += 1
	_stream.data_array = data


func ResetStream() -> void:
	_stream.seek(0)
