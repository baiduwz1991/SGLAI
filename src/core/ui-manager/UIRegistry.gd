class_name UIRegistry
extends RefCounted

const START_GAME_SCENE: StringName = &"START_GAME_SCENE"
const LOGIN_PANEL: StringName = &"LOGIN_PANEL"
const SERVER_LIST_POPUP: StringName = &"SERVER_LIST_POPUP"
const HOME_TEST_PANEL: StringName = &"HOME_TEST_PANEL"

const _UI_REGISTRY: Dictionary[StringName, Dictionary] = {
	START_GAME_SCENE: {
		"scene_path": "res://src/modules/startgame/view/StartGameScene.tscn",
		"default_mode": &"replace",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": true
	},
	LOGIN_PANEL: {
		"scene_path": "res://src/modules/login/view/LoginPanel.tscn",
		"default_mode": &"attach",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": true
	},
	SERVER_LIST_POPUP: {
		"scene_path": "res://src/modules/login/view/ServerListPopup.tscn",
		"default_mode": &"overlay",
		"layer": &"overlay",
		"allow_multi_instance": false,
		"block_input": true
	},
	HOME_TEST_PANEL: {
		"scene_path": "res://src/modules/homeTest/view/HomeTestPanel.tscn",
		"default_mode": &"replace",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": true
	}
}


static func has_ui(ui_id: StringName) -> bool:
	return _UI_REGISTRY.has(ui_id)


static func get_ui_config(ui_id: StringName) -> Dictionary:
	if not has_ui(ui_id):
		return {}
	return (_UI_REGISTRY[ui_id] as Dictionary).duplicate(true)


static func get_scene_path(ui_id: StringName) -> String:
	var config: Dictionary = get_ui_config(ui_id)
	return str(config.get("scene_path", ""))
