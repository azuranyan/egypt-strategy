@tool
extends Node

class_name MapObjectComponent


signal world_changed
signal map_pos_changed


@export var display_name: String

@export var display_icon: Texture2D

@export var world: World:
	set(value):
		world = value
		world_changed.emit()
		
@export var map_pos: Vector2:
	set(value):
		map_pos = value
		map_pos_changed.emit()
	
@export var pathing_group: Map.Pathing:
	set(value):
		pathing_group = value
		update_configuration_warnings()

@export var no_show: bool = false

@export var debug_tile: bool = false

	
