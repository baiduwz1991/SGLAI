class_name WebSocketRecieveData
extends RefCounted

const TcpHeaderLen: int = 12

var RequestId: int = 0
var Protocol: int = 0
var Length: int = 0
var BytesData: PackedByteArray = PackedByteArray()


func Read(data: PackedByteArray) -> bool:
	if data.size() < TcpHeaderLen:
		return false

	RequestId = data.decode_s32(0)
	Protocol = data.decode_s32(4)
	Length = data.decode_s32(8)
	if Length < 0 or Length + TcpHeaderLen != data.size():
		return false

	BytesData = PackedByteArray()
	BytesData.resize(Length)
	var index: int = 0
	while index < Length:
		BytesData[index] = data[TcpHeaderLen + index]
		index += 1
	return true
