@tool
extends Node2D

class_name Map


signal world_changed


## Pathing group ordered by increasing strictness.
enum Pathing {
	## Object is always passable.
	NONE,
	
	## Object is impassable to enemy units.
	UNIT,
	
	## Object is impassable but can by bypassed with a special movement skill.
	DOODAD,
	
	## Object is impassable but can by bypassed with a special movement skill.
	TERRAIN,
	
	## Object is impassable and cannot be bypassed.
	IMPASSABLE,
}


@export var world: World:
	set(value):
		world = value
		world_changed.emit()


var world_instance: WorldInstance

var objects: Array[Node] = []



func _ready():
	world_instance = preload("res://Screens/Battle/map/WorldInstance.tscn").instantiate()
	add_child(world_instance, false, Node.INTERNAL_MODE_BACK)
	world_instance.world = world
	world_instance.z_index = -1
	

func add_map_object(node: Node):
	if node.get_parent():
		node.get_parent().remove_child(node)
	add_child(node)
	_add_map_object(node)
	

func remove_map_object(node: Node):
	remove_child(node)
	_remove_map_object(node)
	

func _add_map_object(node: Node):
	objects.append(node)
	

func _remove_map_object(node: Node):
	objects.erase(node)


## Returns the object at a given position
func get_object_at(pos: Vector2) -> MapObject:
	
	return null


## Returns true if uniform pos is inside bounds.
func is_inside_bounds(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x <= world.map_size.x-1 and pos.y <= world.map_size.y-1
	
	
## Returns a list of spawnable units.
func get_spawn_units(spawn_point: String) -> Array[String]:
	return []
	

func _is_map_object(node: Node) -> bool:
	#return "world" in node and "map_pos" in node and ""
	return "mapobject" in node


func _on_world_changed():
	world_instance.world = world


func _on_child_entered_tree(node: Node):
	# node may not be ready at this point and doing anything to it before
	# it's ready causes tons of headache
	if not node.is_node_ready():
		await node.ready
	if _is_map_object(node):
		_add_map_object(node)


func _on_child_exiting_tree(node: Node):
	if _is_map_object(node):
		_remove_map_object(node)
