@tool
extends Node2D


signal property_changed(prop, value)


@export_category("WorldCreator")

## The image source.
@export var texture: Texture2D:
	set(value):
		texture = value
		property_changed.emit("texture", value)
	get:
		return texture

## The size of the map.
@export var map_size: Vector2i:
	set(value):
		map_size = value
		property_changed.emit("map_size", value)
	get:
		return map_size

## Tile size deduced from source (in world_instance size units).
@export var tile_size: int:
	set(value):
		tile_size = value
		property_changed.emit("tile_size", value)
	get:
		return tile_size

## The off-center offset of the level (in world_instance size units).
@export var offset: Vector2:
	set(value):
		offset = value
		property_changed.emit("offset", value)
	get:
		return offset

## Ratio of tile height to its width.
@export var y_ratio: float:
	set(value):
		y_ratio = value
		property_changed.emit("y_ratio", value)
	get:
		return y_ratio
		
@export_subgroup("Export")

@export var world: World:
	set(value):
		world = value
		property_changed.emit("world", value)
	get:
		return world

@onready var world_instance := $WorldInstance


func _ready():
	property_changed.connect(_update_world)
	
	# we create a new world every time we ready, this will also sync
	# the current values
	world = World.new()
	
	
func _update_world(prop, value):
	# everytime we change a property, we compute a bajillion of things.
	# this isn't ideal but it should work for a class this small.
	if world:
		if prop == "world":
			world.texture = texture
			world.map_size = map_size
			world.tile_size = tile_size
			world.offset = offset
			world.y_ratio = y_ratio
		else:
			world.set(prop, value)
		world.recalculate_uniform_transforms()
		world.recalculate_world_transforms()
	
	world_instance.world = world
