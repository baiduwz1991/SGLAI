class_name TopIndexItem
extends "res://script/ui/super-scroll-view/LoopListViewItem.gd"

#region 节点引用
@export var label_path: NodePath

@onready var label: Label = get_node(label_path) as Label
#endregion


#region 绑定
func bind_index(index: int) -> void:
	item_index = index
	label.text = "%d" % (index + 1)
#endregion
