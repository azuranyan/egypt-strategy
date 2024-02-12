class_name Battle extends Node

	
## Emitted when the battle enters scene. [b]Cannot be suspended.[/b]
signal started(attacker: Empire, defender: Empire, territory: Territory, map_id: int)

## Emitted when the battle exits. [b]Cannot be suspended.[/b]
signal ended(result: BattleResult)

## Emitted when a new cycle starts.
signal cycle_started(cycle: int)

## Emitted when a cycle ends.
signal cycle_ended(cycle: int)

## Emitted when an empire's turn started.
signal turn_started(empire: Empire)

## Emitted when an empire's turn ended.
signal turn_ended(empire: Empire)


enum Overlay {
	## The reachable tiles.
	PATHABLE,
	
	## The units attack range.
	ATTACK_RANGE,
	
	## Attack shape.
	TARGET_SHAPE,
	
	## Unit path.
	PATH,
}

enum {
	## Mask for pathable overlay.
	PATHABLE_MASK = 1 << Overlay.PATHABLE,
	
	## Mask for attack range overlay.
	ATTACK_RANGE_MASK = 1 << Overlay.ATTACK_RANGE,
	
	## Mask for target shape overlay.
	TARGET_SHAPE_MASK = 1 << Overlay.TARGET_SHAPE,
	
	## Mask for path overlay.
	PATH_MASK = 1 << Overlay.PATH,
}


## Starts the battle cycle.
func start_battle(attacker: Empire, defender: Empire, territory: Territory, map_id: int) -> void:
	assert(false, 'not implemented')
	
	
## Stops the battle cycle.
func stop_battle() -> void:
	assert(false, 'not implemented')


## Returns true if the battle is running.
func is_running() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if battle should end.
func should_end() -> bool:
	assert(false, 'not implemented')
	return false
	

## Creates the agent for the empire.
func create_agent(_empire: Empire) -> BattleAgent:
	assert(false, 'not implemented')
	return null
		
		
## Sets the agent for empire.
func set_agent(_empire: Empire, _agent: BattleAgent) -> void:
	assert(false, 'not implemented')
	
	
## Deletes the agent.
func delete_agent(_agent: BattleAgent) -> void:
	assert(false, 'not implemented')
	
	
## Returns the agent for the empire if available.
func get_agent(_empire: Empire) -> BattleAgent:
	assert(false, 'not implemented')
	return null
	
	
## Returns the ai-controlled empire.
func ai() -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the player-controlled empire.
func player() -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the attacking empire.
func attacker() -> Empire:
	assert(false, 'not implemented')
	return null
	

## Returns the defender empire.
func defender() -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the territory the battle is happening on.
func territory() -> Territory:
	assert(false, 'not implemented')
	return null
	
	
## Returns the map id being used.
func map_id() -> int:
	assert(false, 'not implemented')
	return 0
	
	
## Returns the battle missions.
func missions() -> Array[VictoryCondition]:
	assert(false, 'not implemented')
	return []
	
	
## Returns the battle bonus goals.
func bonus_goals() -> Array[VictoryCondition]:
	assert(false, 'not implemented')
	return []


## Returns the empire currently on turn.
func on_turn() -> Empire:
	assert(false, 'not implemented')
	return null


## Returns true if battle is on battle phase.
func is_battle_phase() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if this is a training battle.
func is_training_battle() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns true if this is a quick battle.
func is_quick_battle() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if saving is allowed.
func saving_allowed() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns the unit at cell.
func get_unit_at(_cell: Vector2) -> Unit:
	assert(false, 'not implemented')
	return null


## Returns true if cell is occupied by a unit.
func is_occupied(_cell: Vector2) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns the objects at cell.
func get_objects_at(_cell: Vector2) -> Array[MapObject]:
	assert(false, 'not implemented')
	return []
	

## Returns all the pathables.
func get_pathables() -> Array[PathableComponent]:
	assert(false, 'not implemented')
	return []


## Returns all the pathables at cell.
func get_pathables_at(_cell: Vector2) -> Array[PathableComponent]:
	assert(false, 'not implemented')
	return []

	
## Returns the world bounds.
func world_bounds() -> Rect2:
	assert(false, 'not implemented')
	return Rect2()


## Returns the battle result.
func get_battle_result() -> BattleResult:
	assert(false, 'not implemented')
	return null
	
	
## Evaluates victory conditions and returns first valid result.
func evaluate_battle_result() -> BattleResult:
	assert(false, 'not implemented')
	return null
	

## Returns a config variable.
func get_config_value(_config: StringName) -> Variant:
	assert(false, 'not implemented')
	return null
	
	
## Adds a map object.
func add_map_object(_map_object: MapObject) -> void:
	assert(false, 'not implemented')
	
	
## Removes a map object.
func remove_map_object(_map_object: MapObject) -> void:
	assert(false, 'not implemented')


## Draws overlays.
func draw_overlay(cells: PackedVector2Array, overlay: Overlay):
	assert(false, 'not implemented')
	
	
## Clears overlays.
func clear_overlays(overlay_mask: int):
	assert(false, 'not implemented')
	
	
