class_name HomeBattleTab
extends HomeModuleTabBase

#region 状态
var _chat_messages: Array[Dictionary] = []
#endregion

#region 节点引用
@export var chat_list_view_path: NodePath
@export var top_index_list_view_path: NodePath

@onready var chat_list_view: ScrollContainer = get_node(chat_list_view_path) as ScrollContainer
@onready var top_index_list_view: ScrollContainer = get_node(top_index_list_view_path) as ScrollContainer
#endregion


#region 生命周期
func on_ui_create(params: Dictionary) -> void:
	super.on_ui_create(params)
	_on_battle_create(params)


func on_ui_open(params: Dictionary) -> void:
	super.on_ui_open(params)
	_on_battle_open(params)
#endregion


#region 扩展点
func _get_default_title() -> String:
	return "战斗"
#endregion


#region 交互与显示
func _on_battle_create(_params: Dictionary) -> void:
	if top_index_list_view.has_signal("item_bound"):
		if not top_index_list_view.is_connected("item_bound", Callable(self, "_on_top_index_item_bound")):
			top_index_list_view.connect("item_bound", Callable(self, "_on_top_index_item_bound"))
	if top_index_list_view.has_method("init_list_view"):
		top_index_list_view.call("init_list_view", 100)
	if chat_list_view.has_signal("item_bound"):
		if not chat_list_view.is_connected("item_bound", Callable(self, "_on_chat_item_bound")):
			chat_list_view.connect("item_bound", Callable(self, "_on_chat_item_bound"))
	if chat_list_view.has_method("init_list_view"):
		chat_list_view.call("init_list_view", 0)


func _on_battle_open(_params: Dictionary) -> void:
	_chat_messages = _build_mock_chat_messages()
	if chat_list_view.has_method("set_count_and_refresh"):
		chat_list_view.call("set_count_and_refresh", _chat_messages.size(), true)
	if chat_list_view.has_method("refresh_all_shown_item"):
		chat_list_view.call("refresh_all_shown_item")


func _on_chat_item_bound(index: int, item_node: Node) -> void:
	if item_node == null:
		return
	if index < 0 or index >= _chat_messages.size():
		return
	if item_node.has_method("bind_chat_data"):
		item_node.call("bind_chat_data", index, _chat_messages[index])


func _on_top_index_item_bound(index: int, item_node: Node) -> void:
	if item_node == null:
		return
	if item_node.has_method("bind_index"):
		item_node.call("bind_index", index)
#endregion


#region 内部逻辑
func _build_mock_chat_messages() -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	var short_templates: PackedStringArray = PackedStringArray([
		"收到。",
		"走起！",
		"我在门口。",
		"等我 3 秒。"
	])
	var medium_templates: PackedStringArray = PackedStringArray([
		"这个点位先别压，等技能转好再一起开。",
		"我先去拉一下怪，你们准备好再进场。",
		"右路有动静，来个人帮我看一下视野。",
		"下一波我来先手，你们跟伤害就行。"
	])
	var long_templates: PackedStringArray = PackedStringArray([
		"刚才那波其实能打赢，主要是我进场太急了，下一波我会先报点再开，大家等我口令一起上。",
		"这条是故意做得比较长的虚构消息，用来测试聊天气泡在多行文本场景下的显示和滚动稳定性，请忽略业务含义。",
		"我们先把外围资源点拿稳，再慢慢往中路推进，不要急着越塔，保持阵型和技能衔接就能稳住节奏。"
	])
	var idx: int = 1
	while idx <= 50:
		var minute: int = (idx / 3) % 60
		var second: int = (idx * 7) % 60
		var sender: String = "玩家%02d" % ((idx % 12) + 1)
		var content_body: String = ""
		match idx % 3:
			0:
				content_body = short_templates[idx % short_templates.size()]
			1:
				content_body = medium_templates[idx % medium_templates.size()]
			_:
				content_body = long_templates[idx % long_templates.size()]
		var content: String = "第%d条虚构消息：%s" % [idx, content_body]
		messages.append({
			"time": "%02d:%02d" % [minute, second],
			"sender": sender,
			"content": content
		})
		idx += 1
	return messages
#endregion
