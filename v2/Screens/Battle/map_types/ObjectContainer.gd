@tool
class_name ObjectContainer extends Node2D

signal object_added(obj: MapObject)
signal object_removed(obj: MapObject)


func _ready():
	y_sort_enabled = true
	

func _enter_tree():
	child_entered_tree.connect(_add_object)
	child_exiting_tree.connect(_remove_object)
	
	
func _exit_tree():
	child_entered_tree.disconnect(_add_object)
	child_exiting_tree.disconnect(_remove_object)
	request_ready()
	
	
func _add_object(node: Node):
	if node is ObjectContainer:
		node.object_added.connect(_add_object)
		node.object_removed.connect(_remove_object)
	elif node is MapObject:
		print('container: ', node, ' added')
		object_added.emit(node)


func _remove_object(node: Node):
	if node is ObjectContainer:
		node.object_added.disconnect(_add_object)
		node.object_removed.disconnect(_remove_object)
	elif node is MapObject:
		print('container: ', node, ' removed')
		object_removed.emit(node)
	
	
	
	
	
	
	
	
	
