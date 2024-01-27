@tool
class_name MapObjectComponent
extends Node
## Base class for [MapObject] components.


## The map object this component is connected to.
@export var map_object: MapObject:
	set(value):
		if is_instance_valid(map_object):
			map_object.components.erase(group_id())
		map_object = value
		if is_instance_valid(map_object):
			if group_id() in map_object.components:
				map_object.components[group_id()].map_object = null
			map_object.components[group_id()] = self
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	if not is_instance_valid(map_object):
		return ['"map_object" is not assigned']
	return []


func _enter_tree():
	add_to_group(group_id())


func _exit_tree():
	remove_from_group(group_id())
	

## Returns a human readable id string for grouping.
func group_id() -> StringName:
	return 'BaseComponent'
