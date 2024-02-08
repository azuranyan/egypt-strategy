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

## Emitted an empire's turn starts. Can be suspended.
signal turn_started(empire: Empire)

## Emitted an empire's turn ends. Can be suspended.
signal turn_ended(empire: Empire)


## Starts the overworld cycle.
func start_overworld_cycle():
	assert(false, 'not implemented')
	
	
## Stops the overworld cycle.
func stop_overworld_cycle():
	assert(false, 'not implemented')
	
	
## Pauses the overworld and waits until resume.
func queue_suspend():
	assert(false, 'not implemented')
	
	
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
func get_empire_by_chara_id(chara_id: StringName) -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the empire with the given leader name.
func get_empire_by_leader_name(name: StringName) -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns the territory with the given name.
func get_territory_by_name(territory_name: StringName) -> Territory:
	assert(false, 'not implemented')
	return null
	
	
## Returns the owner of the territory.
func get_territory_owner(territory: Territory) -> Empire:
	assert(false, 'not implemented')
	return null
	
	
## Returns true if territory is a home territory.
func is_home_territory(t: Territory) -> bool:
	assert(false, 'not implemented')
	return false
	
	
## Connects two territories, [code]a[/code] and [code]b[/code].
func connect_territories(a: Territory, b: Territory):
	assert(false, 'not implemented')
	
	
## Transfers territory to [code]new_owner[/code].
func transfer_territory(new_owner: Empire, territory: Territory):
	assert(false, 'not implemented')
	

## Returns the owner of the unit.
func get_unit_owner(unit: Unit) -> Empire:
	assert(false, 'not implemented')
	return null


## Returns true if unit is a hero unit.
func is_hero_unit(unit: Unit) -> bool:
	assert(false, 'not implemented')
	return false
