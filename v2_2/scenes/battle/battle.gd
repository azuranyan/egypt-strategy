class_name Battle extends Node

	
## Emitted when the battle enters scene. [b]Cannot be suspended.[/b]
signal battle_started(attacker: Empire, defender: Empire, territory: Territory, map_id: int)

## Emitted when the battle exits. [b]Cannot be suspended.[/b]
signal battle_ended(result: BattleResult)

## Emitted right before player prep phase starts.
signal player_prep_phase

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


enum {
	## No errors.
	OK = 0,

	## Generic invalid action error.
	INVALID_ACTION,
	
	## Unit's turn is already done.
	TURN_DONE,
	
	## Unit has already taken this type of action.
	ACTION_ALREADY_TAKEN,
	
	## Attack is null.
	NO_ATTACK,
	
	## Attack or movement target is out of range.
	OUT_OF_RANGE,
	
	## Attack target is inside minimum range.
	INSIDE_MIN_RANGE,
	
	## Special attack is not yet unlocked.
	SPECIAL_NOT_UNLOCKED,
	
	## Attack requires a target unit but none is found.
	NO_TARGET,
	
	## Target unit does not meet requirements.
	INVALID_TARGET,
}


## Starts the battle cycle.
func start_battle(_attacker: Empire, _defender: Empire, _territory: Territory, _map_id: int) -> void:
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


## Returns the spawn points
func get_spawn_points(_type: SpawnPoint.Type) -> Array[SpawnPoint]:
	assert(false, 'not implemented')
	return []


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
func draw_overlay(_cells: PackedVector2Array, _overlay: Overlay):
	assert(false, 'not implemented')
	
	
## Clears overlays.
func clear_overlays(_overlay_mask: int) -> void:
	assert(false, 'not implemented')
	

## Sets the camera target. If target are either [Unit] or [Node2D],
## the camera will follow it and if target is [Vector2], the camera
## will be fixed to that position. Setting this to [code]null[/code]
## will stop following the previous target node.
func set_camera_target(_target: Variant) -> void:
	assert(false, 'not implemented')

	
#region Actions
## Returns [constant Error.OK] if movement is valid otherwise returns the error code.
func check_unit_move(_unit: Unit, _cell: Vector2) -> int:
	assert(false, 'not implemented')
	return 0


## Returns [constant Error.OK] if attack is valid otherwise returns the error code.
func check_unit_attack(_unit: Unit, _attack: Attack, _target: Vector2, _rotation: float) -> int:
	assert(false, 'not implemented')
	return 0


## Executes unit action.
func do_action(_unit: Unit, _action: UnitAction) -> void:
	assert(false, 'not implemented')

		
## Unit does nothing and ends their turn.
func unit_action_pass(_unit: Unit) -> void:
	assert(false, 'not implemented')


## Unit walks towards a target.
func unit_action_move(_unit: Unit, _target: Vector2) -> void:
	assert(false, 'not implemented')


## Unit executes attack.
func unit_action_attack(_unit: Unit, _attack: Attack, _target: PackedVector2Array, _rotation: PackedFloat64Array) -> void:
	assert(false, 'not implemented')


## Generates an array of all possible actions.
func generate_actions(_unit: Unit) -> Array[UnitAction]:
	assert(false, 'not implemented')
	return []
			
	
## Returns true if the given action is a valid action for the unit.
func is_valid_action(_action: UnitAction, _unit: Unit) -> bool:
	assert(false, 'not implemented')
	return false
#endregion Actions
