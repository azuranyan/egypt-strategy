class_name Unit
extends Node
## This structure lives only after everything has loaded in.

## Default walk (phase friendly units).
const PHASE_NONE = 0
	
## Ignores enemies.
const PHASE_ENEMIES = 1 << 0
	
## Ignores doodads.
const PHASE_DOODADS = 1 << 1
	
## Ignores terrain.
const PHASE_TERRAIN = 1 << 2
	
## Ignores all pathing and placement restrictions.
const PHASE_NO_CLIP = 1 << 3


@export var unit_type: UnitType

@export var empire: Empire

@export var stats := {
	maxhp = 0,
	hp = 5,
	mov = 0,
	dmg = 0,
	rng = 0,
}

@export var phase: int = PHASE_NONE

@onready var map_object: MapObject


## Returns true if the other unit is an ally.
func is_ally(other: Unit) -> bool:
	return other != self and other.empire == empire
	

## Returns true if the other unit is an enemy.
func is_enemy(other: Unit) -> bool:
	return other != self and other.empire != empire


func is_pathable_cell(cell: Vector2) -> bool:
	
	return false
	
	
func set_standby(standby: bool):
	map_object.map_position = Map.OUT_OF_BOUNDS
	


func is_pathable(pathing: PathingComponent) -> bool:
	if phase & PHASE_NO_CLIP != 0:
		return true
	
	var pathable := true
	match pathing.pathing_group:
		Map.PathingGroup.UNIT:
			if pathing.get_parent().type == 'unit':
				phase & PHASE_ENEMIES
				pathable = pathing.get_parent().get_unit().is_enemy(self)
		Map.PathingGroup.DOODAD:
			pathable = phase & PHASE_DOODADS != 0
		Map.PathingGroup.TERRAIN:
			pathable = phase & PHASE_TERRAIN != 0
		Map.PathingGroup.IMPASSABLE:
			pathable = false
				
	return pathable and _check_pathing_conditions(pathing)
	

## Returns true if pathing conditions are met.
func _check_pathing_conditions(pathing: PathingComponent) -> bool:
	for cond in pathing.conditions:
		if cond == null: continue
		if not cond.is_pathable(pathing, self):
			return false
	return true
