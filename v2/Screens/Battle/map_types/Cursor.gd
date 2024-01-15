@tool
class_name Cursor
extends Node2D


@export var world: World:
	set(value):
		if world == value:
			return
		world = value
		if is_node_ready():
			update_configuration_warnings()
			_update()

@export var texture: Texture2D:
	set(value):
		if texture == value:
			return
		texture = value
		if is_node_ready():
			_update()

@export var vertical_offset: float:
	set(value):
		if vertical_offset == value:
			return
		vertical_offset = value
		if is_node_ready():
			_update()
	
	
@onready var sprite := $Sprite2D


func _ready():
	_update()


func _get_configuration_warnings() -> PackedStringArray:
	if not world:
		return ["World is not assigned!"]
	return []


func _update():
	sprite.texture = texture
	if world:
		var scaling := Vector2(world.tile_size, world.tile_size) / texture.get_size() 
		var offset := Vector2(0, vertical_offset) #- Vector2(0.5, 0.5) * world.tile_size 
		sprite.transform = world.world_transform * Transform2D(0, scaling, 0, Vector2.ZERO)
		sprite.position = Vector2(0, sqrt(2) * world.y_ratio / -2) * world.tile_size 
		sprite.position.y += vertical_offset
	else:
		sprite.transform = Transform2D()
	
	
func _on_map_map_changed():
	_update()

