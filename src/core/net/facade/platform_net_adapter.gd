class_name PlatformNetAdapter
extends RefCounted


func build_login_payload(username: String, token: String, login_info: Dictionary = {}) -> Dictionary:
	var normalized_login_info: Dictionary = login_info.duplicate(true)
	if normalized_login_info.is_empty():
		normalized_login_info = {
			"method": "Login",
			"sessionId": username
		}
	return {
		"user_id": username,
		"token": token,
		"login_info": normalized_login_info
	}


func normalize_server_list_response(response: Dictionary) -> Dictionary:
	var normalized: Dictionary = response.duplicate(true)
	normalized["success"] = bool(response.get("success", true))
	var business_code: int = int(response.get("Code", response.get("code", 0)))
	normalized["Code"] = business_code
	if not normalized.has("Message") and normalized.has("message"):
		normalized["Message"] = response.get("message", "")
	if not normalized.has("Data") or not (normalized.get("Data") is Dictionary):
		normalized["Data"] = {}
	var data_variant: Variant = normalized.get("Data")
	var data_block: Dictionary = data_variant as Dictionary
	if data_block.is_empty() and response.has("data"):
		var response_data_variant: Variant = response.get("data")
		if response_data_variant is Dictionary:
			data_block = response_data_variant as Dictionary
		normalized["Data"] = data_block
	return normalized
