class_name NetCryptoService
extends RefCounted

const DEFAULT_ENCODE_KEY: String = "537b9b7a-a18c-11ea-afae-6c92bf62e626"
const MAX_DECOMPRESS_BYTES: int = 8 * 1024 * 1024

var _encode_key: String = DEFAULT_ENCODE_KEY


func _init(encode_key: String = DEFAULT_ENCODE_KEY) -> void:
	_encode_key = encode_key


func SpecialXorDecode(input: String) -> String:
	if input.is_empty():
		return ""

	var decoded: PackedByteArray = Marshalls.base64_to_raw(input)
	if decoded.is_empty():
		return input

	var key_bytes: PackedByteArray = _encode_key.to_utf8_buffer()
	if key_bytes.is_empty():
		return input

	var index: int = 0
	while index < decoded.size():
		decoded[index] = decoded[index] ^ key_bytes[index % key_bytes.size()]
		index += 1
	return decoded.get_string_from_utf8()


func TryUnzip(raw_bytes: PackedByteArray) -> PackedByteArray:
	if raw_bytes.size() < 2:
		return PackedByteArray()

	# gzip: 1F 8B
	if raw_bytes[0] == 0x1f and raw_bytes[1] == 0x8b:
		return raw_bytes.decompress_dynamic(MAX_DECOMPRESS_BYTES, FileAccess.COMPRESSION_GZIP)

	# zlib(deflate): 78 01 / 78 5E / 78 9C / 78 DA
	if raw_bytes[0] == 0x78 and (raw_bytes[1] == 0x01 or raw_bytes[1] == 0x5e or raw_bytes[1] == 0x9c or raw_bytes[1] == 0xda):
		return raw_bytes.decompress_dynamic(MAX_DECOMPRESS_BYTES, FileAccess.COMPRESSION_DEFLATE)

	return PackedByteArray()
