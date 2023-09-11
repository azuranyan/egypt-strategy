@tool
extends Node2D

## A simple object to display World.
class_name WorldInstance 

@export_category("World")

## The world data to use. Use the WorldCreator at /tools for a visual creator.
@export var world: World:
	set(value):
		world = value
		_update_world()
	get:
		return world

@onready var sprite := $BaseSprite

@onready var grid := $Grid


func _ready():
	world = world


func _update_world():
	#if world:
	#	world.recalculate_uniform_transforms()
	#	world.recalculate_world_transforms()
	
	# reload sprite
	if sprite != null:
		if world != null:
			sprite.texture = world.texture
			sprite.scale = world.get_viewport_scale()
			sprite.position = world.get_viewport_offset()
		else:
			sprite.texture = null
			sprite.scale = Vector2.ONE
			sprite.position = Vector2.ZERO

	# reload grid
	if grid != null:
		if world:
			grid.size = world.map_size
		else:
			# godot silently fails on erroneous assignment and won't call your
			# setter but won't throw an error either. FML
			#grid.size = 0
			grid.size = Vector2.ZERO
