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


## A special out of bounds position.
const OUT_OF_BOUNDS := Vector2(69, 420)


## A reference to the world variable.
@export var world: World:
	set(value):
		world = value
		update_configuration_warnings()
		world_changed.emit()


var world_instance: WorldInstance

# trading space for more efficient lookups
var _objects: Array[MapObject] = []
var _objects_by_group := {}
var _objects_by_pos := {}


func _get_configuration_warnings() -> PackedStringArray:
	var re := PackedStringArray()
	if not world:
		re.append("world is null")
	return re


func _ready():
	world_instance = preload("res://Screens/Battle/map/WorldInstance.tscn").instantiate()
	add_child(world_instance, false, Node.INTERNAL_MODE_BACK)
	world_instance.world = world
	world_instance.z_index = -10
	

## Adds a map object.
func add_object(node: MapObject):
	if node.get_parent():
		node.get_parent().remove_child(node)
	add_child(node)
	_add_map_object(node)
	

## Removes a map object.
func remove_object(node: MapObject):
	remove_child(node)
	_remove_map_object(node)
	

func _add_map_object(node: MapObject):
	node.world = world
	get_objects_of(node.pathing).append(node)
	get_objects_at(node.map_pos).append(node)
	_objects.append(node)
	

func _remove_map_object(node: MapObject):
	get_objects_of(node.pathing).erase(node)
	get_objects_at(node.map_pos).erase(node)
	_objects.erase(node)
	
	
## Returns all the objects.
func get_objects() -> Array[MapObject]:
	return _objects
	
	
## Returns the objects of specified pathing type.
func get_objects_of(type: Pathing) -> Array[MapObject]:
	if not _objects_by_group.has(type):
		var arr: Array[MapObject] = []
		_objects_by_group[type] = arr
		
	return _objects_by_group[type]


## Returns the objects at specified position.
func get_objects_at(pos: Vector2) -> Array[MapObject]:
	var cell := cell(pos)
	if not (pos == OUT_OF_BOUNDS or world.in_bounds(cell)):
		push_error("%s out of bounds" % pos)
		
	if not _objects_by_pos.has(cell):
		var arr: Array[MapObject] = []
		_objects_by_pos[cell] = arr
		
	return _objects_by_pos[cell]
	
	
## Returns the object of given type at a given position.
func get_object(pos: Vector2, type: Pathing) -> MapObject:
	var arr := get_objects_at(pos)
	for obj in arr:
		if obj.pathing == type:
			return obj
	return null


## Returns the object at a given position.
func get_object_at(pos: Vector2) -> MapObject:
	var arr := get_objects_at(pos)
	return arr[0] if not arr.is_empty() else null
	
	
## Returns true if uniform pos is inside bounds.
func is_inside_bounds(pos: Vector2) -> bool:
	var cell := cell(pos)
	return world.in_bounds(cell)
	
	
## Returns a list of spawnable units.
func get_spawn_units(spawn_point: String) -> Array[String]:
	return []
	

## Returns the cell of a given pos.
func cell(pos: Vector2) -> Vector2i:
	return Vector2i(roundi(pos.x), roundi(pos.y))


## Returns the index of a given pos.
func index(pos: Vector2) -> int:
	# TODO to_index works with trunc but we need round
	#return world.to_index(pos)
	var cell := cell(pos)
	return cell.y*world.map_size.x + cell.x
	

## Returns returns true if the cell is occupied by a unit.
func is_occupied(pos: Vector2) -> bool:
	return get_object(pos, Map.Pathing.UNIT) != null
	

func _is_map_object(node: Node) -> bool:
	return node is MapObject


func _on_world_changed():
	if not is_node_ready():
		await self.ready
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
