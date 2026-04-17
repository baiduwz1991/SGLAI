class_name HomeModuleTab
extends BaseUI

@export var module_title: String = ""

@onready var _title_label: Label = get_node_or_null("Content/VBox/Title")
@onready var _desc_label: Label = get_node_or_null("Content/VBox/Desc")


func on_ui_create(_params: Dictionary) -> void:
	_refresh_text(module_title)


func on_ui_open(params: Dictionary) -> void:
	var dynamic_title: String = str(params.get("title", module_title))
	_refresh_text(dynamic_title)


func _refresh_text(title: String) -> void:
	if _title_label != null:
		_title_label.text = title
	if _desc_label != null:
		_desc_label.text = "当前页签：%s" % title
