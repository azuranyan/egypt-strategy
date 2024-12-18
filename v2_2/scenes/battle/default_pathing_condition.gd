class_name DefaultPathingCondition extends PathingCondition


## Returns true if this unit can path through this object.
func is_pathable(map_object: MapObject, pathing_group: Map.PathingGroup, unit: Unit) -> bool:
	var phase := unit.get_phase_flags()
	if (phase & Unit.PHASE_NO_CLIP != 0):
		return true
	match pathing_group:
		Map.PathingGroup.UNIT:
			if (map_object is UnitMapObject) and unit.is_enemy(map_object.unit):
				return phase & Unit.PHASE_ENEMIES != 0
		Map.PathingGroup.DOODAD:
			return phase & Unit.PHASE_DOODADS != 0
		Map.PathingGroup.TERRAIN:
			return phase & Unit.PHASE_TERRAIN != 0
		Map.PathingGroup.IMPASSABLE:
			return false
	return true
