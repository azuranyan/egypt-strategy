class_name Overworld extends Node
## The overworld interface.

	
## Emitted when the overworld enters scene. [b]Cannot be suspended.[/b]
signal started

## Emitted when the overworld exits. [b]Cannot be suspended.[/b]
signal ended

## Emitted when a new cycle starts. Can be suspended.
signal cycle_started(cycle: int)

## Emitted when a cycle ends. Can be suspended.
signal cycle_ended(cycle: int)

## Emitted when an empire's turn starts. Can be suspended.
signal turn_started(empire: Empire)

## Emitted when an empire's turn ends. Can be suspended.
signal turn_ended(empire: Empire)

## Emitted when an empire is defeated. Can be suspended.
signal empire_defeated(empire: Empire)

## Emitted when a territory ownership changed. [b]Cannot be suspended.[/b]
signal territory_owner_changed(old_owner: Empire, new_owner: Empire, territory: Territory)


## Starts the overworld cycle.
func start_overworld_cycle() -> void:
	assert(false, 'not implemented')
	
	
## Stops the overworld cycle.
func stop_overworld_cycle() -> void:
	assert(false, 'not implemented')
	

## Returns true if overworld is running.
func is_running() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns an array of all territories.
func territories() -> Array[Territory]:
	assert(false, 'not implemented')
	return []


## Returns an array of all the empires.
func empires() -> Array[Empire]:
	assert(false, 'not implemented')
	return []
	
	
## Returns the player empire.
func player_empire() -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the boss empire.
func boss_empire() -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns a list of all the active empires.
func active_empires() -> Array[Empire]:
	assert(false, 'not implemented')
	return []
	
	
## Returns a list of all the defeated empires.
func defeated_empires() -> Array[Empire]:
	assert(false, 'not implemented')
	return []
	
	
## Returns the number of overworld cycles.
func cycle() -> int:
	assert(false, 'not implemented')
	return 0

	
## Returns the empire currently on turn.
func on_turn() -> Empire:
	assert(false, 'not implemented')
	return null
	

## Returns true if the boss is active.
func is_boss_active() -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Returns the empire with the given leader.
func get_empire_by_chara_id(_chara_id: StringName) -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the empire with the given leader name.
func get_empire_by_leader_name(_name: StringName) -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the territory with the given name.
func get_territory_by_name(_territory_name: StringName) -> Territory:
	assert(false, 'not implemented')
	return null
	
	
## Returns the owner of the territory.
func get_territory_owner(_territory: Territory) -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns true if territory is a home territory.
func is_home_territory(_t: Territory) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Connects two territories, [code]a[/code] and [code]b[/code].
func connect_territories(_a: Territory, _b: Territory) -> void:
	assert(false, 'not implemented')
	
	
## Transfers territory to [code]new_owner[/code].
func transfer_territory(_new_owner: Empire, _territory: Territory) -> void:
	assert(false, 'not implemented')
	

## Replaces the ai action decision function.
## [code]fun[/code] should take no args and return an action dictionary.
## Set to null to use the default decision function.
## This function will not persist between games and have to be set every time.
func set_ai_decision_function(_fun: Variant) -> void:
	assert(false, 'not implemented')
	
