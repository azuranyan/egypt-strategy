class_name Level
extends Node2D
## Encapsulated system for bookeeping of map objects and additional map
## related functions like overlays and unit path.

signal object_added(map_object: MapObject)
signal object_removed(map_object: MapObject)


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
	var test := func():
		unit = preload("res://scenes/battle/unit/unit_impl.tscn").instantiate()
		unit._id = 0
		unit._chara = load("res://units/alara/chara.tres")
		unit._unit_type = load("res://units/alara/unit_type.tres")
		unit._stats.hp = 3
		unit._stats.maxhp = 6
		unit.notify_property_list_changed()
		add_child(unit)
		
		# map should be loaded first
		load_map(load("res://maps/test/test.tscn"))
		
		Game.battle.level = self # hack for testing
		Game.battle.started.emit(null, null, null, 0)
		#Game.battle.ended.emit(null)
		
		# these functions cannot be used before everything is ready
		unit.set_position(Vector2(4, 4))
		unit.walk_towards(Vector2.ZERO)
		#$PrepUnitList.add_unit(unit)
		#var u2 := unit.duplicate()
		#u2._id = 1
		#$PrepUnitList.add_unit(u2)
		#var u3 := unit.duplicate()
		#u3._id = 2
		#$PrepUnitList.add_unit(u3)
		#$PrepUnitList.set_selected_unit(u2)
		#$PrepUnitList.set_selected_unit(null)
		
		
	test.call_deferred()


var _cur: Vector2
func _input(event):
	if event.is_action_pressed('ui_accept'):
		unit.take_damage(2, null)
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_cur += Vector2.UP
			KEY_S:
				_cur += Vector2.DOWN
			KEY_A:
				_cur += Vector2.LEFT
			KEY_D:
				_cur += Vector2.RIGHT
		var tween := get_tree().create_tween()
		tween.tween_property(cursor, 'position', map.world.as_global(_cur), 0.04)
				
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and unit:
	#	unit.walk_towards(Map.cell(map.world.as_uniform(event.position)))


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
	_cur = Vector2.ZERO
	cursor.position = map.world.as_global(_cur)
	
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
	
	#for cell in impassable:
	#	var barrier := preload("res://scenes/battle/map/map_objects/barrier.tscn").instantiate() as MapObject
	#	barrier.map_position = Vector2(cell)
	#	dummy_container.add_child(barrier)
	
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
		cursor.world = $SampleWorld
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
		

func _to_index(cell: Vector2) -> int:
	return int(cell.y) * map.world.map_size.x + int(cell.x)
		
	
## Returns the world bounds.
func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, map.world.map_size)
	
	
## Returns true if pos is within bounds.
func is_within_bounds(pos: Vector2) -> bool:
	return pos == Map.OUT_OF_BOUNDS or get_bounds().has_point(pos)

