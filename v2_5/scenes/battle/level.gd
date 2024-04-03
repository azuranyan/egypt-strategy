class_name Level
extends Node2D
## Encapsulated system for bookeeping of map objects and additional map
## related functions like overlays and unit path.

signal object_added(map_object: MapObject)
signal object_removed(map_object: MapObject)


const OUT_OF_BOUNDS := Vector2(69, 69)


var map: Map

var objects := {}
var cells := []
var out_of_bounds: Array[MapObject] = []

@onready var cursor := $Cursor

@onready var world_overlays := $WorldOverlays
@onready var pathing_overlay := $WorldOverlays/Pathing as TileOverlay
@onready var attack_range_overlay := $WorldOverlays/AttackRange as TileOverlay
@onready var target_shape_overlay := $WorldOverlays/TargetShape as TileOverlay
@onready var unit_path := $WorldOverlays/UnitPath


func _ready():
	if get_parent() == get_tree().root:
		_test.call_deferred()


func _test():
	print("Doing Level test")
	#load_map(preload("res://maps/test/test.tscn"))
	

## Loads a map.
func load_map(packed_scene: PackedScene) -> bool:
	if not packed_scene:
		push_error("packed_scene is null!")
		
	print('[Level] Loading map "%s"' % packed_scene.resource_path)
	map = packed_scene.instantiate() as Map
	if not map:
		push_error("[Level] Load failed: packed_scene is not a Map")
		return false
		
	if not is_instance_valid(map.world):
		push_error("[Level] Load failed: map doesn't have a valid world")
		return false
		
	cells.resize(map.world.map_size.x * map.world.map_size.y)
	for i in cells.size():
		var arr: Array[MapObject] = []
		cells[i] = arr
		
	map.object_added.connect(add_object)
	map.object_removed.connect(remove_object)
	
	add_child(map)
	
	print("[Level] Adding pathing barriers.")
	_add_pathing_barriers()

	print("[Level] Finalizing map.")
	$SampleWorld.visible = false
	pathing_overlay.world = map.world
	attack_range_overlay.world = map.world
	target_shape_overlay.world = map.world
	
	print("[Level] Loading done.")
	return true
			
			
func _add_pathing_barriers():
	if not is_instance_valid(map.pathing_painter):
		return
	
	var impassable := map.pathing_painter.get_used_cells_by_color(TileOverlay.TileColor.BLACK)
	if impassable.is_empty():
		return
	
	var dummy_container := MapObjectContainer.new()
	dummy_container.name = '_LevelBarriers'
	map.add_child(dummy_container)
	
	for cell in impassable: # TODO
		pass
		#var barrier := preload("res://scenes/battle/map/map_objects/barrier.tscn").instantiate() as MapObject
		#barrier.map_position = Vector2(cell)
		#dummy_container.add_child(barrier)
	
	map.pathing_painter.visible = false
	
	
## Unloads the map
func unload_map():
	if is_instance_valid(map):
		print('[Level] Unloading map "%s"' % map.scene_file_path)
		objects.clear()
		cells.clear()
		out_of_bounds.clear()
		map.queue_free()
		
		$SampleWorld.visible = true
		pathing_overlay.world = $SampleWorld
		attack_range_overlay.world = $SampleWorld
		target_shape_overlay.world = $SampleWorld
		map = null
		print("[Level] Unloading done.")
	
		
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
	object_added.emit(map_object)
	
	
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
	object_removed.emit(map_object)
	
	
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
		return cells[int(cell.y) * map.world.map_size.x + int(cell.x)]
	
	
## Returns the objects of type.
func get_objects(type: String) -> Array[MapObject]:
	if type in objects:
		return objects[type]
	else:
		return []
		
		
## Returns the world bounds.
func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, map.world.map_size)
	
	
## Returns true if pos is within bounds.
func is_within_bounds(pos: Vector2) -> bool:
	return pos == OUT_OF_BOUNDS or get_bounds().has_point(pos)

