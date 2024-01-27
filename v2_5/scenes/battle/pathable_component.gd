@tool
class_name PathableComponent
extends MapObjectComponent
## Provides pathing to a [MapObject]


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
func is_pathable(context: BattleContext, unit: Unit) -> bool:
	return default_pathable(context, unit) and conditionally_pathable(context, unit)
	

func default_pathable(_context: BattleContext, unit: Unit) -> bool:
	if (not enabled) or (unit.phase & Unit.PHASE_NO_CLIP != 0):
		return true
	match pathing_group:
		Map.PathingGroup.UNIT:
			if (map_object is Unit) and unit.is_enemy(map_object.unit):
				return unit.phase & Unit.PHASE_ENEMIES != 0
		Map.PathingGroup.DOODAD:
			return unit.phase & Unit.PHASE_DOODADS != 0
		Map.PathingGroup.TERRAIN:
			return unit.phase & Unit.PHASE_TERRAIN != 0
		Map.PathingGroup.IMPASSABLE:
			return false
	return true


func conditionally_pathable(context: BattleContext, unit: Unit) -> bool:
	for condition in conditions:
		if not condition.is_pathable(context, map_object, unit):
			return false
	return true
