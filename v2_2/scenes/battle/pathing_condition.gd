class_name PathingCondition
extends Resource
## Interface for custom pathability rules.


## Returns true if this unit can path through this object.
func is_pathable(_map_object: MapObject, _pathing_group: Map.PathingGroup, _unit: Unit) -> bool:
	return true
 
