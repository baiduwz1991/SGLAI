class_name TcpSendData
extends RefCounted

const TcpHeaderLen: int = 12

var RequestId: int = 0
var Protocol: int = 0
var LogicIdLen: int = 0
var LogicIdData: PackedByteArray = PackedByteArray()
var ExtendLen: int = 0
var ExtendData: PackedByteArray = PackedByteArray()
var Length: int = 0
var BytesData: PackedByteArray = PackedByteArray()

var _encry: Encry = Encry.new("kuaifeixia_tcp_key-123456")


func Build(
	request_id: int,
	protocol: int,
	logic_id_data: PackedByteArray = PackedByteArray(),
	extend_data: PackedByteArray = PackedByteArray(),
	bytes_data: PackedByteArray = PackedByteArray()
) -> void:
	RequestId = request_id
	Protocol = protocol
	LogicIdData = logic_id_data
	LogicIdLen = logic_id_data.size()
	ExtendData = extend_data
	ExtendLen = extend_data.size()
	BytesData = bytes_data
	Length = bytes_data.size()


func GetBytes() -> PackedByteArray:
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()
	stream.put_32(RequestId)
	stream.put_32(Protocol)
	stream.put_u8(LogicIdLen & 0xff)
	if not LogicIdData.is_empty():
		stream.put_data(LogicIdData)

	stream.put_u8(ExtendLen & 0xff)
	if not ExtendData.is_empty():
		stream.put_data(ExtendData)

	stream.put_32(Length)
	if not BytesData.is_empty():
		stream.put_data(BytesData)

	var packet: PackedByteArray = stream.data_array
	# 旧实现默认不启用加密，保留能力开关。
	# _encry.DoEncry(packet, TcpHeaderLen)
	return packet
