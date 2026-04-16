class_name KcpClient
extends RefCounted


signal state_changed(state: int, reason: String)
signal packet_received(request_id: int, msg_id: int, data: PackedByteArray)


func connect_server(_host: String, _port: int) -> Error:
	state_changed.emit(3, "kcp_not_implemented")
	return ERR_UNAVAILABLE


func close() -> void:
	state_changed.emit(2, "closed")


func send_msg(_request_id: int, _msg_id: int, _payload: PackedByteArray) -> bool:
	return false
