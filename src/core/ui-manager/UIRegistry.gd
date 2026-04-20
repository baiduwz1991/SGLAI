class_name UIRegistry
extends RefCounted

const START_GAME_LAYER: StringName = &"START_GAME_LAYER"
const LOGIN_PANEL: StringName = &"LOGIN_PANEL"
const SELECT_SERVER_PANEL: StringName = &"SELECT_SERVER_PANEL"
const SERVER_LIST_POP_LAYER: StringName = &"SERVER_LIST_POP_LAYER"
const HOME_LAYER: StringName = &"HOME_LAYER"
const HOME_BACKPACK_TAB_CONTENT: StringName = &"HOME_BACKPACK_TAB_CONTENT"
const HOME_BATTLE_TAB_CONTENT: StringName = &"HOME_BATTLE_TAB_CONTENT"
const HOME_WORLD_TAB_CONTENT: StringName = &"HOME_WORLD_TAB_CONTENT"
const HOME_GENERAL_TAB_CONTENT: StringName = &"HOME_GENERAL_TAB_CONTENT"

const _UI_REGISTRY: Dictionary[StringName, Dictionary] = {
	START_GAME_LAYER: {
		"scene_path": "res://src/modules/startgame/view/StartGameLayer.tscn",
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
	SELECT_SERVER_PANEL: {
		"scene_path": "res://src/modules/login/view/SelectServerPanel.tscn",
		"default_mode": &"attach",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": true
	},
	SERVER_LIST_POP_LAYER: {
		"scene_path": "res://src/modules/login/view/ServerListPopLayer.tscn",
		"default_mode": &"overlay",
		"layer": &"overlay",
		"allow_multi_instance": false,
		"block_input": true
	},
	HOME_LAYER: {
		"scene_path": "res://src/modules/home/view/HomeLayer.tscn",
		"default_mode": &"replace",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": true
	},
	HOME_BACKPACK_TAB_CONTENT: {
		"scene_path": "res://src/modules/backpack/view/HomeBackpackTabContent.tscn",
		"default_mode": &"attach",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": false
	},
	HOME_BATTLE_TAB_CONTENT: {
		"scene_path": "res://src/modules/battle/view/HomeBattleTabContent.tscn",
		"default_mode": &"attach",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": false
	},
	HOME_WORLD_TAB_CONTENT: {
		"scene_path": "res://src/modules/world/view/HomeWorldTabContent.tscn",
		"default_mode": &"attach",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": false
	},
	HOME_GENERAL_TAB_CONTENT: {
		"scene_path": "res://src/modules/general/view/HomeGeneralTabContent.tscn",
		"default_mode": &"attach",
		"layer": &"main",
		"allow_multi_instance": false,
		"block_input": false
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
