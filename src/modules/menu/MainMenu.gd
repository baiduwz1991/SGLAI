extends Control

signal start_game_requested
signal settings_requested
signal quit_requested

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _on_start_button_pressed() -> void:
	# 预留：后续在此切换到游戏主场景，或在外部监听 start_game_requested 信号。
	print("开始游戏按钮已点击（预留）")
	start_game_requested.emit()


func _on_settings_button_pressed() -> void:
	# 预留：后续在此弹出设置面板，或在外部监听 settings_requested 信号。
	print("设置按钮已点击（预留）")
	settings_requested.emit()


func _on_quit_button_pressed() -> void:
	# 预留：后续可改为二次确认退出流程。
	print("退出按钮已点击（预留）")
	quit_requested.emit()
	get_tree().quit()
