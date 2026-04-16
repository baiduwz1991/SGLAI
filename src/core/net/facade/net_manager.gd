class_name NetManagerFacade
extends Node


signal connection_state_changed(state: int, reason: String)
signal packet_received(packet: Dictionary)
signal connection_attempt_started(server_url: String)
signal connection_attempt_failed(reason: String)


const BaseWebSocketClientScript: Script = preload("res://src/core/net/transport/base_websocket_client.gd")
const RequestDispatcherScript: Script = preload("res://src/core/net/dispatch/request_dispatcher.gd")
const NetPacketCodecScript: Script = preload("res://src/core/net/protocol/net_packet_codec.gd")

const HEART_INTERVAL: float = 5.0
const REQUEST_TIMEOUT_SECONDS: float = 10.0

var _socket: BaseWebSocketClient
var _dispatcher: RequestDispatcher
var _codec: NetPacketCodec
var _next_request_id: int = 0
var _last_send_elapsed: float = 0.0
var _server_url: String = ""
var _pending_connect_callback: Callable = Callable()
var can_send_request: int = 2


func _ready() -> void:
	_dispatcher = RequestDispatcherScript.new()
	_codec = NetPacketCodecScript.new()
	_socket = BaseWebSocketClientScript.new()
	add_child(_socket)
	_socket.connection_attempt_started.connect(_on_connection_attempt_started)
	_socket.connection_attempt_failed.connect(_on_connection_attempt_failed)
	_socket.opened.connect(_on_socket_opened)
	_socket.text_message_received.connect(_on_socket_text_message)
	_socket.binary_message_received.connect(_on_socket_binary_message)
	_socket.errored.connect(_on_socket_error)
	_socket.closed.connect(_on_socket_closed)
	set_process(true)


func _process(delta: float) -> void:
	_dispatcher.advance_time(delta)
	if not _socket.is_socket_connected():
		return
	_last_send_elapsed += delta
	if _last_send_elapsed >= HEART_INTERVAL:
		_last_send_elapsed = 0.0
		_socket.send_text("")


func connect_game_server(server_url: String, callback: Callable = Callable()) -> Error:
	print("[NetManagerFacade] connect_game_server start url=%s" % server_url)
	_server_url = server_url
	_pending_connect_callback = callback
	can_send_request = 1
	var connect_error: Error = _socket.open_websocket(server_url)
	print("[NetManagerFacade] open_websocket returned error=%s(%s)" % [int(connect_error), _error_to_text(connect_error)])
	if connect_error != OK:
		push_warning("[NetManagerFacade] connect_game_server failed early with error=%s(%s)" % [int(connect_error), _error_to_text(connect_error)])
		can_send_request = 2
		if _pending_connect_callback.is_valid():
			_pending_connect_callback.call(false)
		_pending_connect_callback = Callable()
	return connect_error


func close() -> void:
	_socket.close_websocket()
	_dispatcher.fail_all("connection_closed")
	_dispatcher.clear()
	can_send_request = 2


func reconnect() -> Error:
	if _server_url.is_empty():
		return ERR_INVALID_PARAMETER
	return connect_game_server(_server_url, _pending_connect_callback)


func get_connected_status() -> bool:
	return _socket.is_socket_connected()


func get_status() -> String:
	return "network_connected=%s server_url=%s" % [str(_socket.is_socket_connected()), _server_url]


