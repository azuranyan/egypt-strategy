@tool
extends Node2D

signal property_changed(prop, value)


@export_category("MapCreator")


## The image source.
@export var texture: Texture2D:
	set(value):
		texture = value
		property_changed.emit("texture", value)
		print("set prop ", "texture", ": ", value)
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
		
		
		
# Called when the node enters the scene tree for the first time.
func _ready():
	var world := World.new()
	print(world)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
