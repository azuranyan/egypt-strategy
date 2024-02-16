class_name Level
extends Node2D
## Encapsulated system for bookeeping of map objects and additional map
## related functions like overlays and unit path.

signal object_added(map_object: MapObject)
signal object_removed(map_object: MapObject)

const BarrierScene := preload("res://scenes/battle/map_objects/barrier.tscn")


## The loaded map.
var map: Map

## A list of all the objects in the level.
var objects: Array[MapObject]

## A an array of array of objects in each cell.
var cells := []

## An array of out of bounds objects.
var out_of_bounds: Array[MapObject] = []

## A separate cell array of pathables.
var pathables := []

## An array of out of bounds pathable objects.
var out_of_bounds_pathables: Array[PathableComponent] = []

var unit: Unit


@onready var cursor := $Cursor
@onready var world_overlays := $WorldOverlays
@onready var pathing_overlay := $WorldOverlays/Pathing as TileOverlay
@onready var attack_range_overlay := $WorldOverlays/AttackRange as TileOverlay
@onready var target_shape_overlay := $WorldOverlays/TargetShape as TileOverlay
@onready var unit_path := $WorldOverlays/UnitPath


func _ready():
	load_map(preload('res://maps/test/test.tscn'))


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
	pathables.resize(cells.size())
	for i in cells.size():
		cells[i] = [] as Array[MapObject]
		pathables[i] = [] as Array[PathableComponent]
		
	map.object_added.connect(add_object)
	map.object_removed.connect(remove_object)
	
	add_child(map)
	
	print("[Level] Adding pathing barriers.")
	_add_pathing_barriers()

	print("[Level] Finalizing map.")
	$WorldSample.visible = false
	pathing_overlay.world = map.world
	attack_range_overlay.world = map.world
	target_shape_overlay.world = map.world
	cursor.world = map.world
	cursor.position = map.world.as_global(Vector2.ZERO)
	
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
	
	for cell in impassable:
		if _has_barrier(cell):
			continue
		var barrier: Barrier = BarrierScene.instantiate()
		barrier.map_position = Vector2(cell)
		dummy_container.add_child(barrier)
	
	map.pathing_painter.visible = false
	
	
func _has_barrier(cell: Vector2) -> bool:
	for obj in get_objects_at(cell):
		if obj is Barrier:
			return true
	return false
	
	
## Unloads the map
func unload_map():
	if is_instance_valid(map):
		print('[Level] Unloading map "%s"' % map.scene_file_path)
		objects.clear()
		cells.clear()
		out_of_bounds.clear()
		map.queue_free()
		
		$WorldSample.visible = true
		pathing_overlay.world = $WorldSample
		attack_range_overlay.world = $WorldSample
		target_shape_overlay.world = $WorldSample
		cursor.world = $WorldSample
		map = null
		print("[Level] Unloading done.")
	
		
## Adds the object to the map.
func add_object(map_object: MapObject):
	if map_object in objects:
		return
	_add_object(map_object)
	
	
## Removes the object from the map.
func remove_object(map_object: MapObject):
	if map_object not in objects:
		return
	_remove_object(map_object)
	
	
func _add_object(map_object: MapObject):
	objects.append(map_object)
	_add_to_cells(map_object, map_object.cell())
	
	# add the bookeeping sync function
	var sync := _update_object_cell.bind(map_object)
	map_object.cell_changed.connect(sync)
	map_object.set_meta("_update_object_cell", sync)
	
	object_added.emit(map_object)
	
	
func _remove_object(map_object: MapObject):
	objects.erase(map_object)
	_remove_from_cells(map_object, map_object.cell())
	
	# remove bookeeping sync function
	var sync := map_object.get_meta("_update_object_cell") as Callable
	map_object.cell_changed.disconnect(sync)
	map_object.remove_meta("_update_object_cell")
	
	object_removed.emit(map_object)
	
	
func _add_to_cells(map_object: MapObject, cell: Vector2):
	if not is_within_bounds(cell):
		return
	get_objects_at(cell).append(map_object)
	
	if map_object.components.has(PathableComponent.GROUP_ID):
		get_pathables_at(cell).append(map_object.components[PathableComponent.GROUP_ID])
	
	
func _remove_from_cells(map_object: MapObject, cell: Vector2):
	if not is_within_bounds(cell):
		return
	get_objects_at(cell).erase(map_object)
	
	if map_object.components.has(PathableComponent.GROUP_ID):
		get_pathables_at(cell).erase(map_object.components[PathableComponent.GROUP_ID])
	
	
func _update_object_cell(old_cell: Vector2, new_cell: Vector2, map_object: MapObject):
	_remove_from_cells(map_object, old_cell)
	_add_to_cells(map_object, new_cell)
	
	
## Returns the internal(!!) array of objects at cell.
func get_objects_at(cell: Vector2) -> Array[MapObject]:
	if cell == Map.OUT_OF_BOUNDS:
		return out_of_bounds
	else:
		return cells[_to_index(cell)]
	
	
## Returns the internal(!!) array of objects at cell.
func get_pathables_at(cell: Vector2) -> Array[PathableComponent]:
	if cell == Map.OUT_OF_BOUNDS:
		return out_of_bounds_pathables
	else:
		return pathables[_to_index(cell)]
		
		
## Returns the spawn points
func get_spawn_points(type: SpawnPoint.Type) -> Array[SpawnPoint]:
	var arr: Array[SpawnPoint] = []
	for obj in objects:
		if obj is SpawnPoint and obj.type == type:
			arr.append(obj)
	return arr
	

func _to_index(cell: Vector2) -> int:
	return int(cell.y) * map.world.map_size.x + int(cell.x)
		
	
## Returns the world bounds.
func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, map.world.map_size)
	
	
## Returns true if pos is within bounds.
func is_within_bounds(pos: Vector2) -> bool:
	return pos == Map.OUT_OF_BOUNDS or get_bounds().has_point(pos)

