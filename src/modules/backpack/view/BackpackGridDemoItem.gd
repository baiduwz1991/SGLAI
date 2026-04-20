class_name BackpackGridDemoItem
extends "res://script/ui/super-scroll-view/LoopListViewItem.gd"

@onready var _label: Label = get_node_or_null("Label")


func bind_item_data(index: int, _data: Variant) -> void:
	item_index = index
	if _label == null:
		return
	_label.text = "%d" % (index + 1)
