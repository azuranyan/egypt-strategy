@tool
extends Node2D

@onready var world := $Map.world as World
@onready var unit := $Map/Unit as Unit
@onready var drivers := $Drivers
@onready var unit_path := $UnitPath as UnitPath

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
	if not Engine.is_editor_hint():
		test.call_deferred()
		
	var m := Transform2D()
	
	# scale to downsize to unit vector
	m = m.scaled(Vector2.ONE/Vector2(unit_path.tile_set.tile_size))
	if world:
		# scale to tile size
		m = m.scaled(Vector2(world.tile_size, world.tile_size))
		
	unit_path.transform = world._world_to_screen_transform * m

	unit_path.position = world.uniform_to_screen(Vector2(-0.5, -0.5))
	
	var arr := []
	arr.resize(world.map_size.x * world.map_size.y)
	var n := 0
	for j in world.map_size.y:
		for i in world.map_size.x:
			var vec := Vector2(i, j)
			# TODO if pathable, do this else not pathable
			print(n, " ", vec, " ", world.to_index(vec))
			arr[world.to_index(vec)] = vec
			n += 1
			
	unit_path.initialize(arr)


func _input(event):
	if event is InputEventMouseMotion:
		var start := unit.map_pos
		var end := world.screen_to_uniform(event.position)
		print("connect %s -> %s" % [start, end])
		unit_path.draw(start, end)

	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			walk_towards(unit, world.screen_to_uniform(event.position))


func random_path(length: int) -> PackedVector2Array:
#	if driver.walking:
#		return make_random_path(length, unit.curve.get_point_out(unit.curve.point_count), Vector2.ZERO, world.map_size - Vector2i.ONE, true)
#	else:
	return make_random_path(length, unit.map_pos, Vector2.ZERO, world.map_size - Vector2i.ONE, true)


## Makes the unit walk towards a point.
func walk_towards(which: Unit, end: Vector2):
	var start := which.map_pos
	var path := unit_path._pathfinder.calculate_point_path(start, end)
	walk_along(which, path)
	

## Makes the unit walk along a path.
func walk_along(which: Unit, path: PackedVector2Array):
	if is_walking(which):
		stop_walking(which)
	var driver: UnitDriver = preload("res://Screens/Battle/map/UnitDriver.tscn").instantiate()
	driver.unit = which
	which.set_meta("driver", driver)
	drivers.add_child(driver)
	await driver.walk_along(path)
	drivers.remove_child(driver)
	which.remove_meta("driver")
	driver.queue_free()
	
	
## Makes the unit stop walking.
func stop_walking(which: Unit):
	which.get_meta("driver").stop_walking()
	

## Returns true if the unit is walking.
func is_walking(which: Unit):
	return which.has_meta("driver")
	
	
func test():
	#walk_along(random_path(randi_range(1, 10)))
	pass


