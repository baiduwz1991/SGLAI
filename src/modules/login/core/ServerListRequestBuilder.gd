class_name ServerListRequestBuilder
extends RefCounted


func build_request_bundle(
	platform: Node,
	login_payload: Dictionary,
	server_user_id: String,
	rand_num: int,
	language_code: String
) -> Dictionary:
	var partner_id: String = str(platform.get("partner_id"))
	var game_version_id: String = str(platform.get("version"))
	var login_key: String = str(platform.get("login_key"))
	var encrypt_source: String = "%s%s%s%s" % [partner_id, game_version_id, str(rand_num), login_key]
	var encrypted_string: String = encrypt_source.md5_text()

	var resource_version_name: String = str(platform.get("resource_version_name"))
	var user_id: String = server_user_id
	var should_use_login_info: bool = user_id.is_empty()

	var login_info: Dictionary = {
		"PartnerId": partner_id,
		"sessionId": user_id,
		"method": "Login"
	}
	if login_payload.has("login_info") and login_payload["login_info"] is Dictionary:
		login_info = (login_payload["login_info"] as Dictionary).duplicate(true)

	var request_data: Dictionary = {
		"gameID": 0,
		"PartnerID": partner_id,
		"GameVersionID": game_version_id,
		"RandNum": rand_num,
		"EncryptedString": encrypted_string,
		"ResourceVersionName": resource_version_name,
		"UserID": null if should_use_login_info else user_id,
		"AreaId": null,
		"LabelId": null,
		"NewVersion": "true",
		"Language": language_code
	}
	if should_use_login_info:
		request_data["LoginInfo"] = JSON.stringify(login_info)
	else:
		request_data["LoginInfo"] = null

	var login_key_tail: String = login_key.substr(max(0, login_key.length() - 6), min(6, login_key.length()))
	var debug_meta: Dictionary = {
		"PartnerID": partner_id,
		"GameVersionID": game_version_id,
		"RandNum": rand_num,
		"LoginKeyTail": login_key_tail,
		"EncryptedString": encrypted_string
	}

	return {
		"request_data": request_data,
		"debug_meta": debug_meta
	}
