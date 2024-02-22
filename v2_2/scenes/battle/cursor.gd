@tool
class_name Cursor
extends Node2D


@export var unit_mode := false:
	set(value):
		unit_mode = value
		if not is_node_ready():
			await ready
		$Label.visible = unit_mode
		$Transformable/Sprite.visible = not unit_mode


func _input(event):
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseMotion:
		#var cell := Map.cell(Battle.instance().world().as_uniform(event.position))
		unit_mode = Game._interaction_handler.has_hovered_unit()# or Battle.instance().is_occupied(cell)