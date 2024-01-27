@tool
class_name MapObject
extends Node2D


signal world_changed
signal cell_changed(old_cell: Vector2, new_cell: Vector2)
signal map_position_changed(old_position: Vector2, new_position: Vector2)


## Colors for the debug tile.
const TILE_COLORS := {
	Map.PathingGroup.NONE: Color(0, 0, 0, 0),
	Map.PathingGroup.UNIT: Color(0, 1, 0, 0.3),
	Map.PathingGroup.DOODAD: Color(0, 0, 1, 0.3),
	Map.PathingGroup.TERRAIN: Color(0.33, 1, 0.5, 0.3),
	Map.PathingGroup.IMPASSABLE: Color(1, 0, 0, 0.3),
}

@export var map_position: Vector2 = Map.OUT_OF_BOUNDS:
	set(value):
		map_position = value
		if not is_node_ready():
			await ready
		_update_position()
		map_position_changed.emit()

@export_group("Editor")

@export var snap_to_cell: bool = true


var world: World
var components := {}

var _global_pos: Vector2
var _cell: Vector2
var _standby_pos: Vector2


func _ready():
	set_notify_transform(true)
	
	
func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED and _global_pos != position and is_instance_valid(world):
		map_position = world.as_uniform(position)
		if Engine.is_editor_hint() and snap_to_cell:
			map_position = cell()
			
			
func _get_configuration_warnings() -> PackedStringArray:
	var arr := PackedStringArray()
	if not is_instance_valid(world): 
		arr.append("world is null")
	if not (get_parent() is Map or get_parent() is MapObjectContainer):
		arr.append("not assigned to Map or MapObjectContainer")
	return arr
			
			
func _enter_tree():
	update_configuration_warnings()
	
	
func _exit_tree():
	update_configuration_warnings()


func set_standby(standby: bool):
	if standby:
		_standby_pos = map_position
		map_position = Map.OUT_OF_BOUNDS
	else:
		map_position = _standby_pos
	

func is_standby() -> bool:
	return map_position == Map.OUT_OF_BOUNDS
	

func cell() -> Vector2:
	return Vector2(round(map_position.x), round(map_position.y))
	
	
func _world_changed(_world: World):
	world = _world
	_update_position()
	update_configuration_warnings()
	world_changed.emit()


func _update_position():
	if is_instance_valid(world):
		_global_pos = world.as_global(map_position)
	else:
		_global_pos = Vector2.ZERO
	position = _global_pos
	
	if cell() != _cell:
		_cell = cell()
		cell_changed.emit()
