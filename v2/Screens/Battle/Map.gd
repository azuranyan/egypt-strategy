@tool
extends Node2D
class_name Map


## The world. Populated when world enters the scene tree.
@export var world: World


var dynamic_objects: Array[MapObject] = []

var static_objects: Array[MapObject] = []


# Called when the node enters the scene tree for the first time.
func _ready():
	static_objects.resize(world.map_size.x * world.map_size.y)
	var ss := get_objects(true)
	for c in ss:
		c._map_enter(self)
		static_objects[c.map_pos.y*world.map_size.x + c.map_pos.x] = c
		
	var dd := get_objects(false)
	for c in dd:
		c._map_enter(self)
		dynamic_objects.append(c)
		
	


## Returns a list of objects in the map.
func get_objects(is_static := true) -> Array[MapObject]:
	var v: Array[MapObject] = []
	for c in get_children():
		if c is MapObject and c.is_static() == is_static:
			v.append(c)
	return v
	
	
## Returns the object at a given position
func get_object_at(pos := Vector2.ZERO, is_static := true) -> MapObject:
	var x := roundi(pos.x)
	var y := roundi(pos.y)
	
	if is_static:
		return static_objects[y*world.map_size.x + x]
	else:
		for c in dynamic_objects:
			if roundi(c.map_pos.x) == x and roundi(c.map_pos.y) == y:
				return c
		return null


## Places the object in the map.
func place_object(object: MapObject, pos := Vector2.ZERO):
	add_child(object)
	object._map_enter(self)
	
	if object.is_static():
		var x := roundi(pos.x)
		var y := roundi(pos.y)
		object.map_pos = Vector2(x, y)
		static_objects[y*world.map_size.x + x] = object
	else:
		object.map_pos = pos
		dynamic_objects.append(object)
		
	
## Removes the object from the map.
func remove_object(object: MapObject):
	if object:
		remove_child(object)
		if object.is_static():
			static_objects.erase(object)
		else:
			dynamic_objects.erase(object)
	
