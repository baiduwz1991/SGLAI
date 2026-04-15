extends Node

var _socket_client: GameSocketClient = GameSocketClient.new()
var _protocol_router: ProtocolRouter = ProtocolRouter.new()


func _ready() -> void:
	if not _socket_client.message_received.is_connected(_on_message_received):
		_socket_client.message_received.connect(_on_message_received)


func get_socket_client() -> GameSocketClient:
	return _socket_client


func get_protocol_router() -> ProtocolRouter:
	return _protocol_router


func _on_message_received(message: Dictionary) -> void:
	_protocol_router.dispatch(message)
