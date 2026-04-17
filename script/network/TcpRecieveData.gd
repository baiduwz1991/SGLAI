class_name TcpRecieveData
extends RefCounted

const TcpHeaderLen: int = 12

var RequestId: int = 0
var Protocol: int = 0
var Length: int = 0
var BytesData: PackedByteArray = PackedByteArray()

var _read_buffer: PackedByteArray = PackedByteArray()
var _read_length: int = 0


func _init() -> void:
	_read_buffer.resize(10 * 1024)


func Read(incoming: PackedByteArray, request_id: Array[int], protocol: Array[int], body: Array[PackedByteArray]) -> bool:
	if incoming.size() + _read_length > _read_buffer.size():
		var new_size: int = int(_read_buffer.size() * 1.5)
		if new_size < incoming.size() + _read_length:
			new_size = incoming.size() + _read_length
		_read_buffer.resize(new_size)

	if not incoming.is_empty():
		var index: int = 0
		while index < incoming.size():
			_read_buffer[_read_length + index] = incoming[index]
			index += 1
		_read_length += incoming.size()

	if _read_length < TcpHeaderLen:
		request_id.append(0)
		protocol.append(0)
		body.append(PackedByteArray())
		return false

	RequestId = _read_buffer.decode_s32(0)
	Protocol = _read_buffer.decode_s32(4)
	Length = _read_buffer.decode_s32(8)
	if Length < 0 or Length + TcpHeaderLen > _read_length:
		request_id.append(0)
		protocol.append(0)
		body.append(PackedByteArray())
		return false

	BytesData = PackedByteArray()
	BytesData.resize(Length)
	var payload_index: int = 0
	while payload_index < Length:
		BytesData[payload_index] = _read_buffer[TcpHeaderLen + payload_index]
		payload_index += 1

	var consumed: int = TcpHeaderLen + Length
	_read_length -= consumed
	if _read_length > 0:
		var move_index: int = 0
		while move_index < _read_length:
			_read_buffer[move_index] = _read_buffer[consumed + move_index]
			move_index += 1

	request_id.append(RequestId)
	protocol.append(Protocol)
	body.append(BytesData)
	return true
