@tool
extends Node2D

class_name MapObject


signal world_changed
signal map_pos_changed


## The display name of this object.
@export var display_name: String

## The display icon of this object.
@export var display_icon: Texture2D

## The reference to the world.
@export var world: World:
	set(value):
		world = value
		_refresh_position()
		world_changed.emit()
		
## Position of this object in uniform space.
@export var map_pos: Vector2:
	set(value):
		map_pos = value
		_refresh_position()
		map_pos_changed.emit()

## The pathing group of this object.
@export var pathing: Map.Pathing

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
		

func _refresh_position():
	if world:
		position = world.uniform_to_screen(map_pos)
	else:
		position = Vector2.ZERO
	position.y += vertical_offset
