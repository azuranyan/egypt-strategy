class_name OverworldContext
extends Resource

@export var overworld_scene: PackedScene
@export var territories: Array[Territory]
@export var empires: Array[Empire]
@export var player_empire: Empire
@export var boss_empire: Empire

@export_group("State")
@export var active_empires: Array[Empire]
@export var defeated_empires: Array[Empire]
@export var cycle_count: int
@export var turn_index: int
@export var state: StringName
@export var waiting: bool

	
## Returns the empire with the given id.
func get_empire_by_id(id: int) -> Empire:
	if id == -1:
		return null
	assert(id >= 0 and id < empires.size())
	return empires[id]
	
	
## Returns the empire with the given leader.
func get_empire_by_leader(leader: CharacterInfo) -> Empire:
	for e in empires:
		if e.leader == leader:
			return e
	return null
	
	
## Returns the territory with the given id.
func get_territory_by_id(id: int) -> Territory:
	if id == -1:
		return null
	assert(id >= 0 and id < territories.size())
	return territories[id]
	
	
## Returns the territory with the given name.
func get_territory_by_name(territory_name: String) -> Territory:
	for t in territories:
		if t.name == territory_name:
			return t
	return null
	
	
## Returns the owner of the territory.
func get_territory_owner(territory: Territory) -> Empire:
	for e in empires:
		if territory in e.territories:
			return e
	return null
	

## Returns the owner of the unit.
func get_unit_owner(unit: Unit) -> Empire:
	for e in empires:
		if unit in e.units:
			return e
	return null


## Returns true if unit is a hero unit.
func is_hero_unit(unit: Unit) -> bool:
	for e in empires:
		if e.hero_unit == unit.unit_type:
			return true
	return false


## Returns the empire currently on turn.
func on_turn() -> Empire:
	return active_empires[turn_index]
	

## Returns true if the boss is active.
func is_boss_active() -> bool:
	return boss_empire in active_empires
