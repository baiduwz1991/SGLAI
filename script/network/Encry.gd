class_name Encry
extends RefCounted

var _encry_key: String = ""


func _init(encry_key: String) -> void:
	_encry_key = encry_key


func DoEncry(data: PackedByteArray, start_index: int = 0) -> void:
	if data.is_empty() or _encry_key.is_empty() or start_index >= data.size():
		return

	var key_bytes: PackedByteArray = _encry_key.to_utf8_buffer()
	if key_bytes.is_empty():
		return

	var key_id: int = 0
	var index: int = start_index
	while index < data.size():
		data[index] = data[index] ^ key_bytes[key_id]
		key_id += 1
		if key_id >= key_bytes.size():
			key_id = 0
		index += 1
