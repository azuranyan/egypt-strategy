class_name Empire
extends Node


@export var leader: CharacterInfo

@export var territories: Array[Territory]
@export var base_aggression: float
@export var aggression: float
@export var hp_multiplier: float = 1
@export var home_territory: Territory
@export var defeated: bool
@export var id: int


## Returns true if empire is player owned.
func is_player_owned() -> bool:
	return get_meta('player_owned', false)


## Returns true if empire is boss.
func is_boss() -> bool:
	return get_meta('boss', false)
	
	
## Returns true if empire is player owned.
func leader_name() -> String:
	return leader.name if leader else ""
	
	
## Returns true if empire has territory.
func has_territory(territory: Territory) -> bool:
	return territory.empire == self
	

## Returns true if territory is adjacent.
func is_adjacent_territory(territory: Territory) -> bool:
	if has_territory(territory):
		return false
		
	for t in territories:
		for adj in t.adjacent:
			if (not has_territory(adj)) and (adj == territory):
				return true
				
	return false


## Returns a new array of adjacent territories.
func get_adjacent() -> Array[Territory]:
	var re: Array[Territory] = []
	for t in Game.get_territories():
		if (t not in re) and is_adjacent_territory(t):
			re.append(t)
	return re


## Returns true if the empire is is_defeated.
func is_defeated() -> bool:
	return territories.is_empty()


## Returns the entries of empire.
func get_unit_entries() -> Array[UnitTypeEntry]:
	var arr: Array[UnitTypeEntry] = []
	for t in territories:
		arr.append_array(t.units)
	return arr
