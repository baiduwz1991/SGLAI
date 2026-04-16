class_name NetPacketCodec
extends RefCounted


const HEADER_SIZE: int = 12


func encode_payload(payload: Dictionary) -> String:
	return JSON.stringify(payload)


func decode_text(raw_text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {
		"success": false,
		"error_message": "invalid_json_payload",
		"raw_text": raw_text
	}


func decode_binary(packet: PackedByteArray) -> Dictionary:
	if packet.size() < HEADER_SIZE:
		return {
			"success": false,
			"error_message": "packet_too_short",
			"request_id": 0,
			"msg_id": 0,
			"payload": {}
		}

	var request_id: int = packet.decode_s32(0)
	var msg_id: int = packet.decode_s32(4)
	var body_size: int = packet.decode_s32(8)
	if body_size < 0 or packet.size() < HEADER_SIZE + body_size:
		return {
			"success": false,
			"error_message": "invalid_packet_length",
			"request_id": request_id,
			"msg_id": msg_id,
			"payload": {}
		}

	var body: PackedByteArray = packet.slice(HEADER_SIZE, HEADER_SIZE + body_size)
	var body_text: String = body.get_string_from_utf8()
	var payload: Dictionary = decode_text(body_text)
	payload["request_id"] = request_id
	payload["msg_id"] = msg_id
	payload["success"] = payload.get("success", true)
	return payload
