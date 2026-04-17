class_name HomeModuleTabBase
extends BaseUI

@export var module_title: String = ""

@onready var _title_label: Label = get_node_or_null("Content/VBox/Title")
@onready var _desc_label: Label = get_node_or_null("Content/VBox/Desc")


func on_ui_create(params: Dictionary) -> void:
	var initial_title: String = _resolve_title(params)
	_refresh_text(initial_title)
	_on_module_create(params)


func on_ui_open(params: Dictionary) -> void:
	var current_title: String = _resolve_title(params)
	_refresh_text(current_title)
	_on_module_open(params)


func _on_module_create(_params: Dictionary) -> void:
	pass


func _on_module_open(_params: Dictionary) -> void:
	pass


func _resolve_title(params: Dictionary) -> String:
	var fallback_title: String = module_title
	if fallback_title == "":
		fallback_title = _get_default_title()
	return str(params.get("title", fallback_title))


func _get_default_title() -> String:
	return ""


func _refresh_text(title: String) -> void:
	if _title_label != null:
		_title_label.text = title
	if _desc_label != null:
		_desc_label.text = "当前页签：%s" % title
