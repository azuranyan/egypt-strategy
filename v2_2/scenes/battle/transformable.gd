@tool
class_name Transformable
extends Node2D
## A special object attached to [MapObject] that applies the world transforms to itself.


## The world to receive updates from.
@export var world: World:
	set(value):
		if is_instance_valid(world):
			world.world_changed.disconnect(_on_world_changed)
		world = value
		if is_instance_valid(world):
			world.world_changed.connect(_on_world_changed)
		_on_world_changed()
		update_configuration_warnings()
		
		
## The size to fit in the grid.
@export var internal_size: Vector2 = Vector2(128, 128):
	set(value):
		internal_size = value
		_on_world_changed()


## Which transforms to apply.
@export_flags("Scale:1", "Rotation:2", "Translation:4") var transform_flags: int = 1 | 2:
	set(value):
		transform_flags = value
		_on_world_changed()


func _get_configuration_warnings() -> PackedStringArray:
	if not is_instance_valid(world):
		return ['world not assigned!']
	return []


func _on_world_changed():
	transform = Transform2D()
	if not (is_instance_valid(world) and internal_size.x != 0 and internal_size.y != 0 and transform_flags != 0):
		return
		
	if not world.is_node_ready(): # just in case...
		await ready
		
	var unit_scale := Vector2.ONE / internal_size * world.tile_size
	var m := world.world_transform * Transform2D(0, unit_scale, 0, Vector2.ZERO)
	transform = m
	
	if transform_flags & 1 == 0:
		scale = Vector2.ONE
	if transform_flags & 2 == 0:
		rotation = 0
		skew = 0
	if transform_flags & 4 == 0:
		position = Vector2.ZERO
