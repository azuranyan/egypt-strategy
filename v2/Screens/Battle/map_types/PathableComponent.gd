@tool
class_name PathableComponent
extends Node2D


## Colors for the debug tile.
const TILE_COLORS := {
	Map.Pathing.NONE: Color(0, 0, 0, 0),
	Map.Pathing.UNIT: Color(0, 1, 0, 0.3),
	Map.Pathing.DOODAD: Color(0, 0, 1, 0.3),
	Map.Pathing.TERRAIN: Color(0.33, 1, 0.5, 0.3),
	Map.Pathing.IMPASSABLE: Color(1, 0, 0, 0.3),
}


## Determines the pathing group of this object.
@export var pathing_group: Map.Pathing

## List of conditional pathing. 
## If the default pathing rules need to be overridden, set [code]pathing_group[/code] to [code]Map.Pathing.None[/code]
@export var conditions: Array[ConditionalPathing]

@export var enabled: bool = true

var cell: Vector2

var _map_object: MapObject = null

@export var _debug_tile: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	PathableServer.add_pathable(self)
	if is_instance_valid(_map_object):
		_map_object.map_pos_changed.connect(_on_map_object_map_pos_changed)
	visibility_layer = 1 << 9
	_update_debug_tile()
	

func _enter_tree():
	_map_object = get_parent() as MapObject
	if Engine.is_editor_hint():
		if is_instance_valid(_debug_tile):
			remove_child(_debug_tile)
		_debug_tile = Polygon2D.new()
		add_child(_debug_tile)
	update_configuration_warnings()
	
	
func _exit_tree():
	if is_instance_valid(_debug_tile):
		remove_child(_debug_tile)
	if is_instance_valid(_map_object):
		_map_object.map_pos_changed.disconnect(_on_map_object_map_pos_changed)
	PathableServer.remove_pathable(self)
	request_ready()
	
	
func _get_configuration_warnings() -> PackedStringArray:
	if not is_instance_valid(_map_object):
		return ['expected a MapObject parent!']
	return []
	
		
func _update_debug_tile():
	if not is_instance_valid(_debug_tile): return
	_debug_tile.hide()
	if is_instance_valid(_map_object) and is_instance_valid(_map_object.map):
		_debug_tile.self_modulate = Color("#ffcc00", 0.3) if has_conditions() else TILE_COLORS[pathing_group]
		_debug_tile.transform = _map_object.map.world.world_transform
		_debug_tile.position = _map_object.map.world.as_aligned(_map_object.cell()) - _map_object.position  
		
		var p: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for i in range(4):
			p[i] = p[i] * _map_object.map.world.tile_size
		_debug_tile.polygon = p
		_debug_tile.show()
	

func has_conditions() -> bool:
	for cond in conditions:
		if cond != null:
			return true
	return false
	
	
func check_conditions(unit: Unit) -> bool:
	for cond in conditions:
		if cond == null: continue
		if not cond.is_pathable(self, unit):
			return false
	return true
	
	
func _on_map_object_map_pos_changed():
	PathableServer.update_pathable(self, cell, _map_object.cell())
	cell = _map_object.cell()
	_update_debug_tile()
	
	
