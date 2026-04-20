class_name ChatMessageItem
extends "res://script/ui/super-scroll-view/LoopListViewItem.gd"

@onready var _bubble: PanelContainer = get_node_or_null("Bubble")
@onready var _text_label: Label = get_node_or_null("Bubble/Margin/Text")
var _height_retry_left: int = 0


func bind_chat_data(index: int, payload: Dictionary) -> void:
	item_index = index
	if _text_label == null:
		return
	var sender: String = str(payload.get("sender", "未知玩家"))
	var content: String = str(payload.get("content", ""))
	var time_text: String = str(payload.get("time", "00:00"))
	_text_label.text = "[%s] %s：%s" % [time_text, sender, content]
	_height_retry_left = 4
	call_deferred("_refresh_item_height")


func _refresh_item_height() -> void:
	if _bubble == null or _text_label == null:
		return
	# 首帧宽度未稳定时，Label 会给出异常最小高度，导致条目虚高。
	if (_bubble.size.x < 64.0 or _text_label.size.x < 32.0) and _height_retry_left > 0:
		_height_retry_left -= 1
		call_deferred("_refresh_item_height")
		return
	var min_h: float = 72.0
	min_h = maxf(min_h, _bubble.get_combined_minimum_size().y + 4.0)
	min_h = clampf(min_h, 72.0, 180.0)
	custom_minimum_size.y = min_h
	size.y = min_h
	if parent_list_view != null and parent_list_view.has_method("on_item_size_changed"):
		parent_list_view.call("on_item_size_changed", item_index)
