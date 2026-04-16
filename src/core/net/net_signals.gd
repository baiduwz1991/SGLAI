class_name NetSignals
extends Node


signal connection_state_changed(state: int, reason: String)
signal request_succeeded(command: StringName, payload: Dictionary)
signal request_failed(command: StringName, payload: Dictionary)
signal push_received(command: StringName, payload: Dictionary)
