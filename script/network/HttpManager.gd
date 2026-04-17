extends Node

signal RequestCompleted(request_id: int, result: Dictionary)

const HTTP_METHOD_GET: int = 0
const HTTP_METHOD_POST: int = 1
const MAX_DECOMPRESS_BYTES: int = 8 * 1024 * 1024
const XOR_KEY: String = "537b9b7a-a18c-11ea-afae-6c92bf62e626"


func Request(
	open_type: int,
	url: String,
	callback: Callable,
	unzip: bool = false,
	use_decrypt: bool = false,
	param: String = ""
) -> void:
	var request_id: int = int(Time.get_ticks_msec() & 0x7fffffff)
	RequestAsyncById(request_id, open_type, url, unzip, use_decrypt, param)
	if callback.is_valid():
		RequestCompleted.connect(_on_request_once.bind(request_id, callback), CONNECT_ONE_SHOT)


func RequestAsyncById(
	request_id: int,
	open_type: int,
	url: String,
	unzip: bool,
	use_decrypt: bool,
	param: String
) -> void:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)

	var request_method: int = HTTPClient.METHOD_GET if open_type == HTTP_METHOD_GET else HTTPClient.METHOD_POST
	var request_url: String = url
	var body: String = ""
	var headers: PackedStringArray = PackedStringArray()

	if request_method == HTTPClient.METHOD_GET:
		if not param.is_empty():
			request_url = "%s?%s" % [url, param]
	else:
		body = param
		headers.append("Content-Type: application/x-www-form-urlencoded")

	http_request.request_completed.connect(
		_on_http_completed.bind(request_id, unzip, use_decrypt, http_request),
		CONNECT_ONE_SHOT
	)

	var request_error: Error = http_request.request(request_url, headers, request_method, body)
	if request_error != OK:
		http_request.queue_free()
		RequestCompleted.emit(request_id, {
			"success": false,
			"http_code": 0,
			"error_message": "request_start_failed:%s" % int(request_error),
			"raw_text": ""
		})


func _on_http_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request_id: int,
	unzip: bool,
	use_decrypt: bool,
	http_request: HTTPRequest
) -> void:
	if is_instance_valid(http_request):
		http_request.queue_free()

	var payload_bytes: PackedByteArray = body
	if unzip:
		payload_bytes = _try_unzip(payload_bytes)

	var raw_text: String = payload_bytes.get_string_from_utf8()
	if use_decrypt:
		raw_text = _special_xor_decode(raw_text)

	var response: Dictionary = {
		"success": result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300,
		"http_code": response_code,
		"raw_text": raw_text
	}
	if result != HTTPRequest.RESULT_SUCCESS:
		response["error_message"] = "http_result:%s" % result

	_merge_json(raw_text, response)
	RequestCompleted.emit(request_id, response)


func _on_request_once(finished_id: int, result: Dictionary, request_id: int, callback: Callable) -> void:
	if finished_id != request_id:
		return
	callback.call(result.get("raw_text", ""))


func _special_xor_decode(input: String) -> String:
	if input.is_empty():
		return ""

	var decoded: PackedByteArray = Marshalls.base64_to_raw(input)
	if decoded.is_empty():
		return input

	var key_bytes: PackedByteArray = XOR_KEY.to_utf8_buffer()
	if key_bytes.is_empty():
		return input

	var index: int = 0
	while index < decoded.size():
		decoded[index] = decoded[index] ^ key_bytes[index % key_bytes.size()]
		index += 1
	return decoded.get_string_from_utf8()


func _try_unzip(raw_bytes: PackedByteArray) -> PackedByteArray:
	if raw_bytes.size() < 2:
		return raw_bytes

	# gzip: 1F 8B
	if raw_bytes[0] == 0x1f and raw_bytes[1] == 0x8b:
		var gzip_data: PackedByteArray = raw_bytes.decompress_dynamic(MAX_DECOMPRESS_BYTES, FileAccess.COMPRESSION_GZIP)
		if not gzip_data.is_empty():
			return gzip_data
		return raw_bytes

	# zlib(deflate): 78 01 / 78 5E / 78 9C / 78 DA
	if raw_bytes[0] == 0x78 and (raw_bytes[1] == 0x01 or raw_bytes[1] == 0x5e or raw_bytes[1] == 0x9c or raw_bytes[1] == 0xda):
		var zlib_data: PackedByteArray = raw_bytes.decompress_dynamic(MAX_DECOMPRESS_BYTES, FileAccess.COMPRESSION_DEFLATE)
		if not zlib_data.is_empty():
			return zlib_data
	return raw_bytes


func _merge_json(raw_text: String, result: Dictionary) -> void:
	if raw_text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed is Dictionary:
		for key in (parsed as Dictionary).keys():
			result[key] = (parsed as Dictionary)[key]
