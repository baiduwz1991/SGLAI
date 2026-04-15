extends Node

const CANDIDATE_FONT_PATHS: PackedStringArray = [
	"res://assests/fonts/TDLJ_Font_GBK.ttf",
	"res://assets/fonts/NotoSansSC-Regular.ttf",
	"res://assets/fonts/SourceHanSansSC-Regular.otf",
	"res://assets/fonts/msyh.ttf"
]

const SYSTEM_FONT_NAMES: PackedStringArray = [
	"Microsoft YaHei",
	"PingFang SC",
	"Noto Sans CJK SC",
	"Source Han Sans SC",
	"WenQuanYi Micro Hei",
	"Arial Unicode MS"
]

const DEFAULT_FONT_SIZE: int = 30

var _default_font: Font
var _default_theme: Theme


func _ready() -> void:
	_default_font = _resolve_default_font()
	_default_theme = _build_runtime_theme(_default_font)
	_apply_global_theme(_default_theme)


func get_default_font() -> Font:
	return _default_font


func get_default_theme() -> Theme:
	return _default_theme


func _resolve_default_font() -> Font:
	for font_path in CANDIDATE_FONT_PATHS:
		if ResourceLoader.exists(font_path):
			var loaded_font: Font = load(font_path) as Font
			if loaded_font != null:
				return loaded_font

	var system_font := SystemFont.new()
	system_font.font_names = SYSTEM_FONT_NAMES
	push_warning("未找到内置中文字体。建议将中文字体放到 res://assets/fonts/ 以避免微信端方块字。")
	return system_font


func _build_runtime_theme(font: Font) -> Theme:
	var runtime_theme := Theme.new()
	runtime_theme.default_font = font
	runtime_theme.default_font_size = DEFAULT_FONT_SIZE
	return runtime_theme


func _apply_global_theme(runtime_theme: Theme) -> void:
	var root_window: Window = get_tree().root
	if root_window == null:
		push_warning("UI 字体服务初始化失败：未获取到根窗口。")
		return

	root_window.theme = runtime_theme
