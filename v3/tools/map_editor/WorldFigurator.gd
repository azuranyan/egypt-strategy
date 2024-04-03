@tool
extends Node2D


signal world_changed


func _ready():
	set_notify_local_transform(true)


func _notification(what):
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		pass
		
		
		
