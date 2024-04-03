class_name PathingCondition
extends Resource
## Interface for custom pathability rules.


## Returns true if this unit can path through this object.
func is_pathable(_context: BattleContext, _map_object: MapObject, _unit: UnitState) -> bool:
	return true
 
