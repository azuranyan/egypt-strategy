class_name BattleImpl extends Battle


@export var _attacker: Empire
@export var _defender: Empire
@export var _territory: Territory
@export var _map_id: int

@export var _on_turn: Empire
@export var _should_end: bool


var level: Level


## Starts the battle cycle.
@warning_ignore("shadowed_variable")
func start_battle(_attacker: Empire, _defender: Empire, _territory: Territory, _map_id: int) -> void:
	if not is_running():
		SceneManager.call_scene(SceneManager.scenes.battle, 'fade_to_black')
		await SceneManager.transition_finished
		
	self._attacker = _attacker
	self._defender = _defender
	self._territory = _territory
	self._map_id = _map_id
	started.emit(_attacker, _defender, _territory, _map_id)
	
	
## Stops the battle cycle.
func stop_battle() -> void:
	if not is_running():
		return
	
	get_active_battle_scene().scene_return()
	await SceneManager.transition_finished
	var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, _attacker, _defender, _territory, _map_id)
	ended.emit(result)
	

## Returns true if the battle is running.
func is_running() -> bool:
	# a small hack to get the current overworld scene
	return get_tree().current_scene is BattleScene
	
	
## Returns true if battle should end.
func should_end() -> bool:
	return _should_end
	
	
## Returns the active overworld scene. Kind of a hack, but yes.
func get_active_battle_scene() -> BattleScene:
	assert(is_running(), 'overworld not running!')
	return get_tree().current_scene
	

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
	return _on_turn
	

## Returns true if battle is on battle phase.
func is_battle_phase() -> bool:
	assert(false, 'not implemented')
	return false
	

## Returns true if this is a training battle.
func is_training_battle() -> bool:
	return false
	
	
## Returns true if this is a quick battle.
func is_quick_battle() -> bool:
	return false
	
	
## Returns true if saving is allowed.
func saving_allowed() -> bool:
	return false
	
	
## Returns the unit at cell.
func get_unit_at(cell: Vector2) -> Unit:
	for obj in get_objects_at(cell):
		# this is ugly as shit
		if obj is UnitMapObject and obj.unit.is_valid_target():
			return obj.unit
	return null
		

## Returns true if cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
	return get_unit_at(cell) != null
	
	
## Returns the objects at cell.
func get_objects_at(cell: Vector2) -> Array[MapObject]:
	return level.get_objects_at(cell)
	

## Returns all the pathables.
func get_pathables() -> Array[PathableComponent]:
	return level.pathables


## Returns all the pathables at cell.
func get_pathables_at(cell: Vector2) -> Array[PathableComponent]:
	return level.get_pathables_at(cell)

	
## Returns the world bounds.
func world_bounds() -> Rect2:
	return level.get_bounds()


## Tests the evaluators and returns the first valid [enum Battle.Result].
func get_battle_result() -> BattleResult:
	assert(false, 'not implemented')
	return null


## Returns a config variable.
func get_config_value(config: StringName) -> Variant:
	var config_data := {
		poison_damage = 1,
	}
	return config_data.get(config, null)
	
	
## Adds a map object.
func add_map_object(map_object: MapObject) -> void:
	#level.add_object(map_object)
	level.map.add_child(map_object)
	
	
## Removes a map object.
func remove_map_object(map_object: MapObject) -> void:
	#level.remove_object(map_object)
	level.map.remove_child(map_object)


## Draws overlays.
func draw_overlay(cells: PackedVector2Array, overlay: Overlay):
	assert(false, 'not implemented')
	
	
## Clears overlays.
func clear_overlays(overlay_mask: int):
	assert(false, 'not implemented')
	
	
