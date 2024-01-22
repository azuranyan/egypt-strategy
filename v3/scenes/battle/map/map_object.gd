@tool
class_name MapObject
extends Node2D


signal cell_changed(old_cell: Vector2, new_cell: Vector2)
signal map_position_changed(old_position: Vector2, new_position: Vector2)
signal map_rotation_changed(old_rotation: Vector2, new_rotation: Vector2)


@export var type: String

@export var map_position: Vector2 = Map.OUT_OF_BOUNDS:
	set(value):
		map_position = value
		if not is_node_ready():
			await ready
		_update_position()
		map_position_changed.emit()
		
@export var map_rotation: float


var world: World

var _global_pos: Vector2


func _ready():
	set_notify_transform(true)
	
	
func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED and _global_pos != position and is_instance_valid(world):
		map_position = world.as_uniform(position)
		if Engine.is_editor_hint():
			map_position = cell()
			

func cell() -> Vector2:
	return Vector2(round(map_position.x), round(map_position.y))
	
	
func _world_changed(_world: World):
	world = _world
	_update_position()


func _update_position():
	if is_instance_valid(world):
		_global_pos = world.as_global(map_position)
	else:
		_global_pos = map_position
	position = _global_pos
