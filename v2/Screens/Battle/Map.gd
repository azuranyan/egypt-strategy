@tool
extends Node2D
class_name Map

## The world. Populated when world enters the scene tree.
@export var world: World

var tiles: Array[Tile] = []


class Tile:
	var object
	var x: int
	var y: int
	
	func get_name() -> String:
		if object == null:
			return "None"
		elif object is Node:
			return object.name
		else:
			return object
			
	func is_passable() -> bool:
		if object is Doodad:
			return object.passable
		return true


# Called when the node enters the scene tree for the first time.
func _ready():
	_tile_doodads()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _tile_doodads():
	tiles.resize(world.map_size.x * world.map_size.y)
	for y in world.map_size.y:
		for x in world.map_size.x:
			var tile := Tile.new()
			tile.object = null
			tile.x = x
			tile.y = y
			tiles[y*world.map_size.x + x] = tile
		
	for c in get_children():
		if c is MapObject:
			c._map_enter(self)
			get_tile(c.map_pos).object = c


func get_tile(pos: Vector2) -> Tile:
	var x := roundi(pos.x)
	var y := roundi(pos.y)
	
	if x < 0 or y < 0 or x >= world.map_size.x or y >= world.map_size.y:
		var t := Tile.new()
		t.object = "Out of bounds"
		t.x = x
		t.y = y
		return t
	else:
		return tiles[y*world.map_size.x + x]
	
