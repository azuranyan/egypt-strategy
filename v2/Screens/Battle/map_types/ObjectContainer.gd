@tool
class_name ObjectContainer extends Node2D

signal object_added(obj: MapObject)
signal object_removed(obj: MapObject)


func _on_child_entered_tree(node: Node):
	if node is MapObject:
		object_added.emit(node)


func _on_child_exiting_tree(node: Node):
	if node is MapObject:
		object_removed.emit(node)
