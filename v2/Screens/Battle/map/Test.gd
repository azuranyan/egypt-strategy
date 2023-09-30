@tool
extends Node2D

@onready var world := $Map.world as World
@onready var unit := $Map/Unit as Unit
@onready var drivers := $Drivers
@onready var unit_path := $UnitPath as UnitPath
@onready var terrain_overlay := $TerrainOverlay as TileMap

@onready var map := $Map as Map

static func make_square_path(path: PackedVector2Array) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := Vector2.ZERO
	
	re.append(prev)
	for p in path:
		if p.x != prev.x and p.y != prev.y:
			if p.x < p.y:
				re.append(Vector2(p.x, prev.y))
			else:
				re.append(Vector2(prev.x, p.y))
		re.append(p)
		prev = p
	return re


static func make_random_path(
		length: int,
		start: Vector2,
		min: Vector2,
		max: Vector2,
		square := true
		) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := start
	
	re.append(prev)
	for i in length:
		var p := Vector2(randi_range(min.x, max.x), randi_range(min.y, max.y))
		if square:
			if p.x != prev.x and p.y != prev.y:
				if p.x < p.y:
					p = Vector2(p.x, prev.y)
				else:
					p = Vector2(prev.x, p.y)
		re.append(p)
		prev = p
	
	return re



func _ready():
	unit.unit_type = preload("res://Screens/Battle/data/UnitType_Lysandra.tres")
	$Map/Unit2.unit_type = preload("res://Screens/Battle/data/UnitType_Maia.tres")
		
	var m := Transform2D()
	
	# scale to downsize to unit vector
	m = m.scaled(Vector2.ONE/Vector2(unit_path.tile_set.tile_size))
	if world:
		# scale to tile size
		m = m.scaled(Vector2(world.tile_size, world.tile_size))
		
	unit_path.transform = world._world_to_screen_transform * m

	unit_path.position = world.uniform_to_screen(Vector2(-0.5, -0.5))
	
#	var arr := []
#	arr.resize(world.map_size.x * world.map_size.y)
#	var n := 0
#	for j in world.map_size.y:
#		for i in world.map_size.x:
#			var vec := Vector2(i, j)
#			# TODO if pathable, do this else not pathable
#			print(n, " ", vec, " ", map.index(vec))
#			arr[map.index(vec)] = vec
#			n += 1
	
	var arr := get_walkable_cells(unit)
	unit_path.initialize(arr)
	
	add_unit_callbacks(unit)
	add_unit_callbacks($Map/Unit2)
	
	if not Engine.is_editor_hint():
		test.call_deferred()


#func _input(event):
#	if event is InputEventMouseMotion:
#		var start := unit.map_pos
#		var end := world.screen_to_uniform(event.position)
#		unit_path.draw(start, end)
#
#	if event is InputEventMouseButton:
#		if event.button_index == 1 and event.pressed:
#			unit_path.initialize(get_walkable_cells(unit))
#			walk_towards(unit, world.screen_to_uniform(event.position))


## Directions.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]


func random_path(length: int) -> PackedVector2Array:
#	if driver.walking:
#		return make_random_path(length, unit.curve.get_point_out(unit.curve.point_count), Vector2.ZERO, world.map_size - Vector2i.ONE, true)
#	else:
	return make_random_path(length, unit.map_pos, Vector2.ZERO, world.map_size - Vector2i.ONE, true)


## Makes the unit walk towards a point.
func walk_towards(unit: Unit, end: Vector2):
	var start := unit.map_pos
	var path := unit_path._pathfinder.calculate_point_path(start, end)
	walk_along(unit, path)
	

## Makes the unit walk along a path.
func walk_along(unit: Unit, path: PackedVector2Array):
	if is_walking(unit):
		stop_walking(unit)
		
	# initialize driver
	var driver: UnitDriver = preload("res://Screens/Battle/map/UnitDriver.tscn").instantiate()
	driver.unit = unit
	unit.set_meta("driver", driver)
	drivers.add_child(driver)
	
	# run and wait for driver
	await driver.walk_along(path)
	
	# cleanup
	drivers.remove_child(driver)
	unit.remove_meta("driver")
	driver.queue_free()
	
	walking_finished.emit(unit, driver.stopped)
	
	
## Makes the unit stop walking.
func stop_walking(unit: Unit):
	unit.get_meta("driver").stop_walking()
	

## Returns true if the unit is walking.
func is_walking(unit: Unit):
	return unit.has_meta("driver")
	
	
## Returns an array of walkable cells in range.
func get_walkable_cells(unit: Unit) -> PackedVector2Array:
	return _flood_fill(unit, map.cell(unit.map_pos), unit.mov)
	

func _flood_fill(unit: Unit, cell: Vector2, max_distance: int) -> PackedVector2Array:
	var re := PackedVector2Array()
	
	var stack := [cell]
	
	while not stack.is_empty():
		var current = stack.pop_back()
		
		# bounds check
		if not world.in_bounds(current):
			continue
		
		# dupe check
		if current in re:
			continue
			
		# distance check
		var diff: Vector2 = (current - cell).abs()
		var dist := int(diff.x + diff.y)
		if dist > max_distance:
			continue
			
		if not is_pathable(unit, current):
			continue
			
		re.append(current)
		
		for direction in DIRECTIONS:
			var coords: Vector2 = current + direction
			
			if not world.in_bounds(coords):
				continue
			
			#if map.is_occupied(coords):
			#	continue
			
			if coords in re:
				continue
			
			stack.append(coords)
	return re
	
	

