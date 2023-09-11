@tool
extends Node2D

## Base class for objects in a Map.
class_name MapObject


signal map_pos_changed
signal impassable_changed
signal no_show_changed

## Position of this object in the map.
@export var map_pos: Vector2:
	set(value):
		map_pos = value
		map_pos_changed.emit()

## Whether this object is an impassable solid object.
@export var impassable := true:
	set(value):
		impassable = value
		impassable_changed.emit()

## For special non-interactible, hidden markers in-game ("hidden" property is already taken).
@export var no_show := false:
	set(value):
		no_show = value
		no_show_changed.emit()


## Reference to the map.
var map: Map

## Reference to the world.
var world: World

## The debug tile.
var tile: Polygon2D
	

## Called by map when adding to this node.
func _map_enter(_map: Map):
	map = _map
	world = _map.world
	
	_setup()


# Base ready. Loads a default world when initialized outside of map.
func _ready():
	# load a default world if running headless
	if map == null:
		world = preload("res://Screens/Battle/data/World_StartingZone.tres") as World
		_setup()
	

## Custom ready function.
func _setup():
	_create_tile()
	
	# connect properties
	map_pos_changed.connect(_update_tile)
	impassable_changed.connect(_update_tile_color)
	no_show_changed.connect(_update_visibility)
	
	# refresh properties
	map_pos = map_pos
	impassable = impassable
	no_show = no_show
	
	z_as_relative = false
	#z_index = 1
	
	map_init()
	
	
## Creates the debug tile under the object.
func _create_tile():
	if tile != null:
		remove_child(tile)
		
	tile = Polygon2D.new()
	
	tile.visibility_layer = 1 << 9
	tile.z_index = -1 # set z as -1 so it draws under default z index objects
	
	var p := PackedVector2Array()
	p.resize(4)
	p.fill(Vector2.ZERO)
	
	tile.polygon = p
	
	add_child(tile)
	
	
## Updates the tile color.
func _update_tile_color():
	tile.color = Color(0.78, 0.48, 0.48, 0.6) if impassable else Color(0.48, 0.78, 0.48, 0.6)
	
	
## Updates the tile shape.
func _update_tile():
	# position ourselves to where we should be
	position = world.uniform_to_screen(map_pos)
	
	# recalculate position of tile
	var pos := world.uniform_to_world(map_pos)
	tile.polygon[0] = world.world_to_screen(Vector2(-0.5, -0.5) * world.tile_size + pos) - position
	tile.polygon[1] = world.world_to_screen(Vector2(+0.5, -0.5) * world.tile_size + pos) - position
	tile.polygon[2] = world.world_to_screen(Vector2(+0.5, +0.5) * world.tile_size + pos) - position
	tile.polygon[3] = world.world_to_screen(Vector2(-0.5, +0.5) * world.tile_size + pos) - position
	
	
## Updates visibility.
func _update_visibility():
	if no_show:
		visibility_layer = 1 << 9
	else:
		visibility_layer = 1
	
		
## Virtual function called when map is ready.
func map_init() -> void:
	pass
	
