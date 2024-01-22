@tool
## The base class for objects placed in the map.
class_name MapObject
extends Node2D


signal map_pos_changed


## Position of this object in uniform space.
@export var map_pos: Vector2:
	set(value):
		if map_pos == value:
			return
		map_pos = value
		if is_node_ready():
			_update_position()
		
## Vertical offset.
@export var vertical_offset: float:
	set(value):
		if vertical_offset == value:
			return
		vertical_offset = value
		if is_node_ready():
			_update_position()
	
@export_subgroup("Misc Properties")

## Whether to show the object in-game or not.
@export var no_show: bool = false:
	set(value):
		if no_show == value:
			return
		no_show = value
		if is_node_ready():
			_update_misc()
			
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
	
	
func _ready():
	set_notify_transform(true)
	_update()
	

func _enter_tree() -> void:
	pass

		
func _exit_tree():
	request_ready()
	
	
func _notification(what: int) -> void:
	# TODO since this is a tool script and it relies on map_object and world
	# so many things will fucking break when opening this scene without them
	if what == NOTIFICATION_TRANSFORM_CHANGED and _global_pos != position and is_instance_valid(world):
		map_pos = world.as_uniform(position)
	
	
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
	