func send_msg(
	payload: Dictionary,
	response_command: StringName = StringName(),
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	if not _socket.is_socket_connected():
		return false

	_next_request_id += 1
	var request_id: int = _next_request_id
	var command: StringName = StringName(payload.get("command", payload.get("msg_id", "")))
	var outbound_packet: Dictionary = {
		"request_id": request_id,
		"command": str(command),
		"data": payload.get("data", payload),
	}

	if response_command != StringName() or ok_back.is_valid() or fail_back.is_valid():
		_dispatcher.register_request(request_id, response_command, ok_back, fail_back, REQUEST_TIMEOUT_SECONDS)

	var encoded_text: String = _codec.encode_payload(outbound_packet)
	var sent: bool = _socket.send_text(encoded_text)
	if sent:
		_last_send_elapsed = 0.0
	return sent


func request(params: Dictionary) -> bool:
	if can_send_request > 1:
		return false

	var payload: Dictionary = {
		"command": str(params.get("msg_id", "")),
		"data": params.get("data", {}),
		"logic_id": str(params.get("logic_id", "")),
		"extend_data": params.get("extend_data", {})
	}
	var response_command: StringName = StringName(params.get("response_command", ""))
	var ok_callback: Callable = params.get("successCb", Callable())
	var fail_callback: Callable = params.get("failedCb", Callable())
	return send_msg(payload, response_command, ok_callback, fail_callback)


func request_login(
	request_data: Dictionary,
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	return send_msg(
		{
			"command": "gateway_user_login",
			"data": request_data
		},
		&"gateway_user_login_response",
		ok_back,
		fail_back
	)


func request_player_init_data(
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	return send_msg(
		{
			"command": "logic_player_get_init_data",
			"data": {}
		},
		&"logic_player_get_init_data_response",
		ok_back,
		fail_back
	)


func request_player_get_init_data(
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	return request_player_init_data(ok_back, fail_back)


func clear_call_back_map() -> void:
	_dispatcher.clear()


func add_push_by_command(command: StringName, handler: Callable) -> void:
	_dispatcher.add_push_handler(command, handler)


func remove_push_by_command(command: StringName, handler: Callable) -> void:
	_dispatcher.remove_push_handler(command, handler)


func _on_socket_opened() -> void:
	print("[NetManagerFacade] socket opened")
	can_send_request = 0
	connection_state_changed.emit(1, "connected")
	if _pending_connect_callback.is_valid():
		_pending_connect_callback.call(true)
	_pending_connect_callback = Callable()


func _on_socket_text_message(message: String) -> void:
	if message.is_empty():
		return
	var packet: Dictionary = _codec.decode_text(message)
	packet_received.emit(packet)
	_dispatcher.dispatch(packet)


func _on_socket_binary_message(packet_bytes: PackedByteArray) -> void:
	var packet: Dictionary = _codec.decode_binary(packet_bytes)
	packet_received.emit(packet)
	_dispatcher.dispatch(packet)


func _on_socket_error(reason: String) -> void:
	push_warning("[NetManagerFacade] socket error reason=%s" % reason)
	can_send_request = 1
	_dispatcher.fail_all("transport_error:%s" % reason)
	connection_state_changed.emit(3, reason)
	if _pending_connect_callback.is_valid():
		_pending_connect_callback.call(false)
	_pending_connect_callback = Callable()


func _on_socket_closed(code: int, reason: String) -> void:
	push_warning("[NetManagerFacade] socket closed code=%s reason=%s" % [code, reason])
	can_send_request = 1
	_dispatcher.fail_all("connection_closed:%s:%s" % [code, reason])
	connection_state_changed.emit(2, "%s:%s" % [code, reason])


func _on_connection_attempt_started(server_url: String) -> void:
	print("[NetManagerFacade] connection attempt started url=%s" % server_url)
	connection_attempt_started.emit(server_url)
	connection_state_changed.emit(0, "connecting")


func _on_connection_attempt_failed(reason: String) -> void:
	push_warning("[NetManagerFacade] connection attempt failed reason=%s" % reason)
	connection_attempt_failed.emit(reason)
	connection_state_changed.emit(3, reason)


func _error_to_text(code: Error) -> String:
	match code:
		OK:
			return "OK"
		ERR_UNAVAILABLE:
			return "ERR_UNAVAILABLE"
		ERR_INVALID_PARAMETER:
			return "ERR_INVALID_PARAMETER"
		_:
			return "Error.%s" % int(code)
