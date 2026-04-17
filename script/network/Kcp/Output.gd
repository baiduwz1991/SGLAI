class_name Output
extends RefCounted


func output(_msg: ByteBuf, _kcp: Kcp, _user: Variant) -> void:
	push_error("Output.output must be overridden.")
