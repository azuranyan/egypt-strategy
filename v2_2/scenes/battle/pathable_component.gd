@tool
class_name PathableComponent
extends MapObjectComponent


const GROUP_ID := 'Pathables'


## Colors for the debug tile.
const TILE_COLORS := {
	Map.PathingGroup.NONE: Color(0, 0, 0, 0),
	Map.PathingGroup.UNIT: Color(0, 1, 0, 0.3),
	Map.PathingGroup.DOODAD: Color(0, 0, 1, 0.3),
	Map.PathingGroup.TERRAIN: Color(0.33, 1, 0.5, 0.3),
	Map.PathingGroup.IMPASSABLE: Color(1, 0, 0, 0.3),
}

## Determines the pathing group of this object.
@export var pathing_group: Map.PathingGroup

## List of conditional pathing. 
## If the default pathing rules need to be overridden, set [code]pathing_group[/code] to [code]Map.Pathing.None[/code]
@export var conditions: Array[PathingCondition]

## Whether this 
@export var enabled: bool = true


func group_id() -> StringName:
	return GROUP_ID


## Returns true if unit can path through this object.
func is_pathable(unit: Unit) -> bool:
	return enabled and _conditionally_pathable(unit)


func _conditionally_pathable(unit: Unit) -> bool:
	for condition in conditions:
		if not condition.is_pathable(map_object, pathing_group, unit):
			return false
	return true
