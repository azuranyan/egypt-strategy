class_name PathingComponent
extends Node


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

@export var enabled: bool = true
