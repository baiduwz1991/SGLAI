class_name HttpRequestService
extends Node


const HTTP_METHOD_GET: int = 0
const HTTP_METHOD_POST: int = 1

const HTTP_SVR_TYPE_GAME: int = 0
const HTTP_SVR_TYPE_MANAGE_CENTER: int = 1
const HTTP_SVR_TYPE_ACCOUNT: int = 2
const HTTP_SVR_TYPE_TRACKING: int = 3

const ACCOUNT_TYPE_GET_SERVER_LIST: String = "eGetServerList"
const ACCOUNT_TYPE_SAVE_HISTORY: String = "eSaveHistory"
const ACCOUNT_TYPE_GET_NOTICE_LIST: String = "eGetNoticeList"
const ACCOUNT_TYPE_GET_PRIVACY_EXISTS: String = "eGetUserAppIdPrivacyPolicyExist"
const ACCOUNT_TYPE_SAVE_PRIVACY: String = "eSaveUserAppIdPrivacyPolicy"
const REQUEST_TIMEOUT_SECONDS: float = 15.0

var _http_manager: Object
var _next_request_id: int = 0
var _pending_callbacks: Dictionary = {}


func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		_http_manager = tree.root.get_node_or_null("HttpManager")
	if _http_manager != null and _http_manager.has_signal("RequestCompleted"):
		_http_manager.connect("RequestCompleted", Callable(self, "_on_request_completed"))
	set_process(false)


func _process(delta: float) -> void:
	if _pending_callbacks.is_empty():
		set_process(false)
		return

	var timeout_ids: Array[int] = []
	for request_id_variant in _pending_callbacks.keys():
		var request_id: int = int(request_id_variant)
		var context: Dictionary = _pending_callbacks.get(request_id, {})
		var elapsed: float = float(context.get("elapsed", 0.0)) + delta
		context["elapsed"] = elapsed
		_pending_callbacks[request_id] = context
		if elapsed >= REQUEST_TIMEOUT_SECONDS:
			timeout_ids.append(request_id)

	for timeout_request_id in timeout_ids:
		if not _pending_callbacks.has(timeout_request_id):
			continue
		var timeout_context: Dictionary = _pending_callbacks[timeout_request_id]
		_pending_callbacks.erase(timeout_request_id)
		var timeout_callback: Callable = timeout_context.get("callback", Callable())
		var timeout_module_name: String = str(timeout_context.get("module_name", ""))
		_fail_callback(timeout_callback, "request_timeout", timeout_module_name)

	if _pending_callbacks.is_empty():
		set_process(false)


func request(params: Dictionary) -> void:
	var callback: Callable = params.get("callback", Callable())
	var svr_type: int = int(params.get("svrType", HTTP_SVR_TYPE_MANAGE_CENTER))
	var module_name: String = str(params.get("moduleName", ""))
	var method_data: Dictionary = params.get("methodData", {})

	var request_url: String = str(params.get("url", ""))
	var post_body: String = ""
	var method: int = HTTP_METHOD_POST
	var use_unzip: bool = true
	var use_decrypt: bool = true
	if svr_type == HTTP_SVR_TYPE_MANAGE_CENTER:
		request_url = str(params.get("baseUrl", request_url))
		post_body = _encode_query_string(method_data)
		use_decrypt = false
	elif svr_type == HTTP_SVR_TYPE_ACCOUNT:
		request_url = str(params.get("url", request_url))
		post_body = _encode_query_string(method_data)
		method = HTTP_METHOD_GET
		use_unzip = false
	elif svr_type == HTTP_SVR_TYPE_TRACKING:
		request_url = str(params.get("url", request_url))
		post_body = _encode_query_string(params.get("headData", {}))
		use_unzip = false
		use_decrypt = false
	else:
		request_url = str(params.get("url", request_url))
		post_body = _encode_query_string(method_data)

	if request_url.is_empty():
		_fail_callback(callback, "http_url_is_empty", module_name)
		return

	if method == HTTP_METHOD_GET and not post_body.is_empty():
		request_url = "%s?%s" % [request_url, post_body]
	print("[HttpRequestService] request module=%s svrType=%d method=%d unzip=%s decrypt=%s url=%s body=%s" % [
		module_name,
		svr_type,
		method,
		str(use_unzip),
		str(use_decrypt),
		request_url,
		post_body
	])

	if _http_manager != null and _http_manager.has_method("RequestAsyncById"):
		_next_request_id += 1
		var request_id: int = _next_request_id
		_pending_callbacks[request_id] = {
			"callback": callback,
			"module_name": module_name,
			"elapsed": 0.0
		}
		set_process(true)
		_http_manager.call(
			"RequestAsyncById",
			request_id,
			HTTP_METHOD_GET if method == HTTP_METHOD_GET else HTTP_METHOD_POST,
			request_url,
			use_unzip,
			use_decrypt,
			"" if method == HTTP_METHOD_GET else post_body
		)
		return

	_fail_callback(callback, "http_manager_unavailable", module_name)


func _encode_query_string(params: Dictionary) -> String:
	var segments: PackedStringArray = []
	for key in params.keys():
		var value: Variant = params[key]
		if typeof(value) == TYPE_NIL:
			continue
		segments.append("%s=%s" % [str(key), str(value)])
	return "&".join(segments)


func _fail_callback(callback: Callable, reason: String, module_name: String) -> void:
	if callback.is_valid():
		callback.call({
			"success": false,
			"module_name": module_name,
			"reason": reason
		})


func _on_request_completed(request_id: int, result: Dictionary) -> void:
	if not _pending_callbacks.has(request_id):
		return

	var context: Dictionary = _pending_callbacks[request_id]
	_pending_callbacks.erase(request_id)
	if _pending_callbacks.is_empty():
		set_process(false)
	var callback: Callable = context.get("callback", Callable())
	var module_name: String = str(context.get("module_name", ""))

	if callback.is_valid():
		if not result.has("module_name"):
			result["module_name"] = module_name
		callback.call(result)
