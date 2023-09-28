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


const OUT_OF_BOUNDS := Vector2(69, 420)


@export var world: World:
	set(value):
		world = value
		world_changed.emit()


var world_instance: WorldInstance

var _objects_by_group := {}
var _objects_by_pos := {}


func _ready():
	world_instance = preload("res://Screens/Battle/map/WorldInstance.tscn").instantiate()
	add_child(world_instance, false, Node.INTERNAL_MODE_BACK)
	world_instance.world = world
	world_instance.z_index = -1
	

## Adds a map object. Node must have MapObject component.
func add_map_object(node: Node):
	if node.get_parent():
		node.get_parent().remove_child(node)
	add_child(node)
	_add_map_object(node)
	

## Removes a map object.
func remove_map_object(node: Node):
	remove_child(node)
	_remove_map_object(node)
	

func _add_map_object(node: Node):
	node.mapobject.world = world
	get_objects_of(node.mapobject.pathing_group).append(node)
	get_objects_at(node.mapobject.map_pos).append(node)
	

func _remove_map_object(node: Node):
	node.mapobject.world = world
	get_objects_of(node.mapobject.pathing_group).erase(node)
	get_objects_at(node.mapobject.map_pos).erase(node)
	
	
## Returns the objects of specified pathing type.
func get_objects_of(type: Pathing) -> Array[Node]:
	if not _objects_by_group.has(type):
		var arr: Array[Node] = []
		_objects_by_group[type] = arr
		
	return _objects_by_group[type]


## Returns the objects at specified position.
func get_objects_at(pos: Vector2) -> Array[Node]:
	var cell := Vector2i(pos)
	if not (pos == OUT_OF_BOUNDS or world.in_bounds(cell)):
		push_error("%s out of bounds" % pos)
		
	if not _objects_by_pos.has(cell):
		var arr: Array[Node] = []
		_objects_by_pos[cell] = arr
		
	return _objects_by_pos[cell]
	

## Returns all the objects.
func get_map_objects() -> Array[Node]:
	return _objects_by_group.values()
	
	
## Returns the object at a given position
func get_object_at(pos: Vector2, type: Pathing) -> Node:
	var arr := get_objects_at(pos)
	for obj in arr:
		if obj.mapobject.pathing_group == type:
			return obj
	return null


## Returns true if uniform pos is inside bounds.
func is_inside_bounds(pos: Vector2) -> bool:
	return world.in_bounds(pos)
	
	
## Returns a list of spawnable units.
func get_spawn_units(spawn_point: String) -> Array[String]:
	return []
	

func _is_map_object(node: Node) -> bool:
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
