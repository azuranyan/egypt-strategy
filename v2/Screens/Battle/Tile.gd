@tool
extends Node2D
class_name Tile


@export var tile_size: Vector2:
	set(value):
		var sx = value.x/base_size.x
		var sy = value.y/base_size.y
		tile_size = value
		self.scale.x = sx
		self.scale.y = sy
	get:
		return tile_size

@onready var base_size: Vector2 = $Sprite.get_texture().get_size():
	get:
		return base_size
