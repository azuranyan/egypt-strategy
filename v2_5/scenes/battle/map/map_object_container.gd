@tool
class_name MapObjectContainer
extends Node2D

signal object_added(obj: MapObject)
signal object_removed(obj: MapObject)


func _ready():
	y_sort_enabled = true
	

func _enter_tree():
	child_entered_tree.connect(_add_object)
	child_exiting_tree.connect(_remove_object)
	update_configuration_warnings()
	
	
func _exit_tree():
	child_entered_tree.disconnect(_add_object)
	child_exiting_tree.disconnect(_remove_object)
	request_ready()
	update_configuration_warnings()
	
	
func _add_object(node: Node):
	if node is MapObjectContainer:
		node.object_added.connect(_add_object)
		node.object_removed.connect(_remove_object)
	elif node is MapObject:
		object_added.emit(node)


func _remove_object(node: Node):
	if node is MapObjectContainer:
		node.object_added.disconnect(_add_object)
		node.object_removed.disconnect(_remove_object)
	elif node is MapObject:
		object_removed.emit(node)
	
	
func _get_configuration_warnings() -> PackedStringArray:
	if not (get_parent() is Map or get_parent() is MapObjectContainer):
		return ['not assigned to Map or MapObjectContainer']
	return []
			
			
func _is_map_object_container() -> bool:
	# Map <-> MapObject <-> MapObjectContainer <-> Map
	return true
	
	
	
	
	
	
