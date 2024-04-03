@tool
extends Node

const PATHABLE_GROUPNAME := "Map_pathable_components"


var pathable_map := {}


## Adds a pathable to the server.
func add_pathable(pathable: PathableComponent):
	pathable.add_to_group(PATHABLE_GROUPNAME)
	_add_pathable(pathable, pathable.cell)
	
	
## Removes a pathable from the server.
func remove_pathable(pathable: PathableComponent):
	pathable.remove_from_group(PATHABLE_GROUPNAME)
	_remove_pathable(pathable, pathable.cell)
	
	
## Updates server of the pathable changes.
func update_pathable(pathable: PathableComponent, old_cell: Vector2, new_cell: Vector2):
	if old_cell == new_cell:
		return
	_remove_pathable(pathable, old_cell)
	_add_pathable(pathable, new_cell)
	
	
func _add_pathable(pathable: PathableComponent, cell: Vector2):
	if cell not in pathable_map:
		pathable_map[cell] = []
	pathable_map[cell].append(pathable)
	
	
func _remove_pathable(pathable: PathableComponent, cell: Vector2):
	if cell not in pathable_map:
		return
	pathable_map[cell].erase(pathable)
	pathable_map[cell].is_empty()
	pathable_map.erase(cell)
	
	
## Returns true if the unit can path over cell.
func is_pathable(unit: Unit, cell: Vector2) -> bool:
	return _check_pathable(unit, cell, _is_pathable_unit)


## Returns true if this unit can be placed on cell.
func is_placeable(unit: Unit, cell: Vector2) -> bool:
	return _check_pathable(unit, cell, _is_placeable_unit)
	
	
func _check_pathable(unit: Unit, cell: Vector2, default_rules: Callable) -> bool:
	if cell not in pathable_map:
		return true
		
	if unit.phase & Unit.PHASE_NO_CLIP:
		return true
		
	for p in pathable_map[cell]:
		if (p == unit.pathable) or not p.enabled:
			continue
			
		if not (default_rules.call(p, unit) and p.check_conditions(unit)):
			return false
			
	return true
		
		
func _is_pathable_unit(pathable: PathableComponent, unit: Unit) -> bool:
	match pathable.pathing_group:
		Map.Pathing.UNIT:
			var other := pathable._map_object as Unit
			if other is Unit and unit.is_enemy(other):
				return unit.phase & Unit.PHASE_ENEMIES != 0
		Map.Pathing.DOODAD:
			return unit.phase & Unit.PHASE_DOODADS != 0
		Map.Pathing.TERRAIN:
			return unit.phase & Unit.PHASE_TERRAIN != 0
		Map.Pathing.IMPASSABLE:
			return false
	return true


func _is_placeable_unit(pathable: PathableComponent, unit: Unit) -> bool:
	match pathable.pathing_group:
		Map.Pathing.UNIT:
			return false
		Map.Pathing.DOODAD:
			return unit.phase & Unit.PHASE_DOODADS != 0
		Map.Pathing.TERRAIN:
			return unit.phase & Unit.PHASE_TERRAIN != 0
		Map.Pathing.IMPASSABLE:
			return false
	return true
