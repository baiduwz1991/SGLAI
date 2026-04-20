extends Control

#region 生命周期
func _ready() -> void:
	var start_ui: BaseUI = UIManager.open_ui(UIRegistry.START_GAME_LAYER, {}, UIManager.MODE_REPLACE)
	if start_ui == null:
		push_error("UIBootstrap 启动失败：无法打开 START_GAME_SCENE。")
		return

	# 启动器只负责点火，启动成功后立即自销毁，避免常驻场景树。
	call_deferred("queue_free")
#endregion
