class_name Level
extends Node2D


const OUT_OF_BOUNDS := Vector2(69, 69)

enum Layer {
	WORLD,
	WORLD_OVERLAYS,
	OBJECTS,
	OVERLAYS,
}

@onready var world_layer := $World
@onready var world_overlay_layer := $WorldOverlays
@onready var object_layer := $Objects
@onready var overlay_layer := $Overlays

@onready var pathing_overlay := $WorldOverlays/Pathing
@onready var attack_range_overlay := $WorldOverlays/AttackRange
@onready var target_shape_overlay := $WorldOverlays/TargetShape
@onready var unit_path := $WorldOverlays/UnitPath
@onready var cursor := $Objects/Cursor


var objects := {}
var cells := []
var out_of_bounds: Array[MapObject] = []

	
func load_world(world: World):
	$Sprite2D.texture = world.texture
	$Sprite2D.scale = Vector2(get_viewport().size)/world.get_internal_size()
	
	cells.resize(world.map_size.x * world.map_size.y)
	for i in cells.size():
		var arr: Array[MapObject] = []
		cells[i] = arr
		
		
func load_map():
	
	var world_transform := world.get_world_transform()
	var uniform_transform := world.get_uniform_transform(get_global_transform(), world_transform)
	for child in get_children():
		if child is MapObject:
			child.world_transform = world_transform
			child.uniform_transform = uniform_transform
			add_object(child)
			
		
## Adds the object to the map.
func add_object(map_object: MapObject):
	if (objects.has(map_object.type) and get_objects(map_object.type).has(map_object)):
		return
		
	if not objects.has(map_object.type):
		var arr: Array[MapObject] = []
		objects[map_object.type] = arr
	
	_add_object(map_object)
	
	
## Removes the object from the map.
func remove_object(map_object: MapObject):
	if not (objects.has(map_object.type) and get_objects(map_object.type).has(map_object)):
		return
	
	_remove_object(map_object)
	
	
func _add_object(map_object: MapObject):
	objects[map_object.type].append(map_object)
	_add_to_cells(map_object, map_object.cell())
	
	var bound := _update_object_cell.bind(map_object)
	map_object.cell_changed.connect(bound)
	map_object.set_meta("_update_object_cell", bound)
	
	
func _add_to_cells(map_object: MapObject, cell: Vector2):
	if not is_within_bounds(cell):
		return
	get_objects_at(cell).append(map_object)
	

func _remove_object(map_object: MapObject):
	objects[map_object.type].erase(map_object)
	_remove_from_cells(map_object, map_object.cell())
	
	var bound := map_object.get_meta("_update_object_cell") as Callable
	map_object.cell_changed.disconnect(bound)
	map_object.remove_meta("_update_object_cell")
	
	
func _remove_from_cells(map_object: MapObject, cell: Vector2):
	if not is_within_bounds(cell):
		return
	get_objects_at(cell).erase(map_object)
	
	
func _update_object_cell(old_cell: Vector2, new_cell: Vector2, map_object: MapObject):
	_remove_from_cells(map_object, old_cell)
	_add_to_cells(map_object, new_cell)
	
	
## Returns the internal(!!) array of objects at cell.
func get_objects_at(cell: Vector2) -> Array[MapObject]:
	if cell == OUT_OF_BOUNDS:
		return out_of_bounds
	else:
		return cells[int(cell.y) * world.map_size.x + int(cell.x)]
	
	
## Returns the objects of type.
func get_objects(type: String) -> Array[MapObject]:
	if type in objects:
		return objects[type]
	else:
		return []
		
		
## Returns the world bounds.
func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, world.map_size)
	
	
## Returns true if pos is within bounds.
func is_within_bounds(pos: Vector2) -> bool:
	return pos == OUT_OF_BOUNDS or get_bounds().has_point(pos)

