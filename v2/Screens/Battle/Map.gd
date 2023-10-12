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
const OUT_OF_BOUNDS := Vector2i(69, 420)


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

var _spawnable := {}

func _get_configuration_warnings() -> PackedStringArray:
	var re := PackedStringArray()
	if not world:
		re.append("world is null")
	# TODO add warning when no spawn points
	# TODO add warning when invalid spawn points
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
	get_objects_at(cell(node.map_pos)).append(node)
	_objects.append(node)
	

func _remove_map_object(node: MapObject):
	get_objects_of(node.pathing).erase(node)
	get_objects_at(cell(node.map_pos)).erase(node)
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
func get_objects_at(cell: Vector2i) -> Array[MapObject]:
	var re: Array[MapObject]
	for o in get_objects():
		if cell(o.map_pos) == cell:
			re.append(o)
	return re
	
	
## Returns the object of given type at a given position.
func get_object(cell: Vector2i, type: Pathing) -> MapObject:
	for obj in get_objects_at(cell):
		if obj.pathing == type:
			return obj
	return null


## Returns the object at a given position.
func get_object_at(cell: Vector2i) -> MapObject:
	var arr := get_objects_at(cell)
	return arr[0] if not arr.is_empty() else null
	
	
## Returns true if uniform pos is inside bounds.
func is_inside_bounds(cell: Vector2i) -> bool:
	return world.in_bounds(cell)
	
	
## Returns a list of spawnable units. Safe to call before ready.
func get_spawnable(spawn_point: String) -> Array[String]:
	if not _spawnable.has(spawn_point):
		var arr: Array[String] = []
		var tmp = []

		# TODO cannot get spawn units before ready
		for obj in get_children():
			if not obj is MapObject:
				continue
			
			if obj.get_meta("spawn_point") == spawn_point:
				var spawn_unit = obj.get_meta("spawn_unit")
				if not spawn_unit:
					tmp.append("*")
				elif spawn_unit is String:
					tmp.append(spawn_unit)
				elif spawn_unit is PackedStringArray or spawn_unit is Array[String]:
					for u in spawn_unit:
						tmp.append(u)
						
		for u in tmp:
			if u not in arr:
				arr.append(u)
				
		_spawnable[spawn_point] = arr
	return _spawnable[spawn_point]
	

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
	
	
################################################################################
# Convenience Functions
################################################################################


## Returns the unit at cell.
func get_unit(cell: Vector2i) -> Unit:
	return get_object(cell, Pathing.UNIT) as Unit


## Returns all the units.
func get_units(cells = null) -> Array[Unit]:
	# this isn't pretty but i couldn't care less anymore
	var re: Array[Unit]
	for o in get_objects_of(Pathing.UNIT):
		if not cells or Vector2(cell(o.map_pos)) in cells:
			re.append(o)
	return re


## Returns spawn points with given types.
func get_spawn_points(tag: String) -> PackedVector2Array:
	var re := PackedVector2Array()
	for obj in get_objects():
		if obj.get_meta("spawn_point", "") == tag:
			re.append(cell(obj.map_pos))
	return re
	

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
