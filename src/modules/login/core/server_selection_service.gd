class_name ServerSelectionService
extends RefCounted


func build_selection_result(response: Dictionary, mapper: ServerListMapper) -> Dictionary:
	var allow_register: bool = bool(response.get("allow_register", true))
	var server_list: Array = mapper.extract_server_list(response)
	if server_list.is_empty():
		return {
			"ok": false,
			"allow_register": allow_register,
			"data_keys_summary": mapper.build_data_keys_summary(response)
		}

	var server_map: Dictionary = {}
	var history_servers: Array[Dictionary] = []
	var recommend_servers: Array[Dictionary] = []
	for server_variant in server_list:
		var server: Dictionary = mapper.normalize_server_entry(server_variant, server_map.size() + 1)
		if server.is_empty():
			continue
		var server_id: String = str(server.get("server_id", ""))
		server_map[server_id] = server
		if bool(server.get("is_recommend", false)):
			recommend_servers.append(server)
		if bool(server.get("is_history", false)):
			history_servers.append(server)

	var current_server: Dictionary = _select_default_server(server_map, history_servers, recommend_servers)
	return {
		"ok": true,
		"allow_register": allow_register,
		"server_map": server_map,
		"history_servers": history_servers,
		"recommend_servers": recommend_servers,
		"current_server": current_server
	}


func _select_default_server(
	server_map: Dictionary,
	history_servers: Array[Dictionary],
	recommend_servers: Array[Dictionary]
) -> Dictionary:
	if not history_servers.is_empty():
		return history_servers[0].duplicate(true)
	if not recommend_servers.is_empty():
		return recommend_servers[0].duplicate(true)
	for server in server_map.values():
		return (server as Dictionary).duplicate(true)
	return {}
