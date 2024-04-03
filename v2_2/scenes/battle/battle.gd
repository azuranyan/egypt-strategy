class_name Battle
extends Node


## Bitflag for pathable cells overlay.
const PLACEABLE_CELLS := 1
	
## Bitflag for non pathable cells overlay.
const NON_PLACEABLE_CELLS := 2

## Bitflag for attack range overlay.
const ATTACK_RANGE := 4
	
## Bitflag for target shape overlay.
const TARGET_SHAPE := 8
	
## Bitflag for unit path overlay.
const UNIT_PATH := 16

## All pathing related overlays.
const PATHING_OVERLAYS := PLACEABLE_CELLS | NON_PLACEABLE_CELLS | UNIT_PATH

## All attack related overlays.
const ATTACK_OVERLAYS := ATTACK_RANGE | TARGET_SHAPE

## All the overlays.
const ALL_OVERLAYS := PATHING_OVERLAYS | ATTACK_OVERLAYS


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

	## Target is occupied by another unit.
	ALREADY_OCCUPIED,

	## Target is not pathable.
	NOT_PATHABLE,
}


enum Type {CONQUEST, DEFENSE, TRAINING, FINAL_BATTLE}


## This exists because [Game] battle intellisense doesn't work.
## This also lets us do additional checks and intercept accesses.
static func instance() -> Battle:
	assert(Game.battle != null)
	return Game.battle


## Starts the battle cycle.
func start_battle(_data: Dictionary) -> void:
	assert(false, 'not implemented')
	
	
## Stops the battle cycle.
func stop_battle(_result_value: int = BattleResult.CANCELLED) -> void:
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


## Returns the type of the battle.
func battle_type() -> Type:
	assert(false, 'not implemented')
	return 0 as Type
	
	
## Returns the battle missions.
func missions() -> Array[Objective]:
	assert(false, 'not implemented')
	return []
	
	
## Returns the battle bonus goals.
func bonus_goals() -> Array[Objective]:
	assert(false, 'not implemented')
	return []


## Returns the empire currently on turn.
func on_turn() -> Empire:
	assert(false, 'not implemented')
	return null
	

## Returns the number of cycles.
func cycle() -> int:
	assert(false, 'not implemented')
	return 0


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
func get_unit_at(_cell: Vector2, _excluded: Unit = null) -> Unit:
	assert(false, 'not implemented')
	return null


## Returns true if cell is occupied by a unit.
func is_occupied(_cell: Vector2, _excluded: Unit = null) -> bool:
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


## Returns the world.
func world() -> World:
	assert(false, 'not implemented')
	return null

	
## Returns the world bounds.
func world_bounds() -> Rect2:
	assert(false, 'not implemented')
	return Rect2()


## Returns the out of bounds location in global coordinates.
func global_out_of_bounds() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Returns the global coordinates of a screen position.
## Screen positions are affected by camera transformation so this conversion is necessary.
func screen_to_global(_screen_pos: Vector2) -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Returns the uniform coordinates of a screen position.
## Screen positions are affected by camera transformation so this conversion is necessary.
func screen_to_uniform(_screen_pos: Vector2) -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Returns the cell of a screen position.
## Screen positions are affected by camera transformation so this conversion is necessary.
func screen_to_cell(_screen_pos: Vector2) -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Returns the mouse position in uniform coordinates.
func get_uniform_mouse_position() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Returns the mouse cell.
func get_mouse_cell() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Returns the spawn points
func get_spawn_points(_type: SpawnPoint.Type) -> Array[SpawnPoint]:
	assert(false, 'not implemented')
	return []


## Returns the last known battle result. 
func get_battle_result() -> BattleResult:
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


## Draws the unit path.
func draw_unit_path(_unit: Unit, _cell: Vector2) -> void:
	assert(false, 'not implemented')


## Draws the pathable cells.
func draw_unit_placeable_cells(_unit: Unit, _use_alt_color := false) -> void:
	assert(false, 'not implemented')


## Draws non pathable cells that aren't solely units.
func draw_unit_non_pathable_cells(_unit: Unit) -> void:
	assert(false, 'not implemented')


## Draws the cells that can be reached by specified attack.
func draw_unit_attack_range(_unit: Unit, _attack: Attack) -> void:
	assert(false, 'not implemented')


## Draws the cells in target aoe.
func draw_unit_attack_target(_unit: Unit, _attack: Attack, _target: Array[Vector2], _rotation: Array[float]) -> void:
	assert(false, 'not implemented')


## Clears overlays.
func clear_overlays(_mask: int = ALL_OVERLAYS) -> void:
	assert(false, 'not implemented')


## Sets the camera target. If target are either [Unit] or [Node2D],
## the camera will follow it and if target is [Vector2], the camera
## will be fixed to that position. Setting this to [code]null[/code]
## will stop following the previous target node.
func set_camera_target(_target: Variant) -> void:
	assert(false, 'not implemented')


## Sets the cursor position
func set_cursor_pos(_cell: Vector2) -> void:
	assert(false, 'not implemented')


## Returns the cursor position.
func get_cursor_pos() -> Vector2:
	assert(false, 'not implemented')
	return Vector2.ZERO


## Returns the HUD.
func hud() -> BattleHUD:
	assert(false, 'not implemented')
	return null


func show_pause_menu() -> void:
	assert(false, 'not implemented')


func hide_pause_menu() -> void:
	assert(false, 'not implemented')


func show_forfeit_dialog() -> void:
	assert(false, 'not implemented')


func hide_forfeit_dialog() -> void:
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
func unit_action_attack(_unit: Unit, _attack: Attack, _target: Array[Vector2], _rotation: Array[float]) -> void:
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
