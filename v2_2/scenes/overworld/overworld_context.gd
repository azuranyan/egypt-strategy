class_name OverworldContext
extends Resource

enum State {
	INVALID = 0,
	READY,
	CYCLE_START,
	TURN_START,
	TURN_ONGOING,
	TURN_END,
	CYCLE_END,
}

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
@export var state: State

	
func get_empire_by_id(id: int) -> Empire:
	if id == -1:
		return null
	assert(id >= 0 and id < empires.size())
	return empires[id]
	
	
func get_empire_by_leader(leader: CharacterInfo) -> Empire:
	for e in empires:
		if e.leader == leader:
			return e
	return null
	
	
func get_empire_by_leader_name(leader_name: String) -> Empire:
	for e in empires:
		if e.leader_name() == leader_name:
			return e
	return null
	
	
func get_territory_by_id(id: int) -> Territory:
	if id == -1:
		return null
	assert(id >= 0 and id < territories.size())
	return territories[id]
	
	
func get_territory_by_name(territory_name: String) -> Territory:
	for t in territories:
		if t.name == territory_name:
			return t
	return null
	
	
func on_turn() -> Empire:
	return active_empires[turn_index]
	

func is_boss_active() -> bool:
	return boss_empire in active_empires
