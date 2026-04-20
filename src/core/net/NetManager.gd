extends Node


const NetManagerFacadeScript: Script = preload("res://src/core/net/facade/net_manager.gd")

var _facade: NetManagerFacade


func _ready() -> void:
	_facade = NetManagerFacadeScript.new()
	add_child(_facade)
	_facade.packet_received.connect(_on_packet_received)


func connect_game_server(server_url: String, callback: Callable = Callable()) -> Error:
	return _facade.connect_game_server(server_url, callback)


func close() -> void:
	_facade.close()


func reconnect() -> Error:
	return _facade.reconnect()


func get_connected_status() -> bool:
	return _facade.get_connected_status()


func get_status() -> String:
	return _facade.get_status()


func send_msg(
	payload: Dictionary,
	response_command: StringName = StringName(),
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	return _facade.send_msg(payload, response_command, ok_back, fail_back)


func request_login(
	request_data: Dictionary,
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	return _facade.request_login(request_data, ok_back, fail_back)


func request_player_init_data(
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	return _facade.request_player_init_data(ok_back, fail_back)


func request(params: Dictionary) -> bool:
	return _facade.request(params)


func request_player_get_init_data(
	ok_back: Callable = Callable(),
	fail_back: Callable = Callable()
) -> bool:
	return _facade.request_player_get_init_data(ok_back, fail_back)


func clear_call_back_map() -> void:
	_facade.clear_call_back_map()


func add_push_by_command(command: StringName, handler: Callable) -> void:
	if MessageManager != null:
		MessageManager.add_push_by_command(command, handler)


func remove_push_by_command(command: StringName, handler: Callable) -> void:
	if MessageManager != null:
		MessageManager.remove_push_by_command(command, handler)


func _on_packet_received(packet: Dictionary) -> void:
	var command: StringName = StringName(packet.get("command", ""))
	if command != StringName() and MessageManager != null:
		MessageManager.dispatch_push(command, packet.get("data", packet))
