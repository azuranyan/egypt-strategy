@tool
class_name Cursor
extends Node2D


@export var unit_mode := false:
	set(value):
		unit_mode = value
		if not is_node_ready():
			await ready
		$Label.visible = unit_mode
		#$Transformable/Sprite.visible = not unit_mode

