@tool
extends Node2D

## A simple object to display World.
class_name WorldInstance 


signal world_changed

## The world data to use. Use the WorldCreator at /tools for a visual creator.
@export var world: World:
	set(value):
		world = value
		update_configuration_warnings()
		world_changed.emit()
		

@onready var sprite := $BaseSprite
@onready var grid := $Grid


func _get_configuration_warnings() -> PackedStringArray:
	var re := PackedStringArray()
	if not world:
		re.append("no world assigned")
	
	return re


func _ready():
	world = world


func _on_world_changed():
	if not is_node_ready():
		await self.ready
	grid.world = world
	if world:
		sprite.texture = world.texture
		sprite.scale = world.get_viewport_scale()
		sprite.position = world.get_viewport_offset()
		grid.size = world.map_size
	else:
		sprite.texture = null
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO
		grid.size = Vector2.ZERO
	grid.queue_redraw()
	