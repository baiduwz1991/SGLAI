class_name ServerListMapper
extends RefCounted


func extract_returned_user_id(response: Dictionary) -> String:
	var data_variant: Variant = response.get("Data", {})
	if not (data_variant is Dictionary):
		return ""
	var data_block: Dictionary = data_variant as Dictionary
	var user_info_variant: Variant = data_block.get("UserInfo", {})
	if not (user_info_variant is Dictionary):
		return ""
	var user_info: Dictionary = user_info_variant as Dictionary
	return str(user_info.get("UserID", ""))


func extract_server_list(response: Dictionary) -> Array:
	var data_block: Dictionary = response.get("Data", {})
	var result: Dictionary = response.get("result", {})
	var server_list_variant: Variant = data_block.get(
		"server_list",
		data_block.get(
			"ServerList",
			data_block.get(
				"Server",
				result.get("server_list", response.get("server_list", response.get("Server", [])))
			)
		)
	)
	if server_list_variant is Array:
		return server_list_variant as Array
	return []


func normalize_server_entry(server_variant: Variant, fallback_id: int) -> Dictionary:
	if not (server_variant is Dictionary):
		return {}
	var server: Dictionary = (server_variant as Dictionary).duplicate(true)
	var server_id: String = str(server.get("server_id", server.get("ServerID", "")))
	if server_id.is_empty():
		server_id = str(fallback_id)
	if not server.has("server_id"):
		server["server_id"] = server_id
	if not server.has("server_url"):
		server["server_url"] = str(server.get("ServerUrl", server.get("serverUrl", "")))
	if not server.has("server_name"):
		server["server_name"] = str(server.get("ServerName", "Server-%s" % server_id))
	return server


func build_response_summary(response: Dictionary) -> Dictionary:
	var summary: Dictionary = {
		"http_code": int(response.get("http_code", 0)),
		"success": bool(response.get("success", false)),
		"Code": int(response.get("Code", -1)),
		"Message": str(response.get("Message", response.get("business_message", "")))
	}
	var server_list: Array = extract_server_list(response)
	summary["server_count"] = server_list.size()
	var returned_user_id: String = extract_returned_user_id(response)
	if not returned_user_id.is_empty():
		summary["returned_user_id"] = returned_user_id
	return summary


func build_server_summary(server: Dictionary) -> Dictionary:
	return {
		"server_id": str(server.get("server_id", server.get("ServerID", ""))),
		"server_name": str(server.get("server_name", server.get("ServerName", ""))),
		"server_url": str(server.get("server_url", server.get("ServerUrl", "")))
	}


func build_data_keys_summary(response: Dictionary) -> String:
	var data_variant: Variant = response.get("Data", {})
	if not (data_variant is Dictionary):
		return "[]"
	var data_block: Dictionary = data_variant as Dictionary
	return JSON.stringify(data_block.keys())
