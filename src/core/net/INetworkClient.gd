class_name INetworkClient
extends RefCounted

@warning_ignore("unused_signal")
signal connected
@warning_ignore("unused_signal")
signal connection_closed
@warning_ignore("unused_signal")
signal transport_error(error_message: String)
@warning_ignore("unused_signal")
signal message_received(message: Dictionary)


func connect_server(_server_url: String = "") -> void:
	push_error("INetworkClient.connect_server() 需要在子类中实现。")


func disconnect_server() -> void:
	push_error("INetworkClient.disconnect_server() 需要在子类中实现。")


func is_transport_connected() -> bool:
	return false


func send_json(_payload: Dictionary) -> bool:
	push_error("INetworkClient.send_json() 需要在子类中实现。")
	return false
