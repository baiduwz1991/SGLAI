class_name AccountAuthService
extends RefCounted


var _http_service: HttpRequestService
var _base_url: String = ""
var _app_id: String = ""
var _encode_key: String = ""


func configure(http_service: HttpRequestService, base_url: String, app_id: String, encode_key: String) -> void:
	_http_service = http_service
	_base_url = base_url
	_app_id = app_id
	_encode_key = encode_key


func request_account(module_name: String, method_data: Dictionary, callback: Callable) -> void:
	if _http_service == null:
		if callback.is_valid():
			callback.call({
				"success": false,
				"reason": "http_service_unavailable"
			})
		return

	var signed_query: String = _build_account_signed_query(method_data)
	var request_url: String = "%s/%s?%s" % [_base_url, module_name, signed_query]
	_http_service.request({
		"svrType": HttpRequestService.HTTP_SVR_TYPE_ACCOUNT,
		"moduleName": module_name,
		"url": request_url,
		"methodData": {},
		"callback": func(response: Dictionary) -> void:
			print("[AccountAuthService] response module=%s state=%d message=%s" % [
				module_name,
				read_state(response),
				read_message(response)
			])
			callback.call(response)
	})


func read_state(response: Dictionary) -> int:
	if response.has("State"):
		return int(response.get("State", 0))
	if response.has("state"):
		return int(response.get("state", 0))
	if response.has("Code"):
		return int(response.get("Code", 0))
	if response.has("code"):
		return int(response.get("code", 0))
	return 0


func read_message(response: Dictionary) -> String:
	if response.has("Message"):
		return str(response.get("Message", ""))
	if response.has("message"):
		return str(response.get("message", ""))
	if response.has("Msg"):
		return str(response.get("Msg", ""))
	if response.has("msg"):
		return str(response.get("msg", ""))
	return ""


func looks_like_account_exists(state: int, message: String) -> bool:
	if state == 2 or state == 409:
		return true
	var lower_msg: String = message.to_lower()
	return (
		lower_msg.contains("exist")
		or lower_msg.contains("already")
		or message.contains("已存在")
		or message.contains("重复")
	)


func read_user_id(response: Dictionary) -> String:
	var result_variant: Variant = response.get("Result", {})
	if not (result_variant is Dictionary):
		return ""
	var result: Dictionary = result_variant as Dictionary
	return str(result.get("UserID", ""))


func _build_account_signed_query(method_data: Dictionary) -> String:
	var query_data: Dictionary = {"appid": _app_id}
	for key in method_data.keys():
		query_data[key] = method_data[key]
	var query_string: String = _encode_query_string_plain(query_data)
	var xor_encoded: String = _special_xor_encode(query_string).replace("\r\n", "")
	var sign: String = xor_encoded.md5_text()
	return "%s&sign=%s" % [query_string, sign]


func _special_xor_encode(source: String) -> String:
	var source_bytes: PackedByteArray = source.to_utf8_buffer()
	var key_bytes: PackedByteArray = _encode_key.to_utf8_buffer()
	if key_bytes.is_empty():
		return Marshalls.raw_to_base64(source_bytes)
	for index in range(source_bytes.size()):
		source_bytes[index] = source_bytes[index] ^ key_bytes[index % key_bytes.size()]
	return Marshalls.raw_to_base64(source_bytes)


func _encode_query_string_plain(params: Dictionary) -> String:
	var segments: PackedStringArray = []
	for key in params.keys():
		var value: Variant = params[key]
		if typeof(value) == TYPE_NIL:
			continue
		segments.append("%s=%s" % [str(key), str(value)])
	return "&".join(segments)
