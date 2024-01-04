@tool
## The base class for objects placed in the map.
class_name MapObject
extends Node2D


signal map_changed
signal map_pos_changed


## The display name of this object.
@export var display_name: String

## The display icon of this object.
@export var display_icon: Texture2D
		
## Position of this object in uniform space.
@export var map_pos: Vector2:
	set(value):
		map_pos = value
		_refresh_position()
		map_pos_changed.emit()

## The pathing group of this object.
@export var pathing: Map.Pathing

@export_subgroup("Visible Properties")

## Whether to show the object or not.
@export var no_show: bool = false:
	set(value):
		no_show = value
		if no_show:
			visibility_layer = 1 << 9
		else:
			visibility_layer = 1
			
## Vertical offset.
@export var vertical_offset: float = 0:
	set(value):
		vertical_offset = value
		_refresh_position()
		
## Shows the debug tile.
@export var show_debug_tile: bool = true:
	set(value):
		show_debug_tile = value
		if not is_node_ready():
			await ready
		_polytile.visible = show_debug_tile
		
		
## The reference to the world.
var map: NewMap:
	set(value):
		if map:
			map.world_changed.disconnect(_map_changed_internal)
		map = value
		if map:
			map.world_changed.connect(_map_changed_internal)
		
		_map_changed_internal.call_deferred()
		
		
@onready var _polytile: Polygon2D



func _map_changed_internal():
	_refresh_position()
	var p: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	if map:
		for i in range(4):
			# TODO we're gonna have to constantly do this calculation (-position)
			# becase we don't store local transforms and always compute global.
			p[i] = map.to_global(p[i] + map_pos) - position
	_polytile.polygon = p
	map_changed.emit()
	
	
func _refresh_position():
	if map:
		position = map.to_global(map_pos)
	else:
		position = map_pos
		
	# TODO vertical_offset physically changes the position of the object.
	# this should be a separate property that's applied like a child modifier.
	position.y += vertical_offset
	
	
func _ready():
	_polytile = Polygon2D.new()
	_polytile.self_modulate = Color(0.1, 0.7, 0.1, 0.4)
	add_child(_polytile, false, INTERNAL_MODE_FRONT)