func add_unit_callbacks(unit: Unit):
	var cb := func(button):
		if button == 1:
			unit_selected.emit(unit)
	unit.button_up.connect(cb)
	unit.set_meta("Map_unit_selected", cb)
	
	
func remove_unit_callbacks(unit: Unit):
	var cb = unit.get_meta("Map_unit_selected")
	unit.button_up.disconnect(cb)
	unit.remove_meta("Map_unit_selected")
	
	
func test():
	print("waiting for interact?")


signal unit_selected(unit: Unit)
signal rmb_pressed()
signal location_selected(pos: Vector2)
signal walking_finished(unit: Unit, cancelled: bool)

class Context:
	var state := STATE_IDLE
	var unit: Unit
	var old_pos: Vector2
	var old_facing: float
	var walkable: PackedVector2Array
	
	var location_selected: Vector2
	var location_hovered: Vector2
	

var context := Context.new()

enum {
	STATE_IDLE,
	STATE_UNIT_SELECTED,
	STATE_WALKING,
	STATE_DONE,
}

class UnitMoveAction:
	var unit: Unit
	var pos: Vector2
	var facing: float


func _transition_to(state: int, kwargs: Dictionary = {}):
	_on_exit(context.state, kwargs)
	context.state = state
	_on_enter(context.state, kwargs)


func _on_enter(state: int, kwargs: Dictionary):
	match state:
		STATE_IDLE:
			pass
			
		STATE_UNIT_SELECTED:
			var walkable := get_walkable_cells(kwargs.unit)
			
			kwargs.unit.animation.play("highlight")
			
			unit_path.initialize(walkable)
			
			for pos in walkable:
				terrain_overlay.set_cell(0, Vector2i(pos), 0, Vector2i(0, 0), 0)
			
			context.unit = kwargs.unit
			context.old_pos = kwargs.unit.map_pos
			context.old_facing = kwargs.unit.facing
			context.walkable = walkable
		
		STATE_WALKING:
			walk_towards(context.unit, context.location_selected)
			
		STATE_DONE:
			# TODO place somewhere appropriate
			map.get_objects_at(context.old_pos).erase(context.unit)
			map.get_objects_at(context.unit.map_pos).append(context.unit)
			
			context.unit = null
			context.old_pos = Vector2.ZERO
			context.old_facing = 0
			context.walkable = []
			
			# TODO commit_action
			
			_transition_to.call_deferred(STATE_IDLE)
			
			
func _on_exit(state: int, kwargs: Dictionary):
	match state:
		STATE_IDLE:
			pass
			
		STATE_UNIT_SELECTED:
			context.unit.animation.stop()
			unit_path.clear()
			terrain_overlay.clear()
			
		STATE_WALKING:
			pass
			
		STATE_DONE:
			pass


func _on_unit_selected(unit: Unit):
	print("selected ", unit)
	if context.state == STATE_IDLE:
		print("  %s == %s? %s" % [context.unit, unit, context.unit == unit])
		if context.unit == unit:
			print("  same unit")
		else:
			print("  transition")
			_transition_to(STATE_UNIT_SELECTED, {unit=unit})


func _on_rmb_pressed():
	match context.state:
		STATE_IDLE:
			# TODO pop action
			pass
			
		STATE_UNIT_SELECTED:
			#_transition_to(STATE_IDLE)
			_transition_to(STATE_DONE)
			
		STATE_WALKING:
			stop_walking(context.unit)
		
		STATE_DONE:
			_transition_to(STATE_IDLE)
			unit.map_pos = context.old_pos
			unit.facing = context.old_facing
			


func _on_location_selected(pos: Vector2):
	if context.state == STATE_UNIT_SELECTED:
		if pos == context.old_pos:
			pass
			#_transition_to(STATE_DONE)
		else:
			_transition_to(STATE_WALKING)
			
			
func _on_walking_finished(unit: Unit, cancelled: bool):
	if cancelled:
		unit.map_pos = context.old_pos
		unit.facing = context.old_facing
		_transition_to(STATE_UNIT_SELECTED, {unit=unit})
	else:
		_transition_to(STATE_DONE)


## Returns true if pos is pathable.
func is_pathable(unit: Unit, pos: Vector2) -> bool:
	for obj in map.get_objects_at(pos):
		if not unit.can_path(obj):
			return false
	return true
	

## Returns true if this unit can be placed on pos.
func is_placeable(unit: Unit, pos: Vector2) -> bool:
	if map.cell(unit.map_pos) == map.cell(pos):
		return false
	for obj in map.get_objects_at(pos):
		if not unit.can_place(obj):
			return false
	return true
	
			
func _input(event):
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		rmb_pressed.emit()
		
	match context.state:
		STATE_IDLE:
			pass
			
		STATE_UNIT_SELECTED:
			if event is InputEventMouseMotion:
				var end := world.screen_to_uniform(event.position, true)
				if end != context.location_hovered:
					if end != context.old_pos and \
							end in context.walkable and \
							is_placeable(context.unit, end):
						var start := context.old_pos
						unit_path.draw(start, end)
					else:
						unit_path.clear()
					context.location_hovered = end
				
			if event is InputEventMouseButton:
				if event.button_index == 1 and event.pressed:
					var pos := world.screen_to_uniform(event.position, true)
					if pos in context.walkable and is_placeable(context.unit, pos):
						context.location_selected = pos
						location_selected.emit(pos)
			
		STATE_WALKING:
			pass
		
		STATE_DONE:
			pass
	

