@tool
extends Node2D

@onready var world := $Map.world as World
@onready var unit := $Map/Unit as Unit
@onready var drivers := $Drivers


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


func random_path(length: int) -> PackedVector2Array:
#	if driver.walking:
#		return make_random_path(length, unit.curve.get_point_out(unit.curve.point_count), Vector2.ZERO, world.map_size - Vector2i.ONE, true)
#	else:
	return make_random_path(length, unit.map_pos, Vector2.ZERO, world.map_size - Vector2i.ONE, true)


func walk_along(path: PackedVector2Array):
	var driver: UnitDriver = preload("res://Screens/Battle/map/UnitDriver.tscn").instantiate()
	driver.unit = unit
	unit.set_meta("driver", driver)
	drivers.add_child(driver)
	await driver.walk_along(path)
	drivers.remove_child(driver)
	unit.remove_meta("driver")
	driver.queue_free()
	
	
func stop_walking():
	unit.get_meta("driver").stop_walking()
	
	
func test():
	walk_along(random_path(randi_range(1, 10)))


