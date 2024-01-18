@tool
## The base class for objects placed in the map.
class_name MapObject
extends Node2D


signal map_pos_changed

	
const DEBUG_TILE_NAME := "Internal_MapObject__debug_tile"


## The pathing group of this object.
@export var pathing: Map.Pathing

## Position of this object in uniform space.
@export var map_pos: Vector2:
	set(value):
		if map_pos == value:
			return
		map_pos = value
		if is_node_ready():
			_update_position()
			_update_tile()
		
## Vertical offset.
@export var vertical_offset: float:
	set(value):
		if vertical_offset == value:
			return
		vertical_offset = value
		if is_node_ready():
			_update_position()
		

@export_subgroup("Visible Properties")

## Whether to show the object in-game or not.
@export var no_show: bool = false:
	set(value):
		if no_show == value:
			return
		no_show = value
		if is_node_ready():
			_update_misc()
			
## Shows the editor debug tile.
@export var show_debug_tile: bool:
	set(value):
		if show_debug_tile == value:
			return
		show_debug_tile = value
		if is_node_ready():
			_update_tile()
		
## Shows the editor debug tile.
@export var debug_tile_color: Color = Color(0.1, 0.7, 0.1, 0.4):
	set(value):
		if debug_tile_color == value:
			return
		debug_tile_color = value
		if is_node_ready():
			_update_tile()
		
		
@export_subgroup("Misc Properties")

## The display name of this object.
@export var display_name: String

## The display icon of this object.
@export var display_icon: Texture2D
		
## A reference to the map.
var map: Map
	
## A reference to the world.
var world: World
		
## Last computed global position.
var _global_pos: Vector2
	
## The debug tile object.
var _debug_tile: Polygon2D
	
	
func _ready():
	set_notify_transform(true)
	_create_debug_tile()
	_update()
	

func _enter_tree() -> void:
	pass

		
func _exit_tree():
	request_ready()
	
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _global_pos != position:
		map_pos = world.as_uniform(position)
		
	
func _create_debug_tile():
	# duplicate guard
	for child in get_children(true):
		if child.name == DEBUG_TILE_NAME:
			child.owner = null
			_debug_tile = child
			return
			
	_debug_tile = Polygon2D.new()
	_debug_tile.visibility_layer = 1 << 9
	_debug_tile.name = DEBUG_TILE_NAME
	add_child(_debug_tile, false, Node.INTERNAL_MODE_FRONT)
	
	
func _enter_map(_map: Map, _world: World):
	map = _map
	world = _world
	map.ready.connect(map_ready)
	map_enter()
	if map.is_node_ready():
		ready.connect(map_ready, CONNECT_ONE_SHOT)
	

func _exit_map():
	map_exit()
	map.ready.disconnect(map_ready)
	self.map = null
	self.world = null
	
	
## Returns the cell this object resides in.
func cell() -> Vector2:
	# kinda shite but it is what it is
	#return Vector2(int(snapped(map_pos.x, 0.01)), int(snapped(map_pos.y, 0.01)))
	return Vector2(roundi(map_pos.x), roundi(map_pos.y))


## Called when map object enters the map.
func map_enter():
	pass
	

## Called when map object exits the map.
func map_exit():
	pass
	

## Called when map is ready.
func map_ready():
	pass


func _update():
	_update_position()
	_update_misc()
	_update_tile()


func _update_position():
	if world:
		_global_pos = world.as_global(map_pos)
	else:
		_global_pos = map_pos
	# TODO vertical_offset physically changes the position of the object.
	# this should be a separate property that's applied like a child modifier.
	_global_pos.y += vertical_offset
	position = _global_pos
	map_pos_changed.emit()
	
	
func _update_misc():
	if no_show:
		visibility_layer = 1 << 9
	else:
		visibility_layer = 1
	
	
func _update_tile():
	var p: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var tile_size: float
	
	if world:
		tile_size = world.tile_size
		_debug_tile.transform = world.world_transform
		_debug_tile.position = world.as_aligned(cell()) - position
	else:
		tile_size = 100 
		_debug_tile.transform = Transform2D()
		_debug_tile.position = Vector2.ZERO
		
	for i in range(4):
		p[i] = p[i] * tile_size
	_debug_tile.polygon = p
	
	_debug_tile.self_modulate = debug_tile_color
	#_debug_tile.visible = show_debug_tile
	if show_debug_tile:
		_debug_tile.visibility_layer = 1
	else:
		_debug_tile.visibility_layer = 1 << 9
