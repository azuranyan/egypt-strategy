
@tool
class_name NodePropertyAccess
extends Resource


@export var path: NodePath

@export var property: StringName


func value() -> Variant:
	var node := Game.get_node(path)
	if node and property in node:
		return node.get(property)
	else:
		return null


func _to_string() -> String:
	return str(value())